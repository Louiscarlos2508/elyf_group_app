/// Represents a charge associated with water production or distribution.
class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
    this.productionId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String label; // Motif de la dépense
  final int amountCfa; // Montant en CFA
  final ExpenseCategory category;
  final DateTime date;
  final String? productionId; // ID de la production si liée à une production
  final String? notes; // Notes supplémentaires
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si la dépense est liée à une production
  bool get estLieeAProduction =>
      productionId != null && productionId!.isNotEmpty;

  ExpenseRecord copyWith({
    String? id,
    String? label,
    int? amountCfa,
    ExpenseCategory? category,
    DateTime? date,
    String? productionId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      label: label ?? this.label,
      amountCfa: amountCfa ?? this.amountCfa,
      category: category ?? this.category,
      date: date ?? this.date,
      productionId: productionId ?? this.productionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExpenseRecord.sample(int index) {
    return ExpenseRecord(
      id: 'expense-$index',
      label: index.isEven ? 'Carburant livraison' : 'Réparation pompe',
      amountCfa: 15000 + (index * 7000),
      category: ExpenseCategory.values[index % ExpenseCategory.values.length],
      date: DateTime.now().subtract(Duration(days: index)),
    );
  }
}

enum ExpenseCategory {
  /// Carburant (essence, diesel, etc.)
  carburant,

  /// Réparations et maintenance
  reparations,

  /// Achats divers
  achatsDivers,

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
      case ExpenseCategory.autres:
        return 'Autres';
    }
  }
}
