import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../application/controllers/production_session_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
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
              _buildCurrentStepContent(context, theme, status),
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
  ) {
    switch (status) {
      case ProductionSessionStatus.draft:
        return _buildDraftStep(context, theme);
      case ProductionSessionStatus.started:
        return _buildStartedStep(context, theme);
      case ProductionSessionStatus.inProgress:
        return _buildInProgressStep(context, theme);
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
                // Cela devrait mettre à jour heureDebut et indexCompteurDebut
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer la production'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartedStep(BuildContext context, ThemeData theme) {
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
            _buildInfoRow(
              context,
              Icons.water_drop,
              'Index compteur début',
              '${session.indexCompteurDebut} L',
            ),
            const SizedBox(height: 24),
            Text(
              'Enregistrez les machines et bobines utilisées pour continuer.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressStep(BuildContext context, ThemeData theme) {
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
                Text(
                  'Production en cours',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.precision_manufacturing,
              'Machines utilisées',
              '${session.machinesUtilisees.length}',
            ),
            _buildInfoRow(
              context,
              Icons.inventory_2,
              'Bobines utilisées',
              '${session.bobinesUtilisees.length}',
            ),
            _buildInfoRow(
              context,
              Icons.flash_on,
              'Consommation électrique',
              '${session.consommationCourant.toStringAsFixed(2)} kWh',
            ),
            const SizedBox(height: 24),
            Text(
              'Enregistrez la fin de production et la quantité produite pour finaliser.',
              style: theme.textTheme.bodyMedium,
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
            _buildInfoRow(
              context,
              Icons.water_drop,
              'Consommation d\'eau',
              '${session.consommationEau} L',
            ),
          ],
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
            _buildInfoRow(
              context,
              Icons.access_time,
              'Heure de fin',
              _formatTime(session.heureFin),
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

