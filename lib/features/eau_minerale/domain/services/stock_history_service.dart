import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_repository.dart';

/// Service dédié à la récupération et à l'agrégation de l'historique des mouvements de stock.
class StockHistoryService {
  StockHistoryService(
    this._stockRepository,
    this.enterpriseId,
  );

  final StockRepository _stockRepository;
  final String enterpriseId;

  /// Récupère tous les mouvements de stock combinés.
  Future<List<StockMovement>> fetchAllMovements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Dans le nouveau système unifié, tous les mouvements sont dans StockRepository
    return _stockRepository.fetchMovements(
      productId: null,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
