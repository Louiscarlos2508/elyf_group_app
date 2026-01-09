/// Service pour le filtrage des données par date.
///
/// Centralise la logique de filtrage par période pour tous les modules.
class DateFilterService {
  DateFilterService._();

  /// Retourne le début de la journée.
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Retourne la fin de la journée.
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Retourne le début du mois.
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Retourne la fin du mois.
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  /// Retourne le début de la semaine (lundi).
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return startOfDay(monday);
  }

  /// Retourne la fin de la semaine (dimanche).
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    final sunday = date.add(Duration(days: daysUntilSunday));
    return endOfDay(sunday);
  }

  /// Retourne le début de l'année.
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Vérifie si une date est aujourd'hui.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Vérifie si une date est dans le mois courant.
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Vérifie si une date est dans une période donnée (inclusif).
  static bool isInPeriod(DateTime date, DateTime start, DateTime end) {
    final normalizedDate = startOfDay(date);
    final normalizedStart = startOfDay(start);
    final normalizedEnd = endOfDay(end);
    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }

  /// Filtre une liste par plage de dates.
  static List<T> filterByDateRange<T>(
    List<T> items,
    DateTime Function(T) dateGetter, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) {
      return items;
    }

    final start = startDate ?? DateTime(2020);
    final end = endDate ?? DateTime.now();

    return items.where((item) {
      final itemDate = dateGetter(item);
      return isInPeriod(itemDate, start, end);
    }).toList();
  }

  /// Filtre une liste pour aujourd'hui.
  static List<T> filterToday<T>(
    List<T> items,
    DateTime Function(T) dateGetter,
  ) {
    return items.where((item) => isToday(dateGetter(item))).toList();
  }

  /// Filtre une liste pour le mois courant.
  static List<T> filterThisMonth<T>(
    List<T> items,
    DateTime Function(T) dateGetter,
  ) {
    final now = DateTime.now();
    final monthStart = startOfMonth(now);
    return items.where((item) {
      final date = dateGetter(item);
      return !date.isBefore(monthStart);
    }).toList();
  }

  /// Calcule le nombre de jours restants.
  static int daysRemaining(DateTime targetDate) {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  /// Calcule le nombre de jours écoulés.
  static int daysElapsed(DateTime startDate) {
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }
}
