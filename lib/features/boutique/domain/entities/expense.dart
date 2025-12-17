/// Represents an expense for the boutique.
class Expense {
  const Expense({
    required this.id,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
    this.notes,
  });

  final String id;
  final String label;
  final int amountCfa; // Montant en CFA
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
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

