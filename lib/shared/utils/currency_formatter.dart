/// Utilitaire pour le formatage des montants en devise.
/// Unifie tous les formatages de devise dans l'application.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formate un montant en FCFA avec séparateurs de milliers.
  /// Format standard : "1 234 567 FCFA"
  static String formatFCFA(int amount) {
    return _formatAmount(amount, suffix: ' FCFA');
  }

  /// Formate un montant en CFA avec séparateurs de milliers.
  /// Format alternatif : "1 234 567 CFA"
  static String formatCFA(int amount) {
    return _formatAmount(amount, suffix: ' CFA');
  }

  /// Formate un montant avec juste " F" comme suffixe.
  /// Format court : "1 234 567 F"
  static String formatShort(int amount) {
    return _formatAmount(amount, suffix: ' F');
  }

  /// Formate un montant sans suffixe de devise.
  /// Format simple : "1 234 567"
  static String formatPlain(int amount) {
    return _formatAmount(amount, suffix: '');
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

  /// Formate un montant avec séparateurs de milliers.
  /// Méthode interne unifiée pour tous les formats.
  static String _formatAmount(int amount, {required String suffix}) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + suffix;
  }
}
