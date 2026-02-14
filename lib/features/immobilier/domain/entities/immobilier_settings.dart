
/// Settings for the Immobilier module that should be synced across devices.
class ImmobilierSettings {
  const ImmobilierSettings({
    required this.enterpriseId,
    this.receiptHeader = 'ELYF IMMOBILIER',
    this.receiptFooter = 'Merci de votre confiance !',
    this.showLogo = true,
    this.overdueGracePeriod = 5,
    this.autoBillingEnabled = true,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
  });

  final String enterpriseId;
  final String receiptHeader;
  final String receiptFooter;
  final bool showLogo;
  final int overdueGracePeriod;
  final bool autoBillingEnabled;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ImmobilierSettings copyWith({
    String? enterpriseId,
    String? receiptHeader,
    String? receiptFooter,
    bool? showLogo,
    int? overdueGracePeriod,
    bool? autoBillingEnabled,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return ImmobilierSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      showLogo: showLogo ?? this.showLogo,
      overdueGracePeriod: overdueGracePeriod ?? this.overdueGracePeriod,
      autoBillingEnabled: autoBillingEnabled ?? this.autoBillingEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory ImmobilierSettings.fromMap(Map<String, dynamic> map) {
    return ImmobilierSettings(
      enterpriseId: map['enterpriseId'] as String? ?? 'default',
      receiptHeader: map['receiptHeader'] as String? ?? 'ELYF IMMOBILIER',
      receiptFooter: map['receiptFooter'] as String? ?? 'Merci de votre confiance !',
      showLogo: map['showLogo'] as bool? ?? true,
      overdueGracePeriod: (map['overdueGracePeriod'] as num?)?.toInt() ?? 5,
      autoBillingEnabled: map['autoBillingEnabled'] as bool? ?? true,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enterpriseId': enterpriseId,
      'receiptHeader': receiptHeader,
      'receiptFooter': receiptFooter,
      'showLogo': showLogo,
      'overdueGracePeriod': overdueGracePeriod,
      'autoBillingEnabled': autoBillingEnabled,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
