import 'package:flutter/material.dart';

import '../../../utils/date_formatter.dart';

/// Champ de sélection de date avec formatage.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onTap,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
  });

  final DateTime selectedDate;
  final VoidCallback onTap;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: enabled
              ? const Icon(Icons.arrow_drop_down)
              : const SizedBox.shrink(),
        ),
        child: Text(
          _formatDate(selectedDate),
          style: enabled
              ? null
              : TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                ),
        ),
      ),
    );
  }
}

