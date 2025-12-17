import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sale.dart';

/// Widget displaying forecasts and projections.
class ForecastReportContent extends ConsumerWidget {
  const ForecastReportContent({
    super.key,
    required this.period,
  });

  final ReportPeriod period;

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

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
    final weeklyData = _groupByWeek(recentSales, fourWeeksAgo);

    // Calculate average
    final weeklyAverage = weeklyData.isEmpty
        ? 0.0
        : weeklyData.fold<double>(0, (sum, w) => sum + w) / weeklyData.length;

    // Calculate trend (simple linear regression)
    final trend = _calculateTrend(weeklyData);

    // Project next 4 weeks
    final projections = _projectWeeks(weeklyAverage, trend, 4);

    // Alerts
    final alerts = _generateAlerts(weeklyData, trend, weeklyAverage);

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
            ...alerts.map((alert) => _AlertCard(alert: alert)),
            const SizedBox(height: 24),
          ],

          // Forecast KPIs
          _ForecastKpis(
            weeklyAverage: weeklyAverage,
            trend: trend,
            nextWeekProjection: projections.isNotEmpty ? projections.first : 0,
            monthProjection: projections.fold<double>(0, (sum, p) => sum + p),
            formatCurrency: _formatCurrency,
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
          _ProjectionChart(
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
          _WeeklyBreakdown(
            weeklyData: weeklyData,
            average: weeklyAverage,
            formatCurrency: _formatCurrency,
          ),
        ],
      ),
    );
  }

  List<double> _groupByWeek(List<Sale> sales, DateTime startDate) {
    final weeks = <int, double>{};
    for (var i = 0; i < 4; i++) {
      weeks[i] = 0;
    }

    for (final sale in sales) {
      final daysSinceStart = sale.date.difference(startDate).inDays;
      final weekIndex = daysSinceStart ~/ 7;
      if (weekIndex >= 0 && weekIndex < 4) {
        weeks[weekIndex] = (weeks[weekIndex] ?? 0) + sale.totalPrice;
      }
    }

    return weeks.values.toList();
  }

  double _calculateTrend(List<double> data) {
    if (data.length < 2) return 0;

    // Simple linear regression
    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (var i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  List<double> _projectWeeks(double average, double trend, int weeks) {
    return List.generate(weeks, (i) {
      final projection = average + trend * (i + 1);
      return projection > 0 ? projection : 0;
    });
  }

  List<_Alert> _generateAlerts(
      List<double> weeklyData, double trend, double average) {
    final alerts = <_Alert>[];

    // Declining trend alert
    if (trend < -average * 0.1) {
      alerts.add(_Alert(
        type: _AlertType.warning,
        title: 'Tendance baissière détectée',
        message:
            'Les ventes montrent une tendance à la baisse de ${(trend / average * 100).abs().toStringAsFixed(1)}% par semaine.',
      ));
    }

    // Increasing trend
    if (trend > average * 0.1) {
      alerts.add(_Alert(
        type: _AlertType.success,
        title: 'Croissance positive',
        message:
            'Les ventes augmentent de ${(trend / average * 100).toStringAsFixed(1)}% par semaine.',
      ));
    }

    // High variability
    if (weeklyData.length >= 2) {
      final variance = _calculateVariance(weeklyData, average);
      final coefficientOfVariation =
          average > 0 ? (variance / average) * 100 : 0;
      if (coefficientOfVariation > 30) {
        alerts.add(_Alert(
          type: _AlertType.info,
          title: 'Forte variabilité',
          message:
              'Les ventes présentent une variabilité importante (${coefficientOfVariation.toStringAsFixed(0)}%). Les prévisions peuvent être moins fiables.',
        ));
      }
    }

    return alerts;
  }

  double _calculateVariance(List<double> data, double mean) {
    if (data.isEmpty) return 0;
    final sumSquaredDiff =
        data.fold<double>(0, (sum, x) => sum + (x - mean) * (x - mean));
    return sumSquaredDiff / data.length;
  }
}

enum _AlertType { success, warning, info }

class _Alert {
  const _Alert({
    required this.type,
    required this.title,
    required this.message,
  });

  final _AlertType type;
  final String title;
  final String message;
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final _Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = switch (alert.type) {
      _AlertType.success => Colors.green,
      _AlertType.warning => Colors.orange,
      _AlertType.info => Colors.blue,
    };

    final icon = switch (alert.type) {
      _AlertType.success => Icons.trending_up,
      _AlertType.warning => Icons.warning_amber,
      _AlertType.info => Icons.info_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastKpis extends StatelessWidget {
  const _ForecastKpis({
    required this.weeklyAverage,
    required this.trend,
    required this.nextWeekProjection,
    required this.monthProjection,
    required this.formatCurrency,
  });

  final double weeklyAverage;
  final double trend;
  final double nextWeekProjection;
  final double monthProjection;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final trendPercent =
        weeklyAverage > 0 ? (trend / weeklyAverage) * 100 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        final items = [
          _KpiCard(
            label: 'Moyenne hebdomadaire',
            value: formatCurrency(weeklyAverage.toInt()),
            icon: Icons.analytics,
            color: Colors.blue,
          ),
          _KpiCard(
            label: 'Tendance',
            value: '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}%',
            icon: trendPercent >= 0 ? Icons.trending_up : Icons.trending_down,
            color: trendPercent >= 0 ? Colors.green : Colors.red,
          ),
          _KpiCard(
            label: 'Prévision semaine prochaine',
            value: formatCurrency(nextWeekProjection.toInt()),
            icon: Icons.calendar_today,
            color: Colors.purple,
          ),
          _KpiCard(
            label: 'Prévision mois',
            value: formatCurrency(monthProjection.toInt()),
            icon: Icons.date_range,
            color: Colors.orange,
          ),
        ];

        if (isWide) {
          return Row(
            children: items
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: item,
                      ),
                    ))
                .toList(),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 12),
                Expanded(child: items[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: items[2]),
                const SizedBox(width: 12),
                Expanded(child: items[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({
    required this.historicalData,
    required this.projections,
  });

  final List<double> historicalData;
  final List<double> projections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allData = [...historicalData, ...projections];
    final maxY = allData.fold<double>(0, (a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
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
                  final index = value.toInt();
                  final isProjection = index >= historicalData.length;
                  final weekNum = isProjection
                      ? 'P${index - historicalData.length + 1}'
                      : 'S${index + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekNum,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isProjection
                            ? Colors.purple
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isProjection ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Historical data
            LineChartBarData(
              spots: historicalData
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
            // Projections
            LineChartBarData(
              spots: [
                if (historicalData.isNotEmpty)
                  FlSpot(
                    (historicalData.length - 1).toDouble(),
                    historicalData.last,
                  ),
                ...projections.asMap().entries.map((e) => FlSpot(
                      (historicalData.length + e.key).toDouble(),
                      e.value,
                    )),
              ],
              isCurved: true,
              color: Colors.purple,
              barWidth: 3,
              dashArray: [5, 5],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.purple,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.purple.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBreakdown extends StatelessWidget {
  const _WeeklyBreakdown({
    required this.weeklyData,
    required this.average,
    required this.formatCurrency,
  });

  final List<double> weeklyData;
  final double average;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (weeklyData.isEmpty) {
      return Center(
        child: Text(
          'Pas de données disponibles',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: weeklyData.asMap().entries.map((entry) {
        final weekNum = entry.key + 1;
        final value = entry.value;
        final percentOfAverage = average > 0 ? (value / average) * 100 : 0.0;
        final isAboveAverage = value >= average;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'S$weekNum',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency(value.toInt()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (percentOfAverage / 150).clamp(0, 1),
                      backgroundColor: theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation(
                        isAboveAverage ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAboveAverage
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentOfAverage.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isAboveAverage ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
