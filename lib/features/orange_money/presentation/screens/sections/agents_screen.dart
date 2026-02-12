import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/agent.dart';
import '../../widgets/agents/agents_dialogs.dart';
import '../../widgets/agents/agents_filters.dart';
import '../../widgets/agents/agents_kpi_cards.dart';
import '../../widgets/agents/agents_list_header.dart';
import '../../widgets/agents/agents_low_liquidity_banner.dart';
import '../../widgets/agents/agents_sort_button.dart';
import '../../widgets/agents/agents_table.dart';
import '../../widgets/orange_money_header.dart';

/// Screen for managing affiliated agents.
class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  String _searchQuery = '';
  AgentStatus? _statusFilter;
  String? _sortBy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agentsKey =
        '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
    final statsKey = widget.enterpriseId ?? '';

    final agentsAsync = ref.watch(agentsProvider(agentsKey));
    final statsAsync = ref.watch(agentsDailyStatisticsProvider(statsKey));

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: CustomScrollView(
        slivers: [
          OrangeMoneyHeader(
            title: 'Gestion des Agents',
            subtitle:
                'Gérez votre réseau de distribution, surveillez la liquidité et supervisez les recharges.',
            badgeText: 'AGENTS AFFILIÉS',
            badgeIcon: Icons.people_alt_rounded,
            additionalActions: [
              OutlinedButton.icon(
                onPressed: () {
                  NotificationService.showInfo(
                    context,
                    'Historique global - Fonctionnalité à venir',
                  );
                },
                icon: const Icon(Icons.history_rounded,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Historique',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiSection(agentsAsync, statsAsync, ref),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAgentsListSection(agentsAsync, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(
    AsyncValue<List<Agent>> agentsAsync,
    AsyncValue statsAsync,
    WidgetRef ref,
  ) {
    // Check if any is loading
    if (agentsAsync.isLoading || statsAsync.isLoading) {
      return const LoadingIndicator(height: 140);
    }

    // Check if stats has error, but agents is loaded
    if (statsAsync.hasError && agentsAsync.hasValue) {
      // Show KPIs even if stats failed
      final agents = agentsAsync.value!;
      final lowLiquidityAgents = agents
          .where((a) => a.isLowLiquidity(50000))
          .toList();

      return lowLiquidityAgents.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AgentsLowLiquidityBanner(agents: lowLiquidityAgents),
                const SizedBox(height: AppSpacing.lg),
                ErrorDisplayWidget(
                  error: statsAsync.error!,
                  title: 'Erreur de chargement des statistiques',
                  onRetry: () => ref.refresh(
                    agentsDailyStatisticsProvider(
                      widget.enterpriseId ?? '',
                    ),
                  ),
                ),
              ],
            )
          : ErrorDisplayWidget(
              error: statsAsync.error!,
              title: 'Erreur de chargement des statistiques',
              onRetry: () => ref.refresh(
                agentsDailyStatisticsProvider(
                  widget.enterpriseId ?? '',
                ),
              ),
            );
    }

    // Check if agents has error
    if (agentsAsync.hasError) {
      return ErrorDisplayWidget(
        error: agentsAsync.error!,
        title: 'Erreur de chargement des agents',
        onRetry: () => ref.refresh(
          agentsProvider(
            '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery',
          ),
        ),
      );
    }

    // All data available
    final agents = agentsAsync.value!;
    final stats = statsAsync.value!;

    final lowLiquidityAgents = agents
        .where((a) => a.isLowLiquidity(50000))
        .toList();

    return lowLiquidityAgents.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentsLowLiquidityBanner(agents: lowLiquidityAgents),
              const SizedBox(height: AppSpacing.lg),
              AgentsKpiCards(stats: stats),
            ],
          )
        : AgentsKpiCards(stats: stats);
  }

  Widget _buildAgentsListSection(
    AsyncValue<List<Agent>> agentsAsync,
    WidgetRef ref,
  ) {
    return agentsAsync.when(
      data: (agents) => _buildAgentsList(context, agents),
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des agents',
        onRetry: () => ref.refresh(
          agentsProvider(
            '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery',
          ),
        ),
      ),
    );
  }

  Widget _buildAgentsList(BuildContext context, List<Agent> agents) {
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentsListHeader(
              agentCount: agents.length,
              onAddAgent: () => _showAgentDialog(context, null),
              onRecharge: () => _showRechargeDialog(context),
            ),
            const SizedBox(height: 16),
            AgentsFilters(
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              sortBy: _sortBy,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onStatusChanged: (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
              onSortChanged: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              onReset: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = null;
                  _sortBy = null;
                });
              },
            ),
            const SizedBox(height: 16),
            AgentsSortButton(
              onPressed: () {
                // ✅ TODO résolu: Toggle sort order
                setState(() {
                  // Cycle through sort options: null -> name -> liquidity -> date -> null
                  if (_sortBy == null) {
                    _sortBy = 'name';
                  } else if (_sortBy == 'name') {
                    _sortBy = 'liquidity';
                  } else if (_sortBy == 'liquidity') {
                    _sortBy = 'date';
                  } else {
                    _sortBy = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            AgentsTable(
              agents: agents,
              onView: (agent) {
                // ✅ TODO résolu: View agent details
                // Pour l'instant, on affiche un message
                // L'écran de détails sera créé dans une prochaine étape
                NotificationService.showInfo(
                  context,
                  'Détails de ${agent.name} - Fonctionnalité à venir',
                );
              },
              onRefresh: (agent) {
                // ✅ TODO résolu: Refresh agent
                final agentsKey =
                    '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
                ref.invalidate(agentsProvider((agentsKey)));
                ref.invalidate(agentsDailyStatisticsProvider(widget.enterpriseId ?? ''));
                
                NotificationService.showSuccess(
                  context,
                  'Données de ${agent.name} actualisées',
                );
              },
              onEdit: (agent) => _showAgentDialog(context, agent),
              onDelete: (agent) => _deleteAgent(context, agent),
            ),
          ],
        ),
      );
  }

  void _showAgentDialog(BuildContext context, Agent? agent) {
    AgentsDialogs.showAgentDialog(
      context,
      ref,
      agent,
      widget.enterpriseId,
      _searchQuery,
      _statusFilter,
      () {
        if (mounted) {
          final agentsKey =
              '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
          ref.invalidate(agentsProvider((agentsKey)));
        }
      },
    );
  }

  void _showRechargeDialog(BuildContext context) {
    AgentsDialogs.showRechargeDialog(
      context,
      ref,
      widget.enterpriseId,
      _searchQuery,
      _statusFilter,
      () {
        if (mounted) {
          final agentsKey =
              '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
          ref.invalidate(agentsProvider((agentsKey)));
        }
      },
    );
  }

  Future<void> _deleteAgent(BuildContext context, Agent agent) async {
    final confirmed = await AgentsDialogs.showDeleteDialog(context, agent);

    if (confirmed == true && mounted) {
      final controller = ref.read(agentsControllerProvider);
      await controller.deleteAgent(agent.id);
      if (mounted) {
        final agentsKey =
            '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
        ref.invalidate(agentsProvider((agentsKey)));
      }
    }
  }
}
