import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Represents an expense for the boutique.
class Expense {
  const Expense({
    required this.id,
    required this.enterpriseId,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    this.deletedAt, // Date de suppression (soft delete)
    this.deletedBy, // ID de l'utilisateur qui a supprimé
    this.createdAt,
    this.updatedAt,
    this.receiptPath,
    this.number,
    this.hash,
    this.previousHash,
  });

  final String id;
  final String enterpriseId;
  final String label;
  final int amountCfa; // Montant en CFA
  final ExpenseCategory category;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime? deletedAt; // Date de suppression (soft delete)
  final String? deletedBy; // ID de l'utilisateur qui a supprimé
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? receiptPath;
  final String? number; // Numéro de dépense (ex: DEP-20240212-001)
  final String? hash;
  final String? previousHash;

  /// Indique si la dépense est supprimée (soft delete)
  bool get isDeleted => deletedAt != null;

  Expense copyWith({
    String? id,
    String? enterpriseId,
    String? label,
    int? amountCfa,
    ExpenseCategory? category,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? updatedAt,
    String? receiptPath,
    String? number,
    String? hash,
    String? previousHash,
  }) {
    return Expense(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      label: label ?? this.label,
      amountCfa: amountCfa ?? this.amountCfa,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptPath: receiptPath ?? this.receiptPath,
      number: number ?? this.number,
      hash: hash ?? this.hash,
      previousHash: previousHash ?? this.previousHash,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Expense(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      label: map['label'] as String? ?? map['description'] as String? ?? '',
      amountCfa:
          (map['amountCfa'] as num?)?.toInt() ??
          (map['amount'] as num?)?.toInt() ??
          0,
      category: _parseCategory(map['category'] as String?),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : (map['expenseDate'] != null
                ? DateTime.parse(map['expenseDate'] as String)
                : DateTime.now()),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['paymentMethod'] as String? ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
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
      receiptPath: map['receiptPath'] as String? ?? map['receipt'] as String?,
      number: map['number'] as String?,
      hash: map['hash'] as String?,
      previousHash: map['previousHash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'label': label,
      'description': label,
      'amountCfa': amountCfa.toDouble(),
      'amount': amountCfa.toDouble(),
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'date': date.toIso8601String(),
      'expenseDate': date.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'receiptPath': receiptPath,
      'number': number,
      'hash': hash,
      'previousHash': previousHash,
    };
  }

  static ExpenseCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return ExpenseCategory.other;
    switch (categoryStr.toLowerCase()) {
      case 'stock':
      case 'achats':
        return ExpenseCategory.stock;
      case 'rent':
      case 'loyer':
        return ExpenseCategory.rent;
      case 'utilities':
      case 'services publics':
        return ExpenseCategory.utilities;
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'marketing':
        return ExpenseCategory.marketing;
      default:
        return ExpenseCategory.other;
    }
  }
}

/// Categories of expenses for the boutique.
enum ExpenseCategory {
  stock, // Achats/Approvisionnement
  rent, // Loyer
  utilities, // Services publics (électricité, eau)
  maintenance, // Maintenance
  marketing, // Marketing/Publicité
  other, // Autres
}
