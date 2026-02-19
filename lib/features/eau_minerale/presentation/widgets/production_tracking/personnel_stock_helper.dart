import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/stock_item.dart';
import '../../../domain/entities/material_consumption.dart';

/// Enregistre les consommations et productions sur le stock.
Future<void> _applyConsumptions(
  WidgetRef ref,
  List<MaterialConsumption> newCons,
  List<MaterialConsumption> oldCons,
  List<MaterialConsumption> newProduced,
  List<MaterialConsumption> oldProduced,
  String sessionId,
  bool isCorrection,
) async {
  final ctrl = ref.read(stockControllerProvider);
  
  // 1. Inverser les anciennes consommations (réintégrer le stock)
  if (oldCons.isNotEmpty) {
     final returns = oldCons.map((c) => c.copyWith(quantity: -c.quantity)).toList();
     await ctrl.recordMaterialConsumptions(
        consumptions: returns,
        productionId: sessionId,
        notes: 'Correction consommation journalière (réintégration)',
     );
  }

  // 2. Appliquer les nouvelles consommations
  if (newCons.isNotEmpty) {
    await ctrl.recordMaterialConsumptions(
      consumptions: newCons,
      productionId: sessionId,
      notes: isCorrection ? 'Correction consommation journalière' : 'Enregistrement journalier',
    );
  }

  // 3. Appliquer les productions (Produits Finis du catalogue)
  await _applyProductions(ref, newProduced, oldProduced, sessionId, isCorrection);
}

Future<void> _applyProductions(
  WidgetRef ref,
  List<MaterialConsumption> newProduced,
  List<MaterialConsumption> oldProduced,
  String sessionId,
  bool isCorrection,
) async {
  final ctrl = ref.read(stockControllerProvider);

  // 1. Inverser les anciennes productions (retirer du stock)
  if (oldProduced.isNotEmpty) {
    final returns = oldProduced.map((c) => c.copyWith(quantity: -c.quantity)).toList();
    await ctrl.recordCatalogProduction(
      items: returns,
      productionId: sessionId,
      notes: 'Correction production journalière (ajustement négatif)',
    );
  }

  // 2. Appliquer les nouvelles productions
  if (newProduced.isNotEmpty) {
    await ctrl.recordCatalogProduction(
      items: newProduced,
      productionId: sessionId,
      notes: isCorrection ? 'Correction production journalière' : 'Enregistrement journalier',
    );
  }
}


/// Enregistre pack + emballages sur le stock lors de la sauvegarde d'un jour
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

  final newCons = productionDay.consumptions;
  final oldCons = existingDay?.consumptions ?? [];
  final newProduced = productionDay.producedItems;
  final oldProduced = existingDay?.producedItems ?? [];

  if (deltaPacks == 0 && newCons.isEmpty && oldCons.isEmpty && newProduced.isEmpty && oldProduced.isEmpty) return;

  // Gestion des Consommations et Productions (Catalogue)
  await _applyConsumptions(ref, newCons, oldCons, newProduced, oldProduced, sessionId, existingDay != null);
}

/// Réintègre les consommations et retire les packs du stock lorsqu'un jour est supprimé.
Future<void> addBackStockOnDayDelete(WidgetRef ref, ProductionDay day) async {
  final hasCons = day.consumptions.isNotEmpty;
  final hasProduced = day.producedItems.isNotEmpty;
  final hasPacks = day.packsProduits > 0;
  
  if (!hasCons && !hasPacks && !hasProduced) return;

  final stockController = ref.read(stockControllerProvider);

  // 1. Inverser les consommations
  if (hasCons) {
    final returns = day.consumptions.map((c) => c.copyWith(quantity: -c.quantity)).toList();
    await stockController.recordMaterialConsumptions(
      consumptions: returns,
      productionId: day.productionId,
      notes: 'Réintégration (suppression jour de production)',
    );
  }

  // 2. Inverser les productions
  if (hasProduced) {
    final returns = day.producedItems.map((c) => c.copyWith(quantity: -c.quantity)).toList();
    await stockController.recordCatalogProduction(
      items: returns,
      productionId: day.productionId,
      notes: 'Réintégration production (suppression jour)',
    );
  }
}
