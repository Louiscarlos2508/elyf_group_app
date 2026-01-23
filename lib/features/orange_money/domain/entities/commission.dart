/// Represents a commission period and calculation.
class Commission {
  const Commission({
    required this.id,
    required this.period,
    required this.amount,
    required this.status,
    required this.transactionsCount,
    required this.estimatedAmount,
    required this.enterpriseId,
    this.photoUrl,
    this.paidAt,
    this.paymentDueDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String period; // Format: "YYYY-MM" (ex: "2025-12")
  final int amount; // Montant de la commission en FCFA
  final CommissionStatus status;
  final int transactionsCount; // Nombre de transactions validées
  final int estimatedAmount; // Montant estimé en FCFA (pour le mois en cours)
  final String enterpriseId;
  final String? photoUrl; // URL de la photo de preuve (Firebase Storage)
  final DateTime? paidAt;
  final DateTime? paymentDueDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si la commission est payée.
  bool get isPaid => status == CommissionStatus.paid;

  /// Vérifie si la commission est en attente.
  bool get isPending => status == CommissionStatus.pending;

  /// Vérifie si la commission est en cours de calcul (mois actuel).
  bool get isEstimated => status == CommissionStatus.estimated;

  /// Vérifie si le paiement est proche de l'échéance.
  bool isPaymentDueSoon(int daysBefore) {
    if (paymentDueDate == null) return false;
    final now = DateTime.now();
    final difference = paymentDueDate!.difference(now).inDays;
    return difference <= daysBefore && difference >= 0;
  }
}

enum CommissionStatus {
  estimated, // Estimée pour le mois en cours (non calculée)
  pending, // Calculée mais pas encore payée
  paid, // Payée
}

extension CommissionStatusExtension on CommissionStatus {
  String get label {
    switch (this) {
      case CommissionStatus.estimated:
        return 'Estimée';
      case CommissionStatus.pending:
        return 'En attente';
      case CommissionStatus.paid:
        return 'Payée';
    }
  }
}
