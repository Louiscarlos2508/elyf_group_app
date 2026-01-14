import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/sale.dart';

/// Chart displaying sales and production trends for the last 7 days.
class DashboardTrendsChart extends ConsumerWidget {
  const DashboardTrendsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesStateProvider);
    final productionState = ref.watch(productionSessionsStateProvider);

    return salesState.when(
      data: (sales) => productionState.when(
        data: (sessions) => _buildChart(context, sales.sales, sessions),
        loading: () => _buildLoadingState(),
        error: (_, __) => _buildErrorState(context),
      ),
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(context),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Données non disponibles',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<Sale> sales,
    List<ProductionSession> sessions,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Group sales by day
    final salesByDay = <int, int>{};
    final productionByDay = <int, int>{};

    for (var i = 0; i < 7; i++) {
      salesByDay[i] = 0;
      productionByDay[i] = 0;
    }

    for (final sale in sales) {
      if (sale.date.isAfter(sevenDaysAgo)) {
        final dayIndex = now.difference(sale.date).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          final reversedIndex = 6 - dayIndex;
          salesByDay[reversedIndex] =
              (salesByDay[reversedIndex] ?? 0) + sale.totalPrice;
        }
      }
    }

    for (final session in sessions) {
      if (session.date.isAfter(sevenDaysAgo)) {
        final dayIndex = now.difference(session.date).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          final reversedIndex = 6 - dayIndex;
          productionByDay[reversedIndex] =
              (productionByDay[reversedIndex] ?? 0) + session.quantiteProduite;
        }
      }
    }

    // Find max values for scaling
    final maxSales = salesByDay.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxProduction = productionByDay.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );

    // Normalize production to sales scale for display
    final scaleFactor = maxSales > 0 && maxProduction > 0
        ? maxSales / maxProduction
        : 1.0;

    final salesSpots = salesByDay.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    final productionSpots = productionByDay.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value * scaleFactor))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tendances (7 derniers jours)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _LegendItem(color: Colors.blue, label: 'Ventes'),
                  const SizedBox(width: 16),
                  _LegendItem(color: Colors.purple, label: 'Production'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxSales > 0 ? maxSales / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        final index = value.toInt();
                        if (index < 0 || index > 6) {
                          return const SizedBox.shrink();
                        }
                        final day = now.subtract(Duration(days: 6 - index));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getDayLabel(day),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: salesSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: productionSpots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[date.weekday - 1];
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
