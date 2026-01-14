import 'package:flutter/material.dart';

import '../../domain/entities/report_period.dart';

class ReportPeriodSelector extends StatefulWidget {
  const ReportPeriodSelector({
    super.key,
    required this.selectedPeriod,
    this.startDate,
    this.endDate,
    required this.onPeriodChanged,
  });

  final ReportPeriod selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(ReportPeriod period, DateTime? start, DateTime? end)
  onPeriodChanged;

  @override
  State<ReportPeriodSelector> createState() => _ReportPeriodSelectorState();
}

class _ReportPeriodSelectorState extends State<ReportPeriodSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PeriodChip(
                  label: 'Aujourd\'hui',
                  period: ReportPeriod.today,
                  selected: widget.selectedPeriod == ReportPeriod.today,
                  onSelected: () {
                    widget.onPeriodChanged(ReportPeriod.today, null, null);
                  },
                ),
                _PeriodChip(
                  label: 'Cette semaine',
                  period: ReportPeriod.thisWeek,
                  selected: widget.selectedPeriod == ReportPeriod.thisWeek,
                  onSelected: () {
                    widget.onPeriodChanged(ReportPeriod.thisWeek, null, null);
                  },
                ),
                _PeriodChip(
                  label: 'Ce mois',
                  period: ReportPeriod.thisMonth,
                  selected: widget.selectedPeriod == ReportPeriod.thisMonth,
                  onSelected: () {
                    widget.onPeriodChanged(ReportPeriod.thisMonth, null, null);
                  },
                ),
                _PeriodChip(
                  label: 'Cette année',
                  period: ReportPeriod.thisYear,
                  selected: widget.selectedPeriod == ReportPeriod.thisYear,
                  onSelected: () {
                    widget.onPeriodChanged(ReportPeriod.thisYear, null, null);
                  },
                ),
                _PeriodChip(
                  label: 'Personnalisé',
                  period: ReportPeriod.custom,
                  selected: widget.selectedPeriod == ReportPeriod.custom,
                  onSelected: () async {
                    final now = DateTime.now();
                    final start = await showDatePicker(
                      context: context,
                      initialDate:
                          widget.startDate ??
                          now.subtract(const Duration(days: 30)),
                      firstDate: DateTime(2000),
                      lastDate: now,
                    );
                    if (start != null) {
                      if (!mounted || !context.mounted) return;
                      final end = await showDatePicker(
                        context: context,
                        initialDate: widget.endDate ?? now,
                        firstDate: start,
                        lastDate: now,
                      );
                      if (end != null && mounted) {
                        widget.onPeriodChanged(ReportPeriod.custom, start, end);
                      }
                    }
                  },
                ),
              ],
            ),
            if (widget.selectedPeriod == ReportPeriod.custom &&
                widget.startDate != null &&
                widget.endDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateDisplay(label: 'Du', date: widget.startDate!),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateDisplay(label: 'Au', date: widget.endDate!),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.period,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final ReportPeriod period;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DateDisplay extends StatelessWidget {
  const _DateDisplay({required this.label, required this.date});

  final String label;
  final DateTime date;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
