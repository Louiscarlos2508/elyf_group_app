import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/packaging_stock.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/stock_item.dart';

const String _typeEmballage = 'Emballage';

/// Récupère le stock d'emballages utilisé pour l'enregistrement journalier.
Future<PackagingStock?> _fetchEmballageStock(WidgetRef ref) async {
  final packaging = ref.read(packagingStockControllerProvider);
  var stock = await packaging.fetchByType(_typeEmballage);
  if (stock != null) return stock;
  final all = await packaging.fetchAll();
  return all.isNotEmpty ? all.first : null;
}

/// Enregistre l'effet des emballages sur le stock (mouvement + sync).
Future<void> _applyEmballages(
  WidgetRef ref,
  int delta,
  String sessionId,
  PackagingStock stock,
  bool isCorrection,
) async {
  final ctrl = ref.read(stockControllerProvider);
  if (delta > 0) {
    await ctrl.recordPackagingUsage(
      packagingId: stock.id,
      packagingType: stock.type,
      quantite: delta,
      productionId: sessionId,
      notes: isCorrection ? null : 'Enregistrement journalier',
    );
  } else {
    await ctrl.recordPackagingEntry(
      packagingId: stock.id,
      packagingType: stock.type,
      quantite: -delta,
      notes: 'Réintégration (correction enregistrement journalier)',
    );
  }
}

/// Enregistre l'effet des packs sur le stock (mouvement + sync via recordItemMovement).
Future<void> _applyPacks(
  WidgetRef ref,
  int delta,
  StockItem pack,
  bool isCorrection,
) async {
  if (delta == 0) return;
  final ctrl = ref.read(stockControllerProvider);
  final type = delta > 0 ? StockMovementType.entry : StockMovementType.exit;
  final qty = delta.abs().toDouble();
  final reason = isCorrection
      ? 'Réintégration (correction enregistrement journalier)'
      : 'Enregistrement journalier';
  await ctrl.recordItemMovement(
    itemId: pack.id,
    itemName: pack.name,
    type: type,
    quantity: qty,
    unit: pack.unit,
    reason: reason,
    notes: 'Packs produits',
  );
}

/// Enregistre pack + emballage sur le stock lors de la sauvegarde d'un jour
/// (création ou mise à jour). Mouvements enregistrés et synchronisés.
Future<void> applyStockOnSave(
  WidgetRef ref,
  ProductionDay productionDay,
  ProductionDay? existingDay,
  String sessionId,
) async {
  final newPacks = productionDay.packsProduits;
  final oldPacks = existingDay?.packsProduits ?? 0;
  final deltaPacks = newPacks - oldPacks;

  final newEmb = productionDay.emballagesUtilises;
  final oldEmb = existingDay?.emballagesUtilises ?? 0;
  final deltaEmb = newEmb - oldEmb;

  if (deltaPacks == 0 && deltaEmb == 0) return;

  if (deltaPacks != 0) {
    final pack = await ref.read(stockControllerProvider).ensurePackStockItem();
    await _applyPacks(ref, deltaPacks, pack, existingDay != null);
  }

  if (deltaEmb != 0) {
    final emb = await _fetchEmballageStock(ref);
    if (emb == null) {
      throw StateError(
        'Aucun stock d\'emballages (Emballage) trouvé. '
        'Créez-en un avant d\'enregistrer la production.',
      );
    }
    await _applyEmballages(ref, deltaEmb, sessionId, emb, existingDay != null);
  }
}

/// Réintègre emballages et retire les packs du stock lorsqu'un jour est supprimé.
Future<void> addBackStockOnDayDelete(WidgetRef ref, ProductionDay day) async {
  final hasEmb = day.emballagesUtilises > 0;
  final hasPacks = day.packsProduits > 0;
  if (!hasEmb && !hasPacks) return;

  final stockController = ref.read(stockControllerProvider);

  if (hasEmb) {
    final emb = await _fetchEmballageStock(ref);
    if (emb == null) {
      throw StateError(
        'Aucun stock d\'emballages (Emballage) trouvé. '
        'Impossible de réintégrer les emballages.',
      );
    }
    await stockController.recordPackagingEntry(
      packagingId: emb.id,
      packagingType: emb.type,
      quantite: day.emballagesUtilises,
      notes: 'Réintégration (suppression jour de production)',
    );
  }

  if (hasPacks) {
    final pack = await stockController.ensurePackStockItem();
    await stockController.recordItemMovement(
      itemId: pack.id,
      itemName: pack.name,
      type: StockMovementType.exit,
      quantity: day.packsProduits.toDouble(),
      unit: pack.unit,
      reason: 'Réintégration (suppression jour de production)',
      notes: 'Packs produits',
    );
  }
}
