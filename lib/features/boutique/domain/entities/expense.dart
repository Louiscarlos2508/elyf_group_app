/// Represents an expense for the boutique.
class Expense {
  const Expense({
    required this.id,
    required this.enterpriseId,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
    this.notes,
    this.deletedAt, // Date de suppression (soft delete)
    this.deletedBy, // ID de l'utilisateur qui a supprimé
    this.createdAt,
    this.updatedAt,
    this.receiptPath,
  });

  final String id;
  final String enterpriseId;
  final String label;
  final int amountCfa; // Montant en CFA
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
  final DateTime? deletedAt; // Date de suppression (soft delete)
  final String? deletedBy; // ID de l'utilisateur qui a supprimé
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? receiptPath;

  /// Indique si la dépense est supprimée (soft delete)
  bool get isDeleted => deletedAt != null;

  Expense copyWith({
    String? id,
    String? enterpriseId,
    String? label,
    int? amountCfa,
    ExpenseCategory? category,
    DateTime? date,
    String? notes,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? updatedAt,
    String? receiptPath,
  }) {
    return Expense(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      label: label ?? this.label,
      amountCfa: amountCfa ?? this.amountCfa,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Expense(
      id: map['id'] as String? ?? map['localId'] as String,
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
      'date': date.toIso8601String(),
      'expenseDate': date.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'receiptPath': receiptPath,
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
