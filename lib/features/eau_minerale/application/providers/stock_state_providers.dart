import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/stock_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/service_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';

export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_item.dart';

final stockStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(stockControllerProvider).fetchSnapshot(),
);

final historicalStockStateProvider = FutureProvider.autoDispose
    .family<StockState, DateTime>((ref, date) async {
  return ref.watch(historicalStockServiceProvider).fetchStockStateAtDate(date);
});

/// Stock d'un produit spécifique par son ID (recommandé).
final productStockQuantityProvider =
    FutureProvider.autoDispose.family<int, String>((ref, productId) async {
  if (productId.isEmpty) return 0;
  return ref.watch(stockControllerProvider).getStock(productId);
});

/// Paramètres pour filtrer les mouvements de stock
class StockMovementFiltersParams {
  const StockMovementFiltersParams({
    this.startDate,
    this.endDate,
    this.type,
    this.productId,
    this.productName,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final StockMovementType? type;
  final String? productId;
  final String? productName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementFiltersParams &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          type == other.type &&
          productId == other.productId &&
          productName == other.productName;

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      type.hashCode ^
      productId.hashCode ^
      productName.hashCode;
}

/// Provider pour récupérer tous les mouvements de stock avec filtres.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, StockMovementFiltersParams>((
  ref,
  params,
) async {
  final controller = ref.read(stockControllerProvider);
  return controller.fetchMovements(
    productId: params.productId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
