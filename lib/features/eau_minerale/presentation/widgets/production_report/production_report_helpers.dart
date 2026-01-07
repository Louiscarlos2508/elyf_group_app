import '../production_period_formatter.dart';

/// Helpers pour le formatage des rapports de production.
class ProductionReportHelpers {
  /// Formate un montant en devise.
  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  /// Formate une date.
  static String formatDate(DateTime date) {
    return ProductionPeriodFormatter.formatDate(date);
  }

  /// Formate une heure.
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

