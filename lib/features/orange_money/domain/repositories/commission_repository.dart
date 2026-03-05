import '../entities/commission.dart';

/// Repository for managing commissions with hybrid model support.
abstract class CommissionRepository {
  /// Récupère les commissions avec filtres
  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period, // Format: "YYYY-MM"
  });

  /// Récupère les commissions pour plusieurs entreprises (Support hiérarchie)
  Future<List<Commission>> fetchCommissionsByEnterprises(
    List<String> enterpriseIds, {
    CommissionStatus? status,
    String? period,
  });

  /// Récupère une commission spécifique
  Future<Commission?> getCommission(String commissionId);

  /// Récupère la commission du mois en cours
  Future<Commission?> getCurrentMonthCommission(String enterpriseId);

  /// Récupère les commissions par statut
  Future<List<Commission>> getCommissionsByStatus(
    String enterpriseId,
    CommissionStatus status,
  );

  /// Crée une nouvelle commission (calcul estimatif)
  Future<String> createCommission(Commission commission);

  /// Met à jour une commission
  Future<void> updateCommission(Commission commission);

  /// Marque une commission comme payée
  Future<Commission> markAsPaid({
    required String commissionId,
    required String paymentProofUrl,
    String? notes,
  });

  /// Supprime une commission (soft delete)
  Future<void> deleteCommission(String commissionId, String userId);

  /// Restaure une commission supprimée
  Future<void> restoreCommission(String commissionId);

  /// Écoute les commissions supprimées
  Stream<List<Commission>> watchDeletedCommissions();

  /// Obtenir les statistiques des commissions
  Future<Map<String, dynamic>> getStatistics({String? enterpriseId});

  /// Obtenir les statistiques globales pour un réseau d'entreprises
  Future<Map<String, dynamic>> fetchNetworkStatistics(
    List<String> enterpriseIds, {
    String? period,
  });
}
