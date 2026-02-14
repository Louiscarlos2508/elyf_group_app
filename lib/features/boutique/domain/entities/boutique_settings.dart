
/// Settings for the Boutique module that should be synced across devices.
class BoutiqueSettings {
  const BoutiqueSettings({
    required this.enterpriseId,
    this.receiptHeader = 'ELYF GROUP',
    this.receiptFooter = 'Merci de votre visite !',
    this.showLogo = true,
    this.lowStockThreshold = 5,
    this.enabledPaymentMethods = const ['cash', 'mobile_money', 'card'],
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
  });

  final String enterpriseId;
  final String receiptHeader;
  final String receiptFooter;
  final bool showLogo;
  final int lowStockThreshold;
  final List<String> enabledPaymentMethods;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  BoutiqueSettings copyWith({
    String? enterpriseId,
    String? receiptHeader,
    String? receiptFooter,
    bool? showLogo,
    int? lowStockThreshold,
    List<String>? enabledPaymentMethods,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return BoutiqueSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      showLogo: showLogo ?? this.showLogo,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      enabledPaymentMethods: enabledPaymentMethods ?? this.enabledPaymentMethods,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory BoutiqueSettings.fromMap(Map<String, dynamic> map) {
    return BoutiqueSettings(
      enterpriseId: map['enterpriseId'] as String? ?? 'default',
      receiptHeader: map['receiptHeader'] as String? ?? 'ELYF GROUP',
      receiptFooter: map['receiptFooter'] as String? ?? 'Merci de votre visite !',
      showLogo: map['showLogo'] as bool? ?? true,
      lowStockThreshold: map['lowStockThreshold'] as int? ?? 5,
      enabledPaymentMethods: List<String>.from(map['enabledPaymentMethods'] ?? ['cash', 'mobile_money', 'card']),
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
      'lowStockThreshold': lowStockThreshold,
      'enabledPaymentMethods': enabledPaymentMethods,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
