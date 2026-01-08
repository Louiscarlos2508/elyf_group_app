/// Legacy SaleCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class SaleCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String moduleType;
  String? customerId;
  String? customerName;
  late DateTime saleDate;
  double totalAmount = 0;
  double paidAmount = 0;
  String paymentMethod = 'cash';
  String status = 'completed';
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  SaleCollection();

  /// Creates a SaleCollection from a map.
  factory SaleCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    final collection = SaleCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..moduleType = moduleType
      ..customerId = map['customerId'] as String?
      ..customerName = map['customerName'] as String?
      ..saleDate = map['saleDate'] != null
          ? DateTime.parse(map['saleDate'] as String)
          : (map['date'] != null
              ? DateTime.parse(map['date'] as String)
              : DateTime.now())
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0
      ..paidAmount = (map['paidAmount'] as num?)?.toDouble() ??
          (map['amountPaid'] as num?)?.toDouble() ??
          0
      ..paymentMethod = map['paymentMethod'] as String? ?? 'cash'
      ..status = map['status'] as String? ?? 'completed'
      ..notes = map['notes'] as String?
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId ?? localId,
        'localId': localId,
        'enterpriseId': enterpriseId,
        'customerId': customerId,
        'customerName': customerName,
        'saleDate': saleDate.toIso8601String(),
        'date': saleDate.toIso8601String(),
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'paymentMethod': paymentMethod,
        'status': status,
        'notes': notes,
      };

  double get remainingAmount => totalAmount - paidAmount;
  bool get isPaid => paidAmount >= totalAmount;
}

/// Stub SaleItemCollection.
class SaleItemCollection {
  int id = 0;
  late String saleLocalId;
  late String productId;
  late String productName;
  double quantity = 0;
  double unitPrice = 0;
  double totalPrice = 0;
  late DateTime localUpdatedAt;

  SaleItemCollection();

  /// Creates a SaleItemCollection from a map.
  factory SaleItemCollection.fromMap(
    Map<String, dynamic> map, {
    required String saleLocalId,
  }) {
    final collection = SaleItemCollection()
      ..saleLocalId = saleLocalId
      ..productId = map['productId'] as String? ?? ''
      ..productName = map['productName'] as String? ?? ''
      ..quantity = (map['quantity'] as num?)?.toDouble() ?? 0
      ..unitPrice = (map['unitPrice'] as num?)?.toDouble() ?? 0
      ..totalPrice = (map['totalPrice'] as num?)?.toDouble() ?? 0
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };
}
