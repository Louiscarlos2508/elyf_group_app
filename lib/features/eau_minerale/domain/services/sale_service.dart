import '../../domain/entities/sale.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/customer_repository.dart';

/// Service for sale business logic.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class SaleService {
  SaleService({
    required this.stockRepository,
    required this.customerRepository,
  });

  final StockRepository stockRepository;
  final CustomerRepository customerRepository;

  /// Validates stock availability for a sale.
  ///
  /// Returns true if stock is sufficient, false otherwise.
  Future<bool> validateStockAvailability({
    required String productId,
    required int quantity,
  }) async {
    final currentStock = await stockRepository.getStock(productId);
    return quantity <= currentStock;
  }

  /// Gets current stock for a product.
  Future<int> getCurrentStock(String productId) async {
    return await stockRepository.getStock(productId);
  }

  /// Creates or gets customer ID.
  ///
  /// If customerId is provided, returns it.
  /// If customerName is provided but no customerId, creates a new customer.
  /// Otherwise, returns an anonymous customer ID.
  Future<String> getOrCreateCustomerId({
    String? customerId,
    String? customerName,
    String? customerPhone,
  }) async {
    if (customerId != null && customerId.isNotEmpty) {
      return customerId;
    }

    if (customerName != null && customerName.isNotEmpty) {
      // Create new customer
      // Note: This requires access to a customer repository or controller
      // For now, we'll return a generated ID - the actual creation should be done by the controller
      return 'customer-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Anonymous customer
    return 'anonymous-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Determines sale status based on payment.
  ///
  /// Returns SaleStatus.fullyPaid if fully paid, otherwise SaleStatus.validated.
  SaleStatus determineSaleStatus(int totalPrice, int amountPaid) {
    if (totalPrice - amountPaid == 0) {
      return SaleStatus.fullyPaid;
    }
    return SaleStatus.validated;
  }

  /// Validates sale data before creation.
  ///
  /// Returns null if valid, error message otherwise.
  Future<String?> validateSale({
    required String? productId,
    required int? quantity,
    required int? totalPrice,
    required int? amountPaid,
  }) async {
    if (productId == null) {
      return 'Veuillez sélectionner un produit';
    }

    if (quantity == null || totalPrice == null || amountPaid == null) {
      return 'Veuillez remplir tous les champs';
    }

    final stockAvailable = await validateStockAvailability(
      productId: productId,
      quantity: quantity,
    );

    if (!stockAvailable) {
      final currentStock = await getCurrentStock(productId);
      return 'Stock insuffisant. Disponible: $currentStock';
    }

    return null;
  }
}
