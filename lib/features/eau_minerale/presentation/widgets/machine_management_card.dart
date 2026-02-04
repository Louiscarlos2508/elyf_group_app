import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine.dart';
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

class _MachineManagementCardState extends ConsumerState<MachineManagementCard> {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings_input_component_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des Machines',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configurez le parc de production',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                EauMineralePermissionGuard(
                  permission: EauMineralePermissions.manageProducts,
                  child: FilledButton.icon(
                    onPressed: () => _showAddMachineDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nouveau'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            machinesAsync.when(
              data: (machines) {
                if (machines.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune machine configurée',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: machines.length,
                  itemBuilder: (context, index) {
                    final machine = machines[index];
                    return MachineListItem(
                      machine: machine,
                      onEdit: () => _showEditMachineDialog(context, machine),
                      onDelete: () => _showDeleteConfirm(context, machine),
                    );
                  },
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
