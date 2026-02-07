import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/repositories/customer_repository.dart';

/// Widget for selecting a customer in the sale form.
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final selected = await showDialog<CustomerSummary>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: ElyfCard(
            isGlass: true,
            padding: EdgeInsets.zero,
            borderRadius: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.people_alt_rounded, color: colors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir un client',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Sélectionnez un client existant',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    shrinkWrap: true,
                    itemCount: customers.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ElyfCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 20,
                          backgroundColor: colors.primary.withValues(alpha: 0.05),
                          borderColor: colors.primary.withValues(alpha: 0.2),
                          onTap: () => Navigator.of(context).pop<CustomerSummary?>(null),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.person_add_alt_1_rounded, color: colors.onPrimary, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Nouveau client',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final customer = customers[index - 1];
                      return ElyfCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 20,
                        backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
                        borderColor: colors.outline.withValues(alpha: 0.1),
                        onTap: () => Navigator.of(context).pop(customer),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: colors.secondaryContainer.withValues(alpha: 0.5),
                                child: Text(
                                  customer.name.characters.first.toUpperCase(),
                                  style: TextStyle(
                                    color: colors.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      customer.phone,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (customer.totalCredit > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'DETTE',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colors.onErrorContainer,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatFCFA(customer.totalCredit),
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: colors.onErrorContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null) onCustomerSelected(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () => _selectCustomer(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedCustomer != null 
                ? colors.primary.withValues(alpha: 0.3)
                : colors.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
          color: selectedCustomer != null 
              ? colors.primary.withValues(alpha: 0.02)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (selectedCustomer != null ? colors.primary : colors.surfaceContainerHighest)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_rounded,
                color: selectedCustomer != null ? colors.primary : colors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedCustomer?.name ?? 'Sélectionner ou créer un client',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selectedCustomer != null ? FontWeight.bold : FontWeight.normal,
                      color: selectedCustomer != null ? colors.onSurface : colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
