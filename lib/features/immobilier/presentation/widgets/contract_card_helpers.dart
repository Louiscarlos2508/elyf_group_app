import 'package:flutter/material.dart';

import '../../domain/entities/contract.dart';

/// Helpers pour les cartes de contrat.
class ContractCardHelpers {
  ContractCardHelpers._();

  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

