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

    return sessionsAsync.when(
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

          // Trier les sessions par date (plus récentes en premier)
          final sessionsTriees = List<ProductionSession>.from(sessions)
            ..sort((a, b) => b.date.compareTo(a.date));

          // Calculer les statistiques
          final totalSessions = sessionsTriees.length;
          final sessionsEnCours = sessionsTriees.where((s) =>
            s.effectiveStatus == ProductionSessionStatus.started ||
            s.effectiveStatus == ProductionSessionStatus.inProgress
          ).length;
          final sessionsTerminees = sessionsTriees.where((s) =>
            s.effectiveStatus == ProductionSessionStatus.completed
          ).length;
          final totalProduit = sessionsTriees.fold<double>(
            0,
            (sum, s) => sum + s.quantiteProduite,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                                  'Sessions de production',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalSessions session${totalSessions > 1 ? 's' : ''} au total',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => ref.invalidate(productionSessionsStateProvider),
                            tooltip: 'Actualiser',
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: FilledButton.icon(
                              onPressed: () => _showCreateForm(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Nouvelle session'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Statistiques
                      _StatisticsCards(
                        totalSessions: totalSessions,
                        sessionsEnCours: sessionsEnCours,
                        sessionsTerminees: sessionsTerminees,
                        totalProduit: totalProduit,
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
                      final session = sessionsTriees[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ProductionSessionCard(session: session),
                      );
                    },
                    childCount: sessionsTriees.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
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
    );
  }
}

/// Widget pour afficher les statistiques des sessions
class _StatisticsCards extends StatelessWidget {
  const _StatisticsCards({
    required this.totalSessions,
    required this.sessionsEnCours,
    required this.sessionsTerminees,
    required this.totalProduit,
  });

  final int totalSessions;
  final int sessionsEnCours;
  final int sessionsTerminees;
  final double totalProduit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total',
                  totalSessions.toString(),
                  Icons.factory,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'En cours',
                  sessionsEnCours.toString(),
                  Icons.settings,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Terminées',
                  sessionsTerminees.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total produit',
                  totalProduit.toStringAsFixed(0),
                  Icons.inventory_2,
                  Colors.orange,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total',
                      totalSessions.toString(),
                      Icons.factory,
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'En cours',
                      sessionsEnCours.toString(),
                      Icons.settings,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Terminées',
                      sessionsTerminees.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total produit',
                      totalProduit.toStringAsFixed(0),
                      Icons.inventory_2,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductionSessionDetailScreen(
                sessionId: session.id,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(session.date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(context, session.effectiveStatus),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.dureeHeures.toStringAsFixed(1)}h',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.inventory_2,
                        'Production',
                        '${session.quantiteProduite.toStringAsFixed(0)} ${session.quantiteProduiteUnite}',
                        theme.colorScheme.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.precision_manufacturing,
                        'Machines',
                        '${session.machinesUtilisees.length}',
                        Colors.blue,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.rotate_right,
                        'Bobines',
                        '${session.bobinesUtilisees.length}',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Bouton Modifier pour les sessions en cours
                  if (session.effectiveStatus == ProductionSessionStatus.draft ||
                      session.effectiveStatus == ProductionSessionStatus.started ||
                      session.effectiveStatus == ProductionSessionStatus.inProgress)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductionSessionFormScreen(
                                session: session,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (session.effectiveStatus == ProductionSessionStatus.draft ||
                      session.effectiveStatus == ProductionSessionStatus.started ||
                      session.effectiveStatus == ProductionSessionStatus.inProgress)
                    const SizedBox(width: 12),
                  // Bouton Suivre pour toutes les sessions
                  Expanded(
                    flex: session.effectiveStatus == ProductionSessionStatus.draft ||
                            session.effectiveStatus == ProductionSessionStatus.started ||
                            session.effectiveStatus == ProductionSessionStatus.inProgress
                        ? 1
                        : 1,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductionTrackingScreen(
                              sessionId: session.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.track_changes, size: 18),
                      label: const Text('Suivre'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
      case ProductionSessionStatus.suspended:
        backgroundColor = statusColors?.danger.withValues(alpha: 0.2) ??
            Colors.orange.withValues(alpha: 0.2);
        textColor = statusColors?.danger ?? Colors.orange;
        icon = Icons.pause_circle_outline;
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

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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

