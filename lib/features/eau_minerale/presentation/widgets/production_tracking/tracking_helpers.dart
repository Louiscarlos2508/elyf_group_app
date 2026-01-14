/// Helpers pour le suivi de production.
class TrackingHelpers {
  /// Formate une date au format DD/MM/YYYY.
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Formate une heure au format HH:MM.
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Formate une date et heure au format DD/MM/YYYY à HH:MM.
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} à ${formatTime(date)}';
  }
}
