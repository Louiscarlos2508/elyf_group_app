import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';

/// Helpers pour les cartes de paiement.
class PaymentCardHelpers {
  PaymentCardHelpers._();

  static String formatCurrency(int amount) {
    // Utilise CurrencyFormatter partagé
    return CurrencyFormatter.formatShort(amount);
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String getMethodLabel(PaymentMethod method) {
    // Utilise l'extension partagée
    return method.label;
  }

  static IconData getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.both:
        return Icons.payment;
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

  static Color getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
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
}
