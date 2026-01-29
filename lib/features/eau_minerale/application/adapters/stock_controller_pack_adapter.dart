import '../../domain/adapters/pack_stock_adapter.dart';
import '../../domain/entities/stock_movement.dart';
import '../controllers/stock_controller.dart';

/// Délègue au StockController pour le stock Pack (ventes).
class StockControllerPackAdapter implements PackStockAdapter {
  StockControllerPackAdapter(this._controller);

  final StockController _controller;

  @override
  Future<int> getPackStock({String? productId}) async {
    final pack = await _controller.ensurePackStockItem(productId: productId);
    return pack.quantity.toInt();
  }

  @override
  Future<void> recordPackExit(
    int quantity, {
    String? productId,
    String? reason,
    String? notes,
  }) async {
    final pack = await _controller.ensurePackStockItem(productId: productId);
    await _controller.recordItemMovement(
      itemId: pack.id,
      itemName: pack.name,
      type: StockMovementType.exit,
      quantity: quantity.toDouble(),
      unit: pack.unit,
      reason: reason ?? 'Vente',
      notes: notes,
    );
  }
}
