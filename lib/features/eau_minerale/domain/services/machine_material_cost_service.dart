import '../../../../core/logging/app_logger.dart';
import '../entities/machine_material_usage.dart';
import '../entities/production_session.dart';
import '../repositories/production_session_repository.dart';
import '../repositories/product_repository.dart';

/// Service dédié au calcul des coûts des matières chargées sur les machines.
/// (Anciennement BobineCostCalculatorService).
class MachineMaterialCostService {
  MachineMaterialCostService({
    required this.sessionRepository,
    required this.productRepository,
  });

  final ProductionSessionRepository sessionRepository;
  final ProductRepository productRepository;

  /// Calcule le coût total des nouvelles matières installées dans cette session.
  Future<int> calculateNewMaterialsCost({
    required List<MachineMaterialUsage> materials,
    required String sessionId,
    required bool isNewSession,
    ProductionSession? existingSession,
  }) async {
    int totalCost = 0;

    // Charger les dernières matières non finies pour chaque machine pour détecter les réutilisations
    final unfinishedMaterialsByMachine = <String, MachineMaterialUsage>{};
    
    for (final usage in materials) {
      if (!unfinishedMaterialsByMachine.containsKey(usage.machineId)) {
        // Note: Le repository doit être mis à jour pour retourner MachineMaterialUsage
        // Pour l'instant on suppose une compatibilité via mappers ou mise à jour ultérieure
         final lastUnfinished = await sessionRepository.fetchLastUnfinishedMaterialForMachine(usage.machineId);
         if (lastUnfinished != null) {
            unfinishedMaterialsByMachine[usage.machineId] = lastUnfinished;
         }
      }
    }

    final skipQuota = <String, int>{};
    if (!isNewSession && existingSession != null) {
      for (final m in existingSession.machineMaterials) {
        final key = '${m.machineId}|${m.materialType}';
        skipQuota[key] = (skipQuota[key] ?? 0) + 1;
      }
    }

    for (final usage in materials) {
      // Ignorer si déjà présent dans la session existante (si mise à jour)
      if (!isNewSession && existingSession != null) {
        final key = '${usage.machineId}|${usage.materialType}';
        final quota = skipQuota[key] ?? 0;
        if (quota > 0) {
          skipQuota[key] = quota - 1;
          continue;
        }
      }

      // Vérifier si réutilisée depuis une session précédente
      final unfinishedExistante = unfinishedMaterialsByMachine[usage.machineId];
      final isReused = unfinishedExistante != null &&
          unfinishedExistante.materialType == usage.materialType &&
          unfinishedExistante.dateInstallation.isAtSameMomentAs(usage.dateInstallation);

      if (isReused) continue;

      // Nouvelle matière -> chercher le prix unitaire
      if (usage.productId != null) {
        try {
          final product = await productRepository.getProduct(usage.productId!);
          if (product != null) {
            totalCost += product.unitPrice.toInt();
          }
        } catch (e) {
          AppLogger.error('Erreur lors de la récupération du prix pour ${usage.materialType}', error: e);
        }
      }
    }

    return totalCost;
  }
}
