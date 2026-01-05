import 'package:isar/isar.dart';

part 'product_collection.g.dart';

/// Isar collection for storing Product entities offline.
///
/// This is a unified product collection that can store products from
/// multiple modules (boutique, eau_minerale, etc.).
@collection
class ProductCollection {
  Id id = Isar.autoIncrement;

  /// Remote Firebase document ID.
  @Index(unique: true)
  late String remoteId;

  /// Enterprise this product belongs to.
  @Index()
  late String enterpriseId;

  /// Module type (boutique, eau_minerale, gaz).
  @Index()
  late String moduleType;

  /// Product name.
  @Index()
  late String name;

  /// Product description.
  String? description;

  /// Current stock quantity.
  double stock = 0;

  /// Purchase price.
  double purchasePrice = 0;

  /// Selling price.
  double sellingPrice = 0;

  /// Unit of measurement.
  String? unit;

  /// Category or type.
  String? category;

  /// Minimum stock level for alerts.
  double? minStockLevel;

  /// Barcode or SKU.
  String? barcode;

  /// Image URL.
  String? imageUrl;

  /// Whether the product is active/available.
  @Index()
  bool isActive = true;

  /// Timestamp when created on the server.
  DateTime? createdAt;

  /// Timestamp when last updated on the server.
  @Index()
  DateTime? updatedAt;

  /// Local timestamp when this record was last modified.
  @Index()
  late DateTime localUpdatedAt;

  /// Creates an empty collection instance.
  ProductCollection();

  /// Creates a product collection from a map.
  factory ProductCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
  }) {
    return ProductCollection()
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

  /// Converts to a map.
  Map<String, dynamic> toMap() {
    return {
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
  }

  /// Updates stock quantity.
  void updateStock(double quantity, {bool isAddition = true}) {
    if (isAddition) {
      stock += quantity;
    } else {
      stock -= quantity;
    }
    localUpdatedAt = DateTime.now();
  }

  /// Calculated profit margin.
  double get profitMargin {
    if (purchasePrice <= 0) return 0;
    return ((sellingPrice - purchasePrice) / purchasePrice) * 100;
  }

  /// Whether stock is below minimum level.
  bool get isLowStock {
    if (minStockLevel == null) return false;
    return stock < minStockLevel!;
  }
}
