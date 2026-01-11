import '../entities/cylinder.dart';
import '../repositories/cylinder_stock_repository.dart';

/// Service de gestion des stocks avec logique métier.
class StockService {
  const StockService({
    required this.stockRepository,
  });

  final CylinderStockRepository stockRepository;

  /// Valide qu'un changement de statut est possible.
  /// Retourne null si valide, sinon un message d'erreur.
  Future<String?> validateStatusChange(
    String stockId,
    CylinderStatus newStatus,
  ) async {
    final stock = await stockRepository.getStockById(stockId);
    if (stock == null) {
      return 'Stock introuvable';
    }

    if (stock.quantity <= 0 && newStatus != stock.status) {
      return 'Impossible de changer le statut: quantité nulle';
    }

    return null;
  }

  /// Calcule le stock disponible (pleines) pour un format donné.
  Future<int> getAvailableStock(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    final stocks = await stockRepository.getStocksByWeight(
      enterpriseId,
      weight,
      siteId: siteId,
    );

    final fullStock = stocks
        .where((s) => s.status == CylinderStatus.full)
        .fold<int>(0, (sum, s) => sum + s.quantity);

    return fullStock;
  }

  /// Change le statut d'un stock après validation.
  Future<void> changeStockStatus(
    String stockId,
    CylinderStatus newStatus,
  ) async {
    final error = await validateStatusChange(stockId, newStatus);
    if (error != null) {
      throw Exception(error);
    }

    await stockRepository.changeStockStatus(stockId, newStatus);
  }

  /// Ajuste la quantité d'un stock.
  Future<void> adjustStockQuantity(
    String stockId,
    int newQuantity,
  ) async {
    if (newQuantity < 0) {
      throw Exception('La quantité ne peut pas être négative');
    }

    await stockRepository.updateStockQuantity(stockId, newQuantity);
  }
}