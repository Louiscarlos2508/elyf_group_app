/// Helpers pour l'historique des transactions.
class TransactionsHistoryHelpers {
  TransactionsHistoryHelpers._();

  /// Formate un montant avec signe.
  static String formatAmount(int amount, bool isCashIn) {
    // Format: +5,500 F ou -5,500 F
    final sign = isCashIn ? '+' : '-';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$sign$formatted F';
  }

  /// Construit la clé du provider basée sur les filtres.
  static String buildProviderKey({
    required String searchQuery,
    String? typeStr,
    String? startDateStr,
    String? endDateStr,
  }) {
    return '$searchQuery|${typeStr ?? ''}|${startDateStr ?? ''}|${endDateStr ?? ''}';
  }
}

