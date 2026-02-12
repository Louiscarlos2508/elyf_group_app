/// Paramètres de configuration du module Gaz.
class GazSettings {
  const GazSettings({
    required this.enterpriseId,
    required this.moduleId,
    this.wholesalePrices = const {},
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String enterpriseId;
  final String moduleId;
  final Map<int, double> wholesalePrices; // poids (kg) -> prix en gros (FCFA)
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  GazSettings copyWith({
    String? enterpriseId,
    String? moduleId,
    Map<int, double>? wholesalePrices,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return GazSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      wholesalePrices: wholesalePrices ?? this.wholesalePrices,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory GazSettings.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final wholesalePricesRaw = map['wholesalePrices'] as Map<String, dynamic>?;
    final wholesalePrices = wholesalePricesRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        {};

    return GazSettings(
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      moduleId: map['moduleId'] as String? ?? '',
      wholesalePrices: wholesalePrices,
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
        (k, v) => MapEntry(k.toString(), v),
      ),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;

  /// Récupère le prix en gros pour un poids donné.
  double? getWholesalePrice(int weight) {
    return wholesalePrices[weight];
  }

  /// Définit le prix en gros pour un poids donné.
  GazSettings setWholesalePrice(int weight, double price) {
    final updatedPrices = Map<int, double>.from(wholesalePrices);
    updatedPrices[weight] = price;
    return copyWith(wholesalePrices: updatedPrices, updatedAt: DateTime.now());
  }

  /// Supprime le prix en gros pour un poids donné.
  GazSettings removeWholesalePrice(int weight) {
    final updatedPrices = Map<int, double>.from(wholesalePrices);
    updatedPrices.remove(weight);
    return copyWith(wholesalePrices: updatedPrices, updatedAt: DateTime.now());
  }
}
