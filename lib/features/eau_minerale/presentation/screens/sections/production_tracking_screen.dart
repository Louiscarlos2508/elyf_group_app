import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_event.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../widgets/bobine_finish_dialog.dart';
import '../../widgets/bobine_installation_form.dart';
import '../../widgets/daily_personnel_form.dart';
import '../../widgets/machine_breakdown_dialog.dart';
import '../../widgets/production_event_dialog.dart';
import '../../widgets/production_finalization_dialog.dart';
import '../../widgets/production_resume_dialog.dart';
import '../../widgets/bobine_usage_form_field.dart' show bobineStocksDisponiblesProvider;
import '../../../domain/entities/electricity_meter_type.dart';
import 'production_session_detail_screen.dart' show productionSessionDetailProvider;
import 'production_session_form_screen.dart';

/// Écran de suivi de production en temps réel avec progression dynamique.
class ProductionTrackingScreen extends ConsumerStatefulWidget {
  const ProductionTrackingScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<ProductionTrackingScreen> createState() =>
      _ProductionTrackingScreenState();
}

class _ProductionTrackingScreenState
    extends ConsumerState<ProductionTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      productionSessionDetailProvider(widget.sessionId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de production'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              sessionAsync.whenData((session) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductionSessionFormScreen(
                      session: session,
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) => _ProductionTrackingContent(session: session),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductionTrackingContent extends ConsumerWidget {
  const _ProductionTrackingContent({required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = session.effectiveStatus;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildProgressIndicator(context, theme, status),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
            _buildCurrentStepContent(context, theme, status, ref),
            const SizedBox(height: 24),
            _buildSessionInfo(context, theme),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    ThemeData theme,
    ProductionSessionStatus status,
  ) {
    final steps = [
      _StepInfo(
        label: 'Initialisation',
        icon: Icons.create_outlined,
        description: 'Session créée',
      ),
      _StepInfo(
        label: 'Démarrage',
        icon: Icons.play_arrow,
        description: 'Production démarrée',
      ),
      _StepInfo(
        label: 'En cours',
        icon: Icons.settings,
        description: 'Machines et bobines',
      ),
      _StepInfo(
        label: 'Terminée',
        icon: Icons.check_circle,
        description: 'Production finalisée',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / steps.length;

          return Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final stepInfo = entry.value;
              final isActive = status.isStepActive(index);
              final isCompleted = status.isStepCompleted(index);

              return SizedBox(
                width: stepWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive || isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 24,
                                    color: theme.colorScheme.onPrimary,
                                  )
                                : Icon(
                                    stepInfo.icon,
                                    size: 24,
                                    color: isActive
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stepInfo.label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStepContent(
    BuildContext context,
    ThemeData theme,
    ProductionSessionStatus status,
    WidgetRef ref,
  ) {
    switch (status) {
      case ProductionSessionStatus.draft:
        return _buildDraftStep(context, theme);
      case ProductionSessionStatus.started:
        return _buildStartedStep(context, theme, ref);
      case ProductionSessionStatus.inProgress:
        return _buildInProgressStep(context, theme, ref);
      case ProductionSessionStatus.suspended:
        return _buildSuspendedStep(context, theme, ref);
      case ProductionSessionStatus.completed:
        return _buildCompletedStep(context, theme);
    }
  }

  Widget _buildDraftStep(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Session créée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'La session de production a été créée. Cliquez sur "Démarrer" pour commencer la production.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Implémenter le démarrage de la production
                // Cela devrait mettre à jour heureDebut
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer la production'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartedStep(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Production démarrée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Heure de début',
              _formatDateTime(session.heureDebut),
            ),
            const SizedBox(height: 24),
            Text(
              'Enregistrez les machines et bobines utilisées pour continuer.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showAddMachineDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une machine'),
            ),
            if (session.machinesUtilisees.isNotEmpty &&
                session.bobinesUtilisees.isNotEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showFinalizationDialog(context, ref),
                icon: const Icon(Icons.check),
                label: const Text('Finaliser la production'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressStep(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
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
            _buildInfoRow(
              context,
              Icons.precision_manufacturing,
              'Machines actives',
              '${session.machinesUtilisees.length}',
            ),
            _buildInfoRow(
              context,
              Icons.inventory_2,
              'Bobines installées',
              '${session.bobinesUtilisees.length}',
            ),
            _buildInfoRow(
              context,
              Icons.check_circle_outline,
              'Bobines finies',
              '$bobinesFinies / ${session.bobinesUtilisees.length}',
            ),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Durée de production',
              '${session.dureeHeures.toStringAsFixed(1)} heures',
            ),
            _buildConsumptionInfoRow(context, ref),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _showAddMachineDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une machine'),
            ),
            const SizedBox(height: 24),
            _buildBobinesStatusList(context, theme, ref),
            const SizedBox(height: 24),
            _buildPersonnelSection(context, theme, ref),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEventDialog(context, ref),
                    icon: const Icon(Icons.warning),
                    label: const Text('Enregistrer événement'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showFinalizationDialog(context, ref),
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

  Widget _buildSuspendedStep(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final statusColors = Theme.of(context).extension<StatusColors>();
    return Card(
      color: statusColors?.danger.withValues(alpha: 0.1) ??
          Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  color: statusColors?.danger ?? Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Production suspendue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'La production a été suspendue (panne, coupure ou arrêt forcé).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Les bobines restent dans les machines et ne peuvent pas être retirées tant qu\'elles ne sont pas finies.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (session.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Événements enregistrés :',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...session.events.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${event.type.label}: ${event.motif}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEventDialog(context, ref),
                    icon: const Icon(Icons.warning),
                    label: const Text('Nouvel événement'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResumeDialog(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reprendre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showFinalizationDialog(context, ref),
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

  Widget _buildCompletedStep(BuildContext context, ThemeData theme) {
    final statusColors = Theme.of(context).extension<StatusColors>();
    return Card(
      color: statusColors?.success.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: statusColors?.success ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Production terminée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.inventory_2,
              'Quantité produite',
              '${session.quantiteProduite} ${session.quantiteProduiteUnite}',
            ),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Durée',
              '${session.dureeHeures.toStringAsFixed(1)} heures',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBobinesStatusList(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    if (session.bobinesUtilisees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État des bobines',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...session.bobinesUtilisees.map((bobine) {
          // Vérifier s'il y a déjà une bobine active (non finie) sur cette machine
          // Peu importe le type, si une bobine est active, on ne peut pas installer une nouvelle
          final aBobineActiveSurMachine = session.bobinesUtilisees.any(
            (b) => b.machineId == bobine.machineId && !b.estFinie,
          );
          
          // Le bouton "Nouvelle" ne doit s'afficher que si :
          // - La bobine est finie ET
          // - Il n'y a pas déjà une autre bobine active sur cette machine
          final peutInstallerNouvelle = bobine.estFinie && !aBobineActiveSurMachine;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: bobine.estFinie
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surface,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: bobine.estFinie
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(
                  bobine.estFinie ? Icons.check : Icons.sync,
                  size: 20,
                  color: bobine.estFinie
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(bobine.bobineType),
              subtitle: Text(
                'Machine: ${bobine.machineName}',
              ),
              trailing: bobine.estFinie
                  ? (peutInstallerNouvelle
                      ? IntrinsicWidth(
                          child: OutlinedButton.icon(
                            onPressed: () => _showInstallNewBobineDialog(context, ref, bobine),
                            icon: const Icon(Icons.add_circle, size: 18),
                            label: const Text('Nouvelle'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Bobine active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.build, color: Colors.orange, size: 20),
                          tooltip: 'Signaler panne',
                          onPressed: () => _showMachineBreakdownDialog(context, ref, bobine),
                        ),
                        SizedBox(
                          width: 100,
                          child: OutlinedButton.icon(
                            onPressed: () => _showBobineFinishDialog(context, ref, bobine),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Finie'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }),
      ],
    );
  }

  void _showEventDialog(BuildContext context, WidgetRef ref) {
    // Méthode appelée depuis un ConsumerWidget, ref est disponible
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ProductionEventDialog(
          productionId: session.id,
          onEventRecorded: (event) async {
            // Mettre à jour la session avec le nouvel événement
            final updatedEvents = List<ProductionEvent>.from(session.events)
              ..add(event);
            final updatedSession = session.copyWith(
              events: updatedEvents,
              status: ProductionSessionStatus.suspended,
            );
            
            final controller = ref.read(productionSessionControllerProvider);
            await controller.updateSession(updatedSession);
            
            if (context.mounted) {
              Navigator.of(context).pop();
              ref.invalidate(productionSessionDetailProvider(session.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Événement enregistré. Production suspendue.'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showResumeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => ProductionResumeDialog(
        session: session,
        onResumed: (heureReprise) async {
          // Mettre à jour tous les événements non terminés avec l'heure de reprise
          final updatedEvents = session.events.map((event) {
            if (!event.estTermine) {
              return event.copyWith(heureReprise: heureReprise);
            }
            return event;
          }).toList();
          
          // Mettre à jour la session : statut en cours, événements mis à jour
          final updatedSession = session.copyWith(
            events: updatedEvents,
            status: ProductionSessionStatus.inProgress,
          );
          
          final controller = ref.read(productionSessionControllerProvider);
          await controller.updateSession(updatedSession);
          
          if (context.mounted) {
            ref.invalidate(productionSessionDetailProvider(session.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Production reprise avec succès.'),
              ),
            );
          }
        },
      ),
    );
  }

  void _showFinalizationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => ProductionFinalizationDialog(
        session: session,
        onFinalized: (finalizedSession) {
          ref.invalidate(productionSessionDetailProvider(session.id));
          ref.invalidate(productionSessionsStateProvider);
        },
      ),
    );
  }

  void _showBobineFinishDialog(
    BuildContext context,
    WidgetRef ref,
    BobineUsage bobine,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => BobineFinishDialog(
        session: session,
        bobine: bobine,
        onFinished: (updatedSession) {
          ref.invalidate(productionSessionDetailProvider(session.id));
        },
      ),
    );
  }

  void _showMachineBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    BobineUsage bobine,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => MachineBreakdownDialog(
        session: session,
        bobine: bobine,
        onPanneSignaled: (event) {
          ref.invalidate(productionSessionDetailProvider(session.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Panne signalée avec succès'),
            ),
          );
        },
      ),
    );
  }

  /// Affiche le dialogue pour ajouter une nouvelle machine avec sa bobine.
  Future<void> _showAddMachineDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Récupérer toutes les machines et celles déjà utilisées
    final machinesAsync = ref.watch(allMachinesProvider);
    
    await machinesAsync.when(
      data: (allMachines) async {
        // Filtrer les machines non utilisées et actives
        final machinesUtiliseesIds = session.machinesUtilisees.toSet();
        final machinesDisponibles = allMachines.where(
          (m) => m.estActive && !machinesUtiliseesIds.contains(m.id),
        ).toList();
        
        if (machinesDisponibles.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Toutes les machines actives sont déjà utilisées'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        // Si une seule machine disponible, l'utiliser directement
        // Sinon, afficher un dialog de sélection
        Machine? machineSelectionnee;
        if (machinesDisponibles.length == 1) {
          machineSelectionnee = machinesDisponibles.first;
        } else {
          if (!context.mounted) return;
          machineSelectionnee = await showDialog<Machine>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Sélectionner une machine'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: machinesDisponibles.length,
                  itemBuilder: (context, index) {
                    final machine = machinesDisponibles[index];
                    return ListTile(
                      title: Text(machine.nom),
                      onTap: () => Navigator.of(context).pop(machine),
                    );
                  },
                ),
              ),
            ),
          );
        }
        
        if (machineSelectionnee == null || !context.mounted) return;
        
        // Vérifier d'abord s'il y a déjà une bobine non finie pour cette machine
        BobineUsage? bobineNonFinieExistante;
        for (final session in await ref.read(productionSessionsStateProvider.future)) {
          for (final bobine in session.bobinesUtilisees) {
            if (!bobine.estFinie && bobine.machineId == machineSelectionnee!.id) {
              bobineNonFinieExistante = bobine;
              break;
            }
          }
          if (bobineNonFinieExistante != null) break;
        }
        
        if (bobineNonFinieExistante != null) {
          // Réutiliser la bobine non finie existante
          final maintenant = DateTime.now();
          final bobineReutilisee = bobineNonFinieExistante.copyWith(
            dateInstallation: maintenant,
            heureInstallation: maintenant,
          );
          
          // Ajouter la machine et réutiliser la bobine
          final updatedMachines = List<String>.from(session.machinesUtilisees)
            ..add(machineSelectionnee!.id);
          final updatedBobines = List<BobineUsage>.from(session.bobinesUtilisees)
            ..add(bobineReutilisee);
          
          final updatedSession = session.copyWith(
            machinesUtilisees: updatedMachines,
            bobinesUtilisees: updatedBobines,
          );
          
          final controller = ref.read(productionSessionControllerProvider);
          await controller.updateSession(updatedSession);
          
          if (context.mounted) {
            ref.invalidate(productionSessionDetailProvider(session.id));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Machine ${machineSelectionnee!.nom} ajoutée. Bobine non finie réutilisée: ${bobineNonFinieExistante.bobineType}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
        }
        
        // Si pas de bobine non finie, installer une nouvelle bobine
        await showDialog<BobineUsage>(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
                maxHeight: 700,
              ),
              child: BobineInstallationForm(
                machine: machineSelectionnee!,
                onInstalled: (newBobine) async {
                  // Ajouter la machine et la bobine à la session
                  final updatedMachines = List<String>.from(session.machinesUtilisees)
                    ..add(machineSelectionnee!.id);
                  final updatedBobines = List<BobineUsage>.from(session.bobinesUtilisees)
                    ..add(newBobine);
                  
                  final updatedSession = session.copyWith(
                    machinesUtilisees: updatedMachines,
                    bobinesUtilisees: updatedBobines,
                  );
                  
                  final controller = ref.read(productionSessionControllerProvider);
                  await controller.updateSession(updatedSession);
                  
                  // Le stock est déjà décrémenté lors de l'installation dans BobineInstallationForm
                  // Pas besoin de décrémenter à nouveau ici
                  
                      if (context.mounted) {
                        // Le dialog de sélection est déjà fermé par le formulaire
                        // On se contente de rafraîchir les données et d'afficher un message
                        ref.invalidate(productionSessionDetailProvider(session.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Machine ${machineSelectionnee!.nom} ajoutée avec succès',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                },
              ),
            ),
          ),
        );
      },
      loading: () {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
      error: (error, stack) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des machines: $error'),
            ),
          );
        }
      },
    );
  }

  /// Affiche le dialogue pour installer une nouvelle bobine sur une machine.
  Future<void> _showInstallNewBobineDialog(
    BuildContext context,
    WidgetRef ref,
    BobineUsage bobineFinie,
  ) async {
    // Récupérer directement les données sans utiliser watch pour éviter les problèmes de rebuild
    final machines = await ref.read(allMachinesProvider.future);
    
    if (!context.mounted) return;
    
    final machine = machines.firstWhere(
      (m) => m.id == bobineFinie.machineId,
      orElse: () => throw StateError('Machine not found'),
    );
    
    if (!context.mounted) return;
    
    // Afficher le dialog d'installation
    // Le formulaire récupère automatiquement les stocks de bobines disponibles
    await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: BobineInstallationForm(
            machine: machine,
            onInstalled: (newBobine) async {
              // Vérifier qu'il n'y a pas déjà une bobine active sur cette machine
              final aBobineActive = session.bobinesUtilisees.any(
                (b) => b.machineId == newBobine.machineId && !b.estFinie,
              );
              
              if (aBobineActive) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cette machine a déjà une bobine active. Finalisez d\'abord la bobine en cours.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              
              // Mettre à jour la session avec la nouvelle bobine
              // On AJOUTE la nouvelle bobine au lieu de remplacer l'ancienne
              // pour garder l'historique de toutes les bobines utilisées
              final updatedBobines = List<BobineUsage>.from(session.bobinesUtilisees);
              
              // Vérifier si la nouvelle bobine existe déjà (pour éviter les doublons)
              final existeDeja = updatedBobines.any(
                (b) => b.bobineType == newBobine.bobineType &&
                       b.machineId == newBobine.machineId &&
                       !b.estFinie,
              );
              
              if (!existeDeja) {
                // Ajouter la nouvelle bobine à la liste (l'ancienne reste dans la liste avec estFinie = true)
                updatedBobines.add(newBobine);
              }
              
              final updatedSession = session.copyWith(
                bobinesUtilisees: updatedBobines,
              );
              
              final controller = ref.read(productionSessionControllerProvider);
              await controller.updateSession(updatedSession);
              
              // Le stock est déjà décrémenté lors de l'installation dans BobineInstallationForm
              // Pas besoin de décrémenter à nouveau ici
              
              if (context.mounted) {
                // Le dialog d'installation de bobine se ferme déjà lui‑même.
                // Ici on rafraîchit seulement la session et on notifie l'utilisateur.
                // Invalider les providers pour rafraîchir l'affichage et faire disparaître le bouton
                ref.invalidate(productionSessionDetailProvider(session.id));
                ref.invalidate(productionSessionsStateProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nouvelle bobine installée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPersonnelSection(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personnel et production journalière',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enregistrez le personnel et la production pour chaque jour',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IntrinsicWidth(
                  child: FilledButton.icon(
                    onPressed: () {
                      // Un seul enregistrement de personnel par date.
                      final today = DateTime.now();
                      final existingForToday = session.productionDays.cast<ProductionDay?>().firstWhere(
                            (day) =>
                                day != null &&
                                day.date.year == today.year &&
                                day.date.month == today.month &&
                                day.date.day == today.day,
                            orElse: () => null,
                          );
                      _showPersonnelForm(
                        context,
                        ref,
                        today,
                        existingForToday,
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter jour'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (session.productionDays.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucun personnel enregistré pour cette production.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...session.productionDays.map((day) {
                final hasProduction = day.packsProduits > 0 || day.emballagesUtilises > 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            '${day.nombrePersonnes}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(_formatDate(day.date)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${day.personnelIds.length} personne(s) • '
                              '${day.coutTotalPersonnel} CFA',
                            ),
                            if (hasProduction) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${day.packsProduits} packs produits • '
                                '${day.emballagesUtilises} emballages utilisés',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Production non renseignée',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!hasProduction)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showPersonnelForm(context, ref, day.date, day),
                                  icon: const Icon(Icons.inventory_2, size: 18),
                                  label: const Text('Production'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Modifier le personnel et la production',
                                onPressed: () =>
                                    _showPersonnelForm(context, ref, day.date, day),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Supprimer ce jour',
                              onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Supprimer le jour'),
                                content: Text(
                                  'Supprimer le personnel et la production du ${_formatDate(day.date)} ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true || !context.mounted) return;

                            final updatedDays =
                                List<ProductionDay>.from(session.productionDays)
                                  ..removeWhere((d) => d.id == day.id);

                            final updatedSession = session.copyWith(
                              productionDays: updatedDays,
                            );

                            final controller =
                                ref.read(productionSessionControllerProvider);
                            await controller.updateSession(updatedSession);

                            if (context.mounted) {
                              ref.invalidate(
                                  productionSessionDetailProvider(session.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Jour de production supprimé avec succès'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    ),
                    ],
                  ),
                );
              }),
            if (session.productionDays.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coût total personnel',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${session.coutTotalPersonnel} CFA',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPersonnelForm(
    BuildContext context,
    WidgetRef ref,
    DateTime date, [
    ProductionDay? existingDay,
  ]) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DailyPersonnelForm(
            session: session,
            date: date,
            existingDay: existingDay,
            onSaved: (productionDay) async {
              // Mettre à jour la session avec le nouveau jour de production
              final updatedDays = List<ProductionDay>.from(session.productionDays);
              
              // Calculer la différence pour gérer les modifications
              int ancienPacksProduits = 0;
              int ancienEmballagesUtilises = 0;
              
              if (existingDay != null) {
                ancienPacksProduits = existingDay.packsProduits;
                ancienEmballagesUtilises = existingDay.emballagesUtilises;
                // Mettre à jour le jour existant
                final index = updatedDays.indexWhere((d) => d.id == existingDay.id);
                if (index >= 0) {
                  updatedDays[index] = productionDay;
                }
              } else {
                // Ajouter un nouveau jour
                updatedDays.add(productionDay);
              }
              
              final updatedSession = session.copyWith(
                productionDays: updatedDays,
              );
              
              final controller = ref.read(productionSessionControllerProvider);
              await controller.updateSession(updatedSession);
              
              // IMPORTANT: Ne pas mettre à jour les stocks ici
              // Les mouvements de stock seront enregistrés UNIQUEMENT lors de la finalisation
              // pour éviter les duplications et garantir un historique cohérent
              // Les modifications des jours de production sont juste sauvegardées dans la session
              
              if (context.mounted) {
                Navigator.of(context).pop();
                ref.invalidate(productionSessionDetailProvider(session.id));
                ref.invalidate(stockStateProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Personnel enregistré avec succès'),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }


  Widget _buildSessionInfo(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de la session',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Date',
              _formatDate(session.date),
            ),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Heure de début',
              _formatTime(session.heureDebut),
            ),
            if (session.heureFin != null)
              _buildInfoRow(
                context,
                Icons.access_time,
                'Heure de fin',
                _formatTime(session.heureFin!),
              ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${_formatTime(date)}';
  }

  Widget _buildConsumptionInfoRow(BuildContext context, WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return _buildInfoRow(
          context,
          Icons.flash_on,
          'Consommation électrique',
          '${session.consommationCourant.toStringAsFixed(2)} ${meterType.unit}',
        );
      },
      loading: () => _buildInfoRow(
        context,
        Icons.flash_on,
        'Consommation électrique',
        '${session.consommationCourant.toStringAsFixed(2)}',
      ),
      error: (_, __) => _buildInfoRow(
        context,
        Icons.flash_on,
        'Consommation électrique',
        '${session.consommationCourant.toStringAsFixed(2)}',
      ),
    );
  }
}

class _StepInfo {
  const _StepInfo({
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String description;
}

