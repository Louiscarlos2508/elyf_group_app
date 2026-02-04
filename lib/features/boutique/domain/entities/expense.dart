/// Represents an expense for the boutique.
class Expense {
  const Expense({
    required this.id,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
    this.notes,
    this.deletedAt, // Date de suppression (soft delete)
    this.deletedBy, // ID de l'utilisateur qui a supprimé
    this.updatedAt,
  });

  final String id;
  final String label;
  final int amountCfa; // Montant en CFA
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
  final DateTime? deletedAt; // Date de suppression (soft delete)
  final String? deletedBy; // ID de l'utilisateur qui a supprimé
  final DateTime? updatedAt;

  /// Indique si la dépense est supprimée (soft delete)
  bool get isDeleted => deletedAt != null;
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
