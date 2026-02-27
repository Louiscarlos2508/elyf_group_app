import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' show Agent, AgentStatus;
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_dialogs.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_filters.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_kpi_cards.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_list_header.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_low_liquidity_banner.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_sort_button.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agent_account_table.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agencies_table.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/orange_money_header.dart';
import 'package:elyf_groupe_app/core/permissions/modules/orange_money_permissions.dart';

/// Screen for managing affiliated agents (Mobile Money Enterprises).
class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _sortBy;
  AgentStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsKey = widget.enterpriseId ?? '';
    final statsAsync = ref.watch(agentsDailyStatisticsProvider(statsKey));

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: CustomScrollView(
        slivers: [
          OrangeMoneyHeader(
            title: 'Réseau d\'Agents',
            subtitle: 'Gérez vos agents (SIM/Employés) et vos agences physiques.',
            badgeText: 'GESTION RÉSEAU',
            badgeIcon: Icons.account_tree_rounded,
            asSliver: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsSection(statsAsync),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTabsSection(),
                  const SizedBox(height: AppSpacing.md),
                  _buildListSection(ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => AgentsKpiCards(stats: stats),
      loading: () => const LoadingIndicator(height: 120),
      error: (e, s) => ErrorDisplayWidget(error: e),
    );
  }

  Widget _buildTabsSection() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18),
                SizedBox(width: 8),
                Text('Agents (SIM/Employés)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              children: [
                Icon(Icons.business_outlined, size: 18),
                SizedBox(width: 8),
                Text('Agences (Points de Vente)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(WidgetRef ref) {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
          final agentsAsync = ref.watch(
            agentAccountsProvider('${widget.enterpriseId ?? ''}||$_searchQuery'),
          );
          return _buildAgentsList(agentsAsync, ref);
        } else {
          final agenciesAsync = ref.watch(
            agentAgenciesProvider('${widget.enterpriseId ?? ''}||$_searchQuery'),
          );
      return _buildAgenciesList(agenciesAsync, ref);
    }
  }

  Widget _buildAgentsList(AsyncValue<List<Agent>> agentsAsync, WidgetRef ref) {
    return agentsAsync.when(
      data: (agents) => ElyfCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentsListHeader(
              agentCount: agents.length,
              title: 'Liste des Agents (SIM)',
              onAddAgent: () => _showAddDialog(),
              onRecharge: () => _showRechargeDialog(context),
            ),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            AgentAccountTable(
              agents: agents,
              onView: (agent) => _onViewAgent(agent),
              onRefresh: (agent) => ref.invalidate(agentAccountsProvider),
              onEdit: (agent) => _onEditAgent(agent),
              onDelete: (agent) => _onDeleteAgent(agent),
            ),
          ],
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (e, s) => ErrorDisplayWidget(error: e),
    );
  }

  Widget _buildAgenciesList(AsyncValue<List<Enterprise>> agenciesAsync, WidgetRef ref) {
    return agenciesAsync.when(
      data: (agencies) => ElyfCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentsListHeader(
              agentCount: agencies.length,
              title: 'Liste des Agences (POS)',
              onAddAgent: () => _showAddDialog(),
              onRecharge: () => _showRechargeDialog(context),
            ),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            AgenciesTable(
              agencies: agencies,
              onView: (agency) => _onViewAgency(agency),
              onRefresh: (agency) => ref.invalidate(agentAgenciesProvider),
              onEdit: (agency) => _onEditAgency(agency),
              onDelete: (agency) => _onDeleteAgency(agency),
            ),
          ],
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (e, s) => ErrorDisplayWidget(error: e),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        AgentsFilters(
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          sortBy: _sortBy,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          onStatusChanged: (v) => setState(() => _statusFilter = v),
          onSortChanged: (v) => setState(() => _sortBy = v),
          onReset: () => setState(() { _searchQuery = ''; _statusFilter = null; _sortBy = null; }),
        ),
        const SizedBox(height: 16),
        AgentsSortButton(
          onPressed: () {
            setState(() {
              if (_sortBy == null) _sortBy = 'name';
              else if (_sortBy == 'name') _sortBy = 'liquidity';
              else _sortBy = null;
            });
          },
        ),
      ],
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      AgentsDialogs.showAgentAccountDialog(
        context,
        ref,
        null, // new agent
        widget.enterpriseId,
        () => ref.invalidate(agentAccountsProvider),
      );
    } else {
      _showAgencyDialog(context, null);
    }
  }

  void _showAgencyDialog(BuildContext context, Enterprise? agency) {
    AgentsDialogs.showAgentDialog(
      context,
      ref,
      agency,
      widget.enterpriseId,
      _searchQuery,
      () => ref.invalidate(agentAgenciesProvider),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    AgentsDialogs.showRechargeDialog(
      context,
      ref,
      widget.enterpriseId,
      _searchQuery,
      () {
        ref.invalidate(agentAccountsProvider);
        ref.invalidate(agentAgenciesProvider);
      },
    );
  }

  void _onViewAgent(Agent agent) {
    NotificationService.showInfo(context, 'Détails de l\'agent SIM ${agent.name}');
  }

  void _onEditAgent(Agent agent) {
    AgentsDialogs.showAgentAccountDialog(
      context,
      ref,
      agent,
      widget.enterpriseId,
      () => ref.invalidate(agentAccountsProvider),
    );
  }

  Future<void> _onDeleteAgent(Agent agent) async {
    final confirmed = await AgentsDialogs.showDeleteDialog(context, agent.name);
    if (confirmed == true && mounted) {
      final controller = ref.read(agentsControllerProvider);
      await controller.deleteAgent(agent.id);
      ref.invalidate(agentAccountsProvider);
    }
  }

  void _onViewAgency(Enterprise agency) {
    NotificationService.showInfo(context, 'Détails de l\'agence ${agency.name}');
  }

  void _onEditAgency(Enterprise agency) {
    _showAgencyDialog(context, agency);
  }

  Future<void> _onDeleteAgency(Enterprise agency) async {
    final confirmed = await AgentsDialogs.showDeleteDialog(context, agency.name);
    if (confirmed == true && mounted) {
      final controller = ref.read(agentsControllerProvider);
      await controller.deleteAgency(agency.id);
      ref.invalidate(agentAgenciesProvider);
    }
  }
}
