import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Status of a purchase.
enum PurchaseStatus {
  draft,     // Purchase Order (Bon de Commande)
  validated, // Stock received and payment recorded
  deleted,
}

/// Represents a raw material purchase for the Eau Minerale module.
class Purchase {
  const Purchase({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.supplierId,
    this.paidAmount = 0,
    this.status = PurchaseStatus.validated,
    this.notes,
    this.number, // PO number (ex: BC-20240217-001)
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final List<PurchaseItem> items;
  final int totalAmount;
  final PaymentMethod paymentMethod;
  final String? supplierId;
  final int paidAmount;
  final PurchaseStatus status;
  final String? notes;
  final String? number;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  int get debtAmount => totalAmount - paidAmount;
  bool get isCredit => debtAmount > 0;
  bool get isPO => status == PurchaseStatus.draft;

  Purchase copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    List<PurchaseItem>? items,
    int? totalAmount,
    PaymentMethod? paymentMethod,
    String? supplierId,
    int? paidAmount,
    PurchaseStatus? status,
    String? notes,
    String? number,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Purchase(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      supplierId: supplierId ?? this.supplierId,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      number: number ?? this.number,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Purchase.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final items = (map['items'] as List<dynamic>?)
            ?.map((item) => PurchaseItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return Purchase(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['paymentMethod'] as String? ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      supplierId: map['supplierId'] as String?,
      paidAmount: (map['paidAmount'] as num?)?.toInt() ?? 0,
      status: PurchaseStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'validated'),
        orElse: () => PurchaseStatus.validated,
      ),
      notes: map['notes'] as String?,
      number: map['number'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'supplierId': supplierId,
      'paidAmount': paidAmount,
      'status': status.name,
      'notes': notes,
      'number': number,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

/// Represents an item in a raw material purchase.
class PurchaseItem {
  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.unit,
    this.metadata = const {},
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String unit;
  final Map<String, dynamic> metadata;

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toInt(),
      totalPrice: (map['totalPrice'] as num).toInt(),
      unit: map['unit'] as String? ?? 'unité',
      metadata: map['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unit': unit,
      'metadata': metadata,
    };
  }

  PurchaseItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
    String? unit,
    Map<String, dynamic>? metadata,
  }) {
    return PurchaseItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      unit: unit ?? this.unit,
      metadata: metadata ?? this.metadata,
    );
  }
}
