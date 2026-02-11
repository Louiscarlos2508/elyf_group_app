import '../../../../core/logging/app_logger.dart';
import '../adapters/pack_stock_adapter.dart';
import '../entities/sale.dart';
import '../pack_constants.dart';
import '../repositories/customer_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/stock_repository.dart';

/// Service for sale business logic.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
/// Pour les produits finis (Pack), utilise [PackStockAdapter].
class SaleService {
  SaleService({
    required this.stockRepository,
    required this.customerRepository,
    required this.packStockAdapter,
    this.productRepository,
  });

  final StockRepository stockRepository;
  final CustomerRepository customerRepository;
  final PackStockAdapter packStockAdapter;
  final ProductRepository? productRepository;

  /// Stock pour un produit. Pack → [getPackStock]. Autres PF → idem. Sinon → repo.
  Future<int> getCurrentStock(String productId) async {
    try {
      if (productId == packProductId) {
        final stock = await packStockAdapter.getPackStock(productId: productId);
        AppLogger.debug('Fetched pack stock: $stock', name: 'SaleService');
        return stock;
      }
      final product = await productRepository?.getProduct(productId);
      if (product != null && product.isFinishedGood) {
        final stock = await packStockAdapter.getPackStock(productId: productId);
        AppLogger.debug('Fetched finished good stock: $stock', name: 'SaleService');
        return stock;
      }
      if (product != null) {
        return await stockRepository.getStock(productId);
      }
      return 0;
    } catch (e, st) {
      AppLogger.error('Error in getCurrentStock: $e', name: 'SaleService', error: e, stackTrace: st);
      return 0;
    }
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

  /// Valide les données de vente.
  ///
  /// Si [packStockOverride] est fourni et [productId] == [packProductId],
  /// l'utilise au lieu de [getCurrentStock] (même source que Stock/Dashboard).
  Future<String?> validateSale({
    required String? productId,
    required int? quantity,
    required int? totalPrice,
    required int? amountPaid,
    String? customerId,
    String? customerName,
    String? customerPhone,
    int? packStockOverride,
  }) async {
    if (productId == null) return 'Veuillez sélectionner un produit';
    if (quantity == null || totalPrice == null || amountPaid == null) {
      return 'Veuillez remplir tous les champs';
    }

    // Validation du crédit : informations client obligatoires (Nom + Téléphone)
    if (amountPaid < totalPrice) {
      final hasName = customerName != null && customerName.trim().isNotEmpty && customerName.trim().toLowerCase() != 'inconnu';
      final hasPhone = customerPhone != null && customerPhone.trim().isNotEmpty && customerPhone.trim() != 'Aucun numéro';
      
      if (!hasName || !hasPhone) {
        return 'Le nom et le numéro de téléphone sont obligatoires pour une vente à crédit.';
      }
    }

    final limit = (productId == packProductId && packStockOverride != null)
        ? packStockOverride
        : await getCurrentStock(productId);
    if (quantity > limit) {
      return 'Stock insuffisant. Disponible: $limit';
    }
    return null;
  }
}
