import 'stock_controller.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/product_repository.dart';

import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';

class SalesController {
  SalesController({
    required SaleRepository saleRepository,
    required StockController stockController,
    required ProductRepository productRepository,
    required AuditTrailService auditTrailService,
    required TreasuryRepository treasuryRepository,
  })  : _saleRepository = saleRepository,
        _stockController = stockController,
        _productRepository = productRepository,
        _auditTrailService = auditTrailService,
        _treasuryRepository = treasuryRepository;

  final SaleRepository _saleRepository;
  final StockController _stockController;
  final ProductRepository _productRepository;
  final AuditTrailService _auditTrailService;
  final TreasuryRepository _treasuryRepository;

  Future<SalesState> fetchRecentSales() async {
    final sales = await _saleRepository.fetchSales();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return SalesState(sales: sales);
  }

  Stream<SalesState> watchRecentSales() {
    return _saleRepository.watchSales().map((sales) {
      return SalesState(sales: sales);
    });
  }

  /// Crée une vente et décrémente le stock si c'est un produit fini.
  Future<String> createSale(Sale sale, String userId) async {

    try {
      final id = await _saleRepository.createSale(sale);
      
      // Déterminer dynamiquement si on décrémente le stock
      bool isFinishedGood = false;
      try {
        final product = await _productRepository.getProduct(sale.productId);
        isFinishedGood = product?.isFinishedGood == true;
      } catch (e) {
        AppLogger.error('Error checking product type: $e', name: 'SalesController');
      }

      if (isFinishedGood && sale.quantity > 0) {
        try {
          // Idempotency: Use Sale ID to generate deterministic Stock Movement ID
          final stockMovementId = 'local_stk_sale_$id';
          
          await _stockController.recordExit(
            id: stockMovementId,
            productId: sale.productId,
            productName: sale.productName,
            quantite: sale.quantity.toDouble(),
            raison: 'Vente',
            notes: 'Vente ${sale.productName}',
          );
        } catch (e, st) {
          AppLogger.error('Failed to record stock exit for sale $id', error: e, stackTrace: st);
        }
      }

      await _recordTreasuryOperationsForSale(sale.copyWith(id: id), userId);

      try {
        await _auditTrailService.logSale(
          enterpriseId: sale.enterpriseId,
          userId: userId,
          saleId: id,
          module: 'eau_minerale',
          totalAmount: sale.totalPrice.toDouble(),
          extraMetadata: {
            'productName': sale.productName,
            'quantity': sale.quantity,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log eau_minerale sale audit', error: e);
      }

      return id;
    } catch (e, st) {
      AppLogger.error('Error in createSale: $e', name: 'SalesController', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Met à jour une vente existante.
  Future<void> updateSale(Sale oldSale, Sale newSale, String userId) async {
    try {
      // 1. Mettre à jour la vente dans le dépôt
      await _saleRepository.updateSale(newSale);

      // 2. Ajuster le stock si nécessaire
      bool isFinishedGood = false;
      try {
        final product = await _productRepository.getProduct(newSale.productId);
        isFinishedGood = product?.isFinishedGood == true;
      } catch (e) {
        AppLogger.error('Error checking product type: $e', name: 'SalesController');
      }

      if (isFinishedGood) {
        final double qtyDiff = newSale.quantity.toDouble() - oldSale.quantity.toDouble();
        if (qtyDiff != 0) {
          final adjustmentId = 'local_stk_adj_${newSale.id}_${DateTime.now().millisecondsSinceEpoch}';
          if (qtyDiff > 0) {
            // Plus vendu = Sortie supplémentaire
            await _stockController.recordExit(
              id: adjustmentId,
              productId: newSale.productId,
              productName: newSale.productName,
              quantite: qtyDiff,
              raison: 'Ajustement Vente (Augmentation)',
              notes: 'Correction quantité vente ${newSale.id}',
            );
          } else {
            // Moins vendu = Entrée (restauration)
            await _stockController.recordEntry(
              id: adjustmentId,
              productId: newSale.productId,
              productName: newSale.productName,
              quantite: -qtyDiff,
              raison: 'Ajustement Vente (Diminution)',
              notes: 'Correction quantité vente ${newSale.id}',
            );
          }
        }
      }

      // 3. Ajuster la trésorerie si nécessaire
      // Approche simple: Annuler les anciennes opérations de trésorerie et en créer de nouvelles
      // Ou mieux: Ajuster la différence. Pour la simplicité et la traçabilité:
      await _adjustTreasuryForSaleUpdate(oldSale, newSale, userId);

      // 4. Audit
      try {
        await _auditTrailService.logAction(
          enterpriseId: newSale.enterpriseId,
          userId: userId,
          action: 'UPDATE_SALE',
          module: 'eau_minerale',
          entityId: newSale.id,
          entityType: 'sale',
          metadata: {
            'saleId': newSale.id,
            'oldQuantity': oldSale.quantity,
            'newQuantity': newSale.quantity,
            'oldTotal': oldSale.totalPrice,
            'newTotal': newSale.totalPrice,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log update sale audit', error: e);
      }

    } catch (e, st) {
      AppLogger.error('Error in updateSale: $e', name: 'SalesController', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _adjustTreasuryForSaleUpdate(Sale oldSale, Sale newSale, String userId) async {
    try {
      final saleId = newSale.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Cash Adjustment
      final int cashDiff = newSale.cashAmount - oldSale.cashAmount;
      if (cashDiff != 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_adj_cash_${saleId}_$timestamp',
          enterpriseId: newSale.enterpriseId,
          userId: userId,
          amount: cashDiff,
          type: TreasuryOperationType.supply, // 'supply' est utilisé pour les entrées de caisse dans ce module
          toAccount: PaymentMethod.cash,
          date: DateTime.now(),
          reason: 'Ajustement Vente ${newSale.id}',
          referenceEntityId: newSale.id,
          referenceEntityType: 'sale_adjustment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Orange Money Adjustment
      final int omDiff = newSale.orangeMoneyAmount - oldSale.orangeMoneyAmount;
      if (omDiff != 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_adj_om_${saleId}_$timestamp',
          enterpriseId: newSale.enterpriseId,
          userId: userId,
          amount: omDiff,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.mobileMoney,
          date: DateTime.now(),
          reason: 'Ajustement Vente ${newSale.id} (Orange Money)',
          referenceEntityId: newSale.id,
          referenceEntityType: 'sale_adjustment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to adjust treasury for sale update ${newSale.id}', error: e);
    }
  }

  /// Annule une vente et restaure le stock.
  Future<void> voidSale(String saleId, String userId) async {

    try {
      final sale = await _saleRepository.getSale(saleId);
      if (sale == null) throw NotFoundException('Vente non trouvée : $saleId');
      if (sale.status == SaleStatus.voided) throw const ValidationException('Déjà annulée.');

      final voidedSale = sale.copyWith(status: SaleStatus.voided, deletedBy: userId);
      await _saleRepository.updateSale(voidedSale);

      bool isFinishedGood = false;
      try {
        final product = await _productRepository.getProduct(sale.productId);
        isFinishedGood = product?.isFinishedGood == true;
      } catch (e) {
        AppLogger.error('Error checking product type: $e', name: 'SalesController');
      }

      if (isFinishedGood && sale.quantity > 0) {
        try {
          // Supprimer le mouvement de stock original au lieu de créer une restauration
          final stockMovementId = 'local_stk_sale_$saleId';
          await _stockController.deleteMovement(stockMovementId);
        } catch (e, st) {
          AppLogger.error('Failed to remove stock movement for voided sale $saleId', error: e, stackTrace: st);
        }
      }

      await _cleanupFinancialsForSale(saleId);

      try {
        await _auditTrailService.logAction(
          enterpriseId: sale.enterpriseId,
          userId: userId,
          action: 'VOID_SALE',
          module: 'eau_minerale',
          entityId: saleId,
          entityType: 'sale',
          metadata: {
            'saleId': saleId,
            'totalAmount': sale.totalPrice,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log void sale audit', error: e);
      }
    } catch (e, st) {
      AppLogger.error('Error in voidSale: $e', name: 'SalesController', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _cleanupFinancialsForSale(String saleId) async {
    try {
      // 1. Supprimer les opérations de trésorerie (Cash et OM)
      final cashOpId = 'local_trs_sale_cash_$saleId';
      final omOpId = 'local_trs_sale_om_$saleId';
      
      final cashOp = await _treasuryRepository.getOperation(cashOpId);
      if (cashOp != null) await _treasuryRepository.deleteOperation(cashOp);
      
      final omOp = await _treasuryRepository.getOperation(omOpId);
      if (omOp != null) await _treasuryRepository.deleteOperation(omOp);

      // 2. Supprimer aussi les éventuelles opérations d'annulation (sale_void) créées par les versions précédentes
      final voidCashId = 'local_trs_void_cash_$saleId';
      final voidOmId = 'local_trs_void_om_$saleId';
      
      final vCash = await _treasuryRepository.getOperation(voidCashId);
      if (vCash != null) await _treasuryRepository.deleteOperation(vCash);
      
      final vOm = await _treasuryRepository.getOperation(voidOmId);
      if (vOm != null) await _treasuryRepository.deleteOperation(vOm);

    } catch (e) {
      AppLogger.error('Failed to cleanup financials for sale $saleId', error: e);
    }
  }

  Future<void> _recordTreasuryOperationsForSale(Sale sale, String userId) async {
    try {
      final saleId = sale.id;
      if (sale.cashAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_sale_cash_$saleId',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: sale.cashAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.cash,
          date: sale.date,
          reason: 'Vente ${sale.productName}',
          referenceEntityId: sale.id,
          referenceEntityType: 'sale',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (sale.orangeMoneyAmount > 0) {
        await _treasuryRepository.createOperation(TreasuryOperation(
          id: 'local_trs_sale_om_$saleId',
          enterpriseId: sale.enterpriseId,
          userId: userId,
          amount: sale.orangeMoneyAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.mobileMoney,
          date: sale.date,
          reason: 'Vente ${sale.productName} (Orange Money)',
          referenceEntityId: sale.id,
          referenceEntityType: 'sale',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to record treasury operations for sale ${sale.id}', error: e);
    }
  }
}

class SalesState {
  const SalesState({required this.sales});

  final List<Sale> sales;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int get todayRevenue => sales
      .where((sale) => _isToday(sale.date) && sale.status != SaleStatus.voided)
      .fold(0, (value, sale) => value + sale.totalPrice);

  int get todaySalesCount => sales.where((sale) => _isToday(sale.date)).length;

  int get todayCollections => sales
      .where((sale) => _isToday(sale.date) && sale.status != SaleStatus.voided)
      .fold(0, (value, sale) => value + sale.amountPaid);
}

