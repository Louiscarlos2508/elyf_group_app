import '../entities/site_reconciliation.dart';

/// Interface pour le repository des réconciliations de sites.
abstract class SiteReconciliationRepository {
  Future<List<SiteReconciliation>> getReconciliationsBySite(
    String enterpriseId,
    String siteId,
  );

  Future<SiteReconciliation?> getReconciliationById(String id);

  Future<String> createReconciliation(SiteReconciliation reconciliation);

  Future<void> updateReconciliation(SiteReconciliation reconciliation);

  Future<void> updateReconciliationStatus(
    String id,
    ReconciliationStatus status,
  );

  Future<void> setPaymentProofUrl(String id, String imageUrl);

  Future<void> deleteReconciliation(String id);
}