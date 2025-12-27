/// Utility class for formatting currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats an amount in CFA francs.
  /// 
  /// Example: 150000 -> "150 000 FCFA"
  static String format(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

  /// Formats a double amount in CFA francs.
  /// 
  /// Example: 150000.0 -> "150 000 FCFA"
  /// Example: 0.0 -> "0 FCFA"
  static String formatDouble(double amount) {
    if (amount == 0) return '0 FCFA';
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) +
        ' FCFA';
  }
}

