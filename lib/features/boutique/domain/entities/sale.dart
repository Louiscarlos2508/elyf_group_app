import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Represents a completed sale transaction.
class Sale {
  const Sale({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    this.customerName,
    this.paymentMethod,
    this.notes,
    this.cashAmount = 0,
    this.mobileMoneyAmount = 0,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.number,
    this.ticketHash,
    this.previousHash,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final List<SaleItem> items;
  final int totalAmount; // Total in CFA
  final int amountPaid; // Amount paid in CFA
  final String? customerName;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final int cashAmount; // Montant payé en espèces (pour paiement mixte)
  final int mobileMoneyAmount; // Montant payé en Mobile Money
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? number; // Numéro de facture (ex: FAC-20240212-001)
  final String? ticketHash;
  final String? previousHash;

  bool get isDeleted => deletedAt != null;

  int get change => amountPaid > totalAmount ? amountPaid - totalAmount : 0;

  /// Vérifie si la somme des paiements correspond au montant payé
  bool get isPaymentSplitValid =>
      (cashAmount + mobileMoneyAmount) == amountPaid;

  Sale copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    List<SaleItem>? items,
    int? totalAmount,
    int? amountPaid,
    String? customerName,
    PaymentMethod? paymentMethod,
    String? notes,
    int? cashAmount,
    int? mobileMoneyAmount,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? updatedAt,
    String? number,
    String? ticketHash,
    String? previousHash,
  }) {
    return Sale(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      cashAmount: cashAmount ?? this.cashAmount,
      mobileMoneyAmount: mobileMoneyAmount ?? this.mobileMoneyAmount,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      number: number ?? this.number,
      ticketHash: ticketHash ?? this.ticketHash,
      previousHash: previousHash ?? this.previousHash,
    );
  }

  factory Sale.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final items =
        (map['items'] as List<dynamic>?)
            ?.map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    // Gérer l'enum PaymentMethod avec support pour "both"
    PaymentMethod? paymentMethod;
    if (map['paymentMethod'] != null) {
      final methodStr = map['paymentMethod'] as String;
      switch (methodStr) {
        case 'cash':
          paymentMethod = PaymentMethod.cash;
          break;
        case 'mobileMoney':
          paymentMethod = PaymentMethod.mobileMoney;
          break;
        case 'card':
          paymentMethod = PaymentMethod.cash; // Fallback since card is removed
          break;
        case 'both':
          paymentMethod = PaymentMethod.both;
          break;
        default:
          paymentMethod = PaymentMethod.cash;
      }
    }

    return Sale(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String? ?? map['saleDate'] as String),
      items: items,
      totalAmount: (map['totalAmount'] as num).toInt(),
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      customerName: map['customerName'] as String?,
      paymentMethod: paymentMethod,
      notes: map['notes'] as String?,
      cashAmount: (map['cashAmount'] as num?)?.toInt() ?? 0,
      mobileMoneyAmount: (map['mobileMoneyAmount'] as num?)?.toInt() ?? 0,
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
      ticketHash: map['ticketHash'] as String?,
      previousHash: map['previousHash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'date': date.toIso8601String(),
      'saleDate': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount.toDouble(),
      'paidAmount': amountPaid.toDouble(),
      'amountPaid': amountPaid.toDouble(),
      'paymentMethod': paymentMethod?.name ?? 'cash',
      'customerName': customerName,
      'notes': notes,
      'cashAmount': cashAmount.toDouble(),
      'mobileMoneyAmount': mobileMoneyAmount.toDouble(),
      'isComplete': amountPaid >= totalAmount,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'number': number,
      'ticketHash': ticketHash,
      'previousHash': previousHash,
    };
  }
}

/// Represents an item in a sale.
class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.purchasePrice,
    required this.totalPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int? purchasePrice;
  final int totalPrice;

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toInt(),
      purchasePrice: (map['purchasePrice'] as num?)?.toInt(),
      totalPrice: (map['totalPrice'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'totalPrice': totalPrice,
    };
  }
}
