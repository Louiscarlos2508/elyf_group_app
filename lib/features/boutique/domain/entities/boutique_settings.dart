
/// Settings for the Boutique module that should be synced across devices.
class BoutiqueSettings {
  const BoutiqueSettings({
    required this.enterpriseId,
    this.lowStockThreshold = 5,
    this.enabledPaymentMethods = const ['cash', 'mobile_money', 'card'],
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
  });

  final String enterpriseId;
  final int lowStockThreshold;
  final List<String> enabledPaymentMethods;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  BoutiqueSettings copyWith({
    String? enterpriseId,
    int? lowStockThreshold,
    List<String>? enabledPaymentMethods,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return BoutiqueSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
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
      'lowStockThreshold': lowStockThreshold,
      'enabledPaymentMethods': enabledPaymentMethods,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
