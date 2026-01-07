import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../widgets/kpi_card.dart';
import '../../../../shared.dart';

/// Enhanced reports screen with period selector and detailed statistics.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to today
    _startDate = DateTime.now();
    _endDate = DateTime.now();
  }

  void _setToday() {
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
  }

  void _setSevenDays() {
    setState(() {
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(const Duration(days: 7));
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsKey = '${_startDate?.millisecondsSinceEpoch ?? ''}|${_endDate?.millisecondsSinceEpoch ?? ''}';
    final statsAsync = ref.watch(reportsStatisticsProvider(statsKey));

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
                  _buildPeriodSelectorCard(),
                  const SizedBox(height: 16),
                  statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        _buildKpiCards(stats),
                        const SizedBox(height: 16),
                        _buildNetBalanceCard(stats),
                        const SizedBox(height: 16),
                        _buildDailyDetailCard(context),
                      ],
                    ),
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

  Widget _buildPeriodSelectorCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');

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
        padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Période de rapport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Date de début',
                    date: _startDate,
                    onTap: () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Date de fin',
                    date: _endDate,
                    onTap: () => _selectEndDate(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActions(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent, width: 1.219),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date) : '',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF717182),
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
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _setToday,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.219,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1.219),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Aujourd\'hui',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _setSevenDays,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.219,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1.219),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '7 jours',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> stats) {
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final totalTransactions = stats['totalTransactions'] as int? ?? 0;
    final totalCommission = stats['totalCommission'] as int? ?? 0;

    // Calculer les compteurs (à adapter selon la source de données)
    final depositsCount = stats['depositsCount'] as int? ?? 0;
    final withdrawalsCount = stats['withdrawalsCount'] as int? ?? 0;

    return Row(
      children: [
        _buildReportKpiCard(
          icon: Icons.trending_up,
          iconColor: const Color(0xFF155DFC),
          label: 'Total transactions',
          value: totalTransactions.toString(),
          valueStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(width: 16),
        _buildReportKpiCard(
          icon: Icons.arrow_downward,
          iconColor: const Color(0xFF00A63E),
          label: 'Dépôts',
          value: depositsCount.toString(),
          valueStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Color(0xFF00A63E),
          ),
          subtitle: _formatCurrency(cashInTotal),
        ),
        const SizedBox(width: 16),
        _buildReportKpiCard(
          icon: Icons.arrow_upward,
          iconColor: const Color(0xFFE7000B),
          label: 'Retraits',
          value: withdrawalsCount.toString(),
          valueStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Color(0xFFE7000B),
          ),
          subtitle: _formatCurrency(cashOutTotal),
        ),
        const SizedBox(width: 16),
        _buildReportKpiCard(
          icon: Icons.attach_money,
          iconColor: const Color(0xFFF54900),
          label: 'Commissions',
          value: _formatCurrency(totalCommission),
          valueStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Color(0xFFF54900),
          ),
        ),
      ],
    );
  }

  Widget _buildReportKpiCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required TextStyle valueStyle,
    String? subtitle,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.219,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5565),
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: valueStyle,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5565),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(Map<String, dynamic> stats) {
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final netBalance = cashInTotal - cashOutTotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(
          color: const Color(0xFFB9F8CF),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          children: [
            const Text(
              'Solde net de la période',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF4A5565),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${netBalance >= 0 ? '+' : ''}${_formatCurrency(netBalance)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.normal,
                color: Color(0xFF00A63E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dépôts - Retraits = ${_formatCurrency(cashInTotal)} - ${_formatCurrency(cashOutTotal)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyDetailCard(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Détail par jour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Export to PDF
                    NotificationService.showInfo(context, 'Export PDF - À implémenter');
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Exporter (PDF)'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1.219,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.description,
                      size: 48,
                      color: const Color(0xFF6A7282).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune transaction dans cette période',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF6A7282),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }
}
