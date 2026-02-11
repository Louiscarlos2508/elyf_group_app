import '../../../../core/domain/entities/attached_file.dart';

/// Represents a purchase (achat) of products for the boutique.
class Purchase {
  const Purchase({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.supplier,
    this.notes,
    this.attachedFiles,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final List<PurchaseItem> items;
  final int totalAmount; // Montant total en CFA
  final String? supplier; // Fournisseur
  final String? notes; // Notes additionnelles
  final List<AttachedFile>?
  attachedFiles; // Fichiers joints (factures, photos, etc.)
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  Purchase copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    List<PurchaseItem>? items,
    int? totalAmount,
    String? supplier,
    String? notes,
    List<AttachedFile>? attachedFiles,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Purchase.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final items =
        (map['items'] as List<dynamic>?)
            ?.map((item) => PurchaseItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    final attachedFilesRaw = map['attachedFiles'] as List<dynamic>?;
    final attachedFiles = attachedFilesRaw?.map((f) => AttachedFile.fromMap(f as Map<String, dynamic>)).toList();

    return Purchase(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      attachedFiles: attachedFiles,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'supplier': supplier,
      'notes': notes,
      'attachedFiles': attachedFiles?.map((f) => f.toMap()).toList(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Represents an item in a purchase.
class PurchaseItem {
  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice, // Prix d'achat unitaire
    required this.totalPrice, // Prix total pour cette quantité
  });

  final String productId;
  final String productName;
  final int quantity;
  final int purchasePrice;
  final int totalPrice;

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      purchasePrice: (map['purchasePrice'] as num).toInt(),
      totalPrice: (map['totalPrice'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalPrice': totalPrice,
    };
  }
}
