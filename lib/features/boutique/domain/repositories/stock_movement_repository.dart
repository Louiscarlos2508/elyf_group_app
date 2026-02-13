
import '../entities/stock_movement.dart';

abstract class StockMovementRepository {
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    StockMovementType? type,
  });

  Future<void> recordMovement(StockMovement movement);

  Stream<List<StockMovement>> watchMovements({String? productId});
}
