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
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.credit:
        return Icons.timer_outlined;
    }
  }

  static String getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.partial:
        return 'Partiel';
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
        return const Color(0xFF10B981); // Emerald
      case PaymentStatus.partial:
        return Colors.blue;
      case PaymentStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case PaymentStatus.overdue:
        return const Color(0xFFEF4444); // Red
      case PaymentStatus.cancelled:
        return const Color(0xFF94A3B8); // Slate/Grey
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
