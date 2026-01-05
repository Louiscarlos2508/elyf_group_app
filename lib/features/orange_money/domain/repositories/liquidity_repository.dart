import '../entities/liquidity_checkpoint.dart';

/// Repository interface for managing liquidity checkpoints.
abstract class LiquidityRepository {
  /// Récupère tous les pointages de liquidité.
  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère un pointage spécifique par ID.
  Future<LiquidityCheckpoint?> getCheckpoint(String checkpointId);

  /// Récupère le pointage du jour pour une entreprise.
  Future<LiquidityCheckpoint?> getTodayCheckpoint(String enterpriseId);

  /// Crée un nouveau pointage de liquidité.
  Future<String> createCheckpoint(LiquidityCheckpoint checkpoint);

  /// Met à jour un pointage existant.
  Future<void> updateCheckpoint(LiquidityCheckpoint checkpoint);

  /// Supprime un pointage.
  Future<void> deleteCheckpoint(String checkpointId);

  /// Récupère les statistiques des pointages.
  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

