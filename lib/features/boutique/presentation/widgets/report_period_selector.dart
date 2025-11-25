import 'package:flutter/material.dart';

import '../../domain/entities/report_data.dart';

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
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectCustomDates(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2, 1, 1);
    final lastDate = now;

    final pickedStart = await showDatePicker(
      context: context,
      initialDate: widget.startDate ?? now.subtract(const Duration(days: 30)),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Sélectionner la date de début',
    );

    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: widget.endDate ?? now,
      firstDate: pickedStart,
      lastDate: lastDate,
      helpText: 'Sélectionner la date de fin',
    );

    if (pickedEnd != null) {
      widget.onPeriodChanged(ReportPeriod.custom, pickedStart, pickedEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Card(
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
            SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(
                  value: ReportPeriod.today,
                  label: Text('Aujourd\'hui'),
                ),
                ButtonSegment(
                  value: ReportPeriod.week,
                  label: Text('Semaine'),
                ),
                ButtonSegment(
                  value: ReportPeriod.month,
                  label: Text('Mois'),
                ),
                ButtonSegment(
                  value: ReportPeriod.year,
                  label: Text('Année'),
                ),
                ButtonSegment(
                  value: ReportPeriod.custom,
                  label: Text('Personnalisé'),
                ),
              ],
              selected: {widget.selectedPeriod},
              onSelectionChanged: (Set<ReportPeriod> selection) {
                final period = selection.first;
                DateTime? start;
                DateTime? end;

                switch (period) {
                  case ReportPeriod.today:
                    start = DateTime(now.year, now.month, now.day);
                    end = now;
                    break;
                  case ReportPeriod.week:
                    start = now.subtract(Duration(days: now.weekday - 1));
                    end = now;
                    break;
                  case ReportPeriod.month:
                    start = DateTime(now.year, now.month, 1);
                    end = DateTime(now.year, now.month + 1, 0);
                    break;
                  case ReportPeriod.year:
                    start = DateTime(now.year, 1, 1);
                    end = now;
                    break;
                  case ReportPeriod.custom:
                    _selectCustomDates(context);
                    return;
                }
                widget.onPeriodChanged(period, start, end);
              },
            ),
            if (widget.startDate != null && widget.endDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(widget.startDate!)} - ${_formatDate(widget.endDate!)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.selectedPeriod == ReportPeriod.custom) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _selectCustomDates(context),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

