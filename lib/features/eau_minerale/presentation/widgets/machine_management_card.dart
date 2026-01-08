import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine.dart';
import 'package:elyf_groupe_app/core.dart';
import 'centralized_permission_guard.dart';
import 'machine_form_dialog.dart';
import 'machine_list_item.dart';
import 'machine_selector_field.dart';

/// Carte de gestion des machines.
class MachineManagementCard extends ConsumerStatefulWidget {
  const MachineManagementCard({super.key});

  @override
  ConsumerState<MachineManagementCard> createState() =>
      _MachineManagementCardState();
}

class _MachineManagementCardState
    extends ConsumerState<MachineManagementCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final machinesAsync = ref.watch(allMachinesProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                      Text(
                        'Gestion des Machines',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configurez les machines de production',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                EauMineralePermissionGuard(
                  permission: EauMineralePermissions.manageProducts,
                  child: IntrinsicWidth(
                    child: FilledButton.icon(
                      onPressed: () => _showAddMachineDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            machinesAsync.when(
              data: (machines) {
                if (machines.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune machine'),
                    ),
                  );
                }
                return Column(
                  children: machines.map<Widget>((machine) {
                    return MachineListItem(
                      machine: machine,
                      onEdit: () => _showEditMachineDialog(context, machine),
                      onDelete: () => _showDeleteConfirm(context, machine),
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
                  child: Text('Erreur: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMachineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MachineFormDialog(),
    );
  }

  void _showEditMachineDialog(BuildContext context, Machine machine) {
    showDialog(
      context: context,
      builder: (context) => MachineFormDialog(machine: machine),
    );
  }

  void _showDeleteConfirm(BuildContext context, Machine machine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la machine'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${machine.nom}" ?\n\n'
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
              try {
                await ref
                    .read(machineControllerProvider)
                    .deleteMachine(machine.id);
                ref.invalidate(allMachinesProvider);
                ref.invalidate(machinesProvider);
                if (context.mounted) {
                  NotificationService.showInfo(context, 'Machine supprimée');
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showError(context, e.toString());
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
