import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/tour.dart';
import 'closure_expense_item.dart';

/// Carte de détails pour l'étape de clôture.
class ClosureDetailsCard extends ConsumerWidget {
  const ClosureDetailsCard({
    super.key,
    required this.tour,
    required this.totalBottles,
    required this.loadingFees,
    required this.unloadingFees,
    required this.otherExpenses,
    required this.totalExpenses,
    required this.enterpriseId,
  });

  final Tour tour;
  final int totalBottles;
  final double loadingFees;
  final double unloadingFees;
  final List<dynamic> otherExpenses;
  final double totalExpenses;
  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(23.98),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre "Récapitulatif"
          Text(
            'Récapitulatif',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 46),
          // Bouteilles collectées
          _DetailSection(
            title: 'Bouteilles collectées',
            value: '$totalBottles',
            theme: theme,
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          // Détail des dépenses
          _ExpensesDetailSection(
            loadingFees: loadingFees,
            unloadingFees: unloadingFees,
            otherExpenses: otherExpenses,
            totalExpenses: totalExpenses,
            theme: theme,
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          // Boutons d'action
          _ClosureActionButtons(
            tour: tour,
            enterpriseId: enterpriseId,
            onTourClosed: () {
              ref.invalidate(
                toursProvider(
                  (enterpriseId: enterpriseId, status: null),
                ),
              );
              ref.invalidate(
                toursProvider(
                  (enterpriseId: enterpriseId, status: TourStatus.closure),
                ),
              );
            },
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
            color: const Color(0xFF364153),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF0A0A0A),
          ),
        ),
      ],
    );
  }
}

class _ExpensesDetailSection extends StatelessWidget {
  const _ExpensesDetailSection({
    required this.loadingFees,
    required this.unloadingFees,
    required this.otherExpenses,
    required this.totalExpenses,
    required this.theme,
  });

  final double loadingFees;
  final double unloadingFees;
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
            color: const Color(0xFF364153),
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

class _ClosureActionButtons extends ConsumerWidget {
  const _ClosureActionButtons({
    required this.tour,
    required this.enterpriseId,
    required this.onTourClosed,
  });

  final Tour tour;
  final String enterpriseId;
  final VoidCallback onTourClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlreadyClosed = tour.status == TourStatus.closure;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          style: GazButtonStyles.outlinedWithMinSize(78.71),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Retour',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
        ),
        if (!isAlreadyClosed) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            style: GazButtonStyles.filledPrimaryIcon.copyWith(
              minimumSize: const MaterialStatePropertyAll(Size(147.286, 36)),
            ),
            onPressed: () async {
              try {
                final controller = ref.read(tourControllerProvider);
                await controller.moveToNextStep(tour.id);
                onTourClosed();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tour clôturé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text(
              'Clôturer le tour',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}

