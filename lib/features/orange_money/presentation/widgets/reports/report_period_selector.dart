import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Period selector card for reports screen.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onTodaySelected,
    required this.onSevenDaysSelected,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateSelected;
  final VoidCallback onEndDateSelected;
  final VoidCallback onTodaySelected;
  final VoidCallback onSevenDaysSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Période de rapport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _ReportDateField(
                    label: 'Date de début',
                    date: startDate,
                    onTap: onStartDateSelected,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportDateField(
                    label: 'Date de fin',
                    date: endDate,
                    onTap: onEndDateSelected,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportQuickActions(
                    onTodaySelected: onTodaySelected,
                    onSevenDaysSelected: onSevenDaysSelected,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Date field widget for reports.
class _ReportDateField extends StatelessWidget {
  const _ReportDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent, width: 1.219),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date!) : '',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF717182),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF717182),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick actions widget for reports.
class _ReportQuickActions extends StatelessWidget {
  const _ReportQuickActions({
    required this.onTodaySelected,
    required this.onSevenDaysSelected,
  });

  final VoidCallback onTodaySelected;
  final VoidCallback onSevenDaysSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onTodaySelected,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.219,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 1.219,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Aujourd\'hui',
                  style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onSevenDaysSelected,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.219,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 1.219,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '7 jours',
                  style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
