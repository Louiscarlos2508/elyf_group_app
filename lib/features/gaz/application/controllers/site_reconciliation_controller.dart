import '../../domain/entities/site_reconciliation.dart';
import '../../domain/repositories/site_reconciliation_repository.dart';

/// Contrôleur pour la gestion des réconciliations de sites.
class SiteReconciliationController {
  SiteReconciliationController(this._repository);

  final SiteReconciliationRepository _repository;

  /// Récupère les réconciliations par site.
  Future<List<SiteReconciliation>> getReconciliationsBySite(
    String enterpriseId,
    String siteId,
  ) async {
    return _repository.getReconciliationsBySite(enterpriseId, siteId);
  }

  /// Récupère une réconciliation par ID.
  Future<SiteReconciliation?> getReconciliationById(String id) async {
    return _repository.getReconciliationById(id);
  }

  /// Crée une réconciliation cash-bouteilles.
  Future<String> createReconciliation(
    String siteId,
    String enterpriseId,
    double totalCashTransferred,
    Map<int, int> expectedCylindersSold,
    Map<int, int> actualCylindersSold, {
    String? paymentProofUrl,
    String? notes,
  }) async {
    // Vérifier correspondance cash/bouteilles
    ReconciliationStatus status = ReconciliationStatus.pending;
    if (actualCylindersSold != expectedCylindersSold) {
      status = ReconciliationStatus.discrepancy;
    } else {
      status = ReconciliationStatus.verified;
    }

    final reconciliation = SiteReconciliation(
      id: '',
      siteId: siteId,
      enterpriseId: enterpriseId,
      reconciliationDate: DateTime.now(),
      totalCashTransferred: totalCashTransferred,
      paymentProofScreenshot: paymentProofUrl,
      expectedCylindersSold: expectedCylindersSold,
      actualCylindersSold: actualCylindersSold,
      status: status,
      notes: notes,
    );

    return _repository.createReconciliation(reconciliation);
  }

  /// Met à jour le statut d'une réconciliation.
  Future<void> updateReconciliationStatus(
    String id,
    ReconciliationStatus status,
  ) async {
    await _repository.updateReconciliationStatus(id, status);
  }

  /// Définit l'URL de la preuve de paiement.
  Future<void> setPaymentProofUrl(String id, String imageUrl) async {
    await _repository.setPaymentProofUrl(id, imageUrl);
  }
}