import '../../domain/entities/production_period_config.dart';

/// Helper class for formatting production periods.
class ProductionPeriodFormatter {
  ProductionPeriodFormatter(this.config);

  final ProductionPeriodConfig config;

  String formatPeriod(int period, DateTime date) {
    final month = date.month;
    final year = date.year;
    final daysPerPeriod = config.daysPerPeriod;

    int periodStartDay;
    String periodEndLabel;

    if (period == 1) {
      periodStartDay = 1;
      periodEndLabel = daysPerPeriod.toString();
    } else if (period == 2) {
      periodStartDay = daysPerPeriod + 1;
      periodEndLabel = (daysPerPeriod * 2).toString();
    } else {
      periodStartDay = daysPerPeriod * 2 + 1;
      periodEndLabel = 'fin';
    }

    final monthName = _getMonthName(month);

    if (periodStartDay.toString() == periodEndLabel) {
      return '$periodStartDay $monthName $year';
    }
    return '$periodStartDay-$periodEndLabel $monthName $year';
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return months[month - 1];
  }
}

