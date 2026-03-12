import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(num amount) {
    return '${NumberFormat('#,###', 'fr_FR').format(amount)} FCFA';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }
}
