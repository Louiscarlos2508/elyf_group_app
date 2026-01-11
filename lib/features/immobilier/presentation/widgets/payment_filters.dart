import 'package:flutter/material.dart';

import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';

/// Widget pour les filtres de paiement.
class PaymentFilters extends StatelessWidget {
  const PaymentFilters({
    super.key,
    required this.selectedStatus,
    required this.selectedMethod,
    required this.onStatusChanged,
    required this.onMethodChanged,
    required this.onClear,
  });

  final PaymentStatus? selectedStatus;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentStatus?> onStatusChanged;
  final ValueChanged<PaymentMethod?> onMethodChanged;
  final VoidCallback onClear;

  String _getStatusLabel(PaymentStatus status) {
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

  String _getMethodLabel(PaymentMethod method) {
    // Utilise l'extension partagée
    return method.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = selectedStatus != null || selectedMethod != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PopupMenuButton<PaymentStatus?>(
                    initialValue: selectedStatus,
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem<PaymentStatus?>(
                        value: null,
                        child: Text('Tous les statuts'),
                      ),
                      ...PaymentStatus.values.map(
                        (status) => PopupMenuItem<PaymentStatus?>(
                          value: status,
                          child: Text(_getStatusLabel(status)),
                        ),
                      ),
                    ],
                    child: Chip(
                      label: Text(
                        selectedStatus != null
                            ? _getStatusLabel(selectedStatus!)
                            : 'Statut',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedStatus != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedStatus != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      avatar: selectedStatus != null
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      backgroundColor: selectedStatus != null
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<PaymentMethod?>(
                    initialValue: selectedMethod,
                    onSelected: onMethodChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem<PaymentMethod?>(
                        value: null,
                        child: Text('Toutes les méthodes'),
                      ),
                      ...PaymentMethod.values.map(
                        (method) => PopupMenuItem<PaymentMethod?>(
                          value: method,
                          child: Text(_getMethodLabel(method)),
                        ),
                      ),
                    ],
                    child: Chip(
                      label: Text(
                        selectedMethod != null
                            ? _getMethodLabel(selectedMethod!)
                            : 'Méthode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedMethod != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedMethod != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      avatar: selectedMethod != null
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      backgroundColor: selectedMethod != null
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasFilters)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }
}

