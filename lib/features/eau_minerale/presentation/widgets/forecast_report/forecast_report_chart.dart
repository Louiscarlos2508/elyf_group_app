import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget pour afficher le graphique de projection.
class ForecastProjectionChart extends StatelessWidget {
  const ForecastProjectionChart({
    super.key,
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
                        fontWeight: isProjection
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                ...projections.asMap().entries.map(
                  (e) => FlSpot(
                    (historicalData.length + e.key).toDouble(),
                    e.value,
                  ),
                ),
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
