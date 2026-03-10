import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers.dart';
import 'tracking_dialogs.dart';
import 'machine_installation_form_dialog.dart';

import '../../../domain/entities/machine_material_usage.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/machine.dart';

/// Liste des états des matières machine par machine.
/// (Anciennement BobinesStatusList).
class MachineMaterialsStatusList extends ConsumerWidget {
  const MachineMaterialsStatusList({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final machinesIds = session.machinesUtilisees;

    if (machinesIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Statut des Matières',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...machinesIds.map((machineId) {
          final materialUsage = session.machineMaterials.where(
            (m) => m.machineId == machineId && !m.estFinie,
          ).firstOrNull;

          final machinesAsync = ref.watch(allMachinesProvider);

          return machinesAsync.when(
            data: (list) {
              final machine = list.where((m) => m.id == machineId).firstOrNull;
              final isMachineActive = machine?.isActive ?? true; 
              
              return _MachineMaterialStatusItem(
                machineId: machineId,
                machineName: machine?.name ?? 'Machine $machineId',
                materialUsage: materialUsage,
                isMachineActive: isMachineActive,
                onTap: () {
                  if (machine != null) {
                    _showMaterialDialog(context, ref, machine, materialUsage);
                  }
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    Machine machine,
    MachineMaterialUsage? currentMaterial,
  ) {
    if (currentMaterial == null) {
      // Installer une matière
      MachineInstallationFormDialog.show(
        context,
        ref,
        session,
        machine,
        null,
      );
    } else {
      // Options : Terminer ou Panne
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Marquer la matière comme terminée'),
                onTap: () {
                  Navigator.pop(context);
                  TrackingDialogs.showMaterialFinishDialog(context, ref, session, currentMaterial);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                title: const Text('Signaler une panne'),
                onTap: () {
                  Navigator.pop(context);
                  TrackingDialogs.showMachineBreakdownDialog(context, ref, session, currentMaterial);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _MachineMaterialStatusItem extends StatelessWidget {
  const _MachineMaterialStatusItem({
    required this.machineId,
    required this.machineName,
    this.materialUsage,
    required this.isMachineActive,
    required this.onTap,
  });

  final String machineId;
  final String machineName;
  final MachineMaterialUsage? materialUsage;
  final bool isMachineActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isMachineActive) {
      statusColor = colorScheme.error;
      statusText = 'EN PANNE';
      statusIcon = Icons.report_problem_outlined;
    } else if (materialUsage == null) {
      statusColor = colorScheme.outline;
      statusText = 'AUCUNE MATIÈRE';
      statusIcon = Icons.not_interested;
    } else {
      statusColor = Colors.green;
      statusText = 'EN COURS : ${materialUsage!.materialType}';
      statusIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: statusColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: isMachineActive ? onTap : null,
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          machineName,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
        ),
        trailing: isMachineActive ? const Icon(Icons.edit_outlined, size: 18) : null,
      ),
    );
  }
}
