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

  OrangeMoneySettings copyWith({
    String? enterpriseId,
    NotificationSettings? notifications,
    ThresholdSettings? thresholds,
    String? simNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrangeMoneySettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      notifications: notifications ?? this.notifications,
      thresholds: thresholds ?? this.thresholds,
      simNumber: simNumber ?? this.simNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrangeMoneySettings.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return OrangeMoneySettings(
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      notifications: NotificationSettings.fromMap(
        map['notifications'] as Map<String, dynamic>,
      ),
      thresholds: ThresholdSettings.fromMap(
        map['thresholds'] as Map<String, dynamic>,
      ),
      simNumber: map['simNumber'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enterpriseId': enterpriseId,
      'notifications': notifications.toMap(),
      'thresholds': thresholds.toMap(),
      'simNumber': simNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
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

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      lowLiquidityAlert: map['lowLiquidityAlert'] as bool? ?? true,
      monthlyCommissionReminder: map['monthlyCommissionReminder'] as bool? ?? true,
      paymentDueAlert: map['paymentDueAlert'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lowLiquidityAlert': lowLiquidityAlert,
      'monthlyCommissionReminder': monthlyCommissionReminder,
      'paymentDueAlert': paymentDueAlert,
    };
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

  factory ThresholdSettings.fromMap(Map<String, dynamic> map) {
    return ThresholdSettings(
      criticalLiquidityThreshold:
          (map['criticalLiquidityThreshold'] as num?)?.toInt() ?? 50000,
      paymentDueDaysBefore: (map['paymentDueDaysBefore'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'criticalLiquidityThreshold': criticalLiquidityThreshold,
      'paymentDueDaysBefore': paymentDueDaysBefore,
    };
  }
}
