import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Represents a payment made to a supplier to settle a debt.
class SupplierSettlement {
  const SupplierSettlement({
    required this.id,
    required this.enterpriseId,
    required this.supplierId,
    required this.amount,
    required this.date,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String supplierId;
  final int amount;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  SupplierSettlement copyWith({
    String? id,
    String? enterpriseId,
    String? supplierId,
    int? amount,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return SupplierSettlement(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      supplierId: supplierId ?? this.supplierId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory SupplierSettlement.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return SupplierSettlement(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      supplierId: map['supplierId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(map['date'] as String),
      paymentMethod: map['paymentMethod'] != null 
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['paymentMethod'] || e.toString() == map['paymentMethod'], 
              orElse: () => PaymentMethod.cash)
          : PaymentMethod.cash,
      notes: map['notes'] as String?,
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
      'supplierId': supplierId,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}
