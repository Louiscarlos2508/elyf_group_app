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
        return const Color(0xFF10B981); // Emerald
      case ContractStatus.expired:
        return const Color(0xFFEF4444); // Red
      case ContractStatus.terminated:
        return const Color(0xFF94A3B8); // Slate/Grey
      case ContractStatus.pending:
        return const Color(0xFFF59E0B); // Amber
    }
  }
}
