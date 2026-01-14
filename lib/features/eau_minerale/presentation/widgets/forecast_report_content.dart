import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sale.dart';
import 'forecast_report/forecast_report_helpers.dart';
import 'forecast_report/forecast_report_alert.dart';
import 'forecast_report/forecast_report_kpis.dart';
import 'forecast_report/forecast_report_chart.dart';
import 'forecast_report/forecast_report_weekly_breakdown.dart';

/// Widget displaying forecasts and projections.
class ForecastReportContent extends ConsumerWidget {
  const ForecastReportContent({super.key, required this.period});

  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(salesStateProvider);
    final productionAsync = ref.watch(productionSessionsStateProvider);

    return salesAsync.when(
      data: (salesState) => productionAsync.when(
        data: (sessions) => _buildContent(context, theme, salesState.sales),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    List<Sale> allSales,
  ) {
    // Calculate 4-week moving average
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));

    final recentSales = allSales.where((s) {
      return s.date.isAfter(fourWeeksAgo);
    }).toList();

    // Group by week
    final weeklyData = ForecastReportHelpers.groupByWeek(
      recentSales,
      fourWeeksAgo,
    );

    // Calculate average
    final weeklyAverage = weeklyData.isEmpty
        ? 0.0
        : weeklyData.fold<double>(0, (sum, w) => sum + w) / weeklyData.length;

    // Calculate trend (simple linear regression)
    final trend = ForecastReportHelpers.calculateTrend(weeklyData);

    // Project next 4 weeks
    final projections = ForecastReportHelpers.projectWeeks(
      weeklyAverage,
      trend,
      4,
    );

    // Alerts
    final alerts = generateForecastAlerts(weeklyData, trend, weeklyAverage);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prévisions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Projections basées sur les 4 dernières semaines',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Alerts section
          if (alerts.isNotEmpty) ...[
            ...alerts.map((alert) => ForecastAlertCard(alert: alert)),
            const SizedBox(height: 24),
          ],

          // Forecast KPIs
          ForecastKpis(
            weeklyAverage: weeklyAverage,
            trend: trend,
            nextWeekProjection: projections.isNotEmpty ? projections.first : 0,
            monthProjection: projections.fold<double>(0, (sum, p) => sum + p),
            formatCurrency: ForecastReportHelpers.formatCurrency,
          ),
          const SizedBox(height: 32),

          // Projection chart
          Text(
            'Projection des Ventes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ForecastProjectionChart(
            historicalData: weeklyData,
            projections: projections,
          ),
          const SizedBox(height: 32),

          // Weekly breakdown
          Text(
            'Historique Hebdomadaire',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ForecastWeeklyBreakdown(
            weeklyData: weeklyData,
            average: weeklyAverage,
            formatCurrency: ForecastReportHelpers.formatCurrency,
          ),
        ],
      ),
    );
  }
}
