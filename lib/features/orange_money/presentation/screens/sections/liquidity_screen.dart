import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/liquidity_checkpoint.dart';
import '../../widgets/liquidity_checkpoint_dialog.dart';
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
                data: (stats) => _buildDailyActivitySection(checkpoint, stats),
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

  Widget _buildDailyActivitySection(
    LiquidityCheckpoint? checkpoint,
    Map<String, dynamic> stats,
  ) {
    final deposits = stats['deposits'] as int? ?? 0;
    final withdrawals = stats['withdrawals'] as int? ?? 0;
    final transactionCount = stats['transactionCount'] as int? ?? 0;
    
    final morningCash = checkpoint?.morningCashAmount ?? 0;
    final morningSim = checkpoint?.morningSimAmount ?? 0;

    String _formatWithCommas(int amount) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    return Column(
      children: [
        // Activité de la journée
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Activité de la journée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 12),
              Row(
          children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dépôts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        const SizedBox(height: 4),
            Text(
                          '+${_formatWithCommas(deposits)} F',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF00A63E),
                          ),
            ),
          ],
        ),
      ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Retraits',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${_formatWithCommas(withdrawals)} F',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFFE7000B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transactionCount.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Valeurs théoriques
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFBEDBFF),
                    width: 1.219,
                  ),
                ),
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Valeurs théoriques en fin de journée',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1C398E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cash théorique',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1447E6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatWithCommas(morningCash + deposits - withdrawals)} F',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1C398E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '= ${_formatWithCommas(morningCash)} + ${_formatWithCommas(deposits)} - ${_formatWithCommas(withdrawals)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF155DFC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Solde SIM théorique',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1447E6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatWithCommas(morningSim - deposits + withdrawals)} F',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1C398E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '= ${_formatWithCommas(morningSim)} - ${_formatWithCommas(deposits)} + ${_formatWithCommas(withdrawals)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF155DFC),
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
            ],
          ),
        ),
      ],
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
                _buildFiltersCard(),
                const SizedBox(height: 16),
              ],
                checkpointsAsync.when(
                  data: (checkpoints) {
                  final filteredCheckpoints = _applyFilters(checkpoints);
                  if (filteredCheckpoints.isEmpty) {
                    return _buildEmptyState(_selectedTab == 0);
                    }
                  return _buildCheckpointsList(filteredCheckpoints);
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

  Widget _buildFiltersCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF0A0A0A)),
                    const SizedBox(width: 8),
                    const Text(
                      'Période',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
          ),
        ),
      ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showPeriodFilterDialog(),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1.219,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedPeriodFilter ?? 'Toutes les périodes',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Color(0xFF0A0A0A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0A0A0A)),
                    const SizedBox(width: 8),
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateFilter(context),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1.219,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDateFilter != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedDateFilter!)
                                : '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF717182),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedPeriodFilter = null;
                    _selectedDateFilter = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFE5E5E5),
                    width: 1.219,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                child: const Text(
                  'Réinitialiser filtres',
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

  Widget _buildEmptyState(bool isRecent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Color(0xFF6A7282),
            ),
            const SizedBox(height: 16),
            Text(
              isRecent ? 'Aucun pointage enregistré' : 'Aucun pointage trouvé',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6A7282),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRecent
                  ? 'Commencez par faire votre pointage du matin'
                  : 'Essayez de modifier vos critères de recherche',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6A7282),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointsList(List<LiquidityCheckpoint> checkpoints) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    String _formatWithCommas(int amount) {
      return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    return Column(
      children: checkpoints.map((checkpoint) {
        final hasMorning = checkpoint.hasMorningCheckpoint;
        final hasEvening = checkpoint.hasEveningCheckpoint;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.219,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(checkpoint.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF101828),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMorning)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.transparent,
                              width: 1.219,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wb_sunny,
                                size: 12,
                                color: Color(0xFF9F2D00),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Matin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9F2D00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasEvening)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.transparent,
                              width: 1.219,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.nightlight_round,
                                size: 12,
                                color: Color(0xFF6B21A8),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Soir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B21A8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (hasMorning || hasEvening) ...[
                const SizedBox(height: 12),
                // Section Matin
                if (hasMorning && (checkpoint.morningCashAmount != null || checkpoint.morningSimAmount != null))
                  _ExpansionPeriodCard(
                    title: '🌅 MATIN',
                    backgroundColor: const Color(0xFFFFF7ED),
                    titleColor: const Color(0xFFCA3500),
                    totalColor: const Color(0xFFCA3500),
                    cashAmount: checkpoint.morningCashAmount ?? 0,
                    simAmount: checkpoint.morningSimAmount ?? 0,
                    formatWithCommas: _formatWithCommas,
                  ),
                if (hasMorning && hasEvening) const SizedBox(height: 12),
                // Section Soir
                if (hasEvening && (checkpoint.eveningCashAmount != null || checkpoint.eveningSimAmount != null))
                  _ExpansionPeriodCard(
                    title: '🌙 SOIR',
                    backgroundColor: const Color(0xFFF5F3FF),
                    titleColor: const Color(0xFF7C3AED),
                    totalColor: const Color(0xFF7C3AED),
                    cashAmount: checkpoint.eveningCashAmount ?? 0,
                    simAmount: checkpoint.eveningSimAmount ?? 0,
                    formatWithCommas: _formatWithCommas,
                  ),
                // Section Écarts (si matin et soir sont présents)
                if (hasMorning && hasEvening) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 1.219,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 ÉCARTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cash:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4A5565),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final morningCash = checkpoint.morningCashAmount ?? 0;
                                  final eveningCash = checkpoint.eveningCashAmount ?? 0;
                                  final diff = eveningCash - morningCash;
                                  final isPositive = diff >= 0;
                                  return Text(
                                    '${isPositive ? '+' : ''}${_formatWithCommas(diff)} F',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SIM:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4A5565),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final morningSim = checkpoint.morningSimAmount ?? 0;
                                  final eveningSim = checkpoint.eveningSimAmount ?? 0;
                                  final diff = eveningSim - morningSim;
                                  final isPositive = diff >= 0;
                                  return Text(
                                    '${isPositive ? '+' : ''}${_formatWithCommas(diff)} F',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(
                            height: 20,
                            thickness: 1.219,
                            color: Color(0xFFE5E5E5),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final morningTotal = (checkpoint.morningCashAmount ?? 0) + (checkpoint.morningSimAmount ?? 0);
                                  final eveningTotal = (checkpoint.eveningCashAmount ?? 0) + (checkpoint.eveningSimAmount ?? 0);
                                  final diff = eveningTotal - morningTotal;
                                  final isPositive = diff >= 0;
                                  return Text(
                                    '${isPositive ? '+' : ''}${_formatWithCommas(diff)} F',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
          ),
        );
      }).toList(),
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

/// Widget pour afficher une période (matin/soir) avec expansion/réduction
class _ExpansionPeriodCard extends StatefulWidget {
  const _ExpansionPeriodCard({
    required this.title,
    required this.backgroundColor,
    required this.titleColor,
    required this.totalColor,
    required this.cashAmount,
    required this.simAmount,
    required this.formatWithCommas,
  });

  final String title;
  final Color backgroundColor;
  final Color titleColor;
  final Color totalColor;
  final int cashAmount;
  final int simAmount;
  final String Function(int) formatWithCommas;

  @override
  State<_ExpansionPeriodCard> createState() => _ExpansionPeriodCardState();
}

class _ExpansionPeriodCardState extends State<_ExpansionPeriodCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.cashAmount + widget.simAmount;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header avec titre et bouton expand
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.titleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.formatWithCommas(total)} F',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.totalColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: widget.titleColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Contenu détaillé (affiché si expanded)
          if (_isExpanded) ...[
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE5E5E5),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cash:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5565),
          ),
                      ),
                      Text(
                        '${widget.formatWithCommas(widget.cashAmount)} F',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SIM:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                      Text(
                        '${widget.formatWithCommas(widget.simAmount)} F',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE5E5E5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                      Text(
                        '${widget.formatWithCommas(total)} F',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.totalColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
