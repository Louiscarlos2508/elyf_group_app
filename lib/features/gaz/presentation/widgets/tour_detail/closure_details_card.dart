import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/tour.dart';
import 'closure_expense_item.dart';
import '../../../../../../core/auth/providers.dart';
import '../../../../../../core/logging/app_logger.dart';

/// Carte de détails pour l'étape de clôture.
class ClosureDetailsCard extends ConsumerStatefulWidget {
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
  ConsumerState<ClosureDetailsCard> createState() => _ClosureDetailsCardState();
}

class _ClosureDetailsCardState extends ConsumerState<ClosureDetailsCard> {
  late Map<int, TextEditingController> _receptionControllers;
  late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
      text: widget.tour.gasPurchaseCost?.toString() ?? '',
    );
    _receptionControllers = {};
  }

  @override
  void dispose() {
    for (final controller in _receptionControllers.values) {
      controller.dispose();
    }
    _costController.dispose();
    super.initState();
  }

  Map<int, int> _getReceptionData() {
    final data = <int, int>{};
    for (final entry in _receptionControllers.entries) {
      final qty = int.tryParse(entry.value.text) ?? 0;
      if (qty > 0) {
        data[entry.key] = qty;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            title: 'Bouteilles collectées',
            value: '${widget.totalBottles}',
            theme: theme,
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          
          // Section Réception Fournisseur (Nouvelle section pour Story 1.2)
          cylindersAsync.when(
            data: (cylinders) {
              final weights = cylinders.map((c) => c.weight).toSet().toList()..sort();
              // Initialiser les controllers si nécessaire
              for (final weight in weights) {
                if (!_receptionControllers.containsKey(weight)) {
                  _receptionControllers[weight] = TextEditingController(
                    text: widget.tour.fullBottlesReceived[weight]?.toString() ?? '',
                  );
                }
              }
              
              return _ReplenishmentSection(
                weights: weights,
                controllers: _receptionControllers,
                costController: _costController,
                theme: theme,
                isReadOnly: widget.tour.status == TourStatus.closure,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur chargement cylindres: $e'),
          ),
          
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          _ExpensesDetailSection(
            loadingFees: widget.loadingFees,
            unloadingFees: widget.unloadingFees,
            otherExpenses: widget.otherExpenses,
            totalExpenses: widget.totalExpenses + (double.tryParse(_costController.text) ?? 0),
            theme: theme,
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          _ClosureActionButtons(
            tour: widget.tour,
            enterpriseId: widget.enterpriseId,
            getReceptionData: _getReceptionData,
            getGasPurchaseCost: () => double.tryParse(_costController.text) ?? 0,
            onTourClosed: () {
              ref.invalidate(toursProvider((enterpriseId: widget.enterpriseId, status: null)));
              ref.invalidate(toursProvider((
                enterpriseId: widget.enterpriseId,
                status: TourStatus.closure,
              )));
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

class _ReplenishmentSection extends StatelessWidget {
  const _ReplenishmentSection({
    required this.weights,
    required this.controllers,
    required this.costController,
    required this.theme,
    required this.isReadOnly,
  });

  final List<int> weights;
  final Map<int, TextEditingController> controllers;
  final TextEditingController costController;
  final ThemeData theme;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réception Fournisseur (Pleins)',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...weights.map((weight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('$weight kg')),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: controllers[weight],
                    readOnly: isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Qté reçue',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        TextField(
          controller: costController,
          readOnly: isReadOnly,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Coût total d\'achat gaz (facultatif)',
            prefixIcon: Icon(Icons.money, size: 20),
            border: OutlineInputBorder(),
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
    required this.getReceptionData,
    required this.getGasPurchaseCost,
  });

  final Tour tour;
  final String enterpriseId;
  final VoidCallback onTourClosed;
  final Map<int, int> Function() getReceptionData;
  final double Function() getGasPurchaseCost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlreadyClosed = tour.status == TourStatus.closure;
    final authController = ref.watch(authControllerProvider);
    final userId = authController.currentUser?.id ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: OutlinedButton(
            style: GazButtonStyles.outlinedWithMinSize(context, 78.71),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Retour',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        if (!isAlreadyClosed) ...[
          const SizedBox(width: 8),
          Flexible(
            child: FilledButton.icon(
              style: GazButtonStyles.filledPrimaryIcon(context).copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(147.286, 36)),
              ),
              onPressed: () async {
                try {
                  final controller = ref.read(tourControllerProvider);
                  
                  // 1. Mettre à jour le tour avec les données de réception
                  final updatedTour = tour.copyWith(
                    fullBottlesReceived: getReceptionData(),
                    gasPurchaseCost: getGasPurchaseCost(),
                  );
                  await controller.updateTour(updatedTour);
                  
                  // 2. Clôturer le tour (atomique: stocks + audit + alerts)
                  final alerts = await controller.closeTour(tour.id, userId);
                  
                  // 3. Afficher les alertes de stock (Story 1.4)
                  if (alerts.isNotEmpty) {
                    final alertService = ref.read(gasAlertServiceProvider);
                    if (context.mounted) {
                      for (final alert in alerts) {
                        alertService.notifyIfLowStock(context, alert);
                      }
                    }
                  }
                  
                  onTourClosed();
                  if (context.mounted) {
                    NotificationService.showSuccess(
                      context,
                      'Tour clôturé avec succès et stocks mis à jour',
                    );
                  }
                } catch (e) {
                  AppLogger.error('Erreur lors de la clôture: $e', error: e);
                  if (context.mounted) {
                    NotificationService.showError(context, 'Erreur: $e');
                  }
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text(
                'Confirmer la clôture',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
