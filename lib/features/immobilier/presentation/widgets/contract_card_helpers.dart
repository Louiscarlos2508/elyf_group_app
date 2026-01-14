import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/utils/date_formatter.dart';
import '../../domain/entities/contract.dart';

/// Helpers pour les cartes de contrat.
///
/// Utilise les formatters partagés pour éviter la duplication.
class ContractCardHelpers {
  ContractCardHelpers._();

  static String formatCurrency(int amount) {
    return CurrencyFormatter.formatShort(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  static String getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return 'Actif';
      case ContractStatus.expired:
        return 'Expiré';
      case ContractStatus.terminated:
        return 'Résilié';
      case ContractStatus.pending:
        return 'En attente';
    }
  }

  static Color getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.expired:
        return Colors.red;
      case ContractStatus.terminated:
        return Colors.grey;
      case ContractStatus.pending:
        return Colors.orange;
    }
  }
}
