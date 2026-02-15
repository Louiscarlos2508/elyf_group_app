/// Paramètres de configuration du module Gaz.
class GazSettings {
  const GazSettings({
    required this.enterpriseId,
    required this.moduleId,
    this.wholesalePrices = const {},
    this.lowStockThresholds = const {},
    this.depositRates = const {},
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
    this.autoPrintReceipt = false,
  });

  final String enterpriseId;
  final String moduleId;
  final Map<int, Map<String, double>> wholesalePrices; // poids (kg) -> { tier -> prix }
  final Map<int, int> lowStockThresholds; // poids (kg) -> seuil d'alerte
  final Map<int, double> depositRates; // poids (kg) -> montant de la consigne
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final bool autoPrintReceipt;

  GazSettings copyWith({
    String? enterpriseId,
    String? moduleId,
    Map<int, Map<String, double>>? wholesalePrices,
    Map<int, int>? lowStockThresholds,
    Map<int, double>? depositRates,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
    bool? autoPrintReceipt,
  }) {
    return GazSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      wholesalePrices: wholesalePrices ?? this.wholesalePrices,
      lowStockThresholds: lowStockThresholds ?? this.lowStockThresholds,
      depositRates: depositRates ?? this.depositRates,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
    );
  }

  factory GazSettings.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    // ... existing wholesalePrices and lowStockThresholds logic ...
    final wholesalePricesRaw = map['wholesalePrices'] as Map<String, dynamic>?;
    final Map<int, Map<String, double>> wholesalePrices = {};
    
    wholesalePricesRaw?.forEach((weightStr, tiersRaw) {
      final weight = int.parse(weightStr);
      final tiers = (tiersRaw as Map<String, dynamic>).map(
        (tier, price) => MapEntry(tier, (price as num).toDouble()),
      );
      wholesalePrices[weight] = tiers;
    });

    final lowStockThresholdsRaw = map['lowStockThresholds'] as Map<String, dynamic>?;
    final lowStockThresholds = lowStockThresholdsRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        {};

    final depositRatesRaw = map['depositRates'] as Map<String, dynamic>?;
    final depositRates = depositRatesRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        {};

    return GazSettings(
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      moduleId: map['moduleId'] as String? ?? '',
      wholesalePrices: wholesalePrices,
      lowStockThresholds: lowStockThresholds,
      depositRates: depositRates,
      autoPrintReceipt: map['autoPrintReceipt'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enterpriseId': enterpriseId,
      'moduleId': moduleId,
      'wholesalePrices': wholesalePrices.map(
        (weight, tiers) => MapEntry(weight.toString(), tiers),
      ),
      'lowStockThresholds': lowStockThresholds.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'depositRates': depositRates.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'autoPrintReceipt': autoPrintReceipt,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
  bool get isDeleted => deletedAt != null;

  /// Récupère les prix en gros pour un poids donné.
  Map<String, double> getWholesalePrices(int weight) {
    return wholesalePrices[weight] ?? {};
  }

  /// Récupère le prix en gros pour un poids et un tier donnés.
  double? getWholesalePrice(int weight, {String tier = 'default'}) {
    return wholesalePrices[weight]?[tier];
  }

  /// Définit le prix en gros pour un poids et un tier donnés.
  GazSettings setWholesalePrice(int weight, double price, {String tier = 'default'}) {
    final updatedWholesalePrices = Map<int, Map<String, double>>.from(wholesalePrices);
    final weightTiers = Map<String, double>.from(updatedWholesalePrices[weight] ?? {});
    weightTiers[tier] = price;
    updatedWholesalePrices[weight] = weightTiers;
    
    return copyWith(wholesalePrices: updatedWholesalePrices, updatedAt: DateTime.now());
  }

  /// Supprime un tier de prix pour un poids donné.
  GazSettings removeWholesalePrice(int weight, {String tier = 'default'}) {
    final updatedWholesalePrices = Map<int, Map<String, double>>.from(wholesalePrices);
    final weightTiers = Map<String, double>.from(updatedWholesalePrices[weight] ?? {});
    weightTiers.remove(tier);
    
    if (weightTiers.isEmpty) {
      updatedWholesalePrices.remove(weight);
    } else {
      updatedWholesalePrices[weight] = weightTiers;
    }
    
    return copyWith(wholesalePrices: updatedWholesalePrices, updatedAt: DateTime.now());
  }

  /// Récupère le seuil d'alerte pour un poids donné.
  int getLowStockThreshold(int weight) {
    return lowStockThresholds[weight] ?? 0;
  }

  /// Définit le seuil d'alerte pour un poids donné.
  GazSettings setLowStockThreshold(int weight, int threshold) {
    final updatedThresholds = Map<int, int>.from(lowStockThresholds);
    updatedThresholds[weight] = threshold;
    return copyWith(lowStockThresholds: updatedThresholds, updatedAt: DateTime.now());
  }

  /// Récupère le taux de consigne pour un poids donné.
  double getDepositRate(int weight) {
    return depositRates[weight] ?? 0.0;
  }

  /// Définit le taux de consigne pour un poids donné.
  GazSettings setDepositRate(int weight, double rate) {
    final updatedRates = Map<int, double>.from(depositRates);
    updatedRates[weight] = rate;
    return copyWith(depositRates: updatedRates, updatedAt: DateTime.now());
  }
}
