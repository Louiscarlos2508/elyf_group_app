/// Represents Orange Money settings and configuration.
class OrangeMoneySettings {
  const OrangeMoneySettings({
    required this.enterpriseId,
    required this.notifications,
    required this.thresholds,
    required this.simNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String enterpriseId;
  final NotificationSettings notifications;
  final ThresholdSettings thresholds;
  final String simNumber; // Numéro SIM pour toutes les transactions
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// Settings for notifications and alerts.
class NotificationSettings {
  const NotificationSettings({
    this.lowLiquidityAlert = true,
    this.monthlyCommissionReminder = true,
    this.paymentDueAlert = true,
  });

  final bool lowLiquidityAlert; // Alerte liquidité basse
  final bool monthlyCommissionReminder; // Rappel calcul commission mensuelle
  final bool paymentDueAlert; // Alerte échéance de paiement

  NotificationSettings copyWith({
    bool? lowLiquidityAlert,
    bool? monthlyCommissionReminder,
    bool? paymentDueAlert,
  }) {
    return NotificationSettings(
      lowLiquidityAlert: lowLiquidityAlert ?? this.lowLiquidityAlert,
      monthlyCommissionReminder:
          monthlyCommissionReminder ?? this.monthlyCommissionReminder,
      paymentDueAlert: paymentDueAlert ?? this.paymentDueAlert,
    );
  }
}

/// Settings for thresholds and limits.
class ThresholdSettings {
  const ThresholdSettings({
    this.criticalLiquidityThreshold = 50000, // Seuil liquidité critique en FCFA
    this.paymentDueDaysBefore = 3, // Jours avant échéance pour alerte
  });

  final int criticalLiquidityThreshold; // Seuil liquidité critique (FCFA)
  final int paymentDueDaysBefore; // Jours avant échéance pour alerte

  ThresholdSettings copyWith({
    int? criticalLiquidityThreshold,
    int? paymentDueDaysBefore,
  }) {
    return ThresholdSettings(
      criticalLiquidityThreshold:
          criticalLiquidityThreshold ?? this.criticalLiquidityThreshold,
      paymentDueDaysBefore: paymentDueDaysBefore ?? this.paymentDueDaysBefore,
    );
  }
}
