/// Utility functions for reports.
class ReportUtils {
  ReportUtils._();

  /// Format currency amount to string.
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }
}

