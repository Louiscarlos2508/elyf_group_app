/// Service de formatage pour l'affichage des données.
///
/// Centralise la logique de formatage pour éviter la duplication dans les widgets.
class FormattingService {
  FormattingService._();

  /// Formate un montant en FCFA avec séparateur de milliers.
  static String formatCurrency(int amount, {bool showSymbol = true}) {
    final formatted = amount.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    final prefix = amount < 0 ? '-' : '';
    return showSymbol ? '$prefix$formatted FCFA' : '$prefix$formatted';
  }

  /// Formate un montant double en FCFA.
  static String formatCurrencyDouble(double amount, {bool showSymbol = true}) {
    return formatCurrency(amount.round(), showSymbol: showSymbol);
  }

  /// Formate un pourcentage avec une décimale.
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Formate un nombre avec séparateur de milliers.
  static String formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  /// Formate un nombre double avec décimales.
  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  /// Formate une quantité avec unité.
  static String formatQuantity(int quantity, String unit) {
    return '$quantity $unit';
  }

  /// Formate un poids en kg.
  static String formatWeight(int weightKg) {
    return '${weightKg}kg';
  }

  /// Formate une date au format français (JJ/MM/AAAA).
  static String formatDateFr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  /// Formate une date courte (JJ/MM).
  static String formatDateShort(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  /// Formate une date et heure.
  static String formatDateTime(DateTime dateTime) {
    final date = formatDateFr(dateTime);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  /// Formate une durée en heures et minutes.
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Formate un nom de mois en français.
  static String formatMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }

  /// Formate un mois et année.
  static String formatMonthYear(DateTime date) {
    return '${formatMonthName(date.month)} ${date.year}';
  }

  /// Formate une période entre deux dates.
  static String formatPeriod(DateTime start, DateTime end) {
    return '${formatDateFr(start)} - ${formatDateFr(end)}';
  }

  /// Formate un compteur (ex: "3 sur 10").
  static String formatCounter(int current, int total) {
    return '$current sur $total';
  }

  /// Formate une taille de fichier en octets.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
