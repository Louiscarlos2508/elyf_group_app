import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Utility functions for reports.
///
/// Utilise les formatters partagés pour éviter la duplication.
class ReportUtils {
  ReportUtils._();

  /// Format currency amount to string.
  static String formatCurrency(int amount) {
    return CurrencyFormatter.formatShort(amount);
  }
}
