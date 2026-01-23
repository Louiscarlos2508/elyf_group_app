import 'package:flutter/material.dart';

import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import 'production_report_components.dart';
import 'production_report_helpers.dart';

/// Section personnel du rapport.
class ProductionReportPersonnel extends StatelessWidget {
  const ProductionReportPersonnel({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context) {
    if (session.productionDays.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductionReportComponents.buildSectionTitle('Personnel', theme),
        const SizedBox(height: 16),
        ...session.productionDays.map(
          (day) => _PersonnelDayCard(theme: theme, day: day),
        ),
      ],
    );
  }
}

String _salaireLabel(ProductionDay day) {
  final n = day.personnelIds.length;
  if (n > 0 && day.coutTotalPersonnel > 0) {
    final moy = (day.coutTotalPersonnel / n).round();
    return 'Salaire journalier (moy.): ${ProductionReportHelpers.formatCurrency(moy)}/personne';
  }
  return 'Salaire journalier: ${ProductionReportHelpers.formatCurrency(day.salaireJournalierParPersonne)}/personne';
}

class _PersonnelDayCard extends StatelessWidget {
  const _PersonnelDayCard({required this.theme, required this.day});

  final ThemeData theme;
  final ProductionDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.people, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.personnelIds.length} personne(s) le ${ProductionReportHelpers.formatDate(day.date)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _salaireLabel(day),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Coût total: ${ProductionReportHelpers.formatCurrency(day.coutTotalPersonnel)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
