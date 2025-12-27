import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'profit_report/profit_calculation_detail.dart';
import 'profit_report/profit_financial_summary.dart';
import 'profit_report/profit_performance_indicators.dart';
import 'profit_report/profit_report_header.dart';

/// Content widget for profit report tab - style eau_minerale.
class GazProfitReportContentV2 extends ConsumerWidget {
  const GazProfitReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      ) as ({
          GazReportPeriod period,
          DateTime? startDate,
          DateTime? endDate,
        })),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: reportDataAsync.when(
        data: (data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfitReportHeader(data: data),
              const SizedBox(height: 24),
              ProfitFinancialSummary(data: data, isWide: isWide),
              const SizedBox(height: 24),
              Text(
                'Détail des Calculs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ProfitCalculationDetail(data: data),
              const SizedBox(height: 24),
              Text(
                'Indicateurs de Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ProfitPerformanceIndicators(data: data),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
