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
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agent_network_card.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/orange_money_header.dart';

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
    return CustomScrollView(
      slivers: [
        ElyfModuleHeader(
          title: "Réseau d'Agents",
          subtitle: 'Gérez vos comptes agents (SIM) et agences physiques.',
          module: EnterpriseModule.mobileMoney,
          bottom: _buildTabsSection(),
        ),
        
        // 1. Statistiques
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _buildStatisticsSection(statsAsync),
          ),
        ),
        
        // 2. Filtres & Recherche
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElyfCard(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                   Row(
                    children: [
                      Icon(
                        _tabController.index == 0 ? Icons.person_pin_rounded : Icons.business_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _tabController.index == 0 ? 'COMPTES AGENTS (SIM)' : 'AGENCES & POINTS DE VENTE',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Ajouter',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildFilters(),
                ],
              ),
            ),
          ),
        ),

        // 3. Liste Grosse (Grid)
        _buildListSection(ref),
        
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
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
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      tabs: const [
        Tab(
          child: Row(
            children: [
              Icon(Icons.sim_card_outlined, size: 16),
              SizedBox(width: 8),
              Text('Agents (Comptes SIM)'),
            ],
          ),
        ),
        Tab(
          child: Row(
            children: [
              Icon(Icons.business_outlined, size: 16),
              SizedBox(width: 8),
              Text('Agences (PDV Physique)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(WidgetRef ref) {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      final agentsAsync = ref.watch(
        agentAccountsProvider('${widget.enterpriseId ?? ''}||$_searchQuery'),
      );
      return _buildAgentsGrid(agentsAsync, ref);
    } else {
      final agenciesAsync = ref.watch(
        agentAgenciesProvider('${widget.enterpriseId ?? ''}||$_searchQuery'),
      );
      return _buildAgenciesGrid(agenciesAsync, ref);
    }
  }

  Widget _buildAgentsGrid(AsyncValue<List<Agent>> agentsAsync, WidgetRef ref) {
    return agentsAsync.when(
      data: (agents) => SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 230,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => AgentNetworkCard(
              agent: agents[index],
              onView: () => _onViewAgent(agents[index]),
              onEdit: () => _onEditAgent(agents[index]),
              onDelete: () => _onDeleteAgent(agents[index]),
              onRecharge: () => _showRechargeDialog(context),
            ),
            childCount: agents.length,
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (e, s) => SliverToBoxAdapter(child: ErrorDisplayWidget(error: e)),
    );
  }

  Widget _buildAgenciesGrid(AsyncValue<List<Enterprise>> agenciesAsync, WidgetRef ref) {
    return agenciesAsync.when(
      data: (agencies) => SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 180, // Augmenté pour éviter l'overflow
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => AgentNetworkCard(
              agency: agencies[index],
              onView: () => _onViewAgency(agencies[index]),
              onEdit: () => _onEditAgency(agencies[index]),
              onDelete: () => _onDeleteAgency(agencies[index]),
              onRecharge: () => _showRechargeDialog(context),
            ),
            childCount: agencies.length,
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (e, s) => SliverToBoxAdapter(child: ErrorDisplayWidget(error: e)),
    );
  }

  Widget _buildFilters() {
    return AgentsFilters(
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      sortBy: _sortBy,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      onStatusChanged: (value) => setState(() => _statusFilter = value),
      onSortChanged: (value) => setState(() => _sortBy = value),
      onReset: () => setState(() {
        _searchQuery = '';
        _statusFilter = null;
        _sortBy = null;
      }),
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      AgentsDialogs.showAgentAccountDialog(
        context,
        ref,
        null,
        widget.enterpriseId,
        false,
        () => ref.invalidate(agentAccountsProvider),
      );
    } else {
      AgentsDialogs.showAgentDialog(
        context,
        ref,
        null,
        widget.enterpriseId,
        _searchQuery,
        false,
        () => ref.invalidate(agentAgenciesProvider),
      );
    }
  }

  void _onViewAgent(Agent agent) {
    AgentsDialogs.showAgentAccountDialog(
      context,
      ref,
      agent,
      widget.enterpriseId,
      true,
      () {},
    );
  }

  void _onEditAgent(Agent agent) {
    AgentsDialogs.showAgentAccountDialog(
      context,
      ref,
      agent,
      widget.enterpriseId,
      false,
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
    _showAgencyDialog(context, agency, isReadOnly: true);
  }

  void _onEditAgency(Enterprise agency) {
    _showAgencyDialog(context, agency, isReadOnly: false);
  }

  void _showAgencyDialog(BuildContext context, Enterprise? agency, {bool isReadOnly = false}) {
    AgentsDialogs.showAgentDialog(
      context,
      ref,
      agency,
      widget.enterpriseId,
      _searchQuery,
      isReadOnly,
      () => ref.invalidate(agentAgenciesProvider),
    );
  }

  Future<void> _onDeleteAgency(Enterprise agency) async {
    final confirmed = await AgentsDialogs.showDeleteDialog(context, agency.name);
    if (confirmed == true && mounted) {
      final controller = ref.read(agentsControllerProvider);
      await controller.deleteAgency(agency.id);
      ref.invalidate(agentAgenciesProvider);
    }
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
}
