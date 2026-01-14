import 'package:flutter/material.dart';
import 'forecast_report_helpers.dart';

/// Type d'alerte.
enum ForecastAlertType { success, warning, info }

/// Modèle d'alerte.
class ForecastAlert {
  const ForecastAlert({
    required this.type,
    required this.title,
    required this.message,
  });

  final ForecastAlertType type;
  final String title;
  final String message;
}

/// Widget pour afficher une alerte.
class ForecastAlertCard extends StatelessWidget {
  const ForecastAlertCard({super.key, required this.alert});

  final ForecastAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = switch (alert.type) {
      ForecastAlertType.success => Colors.green,
      ForecastAlertType.warning => Colors.orange,
      ForecastAlertType.info => Colors.blue,
    };

    final icon = switch (alert.type) {
      ForecastAlertType.success => Icons.trending_up,
      ForecastAlertType.warning => Icons.warning_amber,
      ForecastAlertType.info => Icons.info_outline,
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

/// Génère les alertes basées sur les données.
List<ForecastAlert> generateForecastAlerts(
  List<double> weeklyData,
  double trend,
  double average,
) {
  final alerts = <ForecastAlert>[];

  // Declining trend alert
  if (trend < -average * 0.1) {
    alerts.add(
      ForecastAlert(
        type: ForecastAlertType.warning,
        title: 'Tendance baissière détectée',
        message:
            'Les ventes montrent une tendance à la baisse de ${(trend / average * 100).abs().toStringAsFixed(1)}% par semaine.',
      ),
    );
  }

  // Increasing trend
  if (trend > average * 0.1) {
    alerts.add(
      ForecastAlert(
        type: ForecastAlertType.success,
        title: 'Croissance positive',
        message:
            'Les ventes augmentent de ${(trend / average * 100).toStringAsFixed(1)}% par semaine.',
      ),
    );
  }

  // High variability
  if (weeklyData.length >= 2) {
    final variance = ForecastReportHelpers.calculateVariance(
      weeklyData,
      average,
    );
    final coefficientOfVariation = average > 0 ? (variance / average) * 100 : 0;
    if (coefficientOfVariation > 30) {
      alerts.add(
        ForecastAlert(
          type: ForecastAlertType.info,
          title: 'Forte variabilité',
          message:
              'Les ventes présentent une variabilité importante (${coefficientOfVariation.toStringAsFixed(0)}%). Les prévisions peuvent être moins fiables.',
        ),
      );
    }
  }

  return alerts;
}
