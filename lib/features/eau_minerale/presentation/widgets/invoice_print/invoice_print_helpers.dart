import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/utils/date_formatter.dart';

/// Helpers pour le formatage des factures eau minérale.
///
/// Utilise les formatters partagés pour éviter la duplication.
class InvoicePrintHelpers {
  InvoicePrintHelpers._();

  /// Formate un montant en FCFA avec séparateurs de milliers.
  static String formatCurrency(int amount) {
    return CurrencyFormatter.formatFCFA(amount);
  }

  /// Formate une date au format DD/MM/YYYY.
  static String formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
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
