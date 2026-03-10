import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/machine_material_usage.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../application/controllers/stock_controller.dart';

/// Service gérant la logique générique de décrémentation des matières chargées sur les machines.
/// (Anciennement BobineStockManagementService).
class MachineStockManagementService {
  MachineStockManagementService({
    required this.sessionRepository,
    required this.stockRepository,
    required this.stockController,
  });

  final ProductionSessionRepository sessionRepository;
  final StockRepository stockRepository;
  final StockController stockController;

  /// Décrémente le stock uniquement pour les matières nouvelles (pas déjà utilisées).
  /// S'applique aux bobines ou toute autre matière installée sur une machine.
  Future<void> decrementerStockMatieresNouvelles({
    required List<MachineMaterialUsage> matieresUtilisees,
    required String sessionId,
    required bool estNouvelleSession,
    ProductionSession? sessionExistante,
  }) async {
    AppLogger.debug(
      '=== Décrémentation stock matières machine pour session $sessionId ===',
      name: 'eau_minerale.production',
    );

    for (final usage in matieresUtilisees) {
      // Ignorer si déjà réutilisé (déjà décompté dans une session précédente)
      if (usage.isReused) continue;

      // Vérifier si un mouvement existe déjà pour cet UsageID
      final aDejaMouvement = await _verifierMouvementParUsageId(
        productId: usage.productId ?? '',
        usageId: usage.id,
      );

      if (aDejaMouvement) continue;

      // Décrémenter le stock
      try {
        await stockController.recordMachineLoadExit(
          productId: usage.productId ?? '',
          productName: usage.productName ?? usage.materialType,
          quantite: 1,
          productionId: sessionId,
          machineId: usage.machineId,
          usageId: usage.id,
          notes: 'Installation en production (Machine: ${usage.machineName})',
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'ERREUR lors de la décrémentation pour MachineMaterialUsageID ${usage.id}: $e',
          name: 'eau_minerale.production',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Vérifie si une matière a déjà un mouvement de sortie pour un UsageID donné.
  Future<bool> _verifierMouvementParUsageId({
    required String productId,
    required String usageId,
  }) async {
    if (productId.isEmpty) return false;
    try {
      final mouvements = await stockRepository.fetchMovements(
        productId: productId,
      );

      // Chercher dans les notes ou un champ dédié si le mouvement correspond à cet usage
      return mouvements.any((m) => 
        m.type == StockMovementType.exit && 
        (m.notes?.contains(usageId) ?? false || m.id.contains(usageId))
      );
    } catch (e) {
      AppLogger.error('Erreur lors de la vérification par UsageID: $e', error: e);
      return false;
    }
  }
}
