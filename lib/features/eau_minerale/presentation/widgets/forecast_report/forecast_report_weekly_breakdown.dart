import 'package:flutter/material.dart';

/// Widget pour afficher la décomposition hebdomadaire.
class ForecastWeeklyBreakdown extends StatelessWidget {
  const ForecastWeeklyBreakdown({
    super.key,
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

