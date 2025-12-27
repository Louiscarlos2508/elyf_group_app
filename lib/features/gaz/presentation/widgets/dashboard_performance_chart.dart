import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Chart displaying performance over the last 7 days (Bénéfice, Dépenses, Ventes).
class DashboardPerformanceChart extends StatelessWidget {
  const DashboardPerformanceChart({
    super.key,
    required this.profitData,
    required this.expensesData,
    required this.salesData,
  });

  final List<double> profitData; // 7 values
  final List<double> expensesData; // 7 values
  final List<double> salesData; // 7 values

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Prepare spots for each line
    final profitSpots = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), profitData[index]),
    );
    final expensesSpots = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), expensesData[index]),
    );
    final salesSpots = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), salesData[index]),
    );

    // Find max value for Y axis
    final allValues = [...profitData, ...expensesData, ...salesData];
    final maxValue = allValues.isEmpty
        ? 4.0
        : allValues.reduce((a, b) => a > b ? a : b);
    // If all values are 0, show scale 0-4 like in Figma
    // Otherwise, add 20% padding
    final yMax = maxValue == 0
        ? 4.0
        : (maxValue * 1.2).ceilToDouble().clamp(4.0, double.infinity);

    // Generate day labels
    final dayLabels = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      // Use a simple approach that doesn't require locale initialization
      final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final dayName = dayNames[date.weekday - 1];
      final dayNumber = date.day;
      return '$dayName $dayNumber';
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Performance des 7 derniers jours',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 46),
          // Chart
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF666666),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
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
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[index],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: yMax,
                lineBarsData: [
                  // Bénéfice (blue)
                  LineChartBarData(
                    spots: profitSpots,
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF3B82F6),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Dépenses (red)
                  LineChartBarData(
                    spots: expensesSpots,
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotSquarePainter(
                          size: 8,
                          color: const Color(0xFFEF4444),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Ventes (green)
                  LineChartBarData(
                    spots: salesSpots,
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCrossPainter(
                          size: 8,
                          color: const Color(0xFF10B981),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: const Color(0xFF3B82F6),
                label: 'Bénéfice',
              ),
              const SizedBox(width: 24),
              _LegendItem(
                color: const Color(0xFFEF4444),
                label: 'Dépenses',
              ),
              const SizedBox(width: 24),
              _LegendItem(
                color: const Color(0xFF10B981),
                label: 'Ventes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

