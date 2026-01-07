/// Helpers pour le formatage des factures eau minérale.
class InvoicePrintHelpers {
  InvoicePrintHelpers._();

  /// Formate un montant en FCFA avec séparateurs de milliers.
  static String formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  /// Formate une date au format DD/MM/YYYY.
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formate une heure au format HH:MM.
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Centre un texte dans une largeur donnée.
  static String centerText(String text, [int width = 32]) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Tronque un ID à 8 caractères maximum.
  static String truncateId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }
}

