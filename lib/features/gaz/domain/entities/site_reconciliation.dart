/// Statut d'une réconciliation de site.
enum ReconciliationStatus {
  pending('En attente'),
  verified('Vérifiée'),
  discrepancy('Écart détecté');

  const ReconciliationStatus(this.label);
  final String label;
}

/// Représente une réconciliation cash-bouteilles pour un site distant.
class SiteReconciliation {
  const SiteReconciliation({
    required this.id,
    required this.siteId,
    required this.enterpriseId,
    required this.reconciliationDate,
    required this.totalCashTransferred,
    required this.expectedCylindersSold,
    required this.actualCylindersSold,
    required this.status,
    this.paymentProofScreenshot,
    this.notes,
  });

  final String id;
  final String siteId;
  final String enterpriseId;
  final DateTime reconciliationDate;
  final double totalCashTransferred; // Ex: Orange Money
  final String? paymentProofScreenshot; // URL - sera rempli plus tard avec Firebase Storage
  final Map<int, int> expectedCylindersSold; // weight -> quantity
  final Map<int, int> actualCylindersSold; // weight -> quantity
  final ReconciliationStatus status;
  final String? notes;

  SiteReconciliation copyWith({
    String? id,
    String? siteId,
    String? enterpriseId,
    DateTime? reconciliationDate,
    double? totalCashTransferred,
    String? paymentProofScreenshot,
    Map<int, int>? expectedCylindersSold,
    Map<int, int>? actualCylindersSold,
    ReconciliationStatus? status,
    String? notes,
  }) {
    return SiteReconciliation(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      reconciliationDate: reconciliationDate ?? this.reconciliationDate,
      totalCashTransferred:
          totalCashTransferred ?? this.totalCashTransferred,
      paymentProofScreenshot:
          paymentProofScreenshot ?? this.paymentProofScreenshot,
      expectedCylindersSold:
          expectedCylindersSold ?? this.expectedCylindersSold,
      actualCylindersSold: actualCylindersSold ?? this.actualCylindersSold,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// Vérifie s'il y a un écart entre les bouteilles attendues et réelles.
  bool get hasDiscrepancy {
    for (final entry in expectedCylindersSold.entries) {
      final actual = actualCylindersSold[entry.key] ?? 0;
      if (actual != entry.value) return true;
    }
    for (final entry in actualCylindersSold.entries) {
      if (!expectedCylindersSold.containsKey(entry.key)) return true;
    }
    return false;
  }
}