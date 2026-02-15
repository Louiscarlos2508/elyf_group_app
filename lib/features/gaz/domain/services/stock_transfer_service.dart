import '../../../../core/errors/app_exceptions.dart';
import '../entities/stock_transfer.dart';
import '../repositories/stock_transfer_repository.dart';
import '../repositories/cylinder_stock_repository.dart';
import '../repositories/gas_repository.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../entities/cylinder_stock.dart';
import '../../../../core/offline/offline_repository.dart' show LocalIdGenerator;

class StockTransferService {
  const StockTransferService({
    required this.transferRepository,
    required this.stockRepository,
    required this.gasRepository,
    required this.auditTrailRepository,
  });

  final StockTransferRepository transferRepository;
  final CylinderStockRepository stockRepository;
  final GasRepository gasRepository;
  final AuditTrailRepository auditTrailRepository;

  /// Initiates a transfer (Draft/Pending).
  /// Validates that source enterprise has enough stock.
  Future<void> initiateTransfer(StockTransfer transfer) async {
    // 1. Validate stock availability at source
    for (final item in transfer.items) {
      final stocks = await stockRepository.getStocksByWeight(
        transfer.fromEnterpriseId,
        item.weight,
      );
      final totalStock = stocks
          .where((s) => s.status == item.status)
          .fold<int>(0, (sum, s) => sum + s.quantity);
          
      if (totalStock < item.quantity) {
        throw ValidationException(
          'Stock insuffisant à la source pour ${item.weight}kg (${item.status.label}): $totalStock disponible',
          'INSUFFICIENT_STOCK',
        );
      }
    }

    // 2. Save transfer record
    await transferRepository.saveTransfer(transfer.copyWith(
      status: StockTransferStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Ships the transfer.
  /// Deducts stock from the source enterprise.
  Future<void> shipTransfer(String transferId, String userId) async {
    final transfer = await transferRepository.getTransferById(transferId);
    if (transfer == null) throw NotFoundException('Transfert introuvable', 'TRANSFER_NOT_FOUND');
    if (transfer.status != StockTransferStatus.pending) {
      throw ValidationException('Le transfert doit être en attente pour être expédié', 'INVALID_STATUS');
    }

    // 1. Deduct stock from source
    for (final item in transfer.items) {
      final stocks = await stockRepository.getStocksByWeight(
        transfer.fromEnterpriseId,
        item.weight,
      );
      final itemStocks = stocks
          .where((s) => s.status == item.status)
          .toList()
          ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt)); // FIFO
          
      int remainingToDebit = item.quantity;
      for (final stock in itemStocks) {
        if (remainingToDebit <= 0) break;
        final toDebit = remainingToDebit > stock.quantity ? stock.quantity : remainingToDebit;
        await stockRepository.updateStockQuantity(stock.id, stock.quantity - toDebit);
        remainingToDebit -= toDebit;
      }
      
      if (remainingToDebit > 0) {
        throw ValidationException('Stock devenu insuffisant à la source pour ${item.weight}kg', 'INSUFFICIENT_STOCK');
      }
    }

    // 2. Update transfer status
    final updatedTransfer = transfer.copyWith(
      status: StockTransferStatus.shipped,
      shippingDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await transferRepository.saveTransfer(updatedTransfer);

    // 3. Audit Log (Source)
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: transfer.fromEnterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'STOCK_TRANSFER_SHIPPED',
      entityId: transfer.id,
      entityType: 'stock_transfer',
      timestamp: DateTime.now(),
      metadata: updatedTransfer.toMap(),
    ));
  }

  /// Receives the transfer at the destination site.
  /// Increments stock at the destination enterprise.
  Future<void> receiveTransfer(String transferId, String userId) async {
    final transfer = await transferRepository.getTransferById(transferId);
    if (transfer == null) throw NotFoundException('Transfert introuvable', 'TRANSFER_NOT_FOUND');
    if (transfer.status != StockTransferStatus.shipped) {
      throw ValidationException('Le transfert doit être expédié pour être reçu', 'INVALID_STATUS');
    }

    final cylinders = await gasRepository.getCylinders();
    final destCylinders = cylinders.where((c) => c.enterpriseId == transfer.toEnterpriseId).toList();

    // 1. Add stock to destination
    for (final item in transfer.items) {
      final cylinder = destCylinders.where((c) => c.weight == item.weight).firstOrNull;
      if (cylinder == null) {
        throw NotFoundException('Modèle de bouteille ${item.weight}kg non configuré à la destination', 'CYLINDER_NOT_FOUND');
      }

      final destStocks = await stockRepository.getStocksByWeight(
        transfer.toEnterpriseId,
        item.weight,
      );
      final destStock = destStocks.where((s) => s.status == item.status).firstOrNull;

      if (destStock != null) {
        await stockRepository.updateStockQuantity(destStock.id, destStock.quantity + item.quantity);
      } else {
        // Create new stock record if none exists for this status/weight
        await stockRepository.addStock(CylinderStock(
          id: LocalIdGenerator.generate(),
          cylinderId: cylinder.id,
          weight: item.weight,
          status: item.status,
          quantity: item.quantity,
          enterpriseId: transfer.toEnterpriseId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }
    }

    // 2. Update transfer status
    final updatedTransfer = transfer.copyWith(
      status: StockTransferStatus.received,
      deliveryDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await transferRepository.saveTransfer(updatedTransfer);

    // 3. Audit Log (Destination)
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: transfer.toEnterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'STOCK_TRANSFER_RECEIVED',
      entityId: transfer.id,
      entityType: 'stock_transfer',
      timestamp: DateTime.now(),
      metadata: updatedTransfer.toMap(),
    ));
  }

  /// Cancels a transfer if it's still pending or shipped (with rollback).
  Future<void> cancelTransfer(String transferId, String userId) async {
    final transfer = await transferRepository.getTransferById(transferId);
    if (transfer == null) throw NotFoundException('Transfert introuvable', 'TRANSFER_NOT_FOUND');
    
    if (transfer.status == StockTransferStatus.received) {
      throw ValidationException('Impossible d\'annuler un transfert déjà reçu', 'INVALID_STATUS');
    }

    if (transfer.status == StockTransferStatus.shipped) {
      // Rollback stock to source
      for (final item in transfer.items) {
        final stocks = await stockRepository.getStocksByWeight(
          transfer.fromEnterpriseId,
          item.weight,
        );
        final stock = stocks.where((s) => s.status == item.status).firstOrNull;
        if (stock != null) {
          await stockRepository.updateStockQuantity(stock.id, stock.quantity + item.quantity);
        } else {
           // This shouldn't happen as it was just deducted, but for safety:
           final cylinder = (await gasRepository.getCylinders())
              .where((c) => c.enterpriseId == transfer.fromEnterpriseId && c.weight == item.weight)
              .firstOrNull;
           if (cylinder != null) {
              await stockRepository.addStock(CylinderStock(
                id: LocalIdGenerator.generate(),
                cylinderId: cylinder.id,
                weight: item.weight,
                status: item.status,
                quantity: item.quantity,
                enterpriseId: transfer.fromEnterpriseId,
                updatedAt: DateTime.now(),
              ));
           }
        }
      }
    }

    await transferRepository.saveTransfer(transfer.copyWith(
      status: StockTransferStatus.cancelled,
      updatedAt: DateTime.now(),
    ));

    // Audit Log
    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: transfer.fromEnterpriseId,
      userId: userId,
      module: 'gaz',
      action: 'STOCK_TRANSFER_CANCELLED',
      entityId: transfer.id,
      entityType: 'stock_transfer',
      timestamp: DateTime.now(),
      metadata: {'transferId': transferId, 'previousStatus': transfer.status.name},
    ));
  }
}
