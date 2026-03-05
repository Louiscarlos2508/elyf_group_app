import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../widgets/reports/report_kpi_cards.dart';
import '../../widgets/reports/report_net_balance_card.dart';
import '../../widgets/reports/report_period_selector.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart' as tokens;
import '../../widgets/reports/report_performance_chart.dart';

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

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0); // Last day of previous month
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsKey =
        '${_startDate?.millisecondsSinceEpoch ?? ''}|${_endDate?.millisecondsSinceEpoch ?? ''}';
    final theme = Theme.of(context);
    final statsAsync = ref.watch(reportsStatisticsProvider(statsKey));

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          ElyfModuleHeader(
            title: 'Analytique Performance',
            subtitle: "Visualisez vos performances historiques et exportez vos données d'activité.",
            module: EnterpriseModule.mobileMoney,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: tokens.AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportPeriodSelector(
                    startDate: _startDate,
                    endDate: _endDate,
                    onStartDateSelected: () => _selectStartDate(context),
                    onEndDateSelected: () => _selectEndDate(context),
                    onTodaySelected: _setToday,
                    onSevenDaysSelected: _setSevenDays,
                    onThisMonthSelected: _setThisMonth,
                    onLastMonthSelected: _setLastMonth,
                  ),
                  const SizedBox(height: tokens.AppSpacing.lg),
                  statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        ReportPerformanceChart(stats: stats),
                        const SizedBox(height: tokens.AppSpacing.md),
                        ReportKpiCards(stats: stats),
                        const SizedBox(height: tokens.AppSpacing.md),
                        ReportNetBalanceCard(stats: stats),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(tokens.AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) =>
                        Center(child: Text('Erreur: $error')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
