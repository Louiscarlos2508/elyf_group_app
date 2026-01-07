import '../../../../shared.dart';
import '../../domain/entities/payment.dart';

/// Helpers pour le formulaire de paiement.
class PaymentFormHelpers {
  PaymentFormHelpers._();

  static String formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  static String formatCurrency(int amount) {
    // Retourner sans " FCFA" pour compatibilité avec l'usage existant
    return CurrencyFormatter.formatFCFA(amount).replaceAll(' FCFA', '');
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
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
      case PaymentMethod.check:
        return 'Chèque';
    }
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

