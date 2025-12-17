import 'package:flutter/material.dart';

/// Widget for selecting report period for immobilier - style eau_minerale.
class ReportPeriodSelectorV2 extends StatelessWidget {
  const ReportPeriodSelectorV2({
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
                          child: FilledButton.icon(
                            onPressed: onDownload,
                            icon: const Icon(Icons.download),
                            label: const Text('Télécharger'),
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
                        const SizedBox(height: 16),
                        _ReportDateField(
                          label: 'Date de Fin',
                          date: endDate,
                          onTap: onEndDateSelected,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onDownload,
                            icon: const Icon(Icons.download),
                            label: const Text('Télécharger'),
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
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
