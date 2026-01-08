/// Legacy ProductCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class ProductCollection {
  int id = 0;
  late String localId;
  late String remoteId;
  late String enterpriseId;
  late String moduleType;
  late String name;
  String? description;
  double stock = 0;
  double purchasePrice = 0;
  double sellingPrice = 0;
  String? unit;
  String? category;
  double? minStockLevel;
  String? barcode;
  String? imageUrl;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  ProductCollection();

  factory ProductCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    return ProductCollection()
      ..localId = localId
      ..remoteId = map['id'] as String
      ..enterpriseId = enterpriseId
      ..moduleType = moduleType
      ..name = map['name'] as String
      ..description = map['description'] as String?
      ..stock = (map['stock'] as num?)?.toDouble() ?? 0
      ..purchasePrice = (map['purchasePrice'] as num?)?.toDouble() ?? 0
      ..sellingPrice = (map['sellingPrice'] as num?)?.toDouble() ?? 0
      ..unit = map['unit'] as String?
      ..category = map['category'] as String?
      ..minStockLevel = (map['minStockLevel'] as num?)?.toDouble()
      ..barcode = map['barcode'] as String?
      ..imageUrl = map['imageUrl'] as String?
      ..isActive = map['isActive'] as bool? ?? true
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null
      ..localUpdatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId,
        'enterpriseId': enterpriseId,
        'name': name,
        'description': description,
        'stock': stock,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'unit': unit,
        'category': category,
        'minStockLevel': minStockLevel,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  void updateStock(double quantity, {bool isAddition = true}) {
    stock = isAddition ? stock + quantity : stock - quantity;
    localUpdatedAt = DateTime.now();
  }

  double get profitMargin {
    if (purchasePrice <= 0) return 0;
    return ((sellingPrice - purchasePrice) / purchasePrice) * 100;
  }

  bool get isLowStock => minStockLevel != null && stock < minStockLevel!;
}
