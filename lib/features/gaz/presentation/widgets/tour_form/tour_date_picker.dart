import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Sélecteur de date pour le tour.
class TourDatePicker extends StatelessWidget {
  const TourDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date du tour',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            height: 36,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.transparent,
                width: 1.305,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateFormat.format(selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
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

