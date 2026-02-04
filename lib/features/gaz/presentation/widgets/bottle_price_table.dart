import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/notification_service.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/app_shimmers.dart';
import 'cylinder_form_dialog.dart';

/// Tableau des tarifs des bouteilles selon le design Figma.
class BottlePriceTable extends ConsumerWidget {
  const BottlePriceTable({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  Future<void> _deleteCylinder(
    BuildContext context,
    WidgetRef ref,
    Cylinder cylinder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le type de bouteille'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la bouteille de ${cylinder.weight}kg ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final controller = ref.read(cylinderControllerProvider);
      await controller.deleteCylinder(cylinder.id);

      if (!context.mounted) return;

      ref.invalidate(cylindersProvider);

      NotificationService.showSuccess(
        context,
        'Type de bouteille supprimé avec succès',
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(
        context,
        'Erreur lors de la suppression: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);

    return cylindersAsync.when(
      data: (cylinders) {
        if (cylinders.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun type de bouteille configuré',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez un type de bouteille pour commencer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cylinders.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final cylinder = cylinders[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.propane_tank,
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                '${cylinder.weight} kg',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Vente: ${CurrencyFormatter.formatDouble(cylinder.sellPrice)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: '  •  '),
                    TextSpan(
                      text: 'Achat: ${CurrencyFormatter.formatDouble(cylinder.buyPrice)} FCFA',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (context) => CylinderFormDialog(cylinder: cylinder),
                    );
                  } else if (value == 'delete') {
                    _deleteCylinder(context, ref, cylinder);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => AppShimmers.table(context, rows: 3),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}
