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

  /// Parse une période formatée (ex: "1-10 novembre 2024") et retourne les dates de début et fin.
  ({DateTime start, DateTime end})? parsePeriod(String periodString) {
    try {
      // Format: "1-10 novembre 2024" ou "1 novembre 2024"
      final parts = periodString.trim().split(' ');
      if (parts.length < 3) return null;

      final year = int.tryParse(parts.last);
      if (year == null) return null;

      // Trouver le mois
      const monthNames = [
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

      final monthIndex = monthNames.indexWhere((name) => parts.contains(name));
      if (monthIndex == -1) return null;
      final month = monthIndex + 1;

      // Parser les jours
      final dayPart = parts.first;
      int startDay;
      int endDay;

      if (dayPart.contains('-')) {
        final dayParts = dayPart.split('-');
        startDay = int.tryParse(dayParts[0]) ?? 1;
        endDay = dayParts[1] == 'fin'
            ? DateTime(year, month + 1, 0)
                  .day // Dernier jour du mois
            : int.tryParse(dayParts[1]) ?? startDay;
      } else {
        startDay = int.tryParse(dayPart) ?? 1;
        endDay = startDay;
      }

      final start = DateTime(year, month, startDay);
      final end = DateTime(year, month, endDay, 23, 59, 59);

      return (start: start, end: end);
    } catch (e) {
      return null;
    }
  }
}
