/// Helpers pour le formatage des données des agents.
class AgentsFormatHelpers {
  /// Formate un montant en devise avec espaces.
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  /// Formate un montant en devise compact.
  static String formatCurrencyCompact(int amount) {
    return '$amount F';
  }
}

