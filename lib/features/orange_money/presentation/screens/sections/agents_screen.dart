import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/agent.dart';
import '../../widgets/agents/agents_dialogs.dart';
import '../../widgets/agents/agents_filters.dart';
import '../../widgets/agents/agents_header.dart';
import '../../widgets/agents/agents_kpi_cards.dart';
import '../../widgets/agents/agents_list_header.dart';
import '../../widgets/agents/agents_low_liquidity_banner.dart';
import '../../widgets/agents/agents_sort_button.dart';
import '../../widgets/agents/agents_table.dart';

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
    final agentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
    final statsKey = '${widget.enterpriseId ?? ''}';
    
    final agentsAsync = ref.watch(agentsProvider((agentsKey)));
    final statsAsync = ref.watch(agentsDailyStatisticsProvider((statsKey)));

    return Container(
      color: const Color(0xFFF9FAFB),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AgentsHeader(
                    onHistoryPressed: () {
                      // TODO: Navigate to global history
                    },
                  ),
                  const SizedBox(height: 24),
                  agentsAsync.when(
                    data: (agents) {
                      final lowLiquidityAgents = agents
                          .where((a) => a.isLowLiquidity(50000))
                          .toList();
                      return lowLiquidityAgents.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AgentsLowLiquidityBanner(agents: lowLiquidityAgents),
                                const SizedBox(height: 24),
                                statsAsync.when(
                                  data: (stats) => AgentsKpiCards(stats: stats),
                                  loading: () => const SizedBox(
                                    height: 140,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  error: (_, __) => const SizedBox(),
                                ),
                              ],
                            )
                          : statsAsync.when(
                              data: (stats) => AgentsKpiCards(stats: stats),
                              loading: () => const SizedBox(
                                height: 140,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (_, __) => const SizedBox(),
                            );
                    },
                    loading: () => statsAsync.when(
                      data: (stats) => AgentsKpiCards(stats: stats),
                      loading: () => const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                    error: (_, __) => statsAsync.when(
                      data: (stats) => AgentsKpiCards(stats: stats),
                      loading: () => const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  agentsAsync.when(
                    data: (agents) => _buildAgentsList(context, agents),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erreur: $error'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList(BuildContext context, List<Agent> agents) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      child: Padding(
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
                // TODO: Toggle sort order
              },
            ),
            const SizedBox(height: 16),
            AgentsTable(
              agents: agents,
              onView: (agent) {
                // TODO: View agent details
              },
              onRefresh: (agent) {
                // TODO: Refresh agent
              },
              onEdit: (agent) => _showAgentDialog(context, agent),
              onDelete: (agent) => _deleteAgent(context, agent),
            ),
          ],
        ),
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
          final agentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
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
          final agentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
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
        final agentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
        ref.invalidate(agentsProvider((agentsKey)));
      }
    }
  }
}
