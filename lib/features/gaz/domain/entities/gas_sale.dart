import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Représente une vente de gaz.
class GasSale {
  const GasSale({
    required this.id,
    required this.enterpriseId,
    required this.cylinderId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleDate,
    required this.saleType,
    this.sessionId,
    this.customerName,
    this.customerPhone,
    this.createdBy,
    this.notes,
    this.tourId,
    this.wholesalerId,
    this.wholesalerName,
    this.emptyReturnedQuantity = 0,
    this.dealType = GasSaleDealType.exchange,
    this.sellerId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.paymentMethod = PaymentMethod.cash,
    this.cashAmount,       // Part espèces (paiement mixte)
    this.mobileMoneyAmount, // Part mobile money (paiement mixte)
  });

  final String id;
  final String enterpriseId;
  final String cylinderId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime saleDate;
  final SaleType saleType;
  final String? sessionId;
  final String? customerName;
  final String? customerPhone;
  final String? createdBy;
  final String? notes;
  final String? tourId;
  final String? wholesalerId;
  final String? wholesalerName;
  final int emptyReturnedQuantity;
  final GasSaleDealType dealType;
  final String? sellerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final PaymentMethod paymentMethod;
  final double? cashAmount;        // Part espèces si paiement mixte
  final double? mobileMoneyAmount; // Part mobile money si paiement mixte

  bool get isMixedPayment => cashAmount != null && mobileMoneyAmount != null;

  bool get isExchange => dealType == GasSaleDealType.exchange;

  GasSale copyWith({
    String? id,
    String? enterpriseId,
    String? cylinderId,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? saleDate,
    SaleType? saleType,
    String? sessionId,
    String? customerName,
    String? customerPhone,
    String? createdBy,
    String? notes,
    String? tourId,
    String? wholesalerId,
    String? wholesalerName,
    int? emptyReturnedQuantity,
    GasSaleDealType? dealType,
    String? sellerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
    PaymentMethod? paymentMethod,
    Object? cashAmount = _sentinel,
    Object? mobileMoneyAmount = _sentinel,
  }) {
    return GasSale(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      cylinderId: cylinderId ?? this.cylinderId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      saleDate: saleDate ?? this.saleDate,
      saleType: saleType ?? this.saleType,
      sessionId: sessionId ?? this.sessionId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      tourId: tourId ?? this.tourId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      wholesalerName: wholesalerName ?? this.wholesalerName,
      emptyReturnedQuantity: emptyReturnedQuantity ?? this.emptyReturnedQuantity,
      dealType: dealType ?? this.dealType,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashAmount: cashAmount == _sentinel ? this.cashAmount : cashAmount as double?,
      mobileMoneyAmount: mobileMoneyAmount == _sentinel ? this.mobileMoneyAmount : mobileMoneyAmount as double?,
    );
  }

  static const _sentinel = Object();

  factory GasSale.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    // Prioritize embedded localId to maintain offline relations on new devices
    final validLocalId = map['localId'] as String?;
    final objectId = (validLocalId != null && validLocalId.trim().isNotEmpty)
        ? validLocalId
        : (map['id'] as String? ?? '');

    return GasSale(
      id: objectId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      cylinderId: map['cylinderId'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      saleDate: DateTime.parse(map['saleDate'] as String),
      saleType: SaleType.values.byName(map['saleType'] as String? ?? 'retail'),
      sessionId: map['sessionId'] as String?,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      createdBy: map['createdBy'] as String?,
      notes: map['notes'] as String?,
      tourId: map['tourId'] as String?,
      wholesalerId: map['wholesalerId'] as String?,
      wholesalerName: map['wholesalerName'] as String?,
      emptyReturnedQuantity: (map['emptyReturnedQuantity'] as num?)?.toInt() ?? 0,
      dealType: GasSaleDealType.values.byName(map['dealType'] as String? ?? 'exchange'),
      sellerId: map['sellerId'] as String?,
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod'] as String? ?? 'cash'),
      cashAmount: (map['cashAmount'] as num?)?.toDouble(),
      mobileMoneyAmount: (map['mobileMoneyAmount'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'cylinderId': cylinderId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'saleDate': saleDate.toIso8601String(),
      'saleType': saleType.name,
      'sessionId': sessionId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'createdBy': createdBy,
      'notes': notes,
      'tourId': tourId,
      'wholesalerId': wholesalerId,
      'wholesalerName': wholesalerName,
      'emptyReturnedQuantity': emptyReturnedQuantity,
      'dealType': dealType.name,
      'sellerId': sellerId,
      'paymentMethod': paymentMethod.name,
      'cashAmount': cashAmount,
      'mobileMoneyAmount': mobileMoneyAmount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
  bool get isDeleted => deletedAt != null;
}

enum SaleType {
  retail('Détail'),
  wholesale('Gros');

  const SaleType(this.label);
  final String label;
}

enum GasSaleDealType {
  exchange('Échange'),
  newCylinder('Nouveau'),
  returnCylinder('Retour Consigne');

  const GasSaleDealType(this.label);
  final String label;
}

