/// Utilitaire pour le formatage des montants en devise.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formate un montant en FCFA avec séparateurs de milliers.
  static String formatFCFA(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  /// Formate un montant (double) en FCFA avec séparateurs de milliers.
  static String formatDouble(double amount) {
    final intAmount = amount.round();
    return formatFCFA(intAmount);
  }

  /// Formate un montant (int) en FCFA avec séparateurs de milliers.
  /// Alias pour formatFCFA pour compatibilité.
  static String format(int amount) {
    return formatFCFA(amount);
  }
}
