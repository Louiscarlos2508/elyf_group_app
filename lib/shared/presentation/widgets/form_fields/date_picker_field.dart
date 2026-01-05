import 'package:flutter/material.dart';

/// Champ de sélection de date réutilisable.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Date *',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.validator,
  });

  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? Function(DateTime?)? validator;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now(),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          _formatDate(selectedDate),
          style: TextStyle(
            color: enabled
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}

