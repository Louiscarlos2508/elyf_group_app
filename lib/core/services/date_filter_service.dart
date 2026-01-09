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

  /// Retourne la fin de l'année.
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
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

  /// Vérifie si une date est dans la semaine courante.
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = startOfWeek(now);
    final weekEnd = endOfWeek(now);
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        date.isBefore(weekEnd.add(const Duration(seconds: 1)));
  }

  /// Vérifie si une date est dans une période donnée.
  static bool isInPeriod(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  /// Filtre une liste par date.
  static List<T> filterByDate<T>(
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

  /// Filtre une liste pour ce mois.
  static List<T> filterThisMonth<T>(
    List<T> items,
    DateTime Function(T) dateGetter,
  ) {
    final now = DateTime.now();
    final monthStart = startOfMonth(now);
    return items.where((item) {
      final date = dateGetter(item);
      return date.isAfter(monthStart.subtract(const Duration(seconds: 1)));
    }).toList();
  }

  /// Filtre une liste pour cette semaine.
  static List<T> filterThisWeek<T>(
    List<T> items,
    DateTime Function(T) dateGetter,
  ) {
    return items.where((item) => isThisWeek(dateGetter(item))).toList();
  }

  /// Retourne les N derniers jours.
  static List<DateTime> getLastNDays(int n, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    return List.generate(n, (i) {
      return startOfDay(now.subtract(Duration(days: n - 1 - i)));
    });
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
