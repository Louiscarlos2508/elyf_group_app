import 'package:flutter/material.dart';

import '../../../domain/entities/production_session.dart';
import 'production_report_components.dart';
import 'production_report_helpers.dart';

/// Informations générales de la production.
class ProductionReportGeneralInfo extends StatelessWidget {
  const ProductionReportGeneralInfo({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductionReportComponents.buildSectionTitle(
          'Informations Générales',
          theme,
        ),
        const SizedBox(height: 16),
        ProductionReportComponents.buildInfoGrid(
          items: [
            (
              label: 'Date de début',
              value: ProductionReportHelpers.formatDate(session.date),
              icon: Icons.calendar_today,
            ),
            (
              label: 'Heure de début',
              value: ProductionReportHelpers.formatTime(session.heureDebut),
              icon: Icons.access_time,
            ),
            if (session.heureFin != null)
              (
                label: 'Heure de fin',
                value: ProductionReportHelpers.formatTime(session.heureFin!),
                icon: Icons.check_circle,
              ),
            (
              label: 'Durée',
              value: '${session.dureeHeures.toStringAsFixed(1)} heures',
              icon: Icons.timer,
            ),
          ],
          theme: theme,
        ),
      ],
    );
  }
}
