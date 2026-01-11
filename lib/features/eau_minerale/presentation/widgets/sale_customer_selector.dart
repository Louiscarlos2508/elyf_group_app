import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/repositories/customer_repository.dart';

/// Widget for selecting a customer in the sale form.
class SaleCustomerSelector extends ConsumerWidget {
  const SaleCustomerSelector({
    super.key,
    required this.selectedCustomer,
    required this.onCustomerSelected,
  });

  final CustomerSummary? selectedCustomer;
  final ValueChanged<CustomerSummary?> onCustomerSelected;

  Future<void> _selectCustomer(BuildContext context, WidgetRef ref) async {
    final customers = await ref.read(customerRepositoryProvider).fetchCustomers();

    if (customers.isEmpty) {
      if (!context.mounted) return;
      NotificationService.showInfo(context, 'Aucun client disponible');
      return;
    }

    if (!context.mounted) return;
    final selected = await showDialog<CustomerSummary>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sélectionner le client'),
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nouveau client'),
            onTap: () => Navigator.of(context).pop<CustomerSummary?>(null),
          ),
          const Divider(),
          ...customers.map((customer) {
            return ListTile(
              title: Text(customer.name),
              subtitle: Text(customer.phone),
              trailing: customer.totalCredit > 0
                  ? Chip(
                      label: Text('${customer.totalCredit} CFA'),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(customer),
            );
          }),
        ],
      ),
    );

    if (selected != null) {
      onCustomerSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _selectCustomer(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedCustomer?.name ?? 'Sélectionner ou créer un client',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selectedCustomer != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: selectedCustomer != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

