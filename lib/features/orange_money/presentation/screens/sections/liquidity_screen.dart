import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/liquidity_checkpoint.dart';
import '../../widgets/liquidity_checkpoint_dialog.dart';
import '../../widgets/liquidity/liquidity_daily_activity_section.dart';
import '../../widgets/liquidity/liquidity_filters_card.dart';
import '../../widgets/liquidity/liquidity_checkpoints_list.dart';
import '../../widgets/liquidity/liquidity_empty_state.dart';
import '../../../../../shared/utils/currency_formatter.dart';

/// Screen for managing liquidity checkpoints.
class LiquidityScreen extends ConsumerStatefulWidget {
  const LiquidityScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<LiquidityScreen> createState() => _LiquidityScreenState();
}

class _LiquidityScreenState extends ConsumerState<LiquidityScreen> {
  int _selectedTab = 0; // 0 = Historique récent, 1 = Tous les pointages
  String? _selectedPeriodFilter;
  DateTime? _selectedDateFilter;

  @override
  Widget build(BuildContext context) {
    final enterpriseKey = widget.enterpriseId ?? '';
    final todayCheckpointAsync = ref.watch(todayLiquidityCheckpointProvider(enterpriseKey));
    
    // Pour l'historique récent (7 derniers jours)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final recentCheckpointsKey = '$enterpriseKey|${sevenDaysAgo.millisecondsSinceEpoch}|${today.millisecondsSinceEpoch}';
    final recentCheckpointsAsync = ref.watch(liquidityCheckpointsProvider(recentCheckpointsKey));
    
    // Pour tous les pointages
    final allCheckpointsKey = enterpriseKey.isEmpty ? '' : '$enterpriseKey||';
    final allCheckpointsAsync = ref.watch(liquidityCheckpointsProvider(allCheckpointsKey));

    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card: Suivi du jour
                _buildTodayTrackingCard(context, todayCheckpointAsync),
                const SizedBox(height: 16),
                // Tabs and History
                _buildHistorySection(
                  context,
                  _selectedTab == 0 ? recentCheckpointsAsync : allCheckpointsAsync,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTodayTrackingCard(
    BuildContext context,
    AsyncValue<LiquidityCheckpoint?> todayCheckpointAsync,
  ) {
    final today = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(today);

    // Récupérer les statistiques du jour
    final enterpriseKey = widget.enterpriseId ?? '';
    final todayMillis = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    final dailyStatsKey = '$enterpriseKey|$todayMillis';
    final dailyStatsAsync = ref.watch(dailyTransactionStatsProvider(dailyStatsKey));

    return Container(
      decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBEDBFF),
          width: 1.219,
        ),
      ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: Suivi du jour - Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF1C398E),
                ),
                const SizedBox(width: 8),
                Text(
                  'Suivi du jour - $formattedDate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF1C398E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Morning and Evening checkpoint cards
            todayCheckpointAsync.when(
              data: (checkpoint) => _buildCheckpointCards(context, checkpoint),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildCheckpointCards(context, null),
            ),
          const SizedBox(height: 16),
          // Activité de la journée
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: todayCheckpointAsync.when(
              data: (checkpoint) => dailyStatsAsync.when(
                data: (stats) => LiquidityDailyActivitySection(
                  checkpoint: checkpoint,
                  stats: stats,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ),
        ],
      ),
    );
  }

  Widget _buildCheckpointCards(BuildContext context, LiquidityCheckpoint? checkpoint) {
    return Row(
      children: [
        Expanded(
          child: _buildCheckpointCard(
            context,
            title: 'Pointage Matin',
            icon: Icons.wb_sunny,
            iconColor: const Color(0xFFF54900),
            hasCheckpoint: checkpoint?.hasMorningCheckpoint ?? false,
            cashAmount: checkpoint?.morningCashAmount,
            simAmount: checkpoint?.morningSimAmount,
            onPressed: () => _showCheckpointDialog(context, LiquidityCheckpointType.morning, checkpoint),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCheckpointCard(
            context,
            title: 'Pointage Soir',
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF7C3AED),
            hasCheckpoint: checkpoint?.hasEveningCheckpoint ?? false,
            cashAmount: checkpoint?.eveningCashAmount,
            simAmount: checkpoint?.eveningSimAmount,
            onPressed: () => _showCheckpointDialog(context, LiquidityCheckpointType.evening, checkpoint),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool hasCheckpoint,
    int? cashAmount,
    int? simAmount,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
      color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF101828),
                  ),
                ),
              if (hasCheckpoint) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 1.219,
                    ),
                  ),
                  child: const Text(
                    '✓ Fait',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF016630),
                    ),
                  ),
                ),
              ],
              ],
            ),
            const SizedBox(height: 12),
          if (hasCheckpoint && (cashAmount != null || simAmount != null))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cashAmount != null) ...[
                  const Text(
                    '💵 Cash disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5565),
                    ),
                  ),
                  const SizedBox(height: 4),
              Text(
                    CurrencyFormatter.formatFCFA(cashAmount),
                style: const TextStyle(
                  fontSize: 20,
                      fontWeight: FontWeight.normal,
                  color: Color(0xFF101828),
                ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (simAmount != null) ...[
                  const Text(
                    '📱 Solde SIM',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5565),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatFCFA(simAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF155DFC),
                    ),
                  ),
                ],
              ],
              )
            else
              Column(
                children: [
                  const Text(
                    'Aucun pointage effectué',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6A7282),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                      backgroundColor: title.contains('Matin')
                          ? const Color(0xFFF54900)
                          : const Color(0xFF4F39F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Faire le pointage',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
      ),
    );
  }


  Widget _buildHistorySection(
    BuildContext context,
    AsyncValue<List<LiquidityCheckpoint>> checkpointsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFECECF0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(2.99),
                    height: 29.428,
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: _selectedTab == 0
                          ? Border.all(color: Colors.transparent, width: 1.219)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Historique récent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(2.99),
                    height: 29.428,
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: _selectedTab == 1
                          ? Border.all(color: Colors.transparent, width: 1.219)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Tous les pointages',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // History content
        Container(
          decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.219,
            ),
          ),
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                _selectedTab == 0 ? '7 derniers jours' : 'Tous les pointages (${checkpointsAsync.value?.length ?? 0})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 24),
              // Filtres (seulement pour "Tous les pointages")
              if (_selectedTab == 1) ...[
                LiquidityFiltersCard(
                  selectedPeriodFilter: _selectedPeriodFilter,
                  selectedDateFilter: _selectedDateFilter,
                  onPeriodFilterTap: _showPeriodFilterDialog,
                  onDateFilterTap: () => _selectDateFilter(context),
                  onResetFilters: () {
                    setState(() {
                      _selectedPeriodFilter = null;
                      _selectedDateFilter = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
                checkpointsAsync.when(
                  data: (checkpoints) {
                  final filteredCheckpoints = _applyFilters(checkpoints);
                  if (filteredCheckpoints.isEmpty) {
                    return LiquidityEmptyState(isRecent: _selectedTab == 0);
                    }
                  return LiquidityCheckpointsList(
                    checkpoints: filteredCheckpoints,
                  );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  ),
                ),
              ],
            ),
        ),
      ],
    );
  }


  List<LiquidityCheckpoint> _applyFilters(List<LiquidityCheckpoint> checkpoints) {
    var filtered = checkpoints;
    
    if (_selectedPeriodFilter != null) {
      final period = _selectedPeriodFilter == 'Matin'
          ? LiquidityCheckpointType.morning
          : LiquidityCheckpointType.evening;
      filtered = filtered.where((cp) => cp.type == period).toList();
    }
    
    if (_selectedDateFilter != null) {
      final filterDate = DateTime(
        _selectedDateFilter!.year,
        _selectedDateFilter!.month,
        _selectedDateFilter!.day,
      );
      filtered = filtered.where((cp) {
        final cpDate = DateTime(cp.date.year, cp.date.month, cp.date.day);
        return cpDate.isAtSameMomentAs(filterDate);
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _selectDateFilter(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateFilter = picked;
      });
    }
  }

  void _showPeriodFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner la période'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toutes les périodes'),
              onTap: () {
                setState(() {
                  _selectedPeriodFilter = null;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Matin'),
              onTap: () {
                setState(() {
                  _selectedPeriodFilter = 'Matin';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Soir'),
              onTap: () {
                setState(() {
                  _selectedPeriodFilter = 'Soir';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckpointDialog(
    BuildContext context,
    LiquidityCheckpointType type,
    LiquidityCheckpoint? existingCheckpoint,
  ) async {
    final result = await showDialog<LiquidityCheckpoint>(
      context: context,
      builder: (context) => LiquidityCheckpointDialog(
        checkpoint: existingCheckpoint,
        enterpriseId: widget.enterpriseId,
        period: type,
              ),
    );

    if (result != null && mounted) {
                final controller = ref.read(liquidityControllerProvider);

                if (existingCheckpoint != null) {
        await controller.updateCheckpoint(result);
                } else {
        await controller.createCheckpoint(result);
                }

                  final enterpriseKey = widget.enterpriseId ?? '';
                  ref.invalidate(todayLiquidityCheckpointProvider(enterpriseKey));
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final sevenDaysAgo = today.subtract(const Duration(days: 7));
                  final recentCheckpointsKey = '$enterpriseKey|${sevenDaysAgo.millisecondsSinceEpoch}|${today.millisecondsSinceEpoch}';
                  final allCheckpointsKey = enterpriseKey.isEmpty ? '' : '$enterpriseKey||';
                  ref.invalidate(liquidityCheckpointsProvider(recentCheckpointsKey));
                  ref.invalidate(liquidityCheckpointsProvider(allCheckpointsKey));
    }
  }
}

