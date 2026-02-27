import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Représente une dépense liée à l'activité gaz.
class GazExpense {
  const GazExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.enterpriseId,
    required this.isFixed,
    this.paymentMethod, // null = pas de déduction trésorerie auto
    this.notes,
    this.receiptPath,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String enterpriseId;
  final bool isFixed; // Charge fixe vs variable
  final PaymentMethod? paymentMethod; // Mode de paiement (pour déduction auto de la trésorerie)
  final String? notes;
  final String? receiptPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  GazExpense copyWith({
    String? id,
    ExpenseCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    String? enterpriseId,
    bool? isFixed,
    Object? paymentMethod = _sentinel,
    String? notes,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return GazExpense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      isFixed: isFixed ?? this.isFixed,
      paymentMethod: paymentMethod == _sentinel ? this.paymentMethod : paymentMethod as PaymentMethod?,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  static const _sentinel = Object();

  factory GazExpense.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    // Prioritize embedded localId to maintain offline relations on new devices
    final validLocalId = map['localId'] as String?;
    final objectId = (validLocalId != null && validLocalId.trim().isNotEmpty)
        ? validLocalId
        : (map['id'] as String? ?? '');

    return GazExpense(
      id: objectId,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      isFixed: map['isFixed'] as bool? ?? false,
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.byName(map['paymentMethod'] as String)
          : null,
      notes: map['notes'] as String?,
      receiptPath: map['receiptPath'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'enterpriseId': enterpriseId,
      'isFixed': isFixed,
      'paymentMethod': paymentMethod?.name,
      'notes': notes,
      'receiptPath': receiptPath,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

enum ExpenseCategory {
  maintenance('Maintenance'),
  structureCharges('Charges de structure'),
  salaries('Salaires'),
  loadingEvents('Frais de chargement'),
  transport('Transport'),
  rent('Loyer'),
  utilities('Services publics'),
  supplies('Fournitures'),
  stockReplenishment('Achat de stock (Gaz)'),
  stockAdjustment('Ajustement de stock'),
  other('Autre');

  const ExpenseCategory(this.label);
  final String label;
}
