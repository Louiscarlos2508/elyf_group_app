import 'package:flutter/material.dart';
import 'forecast_report_kpi_card.dart';

/// Widget pour afficher les KPIs de prévision.
class ForecastKpis extends StatelessWidget {
  const ForecastKpis({
    super.key,
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
    final trendPercent = weeklyAverage > 0
        ? (trend / weeklyAverage) * 100
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        final items = [
          ForecastKpiCard(
            label: 'Moyenne hebdomadaire',
            value: formatCurrency(weeklyAverage.toInt()),
            icon: Icons.analytics,
            color: Colors.blue,
          ),
          ForecastKpiCard(
            label: 'Tendance',
            value:
                '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}%',
            icon: trendPercent >= 0 ? Icons.trending_up : Icons.trending_down,
            color: trendPercent >= 0 ? Colors.green : Colors.red,
          ),
          ForecastKpiCard(
            label: 'Prévision semaine prochaine',
            value: formatCurrency(nextWeekProjection.toInt()),
            icon: Icons.calendar_today,
            color: Colors.purple,
          ),
          ForecastKpiCard(
            label: 'Prévision mois',
            value: formatCurrency(monthProjection.toInt()),
            icon: Icons.date_range,
            color: Colors.orange,
          ),
        ];

        if (isWide) {
          return Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: item,
                    ),
                  ),
                )
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
