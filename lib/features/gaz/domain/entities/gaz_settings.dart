/// Paramètres de configuration du module Gaz.
class GazSettings {
  const GazSettings({
    required this.enterpriseId,
    required this.moduleId,
    this.retailPrices = const {},
    this.wholesalePrices = const {},
    this.purchasePrices = const {},
    this.supplierExchangeFees = const {},
    this.lowStockThresholds = const {},
    this.depositRates = const {},
    this.nominalStocks = const {},
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
    this.autoPrintReceipt = false,
  });

  final String enterpriseId;
  final String moduleId;
  final Map<int, double> retailPrices; // poids (kg) -> prix détail
  final Map<int, double> wholesalePrices; // poids (kg) -> prix gros
  final Map<int, double> purchasePrices; // poids (kg) -> prix achat (fournisseur)
  final Map<int, double> supplierExchangeFees; // poids (kg) -> frais échange fournisseur
  final Map<int, int> lowStockThresholds; // poids (kg) -> seuil d'alerte
  final Map<int, double> depositRates; // poids (kg) -> montant de la consigne
  final Map<int, int> nominalStocks; // poids (kg) -> quantité totale possédée (fixed stock)
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final bool autoPrintReceipt;

  GazSettings copyWith({
    String? enterpriseId,
    String? moduleId,
    Map<int, double>? retailPrices,
    Map<int, double>? wholesalePrices,
    Map<int, double>? purchasePrices,
    Map<int, double>? supplierExchangeFees,
    Map<int, int>? lowStockThresholds,
    Map<int, double>? depositRates,
    Map<int, int>? nominalStocks,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
    bool? autoPrintReceipt,
  }) {
    return GazSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      retailPrices: retailPrices ?? this.retailPrices,
      wholesalePrices: wholesalePrices ?? this.wholesalePrices,
      purchasePrices: purchasePrices ?? this.purchasePrices,
      supplierExchangeFees: supplierExchangeFees ?? this.supplierExchangeFees,
      lowStockThresholds: lowStockThresholds ?? this.lowStockThresholds,
      depositRates: depositRates ?? this.depositRates,
      nominalStocks: nominalStocks ?? this.nominalStocks,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
    );
  }

  factory GazSettings.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final retailPricesRaw = map['retailPrices'] as Map<String, dynamic>?;
    final retailPrices = retailPricesRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        {};

    final wholesalePricesRaw = map['wholesalePrices'] as Map<String, dynamic>?;
    final Map<int, double> wholesalePrices = {};
    
    wholesalePricesRaw?.forEach((weightStr, priceRaw) {
      final weight = int.parse(weightStr);
      if (priceRaw is num) {
        wholesalePrices[weight] = priceRaw.toDouble();
      } else if (priceRaw is Map<String, dynamic>) {
        // Migration from old tiered structure
        final defaultPrice = priceRaw['default'] ?? priceRaw.values.firstOrNull;
        if (defaultPrice != null) {
          wholesalePrices[weight] = (defaultPrice as num).toDouble();
        }
      }
    });

    final purchasePricesRaw = map['purchasePrices'] as Map<String, dynamic>?;
    final purchasePrices = purchasePricesRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        {};

    final exchangeFeesRaw = map['supplierExchangeFees'] as Map<String, dynamic>?;
    final exchangeFees = exchangeFeesRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        {};

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

    final nominalStocksRaw = map['nominalStocks'] as Map<String, dynamic>?;
    final nominalStocks = nominalStocksRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        {};

    return GazSettings(
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      moduleId: map['moduleId'] as String? ?? '',
      retailPrices: retailPrices,
      wholesalePrices: wholesalePrices,
      purchasePrices: purchasePrices,
      supplierExchangeFees: exchangeFees,
      lowStockThresholds: lowStockThresholds,
      depositRates: depositRates,
      nominalStocks: nominalStocks,
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
      'retailPrices': retailPrices.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'wholesalePrices': wholesalePrices.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'purchasePrices': purchasePrices.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'supplierExchangeFees': supplierExchangeFees.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'lowStockThresholds': lowStockThresholds.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'depositRates': depositRates.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'nominalStocks': nominalStocks.map(
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

  /// Récupère le prix détail pour un poids donné.
  double? getRetailPrice(int weight) {
    return retailPrices[weight];
  }

  /// Définit le prix détail pour un poids donné.
  GazSettings setRetailPrice(int weight, double price) {
    final updated = Map<int, double>.from(retailPrices);
    updated[weight] = price;
    return copyWith(retailPrices: updated, updatedAt: DateTime.now());
  }

  /// Récupère le prix en gros pour un poids donné.
  double? getWholesalePrice(int weight) {
    return wholesalePrices[weight];
  }

  /// Définit le prix en gros pour un poids donné.
  GazSettings setWholesalePrice(int weight, double price) {
    final updated = Map<int, double>.from(wholesalePrices);
    updated[weight] = price;
    return copyWith(wholesalePrices: updated, updatedAt: DateTime.now());
  }

  /// Récupère le prix d'achat pour un poids donné.
  double? getPurchasePrice(int weight) {
    return purchasePrices[weight];
  }

  /// Définit le prix d'achat pour un poids donné.
  GazSettings setPurchasePrice(int weight, double price) {
    final updated = Map<int, double>.from(purchasePrices);
    updated[weight] = price;
    return copyWith(purchasePrices: updated, updatedAt: DateTime.now());
  }

  /// Récupère les frais d'échange fournisseur pour un poids donné.
  double? getSupplierExchangeFee(int weight) {
    return supplierExchangeFees[weight];
  }

  /// Définit les frais d'échange fournisseur pour un poids donné.
  GazSettings setSupplierExchangeFee(int weight, double fee) {
    final updated = Map<int, double>.from(supplierExchangeFees);
    updated[weight] = fee;
    return copyWith(supplierExchangeFees: updated, updatedAt: DateTime.now());
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

  /// Récupère le stock nominal pour un poids donné.
  int getNominalStock(int weight) {
    return nominalStocks[weight] ?? 0;
  }

  /// Définit le stock nominal pour un poids donné.
  GazSettings setNominalStock(int weight, int quantity) {
    final updated = Map<int, int>.from(nominalStocks);
    updated[weight] = quantity;
    return copyWith(nominalStocks: updated, updatedAt: DateTime.now());
  }
}
