import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Represents a charge associated with water production or distribution.
class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.enterpriseId,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
    this.productionId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.receiptPath,
    this.paymentMethod = PaymentMethod.cash,
  });

  final String id;
  final String enterpriseId;
  final String label; // Motif de la dépense
  final int amountCfa; // Montant en CFA
  final ExpenseCategory category;
  final DateTime date;
  final String? productionId; // ID de la production si liée à une production
  final String? notes; // Notes supplémentaires
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;
  final String? receiptPath;
  final PaymentMethod paymentMethod;

  bool get isDeleted => deletedAt != null;
  bool get estLieeAProduction => productionId != null;

  ExpenseRecord copyWith({
    String? id,
    String? enterpriseId,
    String? label,
    int? amountCfa,
    ExpenseCategory? category,
    DateTime? date,
    String? productionId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
    String? receiptPath,
    PaymentMethod? paymentMethod,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      label: label ?? this.label,
      amountCfa: amountCfa ?? this.amountCfa,
      category: category ?? this.category,
      date: date ?? this.date,
      productionId: productionId ?? this.productionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      receiptPath: receiptPath ?? this.receiptPath,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory ExpenseRecord.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return ExpenseRecord(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      label: map['label'] as String? ?? '',
      amountCfa: (map['amountCfa'] as num?)?.toInt() ?? 0,
      category: ExpenseCategory.values.byName(map['category'] as String? ?? 'autres'),
      date: DateTime.parse(map['date'] as String),
      productionId: map['productionId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
      receiptPath: map['receiptPath'] as String?,
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.byName(map['paymentMethod'] as String)
          : PaymentMethod.cash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'label': label,
      'amountCfa': amountCfa,
      'category': category.name,
      'date': date.toIso8601String(),
      'productionId': productionId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'receiptPath': receiptPath,
      'paymentMethod': paymentMethod.name,
    };
  }
}

enum ExpenseCategory {
  /// Carburant (essence, diesel, etc.)
  carburant,

  /// Réparations et maintenance
  reparations,

  /// Achats divers
  achatsDivers,

  /// Salaires et payes
  salaires,

  /// Achat de matières premières
  achatMatieresPremieres,

  /// Autres dépenses
  autres,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.carburant:
        return 'Carburant';
      case ExpenseCategory.reparations:
        return 'Réparations';
      case ExpenseCategory.achatsDivers:
        return 'Achats divers';
      case ExpenseCategory.salaires:
        return 'Salaires';
      case ExpenseCategory.achatMatieresPremieres:
        return 'Achat Matières Premières';
      case ExpenseCategory.autres:
        return 'Autres';
    }
  }
}
