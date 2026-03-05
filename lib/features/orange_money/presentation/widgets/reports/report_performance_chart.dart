import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class ReportPerformanceChart extends StatelessWidget {
  const ReportPerformanceChart({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> history = stats['dailyHistory'] != null 
        ? List<Map<String, dynamic>>.from(stats['dailyHistory'])
        : [];

    if (history.isEmpty) {
      return SizedBox(
        height: 200,
        child: ElyfCard(
          backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
          elevation: isDark ? 0 : 1,
          child: Center(
            child: Text(
              'Aucune donnée pour cette période',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return ElyfCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Évolution des flux',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
              _buildLegend(theme),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(history),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) return const SizedBox.shrink();
                        
                        // Show only 5-ish labels max to avoid overlap
                        if (history.length > 7 && index % (history.length ~/ 5) != 0) {
                          return const SizedBox.shrink();
                        }

                        final date = history[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd/MM').format(date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calculateInterval(history),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.formatShort(value.toInt()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _generateLineData(
                    history: history,
                    field: 'cashIn',
                    color: const Color(0xFFFF6B00), // Orange
                  ),
                  _generateLineData(
                    history: history,
                    field: 'cashOut',
                    color: AppColors.danger, // Red
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => isDark ? AppColors.surfaceDark : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isCashIn = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isCashIn ? 'Dépôt' : 'Retrait'}: ${CurrencyFormatter.formatFCFA(spot.y.toInt())}',
                          theme.textTheme.labelSmall?.copyWith(
                            color: isCashIn ? const Color(0xFFFF6B00) : AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ) ?? const TextStyle(),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _generateLineData({
    required List<Map<String, dynamic>> history,
    required String field,
    required Color color,
  }) {
    return LineChartBarData(
      spots: history.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), (entry.value[field] as int).toDouble());
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      children: [
        _buildLegendItem('Dépôts', const Color(0xFFFF6B00), theme),
        const SizedBox(width: AppSpacing.md),
        _buildLegendItem('Retraits', AppColors.danger, theme),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  double _calculateInterval(List<Map<String, dynamic>> history) {
    int maxVal = 0;
    for (final day in history) {
      final cashIn = day['cashIn'] as int;
      final cashOut = day['cashOut'] as int;
      if (cashIn > maxVal) maxVal = cashIn;
      if (cashOut > maxVal) maxVal = cashOut;
    }
    if (maxVal == 0) return 10000;
    return maxVal / 4;
  }


}
