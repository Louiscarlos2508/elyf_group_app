import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/tour.dart';
import 'closure_expense_item.dart';

/// Carte de détails pour l'étape de clôture.
class ClosureDetailsCard extends ConsumerStatefulWidget {
  const ClosureDetailsCard({
    super.key,
    required this.tour,
    required this.totalBottles,
    required this.loadingFees,
    required this.unloadingFees,
    required this.exchangeFees,
    required this.otherExpenses,
    required this.totalExpenses,
    required this.enterpriseId,
  });

  final Tour tour;
  final int totalBottles;
  final double loadingFees;
  final double unloadingFees;
  final double exchangeFees;
  final List<dynamic> otherExpenses;
  final double totalExpenses;
  final String enterpriseId;

  @override
  ConsumerState<ClosureDetailsCard> createState() => _ClosureDetailsCardState();
}

class _ClosureDetailsCardState extends ConsumerState<ClosureDetailsCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.1) : theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : theme.colorScheme.primary).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'Bouteilles chargées',
            value: '${widget.totalBottles}',
            theme: theme,
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          
          // Section Réception Fournisseur
          Text(
            'Réception Fournisseur (Pleins)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.tour.fullBottlesReceived.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entry.key} kg'),
                Text(
                  '${entry.value} bouteilles',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
          if (widget.tour.totalBottlesReturned > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vides ramenés (magasin)'),
                Text(
                  '${widget.tour.totalBottlesReturned} bouteilles',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          if (widget.tour.totalGasPurchaseCost > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Coût total achat gaz'),
                Text(
                  CurrencyFormatter.formatDouble(widget.tour.totalGasPurchaseCost),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          _ExpensesDetailSection(
            loadingFees: widget.loadingFees,
            unloadingFees: widget.unloadingFees,
            exchangeFees: widget.exchangeFees,
            otherExpenses: widget.otherExpenses,
            totalExpenses: widget.totalExpenses,
            theme: theme,
          ),
          const SizedBox(height: 24),
          // Bouton de retour uniquement
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: GazButtonStyles.outlined(context),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.value,
    required this.theme,
  });

  final String title;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}



class _ExpensesDetailSection extends StatelessWidget {
// ... existing code ...
  const _ExpensesDetailSection({
    required this.loadingFees,
    required this.unloadingFees,
    required this.exchangeFees,
    required this.otherExpenses,
    required this.totalExpenses,
    required this.theme,
  });

  final double loadingFees;
  final double unloadingFees;
  final double exchangeFees;
  final List<dynamic> otherExpenses;
  final double totalExpenses;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail des dépenses',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Liste des dépenses
        Column(
          children: [
            // Frais de chargement
            if (loadingFees > 0)
              ClosureExpenseItem(
                label: 'Frais de chargement',
                amount: loadingFees,
              ),
            // Frais de déchargement
            if (unloadingFees > 0)
              ClosureExpenseItem(
                label: 'Frais de déchargement',
                amount: unloadingFees,
              ),
            // Frais d'échange
            if (exchangeFees > 0)
              ClosureExpenseItem(
                label: 'Frais d\'échange',
                amount: exchangeFees,
              ),
            // Autres dépenses (carburant, etc.)
            ...otherExpenses.map((expense) {
              return ClosureExpenseItem(
                label: expense.description,
                amount: expense.amount,
              );
            }),
            // Total dépenses (highlighted)
            ClosureExpenseItem(
              label: 'Total dépenses',
              amount: totalExpenses,
              isTotal: true,
            ),
          ],
        ),
      ],
    );
  }
}


