import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../../../core/domain/entities/attached_file.dart';

/// Represents a purchase (achat) of products for the boutique.
class Purchase {
  const Purchase({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.supplierId,
    this.paidAmount,
    this.debtAmount,
    this.notes,
    this.attachedFiles,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.number,
    this.hash,
    this.previousHash,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final List<PurchaseItem> items;
  final int totalAmount; // Montant total en CFA
  final PaymentMethod paymentMethod;
  final String? supplierId; // ID du Fournisseur
  final int? paidAmount; // Montant payé
  final int? debtAmount; // Montant restant à payer (dette)
  final String? notes; // Notes additionnelles
  final List<AttachedFile>?
  attachedFiles; // Fichiers joints (factures, photos, etc.)
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? number; // Numéro d'achat (ex: ACH-20240212-001)
  final String? hash;
  final String? previousHash;

  bool get isDeleted => deletedAt != null;

  Purchase copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    List<PurchaseItem>? items,
    int? totalAmount,
    PaymentMethod? paymentMethod,
    String? supplierId,
    int? paidAmount,
    int? debtAmount,
    String? notes,
    List<AttachedFile>? attachedFiles,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? updatedAt,
    String? number,
    String? hash,
    String? previousHash,
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
      debtAmount: debtAmount ?? this.debtAmount,
      notes: notes ?? this.notes,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      number: number ?? this.number,
      hash: hash ?? this.hash,
      previousHash: previousHash ?? this.previousHash,
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
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['paymentMethod'] as String? ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      supplierId: map['supplierId'] as String? ?? map['supplier'] as String?,
      paidAmount: (map['paidAmount'] as num?)?.toInt(),
      debtAmount: (map['debtAmount'] as num?)?.toInt(),
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
      number: map['number'] as String?,
      hash: map['hash'] as String?,
      previousHash: map['previousHash'] as String?,
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
      'debtAmount': debtAmount,
      'notes': notes,
      'attachedFiles': attachedFiles?.map((f) => f.toMap()).toList(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'number': number,
      'hash': hash,
      'previousHash': previousHash,
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
