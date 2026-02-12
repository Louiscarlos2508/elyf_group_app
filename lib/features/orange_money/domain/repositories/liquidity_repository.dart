import '../entities/liquidity_checkpoint.dart';
import '../entities/transaction.dart';

/// Repository interface for managing liquidity checkpoints with theoretical calculations.
abstract class LiquidityRepository {
  /// Récupère tous les pointages de liquidité
  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère les pointages pour plusieurs entreprises (Support hiérarchie)
  Future<List<LiquidityCheckpoint>> fetchCheckpointsByEnterprises(
    List<String> enterpriseIds, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère un pointage spécifique par ID
  Future<LiquidityCheckpoint?> getCheckpoint(String checkpointId);

  /// Récupère le pointage du jour pour une entreprise
  Future<LiquidityCheckpoint?> getTodayCheckpoint(String enterpriseId);

  /// Récupère le dernier pointage du matin
  Future<LiquidityCheckpoint?> getMorningCheckpoint({
    required String enterpriseId,
    required DateTime date,
  });

  /// Récupère les pointages nécessitant une justification
  Future<List<LiquidityCheckpoint>> getCheckpointsRequiringJustification(
    String enterpriseId,
  );

  /// Crée un nouveau pointage de liquidité
  Future<String> createCheckpoint(LiquidityCheckpoint checkpoint);

  /// Crée un pointage avec calcul théorique automatique
  Future<LiquidityCheckpoint> createCheckpointWithCalculation({
    required String enterpriseId,
    required LiquidityCheckpointType type,
    required int cashAmount,
    required int simAmount,
    String? notes,
  });

  /// Calcule la liquidité théorique pour le pointage du soir
  Future<TheoreticalLiquidity> calculateTheoreticalLiquidity({
    required String enterpriseId,
    required DateTime date,
    required int morningCash,
    required int morningSim,
  });

  /// Met à jour un pointage existant
  Future<void> updateCheckpoint(LiquidityCheckpoint checkpoint);

  /// Valide un écart de pointage avec justification
  Future<LiquidityCheckpoint> validateDiscrepancy({
    required String checkpointId,
    required String validatedBy,
    required String justification,
  });

  /// Supprime un pointage
  Future<void> deleteCheckpoint(String checkpointId, String userId);

  /// Restaure un pointage supprimé
  Future<void> restoreCheckpoint(String checkpointId);

  /// Écoute les pointages
  Stream<List<LiquidityCheckpoint>> watchCheckpoints({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Écoute les pointages supprimés
  Stream<List<LiquidityCheckpoint>> watchDeletedCheckpoints();

  /// Récupère les statistiques des pointages
  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Résultat du calcul de liquidité théorique
class TheoreticalLiquidity {
  const TheoreticalLiquidity({
    required this.cash,
    required this.sim,
    required this.cashMovement,
    required this.simMovement,
    required this.transactionsProcessed,
  });

  final int cash; // Cash théorique
  final int sim; // SIM théorique
  final int cashMovement; // Mouvement total cash
  final int simMovement; // Mouvement total SIM
  final int transactionsProcessed; // Nombre de transactions traitées
}
