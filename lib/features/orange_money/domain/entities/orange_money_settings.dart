/// Settings for Orange Money module per enterprise.
class OrangeMoneySettings {
  const OrangeMoneySettings({
    required this.id,
    required this.enterpriseId,
    this.enableLiquidityAlerts = true,
    this.enableCommissionReminders = true,
    this.enableCheckpointReminders = true,
    this.enableTransactionAlerts = true,
    this.criticalLiquidityThreshold = 50000,
    this.checkpointDiscrepancyThreshold = 2.0,
    this.commissionReminderDays = 7,
    this.largeTransactionThreshold = 500000,
    this.cashInTiers = const [],
    this.cashOutTiers = const [],
    this.commissionDiscrepancyMinor = 5.0,
    this.commissionDiscrepancySignificant = 10.0,
    this.autoValidateConformeCommissions = true,
    this.simNumber = '',
    this.operators = const ['Orange Money'],
    this.maxAllowedDebt = 500000,
    this.createdAt,
    this.updatedAt,
  });

  final String id; // enterpriseId
  final String enterpriseId;
  final String simNumber; // Numéro SIM Orange Money
  final List<String> operators; // Liste des opérateurs actifs (Orange, Moov, etc.)
  final int maxAllowedDebt; // Dette maximum autorisée pour les agents (FCFA)

  // NOTIFICATIONS
  final bool enableLiquidityAlerts; // Alertes de liquidité faible
  final bool enableCommissionReminders; // Rappels de déclaration commission
  final bool enableCheckpointReminders; // Rappels de pointage
  final bool enableTransactionAlerts; // Alertes transactions importantes

  // SEUILS
  final int criticalLiquidityThreshold; // Seuil critique liquidité (FCFA)
  final double checkpointDiscrepancyThreshold; // Seuil écart pointage (%)
  final int commissionReminderDays; // Jours avant rappel commission
  final int largeTransactionThreshold; // Seuil transaction importante (FCFA)

  // BARÈMES DE COMMISSION (Configurables)
  final List<CommissionTier> cashInTiers; // Barème Cash-In
  final List<CommissionTier> cashOutTiers; // Barème Cash-Out

  // VALIDATION COMMISSIONS
  final double commissionDiscrepancyMinor; // Écart mineur (%)
  final double commissionDiscrepancySignificant; // Écart significatif (%)
  final bool autoValidateConformeCommissions; // Auto-valider si conforme

  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrangeMoneySettings copyWith({
    String? id,
    String? enterpriseId,
    String? simNumber,
    bool? enableLiquidityAlerts,
    bool? enableCommissionReminders,
    bool? enableCheckpointReminders,
    bool? enableTransactionAlerts,
    int? criticalLiquidityThreshold,
    double? checkpointDiscrepancyThreshold,
    int? commissionReminderDays,
    int? largeTransactionThreshold,
    List<CommissionTier>? cashInTiers,
    List<CommissionTier>? cashOutTiers,
    double? commissionDiscrepancyMinor,
    double? commissionDiscrepancySignificant,
    bool? autoValidateConformeCommissions,
    List<String>? operators,
    int? maxAllowedDebt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrangeMoneySettings(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      simNumber: simNumber ?? this.simNumber,
      operators: operators ?? this.operators,
      maxAllowedDebt: maxAllowedDebt ?? this.maxAllowedDebt,
      enableLiquidityAlerts:
          enableLiquidityAlerts ?? this.enableLiquidityAlerts,
      enableCommissionReminders:
          enableCommissionReminders ?? this.enableCommissionReminders,
      enableCheckpointReminders:
          enableCheckpointReminders ?? this.enableCheckpointReminders,
      enableTransactionAlerts:
          enableTransactionAlerts ?? this.enableTransactionAlerts,
      criticalLiquidityThreshold:
          criticalLiquidityThreshold ?? this.criticalLiquidityThreshold,
      checkpointDiscrepancyThreshold:
          checkpointDiscrepancyThreshold ?? this.checkpointDiscrepancyThreshold,
      commissionReminderDays:
          commissionReminderDays ?? this.commissionReminderDays,
      largeTransactionThreshold:
          largeTransactionThreshold ?? this.largeTransactionThreshold,
      cashInTiers: cashInTiers ?? this.cashInTiers,
      cashOutTiers: cashOutTiers ?? this.cashOutTiers,
      commissionDiscrepancyMinor:
          commissionDiscrepancyMinor ?? this.commissionDiscrepancyMinor,
      commissionDiscrepancySignificant: commissionDiscrepancySignificant ??
          this.commissionDiscrepancySignificant,
      autoValidateConformeCommissions: autoValidateConformeCommissions ??
          this.autoValidateConformeCommissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrangeMoneySettings.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return OrangeMoneySettings(
      id: map['id'] as String? ?? defaultEnterpriseId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      simNumber: map['simNumber'] as String? ?? '',
      operators: (map['operators'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          ['Orange Money'],
      maxAllowedDebt: (map['maxAllowedDebt'] as num?)?.toInt() ?? 500000,
      enableLiquidityAlerts: map['enableLiquidityAlerts'] as bool? ?? true,
      enableCommissionReminders:
          map['enableCommissionReminders'] as bool? ?? true,
      enableCheckpointReminders:
          map['enableCheckpointReminders'] as bool? ?? true,
      enableTransactionAlerts: map['enableTransactionAlerts'] as bool? ?? true,
      criticalLiquidityThreshold:
          (map['criticalLiquidityThreshold'] as num?)?.toInt() ?? 50000,
      checkpointDiscrepancyThreshold:
          (map['checkpointDiscrepancyThreshold'] as num?)?.toDouble() ?? 2.0,
      commissionReminderDays:
          (map['commissionReminderDays'] as num?)?.toInt() ?? 7,
      largeTransactionThreshold:
          (map['largeTransactionThreshold'] as num?)?.toInt() ?? 500000,
      cashInTiers: (map['cashInTiers'] as List<dynamic>?)
              ?.map((e) => CommissionTier.fromMap(e as Map<String, dynamic>))
              .toList() ??
          _defaultCashInTiers(),
      cashOutTiers: (map['cashOutTiers'] as List<dynamic>?)
              ?.map((e) => CommissionTier.fromMap(e as Map<String, dynamic>))
              .toList() ??
          _defaultCashOutTiers(),
      commissionDiscrepancyMinor:
          (map['commissionDiscrepancyMinor'] as num?)?.toDouble() ?? 5.0,
      commissionDiscrepancySignificant:
          (map['commissionDiscrepancySignificant'] as num?)?.toDouble() ?? 10.0,
      autoValidateConformeCommissions:
          map['autoValidateConformeCommissions'] as bool? ?? true,
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
      'id': id,
      'enterpriseId': enterpriseId,
      'simNumber': simNumber,
      'operators': operators,
      'maxAllowedDebt': maxAllowedDebt,
      'enableLiquidityAlerts': enableLiquidityAlerts,
      'enableCommissionReminders': enableCommissionReminders,
      'enableCheckpointReminders': enableCheckpointReminders,
      'enableTransactionAlerts': enableTransactionAlerts,
      'criticalLiquidityThreshold': criticalLiquidityThreshold,
      'checkpointDiscrepancyThreshold': checkpointDiscrepancyThreshold,
      'commissionReminderDays': commissionReminderDays,
      'largeTransactionThreshold': largeTransactionThreshold,
      'cashInTiers': cashInTiers.map((e) => e.toMap()).toList(),
      'cashOutTiers': cashOutTiers.map((e) => e.toMap()).toList(),
      'commissionDiscrepancyMinor': commissionDiscrepancyMinor,
      'commissionDiscrepancySignificant': commissionDiscrepancySignificant,
      'autoValidateConformeCommissions': autoValidateConformeCommissions,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Barème Cash-In par défaut (Orange Money Burkina Faso)
  static List<CommissionTier> _defaultCashInTiers() {
    return [
      const CommissionTier(
        minAmount: 0,
        maxAmount: 5000,
        fixedCommission: 0,
      ),
      const CommissionTier(
        minAmount: 5001,
        maxAmount: 25000,
        fixedCommission: 100,
      ),
      const CommissionTier(
        minAmount: 25001,
        maxAmount: 50000,
        fixedCommission: 200,
      ),
      const CommissionTier(
        minAmount: 50001,
        maxAmount: 100000,
        fixedCommission: 400,
      ),
      const CommissionTier(
        minAmount: 100001,
        maxAmount: null,
        percentageCommission: 0.4,
      ),
    ];
  }

  /// Barème Cash-Out par défaut (Orange Money Burkina Faso)
  static List<CommissionTier> _defaultCashOutTiers() {
    return [
      const CommissionTier(
        minAmount: 0,
        maxAmount: 5000,
        fixedCommission: 0,
      ),
      const CommissionTier(
        minAmount: 5001,
        maxAmount: 25000,
        fixedCommission: 150,
      ),
      const CommissionTier(
        minAmount: 25001,
        maxAmount: 50000,
        fixedCommission: 300,
      ),
      const CommissionTier(
        minAmount: 50001,
        maxAmount: 100000,
        fixedCommission: 500,
      ),
      const CommissionTier(
        minAmount: 100001,
        maxAmount: null,
        percentageCommission: 0.5,
      ),
    ];
  }
}

/// Tranche de commission
class CommissionTier {
  const CommissionTier({
    required this.minAmount,
    this.maxAmount,
    this.fixedCommission,
    this.percentageCommission,
  }) : assert(
          fixedCommission != null || percentageCommission != null,
          'Either fixedCommission or percentageCommission must be provided',
        );

  final int minAmount; // Montant minimum (FCFA)
  final int? maxAmount; // Montant maximum (null = illimité)
  final int? fixedCommission; // Commission fixe (FCFA)
  final double? percentageCommission; // Commission en % (ex: 0.4 pour 0.4%)

  /// Vérifie si un montant est dans cette tranche
  bool contains(int amount) {
    if (amount < minAmount) return false;
    if (maxAmount == null) return true;
    return amount <= maxAmount!;
  }

  /// Calcule la commission pour un montant
  int calculateCommission(int amount) {
    if (!contains(amount)) return 0;

    if (fixedCommission != null) {
      return fixedCommission!;
    } else if (percentageCommission != null) {
      return (amount * percentageCommission! / 100).round();
    }

    return 0;
  }

  factory CommissionTier.fromMap(Map<String, dynamic> map) {
    return CommissionTier(
      minAmount: (map['minAmount'] as num).toInt(),
      maxAmount: (map['maxAmount'] as num?)?.toInt(),
      fixedCommission: (map['fixedCommission'] as num?)?.toInt(),
      percentageCommission:
          (map['percentageCommission'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'fixedCommission': fixedCommission,
      'percentageCommission': percentageCommission,
    };
  }

  /// Label pour affichage
  String get label {
    final min = minAmount.toString();
    final max = maxAmount?.toString() ?? '∞';
    return '$min - $max FCFA';
  }

  /// Commission pour affichage
  String get commissionLabel {
    if (fixedCommission != null) {
      return '$fixedCommission FCFA';
    } else if (percentageCommission != null) {
      return '$percentageCommission%';
    }
    return '0 FCFA';
  }
}
