import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Widget for selecting report period.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
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

        return ElyfCard(
          isGlass: true,
          borderColor: Colors.indigo.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      size: 20,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Période du Rapport',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                        FilledButton.icon(
                          onPressed: onDownload,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Générer PDF'),
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onDownload,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Générer le Rapport PDF'),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
