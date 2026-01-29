import '../../domain/adapters/pack_stock_adapter.dart';

/// Adapter factice utilisé en secours si le vrai adapter n'est pas disponible.
/// getPackStock → 0, recordPackExit → no-op.
class NoOpPackStockAdapter implements PackStockAdapter {
  NoOpPackStockAdapter();

  @override
  Future<int> getPackStock({String? productId}) async => 0;

  @override
  Future<void> recordPackExit(
    int quantity, {
    String? productId,
    String? reason,
    String? notes,
  }) async {}
}
