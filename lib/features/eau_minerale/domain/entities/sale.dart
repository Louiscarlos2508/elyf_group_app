/// Complete sale record.
class Sale {
  const Sale({
    required this.id,
    required this.enterpriseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.amountPaid,
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
    required this.date,
    required this.status,
    required this.createdBy,
    this.customerCnib,
    this.notes,
    this.cashAmount = 0,
    this.orangeMoneyAmount = 0,
    this.productionSessionId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String productId;
  final String productName;
  final double quantity;
  final int unitPrice;
  final int totalPrice;
  final int amountPaid;
  final String customerName;
  final String customerPhone;
  final String customerId;
  final DateTime date;
  final SaleStatus status;
  final String createdBy;
  final String? customerCnib;
  final String? notes;
  final int cashAmount;
  final int orangeMoneyAmount;
  final String? productionSessionId; // Lien vers la session de production
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  Sale copyWith({
    String? id,
    String? enterpriseId,
    String? productId,
    String? productName,
    double? quantity,
    int? unitPrice,
    int? totalPrice,
    int? amountPaid,
    String? customerName,
    String? customerPhone,
    String? customerId,
    DateTime? date,
    SaleStatus? status,
    String? createdBy,
    String? customerCnib,
    String? notes,
    int? cashAmount,
    int? orangeMoneyAmount,
    String? productionSessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Sale(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      amountPaid: amountPaid ?? this.amountPaid,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      customerCnib: customerCnib ?? this.customerCnib,
      notes: notes ?? this.notes,
      cashAmount: cashAmount ?? this.cashAmount,
      orangeMoneyAmount: orangeMoneyAmount ?? this.orangeMoneyAmount,
      productionSessionId: productionSessionId ?? this.productionSessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Sale.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    // Helper to safely parse status
    SaleStatus parseStatus(String? statusStr) {
      if (statusStr == null) return SaleStatus.validated;
      try {
        return SaleStatus.values.byName(statusStr.toLowerCase().trim());
      } catch (_) {
        // Handle variations or legacy names
        if (statusStr.toLowerCase().contains('void') || statusStr.toLowerCase().contains('annule')) {
          return SaleStatus.voided;
        }
        if (statusStr.toLowerCase().contains('paid') || statusStr.toLowerCase().contains('paye')) {
          return SaleStatus.fullyPaid;
        }
        return SaleStatus.validated;
      }
    }

    // Helper to safely parse dates from String or Timestamp
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      // Handle Firestore Timestamp if present in the map
      try {
        if (value.runtimeType.toString() == 'Timestamp') {
          return (value as dynamic).toDate();
        }
      } catch (_) {}
      return null;
    }

    return Sale(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toInt() ??
          (map['totalAmount'] as num?)?.toInt() ??
          (map['total'] as num?)?.toInt() ??
          0,
      amountPaid: (map['amountPaid'] as num?)?.toInt() ??
          (map['paidAmount'] as num?)?.toInt() ??
          (map['paid'] as num?)?.toInt() ??
          0,
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      date: parseDate(map['date']) ?? 
            parseDate(map['saleDate']) ?? 
            DateTime.now(),
      status: parseStatus(map['status'] as String?),
      createdBy: map['createdBy'] as String? ?? map['soldBy'] as String? ?? '',
      customerCnib: map['customerCnib'] as String?,
      notes: map['notes'] as String?,
      cashAmount: (map['cashAmount'] as num?)?.toInt() ?? 
                 (map['cash'] as num?)?.toInt() ?? 0,
      orangeMoneyAmount: (map['orangeMoneyAmount'] as num?)?.toInt() ?? 
                        (map['mobileMoney'] as num?)?.toInt() ?? 0,
      productionSessionId: map['productionSessionId'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      deletedAt: parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'amountPaid': amountPaid,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'status': status.name,
      'createdBy': createdBy,
      'customerCnib': customerCnib,
      'notes': notes,
      'cashAmount': cashAmount,
      'orangeMoneyAmount': orangeMoneyAmount,
      'productionSessionId': productionSessionId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  int get remainingAmount => totalPrice - amountPaid;
  bool get isCredit => remainingAmount > 0;
  bool get isFullyPaid => remainingAmount == 0;
  bool get isDeleted => deletedAt != null;

  /// Vérifie si la somme des paiements correspond au montant payé
  bool get isPaymentSplitValid =>
      (cashAmount + orangeMoneyAmount) == amountPaid;
}

enum SaleStatus { validated, fullyPaid, voided }
