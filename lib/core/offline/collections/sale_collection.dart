import 'package:isar/isar.dart';

part 'sale_collection.g.dart';

/// Isar collection for storing Sale entities offline.
///
/// This is a unified sale collection that can store sales from
/// multiple modules (boutique, eau_minerale, gaz, etc.).
@collection
class SaleCollection {
  Id id = Isar.autoIncrement;

  /// Remote Firebase document ID.
  @Index()
  String? remoteId;

  /// Local unique identifier (UUID).
  @Index(unique: true)
  late String localId;

  /// Enterprise this sale belongs to.
  @Index()
  late String enterpriseId;

  /// Module type (boutique, eau_minerale, gaz).
  @Index()
  late String moduleType;

  /// Sale date.
  @Index()
  late DateTime saleDate;

  /// Total amount of the sale.
  late double totalAmount;

  /// Amount paid.
  double paidAmount = 0;

  /// Payment method (cash, credit, mobile_money).
  String? paymentMethod;

  /// Customer name (if applicable).
  String? customerName;

  /// Customer ID (if registered customer).
  String? customerId;

  /// Notes or comments.
  String? notes;

  /// User who made the sale.
  String? soldBy;

  /// Whether the sale is complete or pending.
  @Index()
  bool isComplete = true;

  /// Timestamp when created on the server.
  DateTime? createdAt;

  /// Timestamp when last updated on the server.
  DateTime? updatedAt;

  /// Local timestamp when this record was last modified.
  @Index()
  late DateTime localUpdatedAt;

  /// Creates an empty collection instance.
  SaleCollection();

  /// Creates a sale from a map.
  factory SaleCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    return SaleCollection()
      ..remoteId = map['id'] as String?
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..moduleType = moduleType
      ..saleDate = map['saleDate'] != null
          ? DateTime.parse(map['saleDate'] as String)
          : DateTime.now()
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0
      ..paidAmount = (map['paidAmount'] as num?)?.toDouble() ?? 0
      ..paymentMethod = map['paymentMethod'] as String?
      ..customerName = map['customerName'] as String?
      ..customerId = map['customerId'] as String?
      ..notes = map['notes'] as String?
      ..soldBy = map['soldBy'] as String?
      ..isComplete = map['isComplete'] as bool? ?? true
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
      'localId': localId,
      'enterpriseId': enterpriseId,
      'saleDate': saleDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerId': customerId,
      'notes': notes,
      'soldBy': soldBy,
      'isComplete': isComplete,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Remaining balance for partial payments.
  double get balance => totalAmount - paidAmount;

  /// Whether the sale is fully paid.
  bool get isFullyPaid => paidAmount >= totalAmount;

  /// Whether this is a credit sale.
  bool get isCredit => paymentMethod == 'credit' || !isFullyPaid;
}

/// Isar collection for sale items (line items).
@collection
class SaleItemCollection {
  Id id = Isar.autoIncrement;

  /// Reference to the parent sale (local ID).
  @Index()
  late String saleLocalId;

  /// Product ID.
  late String productId;

  /// Product name (denormalized for offline display).
  late String productName;

  /// Quantity sold.
  late double quantity;

  /// Unit price at time of sale.
  late double unitPrice;

  /// Total price (quantity * unitPrice).
  late double totalPrice;

  /// Unit of measurement.
  String? unit;

  /// Discount applied (if any).
  double discount = 0;

  /// Notes for this item.
  String? notes;

  /// Creates an empty collection instance.
  SaleItemCollection();

  /// Creates from a map.
  factory SaleItemCollection.fromMap(
    Map<String, dynamic> map, {
    required String saleLocalId,
  }) {
    return SaleItemCollection()
      ..saleLocalId = saleLocalId
      ..productId = map['productId'] as String
      ..productName = map['productName'] as String
      ..quantity = (map['quantity'] as num).toDouble()
      ..unitPrice = (map['unitPrice'] as num).toDouble()
      ..totalPrice = (map['totalPrice'] as num).toDouble()
      ..unit = map['unit'] as String?
      ..discount = (map['discount'] as num?)?.toDouble() ?? 0
      ..notes = map['notes'] as String?;
  }

  /// Converts to a map.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unit': unit,
      'discount': discount,
      'notes': notes,
    };
  }
}
