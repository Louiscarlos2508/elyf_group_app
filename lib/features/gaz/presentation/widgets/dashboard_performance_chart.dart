import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

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

    return ElyfCard(
      isGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Performance des 7 derniers jours',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
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
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
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
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
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
                  // Bénéfice (Blue)
                  LineChartBarData(
                    spots: profitSpots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Dépenses (Red)
                  LineChartBarData(
                    spots: expensesSpots,
                    isCurved: true,
                    color: theme.colorScheme.error,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.error,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Ventes (Emerald)
                  LineChartBarData(
                    spots: salesSpots,
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.success,
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(color: theme.colorScheme.primary, label: 'Bénéfice'),
              _LegendItem(color: theme.colorScheme.error, label: 'Dépenses'),
              _LegendItem(color: AppColors.success, label: 'Ventes'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
