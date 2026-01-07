import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_usage.dart';
import 'bobine_usage_item_form.dart';
import 'machine_selector_field.dart' show machinesProvider;
import '../../../shared.dart';

/// Champ pour gérer les bobines utilisées dans une session.
class BobineUsageFormField extends ConsumerWidget {
  const BobineUsageFormField({
    super.key,
    required this.bobinesUtilisees,
    required this.machinesDisponibles,
    required this.onBobinesChanged,
  });

  /// Limite maximum de bobines autorisées
  static const maxBobines = 20;

  final List<BobineUsage> bobinesUtilisees;
  final List<String> machinesDisponibles;
  final ValueChanged<List<BobineUsage>> onBobinesChanged;

  Future<void> _ajouterBobine(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (bobinesUtilisees.length >= maxBobines) {
      if (!context.mounted) return;
      NotificationService.showError(context, 'Maximum $maxBobines bobines autorisées');
      return;
    }

    final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
    final machines = await ref.read(machinesProvider.future);
    
    // Filtrer les machines qui ont déjà une bobine
    final machinesAvecBobine = bobinesUtilisees.map((u) => u.machineId).toSet();
    final machinesDisponiblesFiltrees = machines
        .where((m) => machinesDisponibles.contains(m.id))
        .where((m) => !machinesAvecBobine.contains(m.id))
        .toList();
    
    if (machinesDisponiblesFiltrees.isEmpty) {
      if (!context.mounted) return;
      NotificationService.showInfo(context, 'Toutes les machines ont déjà une bobine');
      return;
    }

    if (bobineStocks.isEmpty) {
      if (!context.mounted) return;
      NotificationService.showInfo(context, 'Aucune bobine disponible en stock');
      return;
    }

    if (!context.mounted) return;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final maxDialogWidth = (screenWidth * 0.9).clamp(400.0, 600.0);

    final result = await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BobineUsageItemForm(
              bobineStocksDisponibles: bobineStocks,
              machinesDisponibles: machinesDisponiblesFiltrees,
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      final nouvellesBobines = List<BobineUsage>.from(bobinesUtilisees);
      nouvellesBobines.add(result);
      onBobinesChanged(nouvellesBobines);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canAddMore = bobinesUtilisees.length < maxBobines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bobines utilisées',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (bobinesUtilisees.isNotEmpty)
                    Text(
                      '${bobinesUtilisees.length} bobine(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: canAddMore ? () => _ajouterBobine(context, ref) : null,
              tooltip: canAddMore
                  ? 'Ajouter bobine'
                  : 'Maximum $maxBobines bobines autorisées',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (bobinesUtilisees.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Aucune bobine ajoutée',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: bobinesUtilisees.length,
              itemBuilder: (context, index) {
                final bobine = bobinesUtilisees[index];
                return Card(
                  margin: EdgeInsets.only(
                    bottom: index < bobinesUtilisees.length - 1 ? 8 : 0,
                  ),
                  child: ListTile(
                    title: Text(bobine.bobineType),
                    subtitle: Text(
                      'Machine: ${bobine.machineName}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        final nouvellesBobines =
                            List<BobineUsage>.from(bobinesUtilisees);
                        nouvellesBobines.removeAt(index);
                        onBobinesChanged(nouvellesBobines);
                      },
                      tooltip: 'Supprimer',
                    ),
                  ),
                );
              },
            ),
          ),
        if (!canAddMore && bobinesUtilisees.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maximum $maxBobines bobines autorisées',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Provider pour récupérer les stocks de bobines disponibles (nouveau système par type/quantité).
final bobineStocksDisponiblesProvider = FutureProvider.autoDispose<List<BobineStock>>(
  (ref) async {
    final stocks = await ref.read(bobineStockQuantityRepositoryProvider).fetchAll();
    // Filtrer seulement les stocks avec quantité > 0
    return stocks.where((stock) => stock.quantity > 0).toList();
  },
);

