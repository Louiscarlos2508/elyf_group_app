import '../../../../core/logging/app_logger.dart';

import '../entities/sale.dart';
import '../repositories/customer_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/stock_repository.dart';

/// Service for sale business logic.
class SaleService {
  SaleService({
    required this.stockRepository,
    required this.customerRepository,
    this.productRepository,
  });

  final StockRepository stockRepository;
  final CustomerRepository customerRepository;
  final ProductRepository? productRepository;

  /// Stock pour un produit.
  Future<double> getCurrentStock(String productId) async {
    try {
      return await stockRepository.getStock(productId);
    } catch (e, st) {
      AppLogger.error('Error in getCurrentStock: $e', name: 'SaleService', error: e, stackTrace: st);
      return 0;
    }
  }

  /// Determines sale status based on payment.
  SaleStatus determineSaleStatus(int totalPrice, int amountPaid) {
    if (totalPrice - amountPaid == 0) {
      return SaleStatus.fullyPaid;
    }
    return SaleStatus.validated;
  }

  /// Valide les données de vente.
  Future<String?> validateSale({
    required String? productId,
    required num? quantity,
    required int? totalPrice,
    required int? amountPaid,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? stockOverride,
  }) async {
    if (productId == null) return 'Veuillez sélectionner un produit';
    if (quantity == null || totalPrice == null || amountPaid == null) {
      return 'Veuillez remplir tous les champs';
    }

    // Validation du crédit : informations client minimales (nom)
    if (amountPaid < totalPrice) {
      final hasName = customerName != null && customerName.trim().isNotEmpty && 
                     customerName.trim().toLowerCase() != 'inconnu' &&
                     customerName.trim().toLowerCase() != 'client anonyme';
      
      if (!hasName) {
        return 'Le nom du client est obligatoire pour une vente à crédit.';
      }
    }

    final limit = stockOverride ?? await getCurrentStock(productId);
    if (quantity > limit) {
      return 'Stock insuffisant. Disponible: $limit';
    }
    return null;
  }
}

