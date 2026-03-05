
/// Settings for the Immobilier module that should be synced across devices.
class ImmobilierSettings {
  const ImmobilierSettings({
    required this.enterpriseId,
    this.overdueGracePeriod = 5,
    this.autoBillingEnabled = true,
    this.penaltyRate = 0.0,
    this.penaltyType = 'fixed', // 'fixed' or 'daily'
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
  });

  final String enterpriseId;
  final int overdueGracePeriod;
  final bool autoBillingEnabled;
  final double penaltyRate;
  final String penaltyType;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ImmobilierSettings copyWith({
    String? enterpriseId,
    int? overdueGracePeriod,
    bool? autoBillingEnabled,
    double? penaltyRate,
    String? penaltyType,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return ImmobilierSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      overdueGracePeriod: overdueGracePeriod ?? this.overdueGracePeriod,
      autoBillingEnabled: autoBillingEnabled ?? this.autoBillingEnabled,
      penaltyRate: penaltyRate ?? this.penaltyRate,
      penaltyType: penaltyType ?? this.penaltyType,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory ImmobilierSettings.fromMap(Map<String, dynamic> map) {
    return ImmobilierSettings(
      enterpriseId: map['enterpriseId'] as String? ?? 'default',
      overdueGracePeriod: (map['overdueGracePeriod'] as num?)?.toInt() ?? 5,
      autoBillingEnabled: map['autoBillingEnabled'] as bool? ?? true,
      penaltyRate: (map['penaltyRate'] as num?)?.toDouble() ?? 0.0,
      penaltyType: map['penaltyType'] as String? ?? 'fixed',
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enterpriseId': enterpriseId,
      'overdueGracePeriod': overdueGracePeriod,
      'autoBillingEnabled': autoBillingEnabled,
      'penaltyRate': penaltyRate,
      'penaltyType': penaltyType,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
