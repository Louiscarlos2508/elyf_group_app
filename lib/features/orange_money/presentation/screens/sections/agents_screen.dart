import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/app_radius.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' show Agent, AgentStatus;
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_dialogs.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_filters.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_kpi_cards.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agent_network_card.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    // Use activeEnterpriseProvider to get the real enterprise ID — ensures
    // it matches what is stored in TreasuryOperation records created by the controller.
    final activeEnterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
    final statsKey = widget.enterpriseId ?? activeEnterpriseId;
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
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: _buildStatisticsSection(statsAsync),
          ),
        ),
        
        // 2. Filtres & Recherche
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ElyfCard(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                   Row(
                    children: [
                      Icon(
                        _tabController.index == 0 
                            ? Icons.person_pin_rounded 
                            : _tabController.index == 1 
                                ? Icons.business_rounded 
                                : Icons.history_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _tabController.index == 0 
                              ? 'COMPTES AGENTS (SIM)' 
                              : _tabController.index == 1 
                                  ? 'AGENCES'
                                  : 'HISTORIQUE DES RECHARGES',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontFamily: 'Outfit',
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    if (_tabController.index != 2)
                      IconButton.filled(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Ajouter',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ],
                  ),
                  if (_tabController.index != 2) ...[
                    Divider(height: AppSpacing.lg),
                    _buildFilters(),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 3. Liste Grosse (Grid)
        _buildListSection(ref),
        
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Widget _buildStatisticsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => AgentsKpiCards(stats: stats),
      loading: () => LoadingIndicator(height: 100),
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
      unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
      ),
      unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.normal,
        fontFamily: 'Outfit',
      ),
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sim_card_outlined, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('Agents'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_outlined, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('Agences'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('Historique'),
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
    } else if (tabIndex == 1) {
      final agenciesAsync = ref.watch(
        agentAgenciesProvider('${widget.enterpriseId ?? ''}||$_searchQuery'),
      );
      return _buildAgenciesGrid(agenciesAsync, ref);
    } else {
      // Use activeEnterpriseId so we always match the ID stored in TreasuryOperation records.
      final activeEnterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
      final historyAsync = ref.watch(
        allAgentRechargesProvider(widget.enterpriseId ?? activeEnterpriseId),
      );
      return _buildHistoryList(historyAsync);
    }
  }

  Widget _buildHistoryList(AsyncValue<List<TreasuryOperation>> historyAsync) {
    return historyAsync.when(
      data: (ops) => ops.isEmpty
          ? const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Aucun historique de recharge trouvé')),
            )
          : SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _HistoryTile(operation: ops[index]),
                  childCount: ops.length,
                ),
              ),
            ),
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (e, s) => SliverToBoxAdapter(child: ErrorDisplayWidget(error: e)),
    );
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
        ref.invalidate(allAgentRechargesProvider);
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TreasuryOperation operation;

  const _HistoryTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');
    final isRecharge = operation.fromAccount == PaymentMethod.cash;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isRecharge ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRecharge ? Icons.add_rounded : Icons.remove_rounded,
            color: isRecharge ? Colors.blue : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          isRecharge ? 'Recharge Agent' : 'Retrait Agent',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(operation.date),
          style: theme.textTheme.labelSmall,
        ),
        trailing: Text(
          '${isRecharge ? "+" : "-"}${fmt.format(operation.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: isRecharge ? Colors.blue : Colors.orange,
          ),
        ),
      ),
    );
  }
}
