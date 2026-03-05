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
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_search_field.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_kpi_cards.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agent_network_card.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

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
  String _historyFilter = 'TOUTES';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    _tabController = TabController(length: 4, vsync: this);
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: _buildStatisticsSection(statsAsync),
          ),
        ),
        
        // 2. Filtres & Recherche
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ElyfCard(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(AppSpacing.sm),
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
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _tabController.index == 0 
                              ? 'COMPTES AGENTS (SIM)' 
                              : _tabController.index == 1 
                                  ? 'AGENCES'
                                  : _tabController.index == 2
                                      ? 'HISTORIQUE DES RECHARGES'
                                      : 'CLASSEMENT DES AGENTS',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontFamily: 'Outfit',
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    if (_tabController.index == 0)
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
                  const Divider(height: AppSpacing.lg),
                  _buildFilters(),
                ],
              ),
            ),
          ),
        ),

        // 3. Liste Grosse (Grid)
        _buildListSection(ref),
        
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Widget _buildStatisticsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => AgentsKpiCards(stats: stats),
      loading: () => const LoadingIndicator(height: 100),
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
      tabs: const [
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
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.leaderboard_rounded, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text('Classement'),
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
    } else if (tabIndex == 2) {
      // Use activeEnterpriseId so we always match the ID stored in TreasuryOperation records.
      final activeEnterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
      final historyKey = '${widget.enterpriseId ?? activeEnterpriseId}|${_startDate.millisecondsSinceEpoch}|${_endDate.millisecondsSinceEpoch}';
      final historyAsync = ref.watch(
        allAgentRechargesProvider(historyKey),
      );
      return _buildHistoryList(historyAsync);
    } else {
      final activeEnterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
      final rankingKey = '${widget.enterpriseId ?? activeEnterpriseId}|$_searchQuery|${_startDate.millisecondsSinceEpoch}|${_endDate.millisecondsSinceEpoch}';
      return _buildRankingTab(rankingKey);
    }
  }

  Widget _buildHistoryList(AsyncValue<List<TreasuryOperation>> historyAsync) {
    return historyAsync.when(
      data: (ops) {
        final filteredOps = ops.where((op) {
          final isRechargeStr = op.reason?.toLowerCase().contains('recharge') == true ||
                                op.reason?.toLowerCase().contains('dépôt') == true ||
                                op.reason?.toLowerCase().contains('depot') == true;
          final isRetraitStr = op.reason?.toLowerCase().contains('retrait') == true;
          
          final actuallyIsRecharge = isRechargeStr || (!isRetraitStr && op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney);
          final actuallyIsRetrait = isRetraitStr || (!isRechargeStr && op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash);
          
          if (_historyFilter == 'RECHARGE' && !actuallyIsRecharge) return false;
          if (_historyFilter == 'RETRAIT' && !actuallyIsRetrait) return false;
          
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final reason = op.reason?.toLowerCase() ?? '';
            if (!reason.contains(query)) return false;
          }
          return true;
        }).toList();

        return filteredOps.isEmpty
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Aucun historique trouvé pour ce filtre')),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _HistoryTile(operation: filteredOps[index]),
                    childCount: filteredOps.length,
                  ),
                ),
              );
      },
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
            (context, index) {
              final agent = agents[index];
              return Consumer(
                builder: (context, ref, _) {
                  final statsKey = '${agent.id}|${_startDate.millisecondsSinceEpoch}|${_endDate.millisecondsSinceEpoch}';
                  final stats = ref.watch(agentStatisticsProvider(statsKey));
                  return AgentNetworkCard(
                    agent: agent,
                    stats: stats,
                    onView: () => _onViewAgent(agent),
                    onEdit: () => _onEditAgent(agent),
                    onDelete: () => _onDeleteAgent(agent),
                    onRecharge: () => _showRechargeDialog(context),
                  );
                },
              );
            },
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
    final theme = Theme.of(context);
    final isHistoryTab = _tabController.index == 2;
    final isRankingTab = _tabController.index == 3;

    if (isHistoryTab || isRankingTab) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width < 600 ? double.infinity : 300,
            child: AgentsSearchField(onChanged: (value) => setState(() => _searchQuery = value)),
          ),
          if (isHistoryTab)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'TOUTES', label: Text('Toutes')),
                  ButtonSegment(value: 'RECHARGE', label: Text('Dépôts')),
                  ButtonSegment(value: 'RETRAIT', label: Text('Retraits')),
                ],
                selected: {_historyFilter},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _historyFilter = newSelection.first;
                  });
                },
              ),
            ),
          
          // Date Range Picker Button
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _searchQuery = '';
                _historyFilter = 'TOUTES';
                final now = DateTime.now();
                _startDate = DateTime(now.year, now.month, now.day);
                _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
              }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réinitialiser'),
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                foregroundColor: theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AgentsFilters(
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      sortBy: _sortBy,
      startDate: _startDate,
      endDate: _endDate,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      onStatusChanged: (value) => setState(() => _statusFilter = value),
      onSortChanged: (value) => setState(() => _sortBy = value),
      onDateRangeSelected: _selectDateRange,
      onReset: () => setState(() {
        _searchQuery = '';
        _statusFilter = null;
        _sortBy = null;
        final now = DateTime.now();
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      }),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
      });
    }
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

  Widget _buildRankingTab(String key) {
    final rankingAsync = ref.watch(agentPerformanceRankingProvider(key));
    return rankingAsync.when(
      data: (ranking) {
        if (ranking.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Aucun agent pour le classement')),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = ranking[index];
                return _RankingTile(
                  rank: index + 1,
                  agent: entry['agent'] as Agent,
                  totalVolume: entry['totalVolume'] as int,
                  deposits: entry['deposits'] as int,
                  withdrawals: entry['withdrawals'] as int,
                  count: entry['count'] as int,
                );
              },
              childCount: ranking.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (e, s) => SliverToBoxAdapter(child: ErrorDisplayWidget(error: e)),
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
    
    final isRechargeStr = operation.reason?.toLowerCase().contains('recharge') == true ||
                       operation.reason?.toLowerCase().contains('dépôt') == true ||
                       operation.reason?.toLowerCase().contains('depot') == true;
    final isRetraitStr = operation.reason?.toLowerCase().contains('retrait') == true;
    
    final actuallyIsRecharge = isRechargeStr || (!isRetraitStr && operation.fromAccount == PaymentMethod.cash && operation.toAccount == PaymentMethod.mobileMoney);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (actuallyIsRecharge ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            actuallyIsRecharge ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: actuallyIsRecharge ? Colors.blue : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          operation.reason ?? (actuallyIsRecharge ? 'Recharge (Dépôt) Agent' : 'Retrait Agent'),
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(operation.date),
          style: theme.textTheme.labelSmall,
        ),
        trailing: Text(
          '${actuallyIsRecharge ? "+" : "-"}${fmt.format(operation.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: actuallyIsRecharge ? Colors.blue : Colors.orange,
          ),
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final Agent agent;
  final int totalVolume;
  final int deposits;
  final int withdrawals;
  final int count;

  const _RankingTile({
    required this.rank,
    required this.agent,
    required this.totalVolume,
    required this.deposits,
    required this.withdrawals,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;
    final rankColor = rank == 1 
        ? const Color(0xFFFFD700) 
        : rank == 2 
            ? const Color(0xFFC0C0C0) 
            : rank == 3 
                ? const Color(0xFFCD7F32) 
                : theme.colorScheme.outline.withValues(alpha: 0.2);

    return ElyfCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isTop3 ? rankColor : rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isTop3 ? Colors.white : theme.colorScheme.onSurface,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Agent Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Outfit',
                  ),
                ),
                Text(
                  'SIM: ${agent.simNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Performance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatFCFA(totalVolume),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  fontFamily: 'Outfit',
                ),
              ),
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '$count op.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

