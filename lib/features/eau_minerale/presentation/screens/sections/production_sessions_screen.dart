import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/production_margin_calculator.dart';
import '../../widgets/section_placeholder.dart';
import 'production_session_detail_screen.dart';
import 'production_session_form_screen.dart';
import 'production_tracking_screen.dart';

/// Écran de liste des sessions de production.
class ProductionSessionsScreen extends ConsumerWidget {
  const ProductionSessionsScreen({super.key});

  void _showCreateForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductionSessionFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(productionSessionsStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions de production'),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return SectionPlaceholder(
              icon: Icons.factory_outlined,
              title: 'Aucune session de production',
              subtitle: 'Créez une nouvelle session pour commencer',
              primaryActionLabel: 'Nouvelle session',
              onPrimaryAction: () => _showCreateForm(context),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Text(
                        'Sessions de production',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IntrinsicWidth(
                        child: FilledButton.icon(
                          onPressed: () => _showCreateForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle session'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = sessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProductionSessionCard(session: session),
                      );
                    },
                    childCount: sessions.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SectionPlaceholder(
          icon: Icons.error_outline,
          title: 'Erreur de chargement',
          subtitle: 'Impossible de charger les sessions de production.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(productionSessionsStateProvider),
        ),
      ),
    );
  }
}

/// Carte affichant les informations d'une session de production.
class _ProductionSessionCard extends ConsumerWidget {
  const _ProductionSessionCard({required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ventesAsync = ref.watch(
      ventesParSessionProvider(session.id),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductionSessionDetailScreen(
                sessionId: session.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(session.date),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(session.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(context, session.effectiveStatus),
                      const SizedBox(height: 8),
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text('${session.dureeHeures.toStringAsFixed(1)}h'),
                          ],
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInfoChip(
                    context,
                    Icons.inventory_2,
                    '${session.quantiteProduite} ${session.quantiteProduiteUnite}',
                  ),
                  _buildInfoChip(
                    context,
                    Icons.precision_manufacturing,
                    '${session.machinesUtilisees.length} machine${session.machinesUtilisees.length > 1 ? 's' : ''}',
                  ),
                  _buildInfoChip(
                    context,
                    Icons.inventory,
                    '${session.bobinesUtilisees.length} bobine${session.bobinesUtilisees.length > 1 ? 's' : ''}',
                  ),
                  _buildInfoChip(
                    context,
                    Icons.water_drop,
                    '${session.consommationEau} L',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductionTrackingScreen(
                            sessionId: session.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Suivre'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ventesAsync.when(
                data: (ventes) {
                  if (ventes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final marge = ProductionMarginCalculator.calculerMarge(
                    session: session,
                    ventesLiees: ventes,
                  );
                  final statusColors = Theme.of(context).extension<StatusColors>()!;
                  final marginColor = marge.estRentable ? statusColors.success : statusColors.danger;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: marginColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: marginColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          marge.estRentable ? Icons.trending_up : Icons.trending_down,
                          color: marginColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Marge: ${marge.pourcentageMargeFormate}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: marginColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    ProductionSessionStatus status,
  ) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<StatusColors>();
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (status) {
      case ProductionSessionStatus.draft:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.edit_outlined;
        break;
      case ProductionSessionStatus.started:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        icon = Icons.play_circle_outline;
        break;
      case ProductionSessionStatus.inProgress:
        backgroundColor = statusColors?.success.withValues(alpha: 0.2) ??
            Colors.blue.withValues(alpha: 0.2);
        textColor = statusColors?.success ?? Colors.blue;
        icon = Icons.settings;
        break;
      case ProductionSessionStatus.completed:
        backgroundColor = statusColors?.success.withValues(alpha: 0.2) ??
            Colors.green.withValues(alpha: 0.2);
        textColor = statusColors?.success ?? Colors.green;
        icon = Icons.check_circle;
        break;
    }
    
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Provider pour récupérer les ventes liées à une session.
final ventesParSessionProvider = FutureProvider.autoDispose.family<
    List<Sale>,
    String>(
  (ref, sessionId) async {
    final salesState = await ref.read(salesControllerProvider).fetchRecentSales();
    return salesState.sales.where((v) => v.productionSessionId == sessionId).toList();
  },
);

