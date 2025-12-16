/// Utility class for formatting dates.
class DateFormatter {
  DateFormatter._();

  /// Gets the French month name for a given month number (1-12).
  static String getMonthName(int month) {
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
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12, got $month');
    }
    return months[month - 1];
  }

  /// Formats a date as "DD/MM/YYYY".
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formats a period as "MonthName Year" (e.g., "janvier 2024").
  static String formatPeriod(DateTime date) {
    return '${getMonthName(date.month)} ${date.year}';
  }
}

