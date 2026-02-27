/// Paramètres de configuration du module Gaz.
class GazSettings {
  const GazSettings({
    required this.enterpriseId,
    required this.moduleId,
    Map<int, double>? retailPrices,
    Map<int, double>? wholesalePrices,
    Map<int, double>? purchasePrices,
    Map<int, double>? supplierExchangeFees,
    Map<int, int>? lowStockThresholds,
    Map<int, double>? depositRates,
    Map<int, double>? loadingFees,
    Map<int, double>? unloadingFees,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
    this.autoPrintReceipt = false,
  })  : _retailPrices = retailPrices,
        _wholesalePrices = wholesalePrices,
        _purchasePrices = purchasePrices,
        _supplierExchangeFees = supplierExchangeFees,
        _lowStockThresholds = lowStockThresholds,
        _depositRates = depositRates,
        _loadingFees = loadingFees,
        _unloadingFees = unloadingFees;

  final String enterpriseId;
  final String moduleId;

  final Map<int, double>? _retailPrices;
  Map<int, double> get retailPrices => _retailPrices ?? const <int, double>{};

  final Map<int, double>? _wholesalePrices;
  Map<int, double> get wholesalePrices => _wholesalePrices ?? const <int, double>{};

  final Map<int, double>? _purchasePrices;
  Map<int, double> get purchasePrices => _purchasePrices ?? const <int, double>{};

  final Map<int, double>? _supplierExchangeFees;
  Map<int, double> get supplierExchangeFees => _supplierExchangeFees ?? const <int, double>{};

  final Map<int, int>? _lowStockThresholds;
  Map<int, int> get lowStockThresholds => _lowStockThresholds ?? const <int, int>{};

  final Map<int, double>? _depositRates;
  Map<int, double> get depositRates => _depositRates ?? const <int, double>{};

  final Map<int, double>? _loadingFees;
  Map<int, double> get loadingFees => _loadingFees ?? const <int, double>{};

  final Map<int, double>? _unloadingFees;
  Map<int, double> get unloadingFees => _unloadingFees ?? const <int, double>{};

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
    Map<int, double>? loadingFees,
    Map<int, double>? unloadingFees,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
    bool? autoPrintReceipt,
  }) {
    return GazSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      retailPrices: retailPrices ?? _retailPrices,
      wholesalePrices: wholesalePrices ?? _wholesalePrices,
      purchasePrices: purchasePrices ?? _purchasePrices,
      supplierExchangeFees: supplierExchangeFees ?? _supplierExchangeFees,
      lowStockThresholds: lowStockThresholds ?? _lowStockThresholds,
      depositRates: depositRates ?? _depositRates,
      loadingFees: loadingFees ?? _loadingFees,
      unloadingFees: unloadingFees ?? _unloadingFees,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
    );
  }

  factory GazSettings.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final retailPrices = (map['retailPrices'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        const <int, double>{};

    final wholesalePricesRaw = map['wholesalePrices'] as Map<String, dynamic>?;
    final Map<int, double> wholesalePrices = {};
    
    wholesalePricesRaw?.forEach((weightStr, priceRaw) {
      final weight = int.parse(weightStr);
      if (priceRaw is num) {
        wholesalePrices[weight] = priceRaw.toDouble();
      } else if (priceRaw is Map<String, dynamic>) {
        final defaultPrice = priceRaw['default'] ?? priceRaw.values.firstOrNull;
        if (defaultPrice != null) {
          wholesalePrices[weight] = (defaultPrice as num).toDouble();
        }
      }
    });

    final purchasePrices = (map['purchasePrices'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        const <int, double>{};

    final exchangeFees = (map['supplierExchangeFees'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        const <int, double>{};

    final lowStockThresholds = (map['lowStockThresholds'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
        ) ??
        const <int, int>{};

    final depositRates = (map['depositRates'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        const <int, double>{};

    final loadingFees = (map['loadingFees'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        const <int, double>{};

    final unloadingFees = (map['unloadingFees'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        const <int, double>{};

    return GazSettings(
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      moduleId: map['moduleId'] as String? ?? '',
      retailPrices: retailPrices,
      wholesalePrices: wholesalePrices,
      purchasePrices: purchasePrices,
      supplierExchangeFees: exchangeFees,
      lowStockThresholds: lowStockThresholds,
      depositRates: depositRates,
      loadingFees: loadingFees,
      unloadingFees: unloadingFees,
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
      'loadingFees': loadingFees.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'unloadingFees': unloadingFees.map(
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

  double? getRetailPrice(int weight) => retailPrices[weight];

  GazSettings setRetailPrice(int weight, double price) {
    final updated = Map<int, double>.from(retailPrices);
    updated[weight] = price;
    return copyWith(retailPrices: updated, updatedAt: DateTime.now());
  }

  double? getWholesalePrice(int weight) => wholesalePrices[weight];

  GazSettings setWholesalePrice(int weight, double price) {
    final updated = Map<int, double>.from(wholesalePrices);
    updated[weight] = price;
    return copyWith(wholesalePrices: updated, updatedAt: DateTime.now());
  }

  double? getPurchasePrice(int weight) => purchasePrices[weight];

  GazSettings setPurchasePrice(int weight, double price) {
    final updated = Map<int, double>.from(purchasePrices);
    updated[weight] = price;
    return copyWith(purchasePrices: updated, updatedAt: DateTime.now());
  }

  double? getSupplierExchangeFee(int weight) => supplierExchangeFees[weight];

  GazSettings setSupplierExchangeFee(int weight, double fee) {
    final updated = Map<int, double>.from(supplierExchangeFees);
    updated[weight] = fee;
    return copyWith(supplierExchangeFees: updated, updatedAt: DateTime.now());
  }

  int getLowStockThreshold(int weight) => lowStockThresholds[weight] ?? 0;

  GazSettings setLowStockThreshold(int weight, int threshold) {
    final updatedThresholds = Map<int, int>.from(lowStockThresholds);
    updatedThresholds[weight] = threshold;
    return copyWith(lowStockThresholds: updatedThresholds, updatedAt: DateTime.now());
  }

  double getDepositRate(int weight) => depositRates[weight] ?? 0.0;

  GazSettings setDepositRate(int weight, double rate) {
    final updatedRates = Map<int, double>.from(depositRates);
    updatedRates[weight] = rate;
    return copyWith(depositRates: updatedRates, updatedAt: DateTime.now());
  }

  GazSettings setLoadingFee(int weight, double fee) {
    final updated = Map<int, double>.from(loadingFees);
    updated[weight] = fee;
    return copyWith(loadingFees: updated, updatedAt: DateTime.now());
  }

  GazSettings setUnloadingFee(int weight, double fee) {
    final updated = Map<int, double>.from(unloadingFees);
    updated[weight] = fee;
    return copyWith(unloadingFees: updated, updatedAt: DateTime.now());
  }
}
