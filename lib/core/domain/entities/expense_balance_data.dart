/// Données d'une dépense pour le bilan.
class ExpenseBalanceData {
  const ExpenseBalanceData({
    required this.id,
    required this.label,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
  });

  final String id;
  final String label;
  final int amount; // Montant en CFA
  final String category; // Catégorie (sera convertie selon le module)
  final DateTime date;
  final String? description;
}

