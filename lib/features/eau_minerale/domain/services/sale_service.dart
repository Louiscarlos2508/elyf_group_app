import '../entities/sale.dart';
import '../repositories/sale_repository.dart';
import '../repositories/stock_repository.dart';
import '../repositories/credit_repository.dart';

/// Business logic service for sales with automatic stock and credit management.
class SaleService {
  const SaleService({
    required this.saleRepository,
    required this.stockRepository,
    required this.creditRepository,
  });

  final SaleRepository saleRepository;
  final StockRepository stockRepository;
  final CreditRepository creditRepository;

  /// Creates a sale and handles validation workflow.
  Future<String> createSale(Sale sale, String userId, bool isManager) async {
    // Check stock availability
    final currentStock = await stockRepository.getStock(sale.productId);
    if (currentStock < sale.quantity) {
      throw Exception('Stock insuffisant. Disponible: $currentStock');
    }

    // Determine initial status
    final status = isManager ? SaleStatus.validated : SaleStatus.pending;

    final saleWithStatus = Sale(
      id: sale.id,
      productId: sale.productId,
      productName: sale.productName,
      quantity: sale.quantity,
      unitPrice: sale.unitPrice,
      totalPrice: sale.totalPrice,
      amountPaid: sale.amountPaid,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      customerId: sale.customerId,
      date: sale.date,
      status: status,
      createdBy: userId,
      customerCnib: sale.customerCnib,
      notes: sale.notes,
    );

    final saleId = await saleRepository.createSale(saleWithStatus);

    // If validated by manager, update stock immediately
    if (status == SaleStatus.validated) {
      await stockRepository.updateStock(
        sale.productId,
        currentStock - sale.quantity,
      );
    }

    return saleId;
  }

  /// Validates a pending sale and updates stock.
  Future<void> validateSale(String saleId, String validatedBy) async {
    final sale = await saleRepository.getSale(saleId);
    if (sale == null) throw Exception('Vente introuvable');
    if (sale.isValidated) throw Exception('Vente déjà validée');

    // Update stock
    final currentStock = await stockRepository.getStock(sale.productId);
    if (currentStock < sale.quantity) {
      throw Exception('Stock insuffisant pour valider cette vente');
    }

    await stockRepository.updateStock(
      sale.productId,
      currentStock - sale.quantity,
    );

    await saleRepository.validateSale(saleId, validatedBy);
  }

  /// Rejects a pending sale.
  Future<void> rejectSale(String saleId, String rejectedBy) async {
    await saleRepository.rejectSale(saleId, rejectedBy);
  }
}
