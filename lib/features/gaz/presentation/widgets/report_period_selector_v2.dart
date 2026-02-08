import 'package:flutter/material.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_button.dart';

/// Widget for selecting report period - style eau_minerale.
class GazReportPeriodSelectorV2 extends StatelessWidget {
  const GazReportPeriodSelectorV2({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onDownload,
  });

  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartDateSelected;
  final VoidCallback onEndDateSelected;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Container(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Période du Rapport',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sélectionnez la période pour générer le rapport',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _ReportDateField(
                            label: 'Date de Début',
                            date: startDate,
                            onTap: onStartDateSelected,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ReportDateField(
                            label: 'Date de Fin',
                            date: endDate,
                            onTap: onEndDateSelected,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IntrinsicWidth(
                          child: ElyfButton(
                            onPressed: onDownload,
                            icon: Icons.download,
                            child: const Text('Télécharger'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _ReportDateField(
                          label: 'Date de Début',
                          date: startDate,
                          onTap: onStartDateSelected,
                        ),
                        const SizedBox(height: 12),
                        _ReportDateField(
                          label: 'Date de Fin',
                          date: endDate,
                          onTap: onEndDateSelected,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElyfButton(
                            onPressed: onDownload,
                            icon: Icons.download,
                            child: const Text('Télécharger PDF'),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportDateField extends StatelessWidget {
  const _ReportDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
