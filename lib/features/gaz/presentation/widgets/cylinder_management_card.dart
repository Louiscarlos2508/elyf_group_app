import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/cylinder_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'cylinder_form_dialog.dart';
import 'cylinder_list_item.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
/// Carte de gestion des bouteilles de gaz dans les paramètres.
class CylinderManagementCard extends ConsumerStatefulWidget {
  const CylinderManagementCard({super.key});

  @override
  ConsumerState<CylinderManagementCard> createState() =>
      _CylinderManagementCardState();
}

class _CylinderManagementCardState
    extends ConsumerState<CylinderManagementCard> {

  Future<void> _deleteCylinder(String id) async {
    try {
      final controller = ref.read(cylinderControllerProvider);
      await controller.deleteCylinder(id);
      if (!mounted) return;

      ref.invalidate(cylindersProvider);

      if (!mounted) return;
      NotificationService.showSuccess(context, 'Bouteille supprimée avec succès');
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cylindersAsync = ref.watch(cylindersProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: colors.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestion des Bouteilles',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configurez les types de bouteilles de gaz',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IntrinsicWidth(
                  child: FilledButton.icon(
                    onPressed: () => _showAddCylinderDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            cylindersAsync.when(
              data: (cylinders) {
                if (cylinders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune bouteille'),
                    ),
                  );
                }
                return Column(
                  children: cylinders.map<Widget>((cylinder) {
                    return CylinderListItem(
                      cylinder: cylinder,
                      onEdit: () => _showEditCylinderDialog(context, cylinder),
                      onDelete: () => _showDeleteConfirm(context, cylinder),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Erreur lors du chargement',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCylinderDialog(BuildContext context) {
    try {
      showDialog(
        context: context,
        builder: (dialogContext) => const CylinderFormDialog(),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du dialog: $e');
      NotificationService.showError(context, 'Erreur: $e');
    }
  }

  void _showEditCylinderDialog(BuildContext context, Cylinder cylinder) {
    try {
      showDialog(
        context: context,
        builder: (dialogContext) => CylinderFormDialog(
          cylinder: cylinder,
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du dialog: $e');
      NotificationService.showError(context, 'Erreur: $e');
    }
  }

  void _showDeleteConfirm(BuildContext context, Cylinder cylinder) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la bouteille'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${cylinder.weight} kg" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteCylinder(cylinder.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
