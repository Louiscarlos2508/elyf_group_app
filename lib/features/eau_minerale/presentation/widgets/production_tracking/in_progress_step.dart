import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'bobines_status_list.dart';
import 'info_row.dart';
import 'personnel_section.dart';
import 'tracking_dialogs.dart';

/// Widget pour l'étape "InProgress" (en cours) de la session de production.
class InProgressStep extends ConsumerWidget {
  const InProgressStep({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bobinesFinies = session.bobinesUtilisees
        .where((b) => b.estFinie)
        .length;
    final toutesBobinesFinies = session.toutesBobinesFinies;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Production en cours',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (toutesBobinesFinies)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Toutes bobines finies',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InfoRow(
              icon: Icons.precision_manufacturing,
              label: 'Machines actives',
              value: '${session.machinesUtilisees.length}',
            ),
            InfoRow(
              icon: Icons.inventory_2,
              label: 'Bobines installées',
              value: '${session.bobinesUtilisees.length}',
            ),
            InfoRow(
              icon: Icons.check_circle_outline,
              label: 'Bobines finies',
              value: '$bobinesFinies / ${session.bobinesUtilisees.length}',
            ),
            InfoRow(
              icon: Icons.access_time,
              label: 'Durée de production',
              value: '${session.dureeHeures.toStringAsFixed(1)} heures',
            ),
            _buildConsumptionInfoRow(context, ref),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => TrackingDialogs.showAddMachineDialog(context, ref, session),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une machine'),
            ),
            const SizedBox(height: 24),
            BobinesStatusList(session: session),
            const SizedBox(height: 24),
            PersonnelSection(session: session),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => TrackingDialogs.showEventDialog(context, ref, session),
                    icon: const Icon(Icons.warning),
                    label: const Text('Enregistrer événement'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => TrackingDialogs.showFinalizationDialog(context, ref, session),
                    icon: const Icon(Icons.check),
                    label: const Text('Finaliser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionInfoRow(BuildContext context, WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return meterTypeAsync.when(
      data: (meterType) {
        return InfoRow(
          icon: Icons.flash_on,
          label: 'Consommation électrique',
          value: '${session.consommationCourant.toStringAsFixed(2)} ${meterType.unit}',
        );
      },
      loading: () => InfoRow(
        icon: Icons.flash_on,
        label: 'Consommation électrique',
        value: session.consommationCourant.toStringAsFixed(2),
      ),
      error: (_, __) => InfoRow(
        icon: Icons.flash_on,
        label: 'Consommation électrique',
        value: session.consommationCourant.toStringAsFixed(2),
      ),
    );
  }
}

