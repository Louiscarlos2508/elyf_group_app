import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/agent.dart';
import '../../widgets/agent_form_dialog.dart';
import '../../widgets/agent_recharge_dialog.dart' show AgentRechargeDialog, AgentTransactionType;
import '../../widgets/kpi_card.dart';

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
    
    final agentsAsync = ref.watch(agentsProvider(agentsKey));
    final statsAsync = ref.watch(agentsDailyStatisticsProvider(statsKey));

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
                  _buildHeader(context),
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
                                _buildLowLiquidityBanner(lowLiquidityAgents),
                                const SizedBox(height: 24),
                                statsAsync.when(
                                  data: (stats) => _buildKpiCards(stats),
                                  loading: () => const SizedBox(
                                    height: 140,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  error: (_, __) => const SizedBox(),
                                ),
                              ],
                            )
                          : statsAsync.when(
                              data: (stats) => _buildKpiCards(stats),
                              loading: () => const SizedBox(
                                height: 140,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (_, __) => const SizedBox(),
                            );
                    },
                    loading: () => statsAsync.when(
                      data: (stats) => _buildKpiCards(stats),
                      loading: () => const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                    error: (_, __) => statsAsync.when(
                      data: (stats) => _buildKpiCards(stats),
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '👥 Agents Affiliés',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFFF54900),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez vos agents affiliés et leurs transactions de recharge',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF4A5565),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Navigate to global history
          },
          icon: const Icon(Icons.history, size: 16),
          label: const Text(
            'Historique global',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 36),
            side: BorderSide(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.219,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLowLiquidityBanner(List<Agent> agents) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25.219, 17.219, 1.219, 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        border: Border.all(
          color: const Color(0xFFFFF085),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Color(0xFF894B00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ ${agents.length} agent(s) avec liquidité faible (< 50 000 F)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF894B00),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: agents.map((agent) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9.219,
                        vertical: 3.219,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFDC700),
                          width: 1.219,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${agent.name}: ${_formatCurrencyCompact(agent.liquidity)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFFA65F00),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> stats) {
    final recharges = stats['rechargesToday'] as int? ?? 0;
    final retraits = stats['withdrawalsToday'] as int? ?? 0;
    final alertes = stats['lowLiquidityAlerts'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: KpiCard(
            label: 'Recharges (jour)',
            value: '${_formatCurrencyCompact(recharges)}',
            icon: Icons.arrow_downward,
            valueColor: const Color(0xFF00A63E),
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFF00A63E),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'Retraits (jour)',
            value: '${_formatCurrencyCompact(retraits)}',
            icon: Icons.arrow_upward,
            valueColor: const Color(0xFFE7000B),
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFFE7000B),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'Alertes liquidité',
            value: alertes.toString(),
            icon: Icons.warning,
            valueColor: const Color(0xFFD08700),
            valueStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: Color(0xFFD08700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentsList(BuildContext context, List<Agent> agents) {
    final theme = Theme.of(context);
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
            _buildListHeader(context, agents.length),
            const SizedBox(height: 16),
            _buildFilters(context),
            const SizedBox(height: 16),
            _buildSortButton(context),
            const SizedBox(height: 16),
            _buildAgentsTable(context, agents, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Liste des agents ($count)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: () => _showAgentDialog(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Nouvel agent',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF54900),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: () => _showRechargeDialog(context),
            icon: const Icon(Icons.arrow_downward, size: 16),
            label: const Text(
              'Recharge / Retrait',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A63E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSearchField(context),
        ),
        const SizedBox(width: 16),
        _buildStatusFilter(context),
        const SizedBox(width: 16),
        _buildNameFilter(context),
        const SizedBox(width: 16),
        SizedBox(
          width: 210.586,
          height: 36,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _statusFilter = null;
                _sortBy = null;
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.219,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Réinitialiser',
              style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SizedBox(
      width: 210.586,
      height: 36,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher (nom, tél, SIM)...',
          hintStyle: const TextStyle(
            color: Color(0xFF717182),
            fontSize: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search, size: 16, color: Color(0xFF717182)),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          filled: true,
          fillColor: const Color(0xFFF3F3F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Container(
      width: 210.586,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent, width: 1.219),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AgentStatus?>(
          value: _statusFilter,
          hint: const Text(
            'Tous les statuts',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF0A0A0A)),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Tous les statuts', style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A))),
            ),
            ...AgentStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.label, style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A))),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _statusFilter = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildNameFilter(BuildContext context) {
    return Container(
      width: 210.586,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent, width: 1.219),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _sortBy,
          hint: const Text(
            'Nom',
            style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF0A0A0A)),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Nom', style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A))),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _sortBy = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextButton.icon(
        onPressed: () {
          // TODO: Toggle sort order
        },
        icon: const Icon(Icons.swap_vert, size: 16, color: Color(0xFF0A0A0A)),
        label: const Text(
          'Croissant',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentsTable(
    BuildContext context,
    List<Agent> agents,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1.219,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeader('Agent', 171.673),
                _buildTableHeader('Téléphone', 122.274),
                _buildTableHeader('N° SIM', 135.989),
                _buildTableHeader('Opérateur', 84.741),
                _buildTableHeader('Liquidité', 100.884, alignRight: false),
                _buildTableHeader('%Commission', 110.178, alignRight: true),
                _buildTableHeader('Statut', 62.246),
                _buildTableHeader('Actions', 185.92),
              ],
            ),
          ),
          // Table body
          if (agents.isEmpty)
            Container(
              height: 128,
              alignment: Alignment.center,
              child: Text(
                'Aucun agent trouvé',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6A7282),
                ),
              ),
            )
          else
            ...agents.map((agent) {
              return Container(
                height: 52.608,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1.219,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildAgentNameCell(agent),
                    _buildTableCell(agent.phoneNumber, 122.274),
                    _buildTableCell(agent.simNumber, 135.989),
                    _buildTableCell(_buildOperatorBadge(agent.operator), 84.741),
                    _buildTableCell(
                      _formatCurrency(agent.liquidity),
                      100.884,
                      alignRight: false,
                      color: agent.liquidity == 0 ? const Color(0xFFE7000B) : null,
                    ),
                    _buildTableCell(
                      '${agent.commissionRate}%',
                      110.178,
                      alignRight: true,
                    ),
                    _buildTableCell(
                      _buildStatusChip(agent.status),
                      62.246,
                    ),
                    _buildActionsCell(context, agent, 185.92),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, double width, {bool alignRight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(left: 8, top: 9),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF0A0A0A),
        ),
      ),
    );
  }

  Widget _buildAgentNameCell(Agent agent) {
    final isLowLiquidity = agent.isLowLiquidity(50000);
    final dateFormat = DateFormat('d/M/yyyy');
    final dateStr = agent.createdAt != null
        ? dateFormat.format(agent.createdAt!)
        : 'N/A';

    return SizedBox(
      width: 171.673,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8.61, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    agent.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isLowLiquidity)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: Color(0xFFFDC700),
                    ),
                  ),
              ],
            ),
            Text(
              'Depuis le $dateStr',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Color(0xFF6A7282),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(dynamic content, double width, {bool alignRight = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: content is Widget
              ? content
              : Text(
                  content.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? const Color(0xFF0A0A0A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }

  Widget _buildOperatorBadge(MobileOperator operator) {
    return Container(
      height: 22.438,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          operator.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCell(BuildContext context, Agent agent, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 10.61, right: 8, bottom: 10.61),
        child: Row(
          children: [
            _buildActionButton(
              icon: Icons.visibility,
              onPressed: () {
                // TODO: View agent details
              },
            ),
            const SizedBox(width: 4),
            _buildActionButton(
              icon: Icons.refresh,
              onPressed: () {
                // TODO: Refresh agent
              },
            ),
            const SizedBox(width: 4),
            _buildActionButton(
              icon: Icons.edit,
              onPressed: () => _showAgentDialog(context, agent),
            ),
            const SizedBox(width: 4),
            _buildActionButton(
              icon: Icons.close,
              color: Colors.red,
              onPressed: () => _deleteAgent(context, agent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      width: 38.437,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: color ?? const Color(0xFF0A0A0A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AgentStatus status) {
    final isActive = status == AgentStatus.active;
    return Container(
      height: 22.438,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF030213) : Colors.transparent,
        border: isActive
            ? Border.all(color: Colors.transparent, width: 1.219)
            : Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.219,
              ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          status.label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF6A7282),
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAgentDialog(BuildContext context, Agent? agent) {
    showDialog(
      context: context,
      builder: (context) => AgentFormDialog(
        agent: agent,
        onSave: (Agent savedAgent) async {
          final controller = ref.read(agentsControllerProvider);
          if (agent == null) {
            await controller.createAgent(savedAgent);
          } else {
            await controller.updateAgent(savedAgent);
          }
          if (mounted) {
            final agentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
            ref.invalidate(agentsProvider(agentsKey));
          }
        },
      ),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    final agentsKey = '${widget.enterpriseId ?? ''}||';
    final agentsAsync = ref.read(agentsProvider(agentsKey));
    
    agentsAsync.whenData((agents) {
      if (agents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun agent disponible')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) => AgentRechargeDialog(
          agents: agents,
          onConfirm: (agent, type, amount, notes) async {
            final controller = ref.read(agentsControllerProvider);
            await controller.updateAgentLiquidity(
              agent: agent,
              amount: amount,
              isRecharge: type == AgentTransactionType.recharge,
            );
            if (mounted) {
              final currentAgentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
              ref.invalidate(agentsProvider(currentAgentsKey));
              ref.invalidate(agentsDailyStatisticsProvider('${widget.enterpriseId ?? ''}'));
              
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      type == AgentTransactionType.recharge
                          ? 'Recharge de ${_formatCurrency(amount)} effectuée pour ${agent.name}'
                          : 'Retrait de ${_formatCurrency(amount)} effectué pour ${agent.name}',
                    ),
                  ),
                );
              }
            }
          },
        ),
      );
    });
  }

  Future<void> _deleteAgent(BuildContext context, Agent agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'agent'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${agent.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(agentsControllerProvider);
      await controller.deleteAgent(agent.id);
      if (mounted) {
        final agentsKey = '${widget.enterpriseId ?? ''}|${_statusFilter?.name ?? ''}|$_searchQuery';
        ref.invalidate(agentsProvider(agentsKey));
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  String _formatCurrencyCompact(int amount) {
    return '$amount F';
  }
}

