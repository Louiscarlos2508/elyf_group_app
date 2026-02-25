import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/entities/transport_expense.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers.dart';
import '../../transport_expense_form_dialog.dart';

/// Section des autres dépenses du trajet.
class OtherExpensesSection extends ConsumerWidget {
  const OtherExpensesSection({super.key, required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Autres dépenses du trajet',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _addExpense(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Liste des dépenses
        if (tour.transportExpenses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              'Aucune dépense enregistrée',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          ...tour.transportExpenses.map((expense) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.1) : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.payments_outlined, size: 16, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatDouble(expense.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                    onPressed: () => _editExpense(context, ref, expense),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                    onPressed: () => _deleteExpense(context, ref, expense),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // Divider
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          // Total général des dépenses
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Frais de Route',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatDouble(tour.totalTransportExpenses),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL TOUTES DÉPENSES',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatDouble(tour.totalExpenses),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addExpense(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TransportExpenseFormDialog(tour: tour),
    );

    if (result == true) {
      ref.refresh(tourProvider(tour.id));
    }
  }

  Future<void> _editExpense(BuildContext context, WidgetRef ref, TransportExpense expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TransportExpenseFormDialog(
        tour: tour,
        initialExpense: expense,
      ),
    );

    if (result == true) {
      ref.refresh(tourProvider(tour.id));
    }
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, TransportExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text('Voulez-vous supprimer "${expense.description}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedExpenses = tour.transportExpenses.where((e) => e.id != expense.id).toList();
        final updatedTour = tour.copyWith(
          transportExpenses: updatedExpenses,
          updatedAt: DateTime.now(),
        );

        await ref.read(tourControllerProvider).updateTour(updatedTour);
        ref.refresh(tourProvider(tour.id));
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, 'Erreur lors de la suppression: $e');
        }
      }
    }
  }
}
