import '../entities/sale.dart';
import '../entities/stock_movement.dart';
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

  /// Creates a sale directly (no validation workflow).
  /// Stock is updated immediately upon sale creation.
  Future<String> createSale(Sale sale, String userId) async {
    // Check stock availability
    final currentStock = await stockRepository.getStock(sale.productId);
    if (currentStock < sale.quantity) {
      throw Exception('Stock insuffisant. Disponible: $currentStock');
    }

    // Determine status: fullyPaid if completely paid, otherwise validated (credit sale)
    final status = sale.isFullyPaid ? SaleStatus.fullyPaid : SaleStatus.validated;

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
      cashAmount: sale.cashAmount,
      orangeMoneyAmount: sale.orangeMoneyAmount,
      productionSessionId: sale.productionSessionId,
    );

    final saleId = await saleRepository.createSale(saleWithStatus);

    // Update stock immediately (direct sale system)
    final newStock = currentStock - sale.quantity;
    await stockRepository.updateStock(sale.productId, newStock);

    // Enregistrer le mouvement de stock pour la vente
    final movement = StockMovement(
      id: 'sale-$saleId',
      date: sale.date,
      productName: sale.productName,
      type: StockMovementType.exit,
      reason: 'Vente',
      quantity: sale.quantity.toDouble(),
      unit: 'unité',
      notes: sale.customerName.isNotEmpty 
          ? 'Client: ${sale.customerName}${sale.customerPhone.isNotEmpty ? ' (${sale.customerPhone})' : ''}'
          : null,
    );
    await stockRepository.recordMovement(movement);

    return saleId;
  }
}
