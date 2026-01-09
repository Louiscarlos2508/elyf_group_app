import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sale.dart';
import 'production_period_formatter.dart';

/// Widget displaying trends and comparisons with previous period.
class TrendsReportContent extends ConsumerWidget {
  const TrendsReportContent({
    super.key,
    required this.period,
  });

  final ReportPeriod period;

  ReportPeriod get _previousPeriod {
    final duration = period.endDate.difference(period.startDate);
    return ReportPeriod(
      startDate: period.startDate.subtract(duration),
      endDate: period.startDate.subtract(const Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(salesStateProvider);
    final productionAsync = ref.watch(productionSessionsStateProvider);

    return salesAsync.when(
      data: (salesState) => productionAsync.when(
        data: (sessions) => _buildContent(
          context,
          theme,
          salesState.sales,
          sessions,
        ),
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
    List<ProductionSession> allSessions,
  ) {
    // Filter current period
    final currentSales = allSales.where((s) {
      return s.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          s.date.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();

    final currentSessions = allSessions.where((s) {
      return s.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          s.date.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter previous period
    final previousSales = allSales.where((s) {
      return s.date.isAfter(
              _previousPeriod.startDate.subtract(const Duration(days: 1))) &&
          s.date.isBefore(_previousPeriod.endDate.add(const Duration(days: 1)));
    }).toList();

    final previousSessions = allSessions.where((s) {
      return s.date.isAfter(
              _previousPeriod.startDate.subtract(const Duration(days: 1))) &&
          s.date.isBefore(_previousPeriod.endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate metrics
    final currentRevenue =
        currentSales.fold<int>(0, (sum, s) => sum + s.totalPrice);
    final previousRevenue =
        previousSales.fold<int>(0, (sum, s) => sum + s.totalPrice);
    final revenueChange = _calculateChange(currentRevenue, previousRevenue);

    final currentProduction =
        currentSessions.fold<int>(0, (sum, s) => sum + s.quantiteProduite);
    final previousProduction =
        previousSessions.fold<int>(0, (sum, s) => sum + s.quantiteProduite);
    final productionChange =
        _calculateChange(currentProduction, previousProduction);

    final currentSalesCount = currentSales.length;
    final previousSalesCount = previousSales.length;
    final salesCountChange =
        _calculateChange(currentSalesCount, previousSalesCount);

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
            'Analyse des Tendances',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comparaison avec la période précédente',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Comparison cards
          _ComparisonGrid(
            items: [
              _ComparisonItem(
                label: 'Chiffre d\'Affaires',
                currentValue: CurrencyFormatter.formatFCFA(currentRevenue),
                previousValue: CurrencyFormatter.formatFCFA(previousRevenue),
                changePercent: revenueChange,
                icon: Icons.trending_up,
              ),
              _ComparisonItem(
                label: 'Production',
                currentValue: '$currentProduction sachets',
                previousValue: '$previousProduction sachets',
                changePercent: productionChange,
                icon: Icons.factory,
              ),
              _ComparisonItem(
                label: 'Nombre de ventes',
                currentValue: '$currentSalesCount',
                previousValue: '$previousSalesCount',
                changePercent: salesCountChange,
                icon: Icons.shopping_cart,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Chart comparison
          Text(
            'Évolution Comparée',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonChart(
            currentSales: currentSales,
            previousSales: previousSales,
            period: period,
            previousPeriod: _previousPeriod,
          ),
          const SizedBox(height: 32),

          // Period details
          _PeriodDetailsRow(
            currentPeriod: period,
            previousPeriod: _previousPeriod,
          ),
        ],
      ),
    );
  }

  double _calculateChange(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }
}

class _ComparisonGrid extends StatelessWidget {
  const _ComparisonGrid({required this.items});

  final List<_ComparisonItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: items
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: item,
                      ),
                    ))
                .toList(),
          );
        }
        return Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: item,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  const _ComparisonItem({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.changePercent,
    required this.icon,
  });

  final String label;
  final String currentValue;
  final String previousValue;
  final double changePercent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = changePercent >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentValue,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${changePercent.abs().toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'vs $previousValue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({
    required this.currentSales,
    required this.previousSales,
    required this.period,
    required this.previousPeriod,
  });

  final List<Sale> currentSales;
  final List<Sale> previousSales;
  final ReportPeriod period;
  final ReportPeriod previousPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = period.endDate.difference(period.startDate).inDays + 1;

    // Group by day index
    final currentByDay = _groupByDayIndex(currentSales, period.startDate, days);
    final previousByDay =
        _groupByDayIndex(previousSales, previousPeriod.startDate, days);

    final maxValue = [...currentByDay, ...previousByDay]
        .fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barGroups: List.generate(
            days > 14 ? 14 : days,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: index < currentByDay.length ? currentByDay[index] : 0,
                  color: Colors.blue,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: index < previousByDay.length ? previousByDay[index] : 0,
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 2 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'J${value.toInt() + 1}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  List<double> _groupByDayIndex(
      List<Sale> sales, DateTime startDate, int days) {
    final result = List.filled(days, 0.0);
    for (final sale in sales) {
      final dayIndex = sale.date.difference(startDate).inDays;
      if (dayIndex >= 0 && dayIndex < days) {
        result[dayIndex] += sale.totalPrice.toDouble();
      }
    }
    return result;
  }
}

class _PeriodDetailsRow extends StatelessWidget {
  const _PeriodDetailsRow({
    required this.currentPeriod,
    required this.previousPeriod,
  });

  final ReportPeriod currentPeriod;
  final ReportPeriod previousPeriod;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PeriodBadge(
            label: 'Période actuelle',
            period: currentPeriod,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PeriodBadge(
            label: 'Période précédente',
            period: previousPeriod,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _PeriodBadge extends StatelessWidget {
  const _PeriodBadge({
    required this.label,
    required this.period,
    required this.color,
  });

  final String label;
  final ReportPeriod period;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${ProductionPeriodFormatter.formatDate(period.startDate)} - '
            '${ProductionPeriodFormatter.formatDate(period.endDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
