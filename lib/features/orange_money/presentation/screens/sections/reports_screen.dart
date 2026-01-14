import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../widgets/reports/report_daily_detail_card.dart';
import '../../widgets/reports/report_kpi_cards.dart';
import '../../widgets/reports/report_net_balance_card.dart';
import '../../widgets/reports/report_period_selector.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

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
    final statsKey =
        '${_startDate?.millisecondsSinceEpoch ?? ''}|${_endDate?.millisecondsSinceEpoch ?? ''}';
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
                  ReportPeriodSelector(
                    startDate: _startDate,
                    endDate: _endDate,
                    onStartDateSelected: () => _selectStartDate(context),
                    onEndDateSelected: () => _selectEndDate(context),
                    onTodaySelected: _setToday,
                    onSevenDaysSelected: _setSevenDays,
                  ),
                  const SizedBox(height: 16),
                  statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        ReportKpiCards(stats: stats),
                        const SizedBox(height: 16),
                        ReportNetBalanceCard(stats: stats),
                        const SizedBox(height: 16),
                        ReportDailyDetailCard(
                          onExportPdf: () {
                            NotificationService.showInfo(
                              context,
                              'Export PDF - À implémenter',
                            );
                          },
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
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
