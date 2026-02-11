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
    this.customerName,
    this.customerPhone,
    this.createdBy,
    this.notes,
    this.tourId, // ID du tour d'approvisionnement (pour ventes en gros)
    this.wholesalerId, // ID du grossiste (pour ventes en gros)
    this.wholesalerName, // Nom du grossiste (pour ventes en gros)
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String cylinderId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime saleDate;
  final SaleType saleType;
  final String? customerName;
  final String? customerPhone;
  final String? createdBy;
  final String? notes;
  final String? tourId; // ID du tour d'approvisionnement (pour ventes en gros)
  final String? wholesalerId; // ID du grossiste (pour ventes en gros)
  final String? wholesalerName; // Nom du grossiste (pour ventes en gros)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  GasSale copyWith({
    String? id,
    String? enterpriseId,
    String? cylinderId,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? saleDate,
    SaleType? saleType,
    String? customerName,
    String? customerPhone,
    String? createdBy,
    String? notes,
    String? tourId,
    String? wholesalerId,
    String? wholesalerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
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
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      tourId: tourId ?? this.tourId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      wholesalerName: wholesalerName ?? this.wholesalerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
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
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      createdBy: map['createdBy'] as String?,
      notes: map['notes'] as String?,
      tourId: map['tourId'] as String?,
      wholesalerId: map['wholesalerId'] as String?,
      wholesalerName: map['wholesalerName'] as String?,
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
      'customerName': customerName,
      'customerPhone': customerPhone,
      'createdBy': createdBy,
      'notes': notes,
      'tourId': tourId,
      'wholesalerId': wholesalerId,
      'wholesalerName': wholesalerName,
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
