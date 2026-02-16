import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

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
    this.sessionId, // ID de la session active
    this.customerName,
    this.customerPhone,
    this.createdBy,
    this.notes,
    this.tourId, // ID du tour d'approvisionnement (pour ventes en gros)
    this.wholesalerId, // ID du grossiste (pour ventes en gros)
    this.wholesalerName, // Nom du grossiste (pour ventes en gros)
    this.emptyReturnedQuantity = 0, // Nombre de bouteilles vides rendues
    this.dealType = GasSaleDealType.exchange, // Type de transaction (Échange ou Nouveau)
    this.sellerId, // ID du vendeur
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.paymentMethod = PaymentMethod.cash,
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
  final String? tourId; // ID du tour d'approvisionnement (pour ventes en gros)
  final String? wholesalerId; // ID du grossiste (pour ventes en gros)
  final String? wholesalerName; // Nom du grossiste (pour ventes en gros)
  final int emptyReturnedQuantity; // Nombre de bouteilles vides rendues
  final GasSaleDealType dealType; // Type de transaction (Échange ou Nouveau)
  final String? sellerId; // ID du vendeur
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final PaymentMethod paymentMethod;

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
    );
  }

  factory GasSale.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return GasSale(
      id: map['id'] as String? ?? map['localId'] as String,
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
  newCylinder('Nouveau');

  const GasSaleDealType(this.label);
  final String label;
}

