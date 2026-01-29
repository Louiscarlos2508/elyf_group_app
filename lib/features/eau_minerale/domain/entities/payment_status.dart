/// Statut de paiement d'un jour de production.
enum PaymentStatus {
  /// Non payé
  unpaid,

  /// Partiellement payé
  partial,

  /// Payé
  paid,

  /// Vérifié et validé
  verified;

  /// Libellé français du statut
  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Non payé';
      case PaymentStatus.partial:
        return 'Partiellement payé';
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.verified:
        return 'Vérifié';
    }
  }

  /// Icône associée au statut
  String get icon {
    switch (this) {
      case PaymentStatus.unpaid:
        return '⏳';
      case PaymentStatus.partial:
        return '⚠️';
      case PaymentStatus.paid:
        return '✅';
      case PaymentStatus.verified:
        return '🔒';
    }
  }
}
