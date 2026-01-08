import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/domain/entities/payment_method.dart';
import '../../../../../shared/utils/date_formatter.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/payment.dart';

/// Helpers pour le formulaire de paiement.
class PaymentFormHelpers {
  PaymentFormHelpers._();

  static String formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  static String formatCurrency(int amount) {
    // Utilise CurrencyFormatter partagé sans suffixe
    return CurrencyFormatter.formatPlain(amount);
  }

  static String getMonthName(int month) {
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

  static String getMethodLabel(PaymentMethod method) {
    // Utilise l'extension partagée
    return method.label;
  }

  static String getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.overdue:
        return 'En retard';
      case PaymentStatus.cancelled:
        return 'Annulé';
    }
  }
}

