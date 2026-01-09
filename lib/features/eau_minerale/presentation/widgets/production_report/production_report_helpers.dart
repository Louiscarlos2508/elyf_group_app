import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/utils/date_formatter.dart';

/// Helpers pour le formatage des rapports de production.
///
/// Utilise les formatters partagés pour éviter la duplication.
class ProductionReportHelpers {
  /// Formate un montant en devise.
  static String formatCurrency(int amount) {
    return CurrencyFormatter.formatFCFA(amount);
  }

  /// Formate une date.
  static String formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  /// Formate une heure.
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

