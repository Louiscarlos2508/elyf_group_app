import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';

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
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          
          // Section Distribution aux Grossistes
          _WholesaleDistributionSection(
            tour: widget.tour,
            enterpriseId: widget.enterpriseId,
            theme: theme,
          ),
          
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
              if (widget.tour.status == TourStatus.open && widget.tour.receptionCompletedDate != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _handleCloseTour(context, ref),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Encaisser et Clôturer'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCloseTour(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la clôture'),
        content: const Text(
          'Cette action va enregistrer les ventes grossistes, '
          'encaisser les montants dus en trésorerie et clôturer le tour définitivement.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final controller = ref.read(tourControllerProvider);
        final userId = ref.read(currentUserIdProvider);
        
        // Calculer les distributions à passer au service
        final params = (enterpriseId: widget.enterpriseId, moduleId: 'gaz');
        final settingsAsync = ref.read(gazSettingsProvider(params));
        final cylindersAsync = ref.read(cylindersProvider);
        
        final settings = settingsAsync.value;
        final cylinders = cylindersAsync.value ?? [];
        
        final distributions = <WholesaleDistribution>[];
        final weightToCylinderId = <int, String>{};
        
        for (final cyl in cylinders) {
          weightToCylinderId[cyl.weight] = cyl.id;
        }
        
        if (settings != null) {
          final wholesalerSources = widget.tour.loadingSources
              .where((s) => s.type == TourLoadingSourceType.wholesaler)
              .toList();
              
          for (final source in wholesalerSources) {
            double totalAmount = 0;
            for (final entry in source.quantities.entries) {
              final price = settings.getWholesalePrice(entry.key) ?? 0;
              totalAmount += price * entry.value;
            }
            
            distributions.add(WholesaleDistribution(
              wholesalerId: source.id,
              wholesalerName: source.sourceName,
              quantities: source.quantities,
              totalAmount: totalAmount,
              paymentMethod: PaymentMethod.cash,
            ));
          }
        }

        await controller.closeTour(
          widget.tour.id, 
          userId,
          distributions: distributions,
          weightToCylinderId: weightToCylinderId,
        );
        if (mounted) {
          NotificationService.showSuccess(context, 'Tour clôturé avec succès');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) NotificationService.showError(context, 'Erreur lors de la clôture: $e');
      }
    }
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

class _WholesaleDistributionSection extends ConsumerWidget {
  const _WholesaleDistributionSection({
    required this.tour,
    required this.enterpriseId,
    required this.theme,
  });

  final Tour tour;
  final String enterpriseId;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (enterpriseId: enterpriseId, moduleId: 'gaz');
    final settingsAsync = ref.watch(gazSettingsProvider(params));
    final wholesalerSources = tour.loadingSources
        .where((s) => s.type == TourLoadingSourceType.wholesaler)
        .toList();

    if (wholesalerSources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribution aux Grossistes',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...wholesalerSources.map((source) {
          return settingsAsync.when(
            data: (settings) {
              double totalAmount = 0;
              if (settings != null) {
                for (final entry in source.quantities.entries) {
                  final price = settings.getWholesalePrice(entry.key) ?? 0;
                  totalAmount += price * entry.value;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          source.sourceName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.formatDouble(totalAmount),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: source.quantities.entries.map((e) {
                        return Chip(
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          label: Text('${e.key}kg x${e.value}'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: theme.colorScheme.surface,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, s) => Text('Erreur: $e'),
          );
        }),
      ],
    );
  }
}
