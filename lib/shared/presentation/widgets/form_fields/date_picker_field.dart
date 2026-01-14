import 'package:flutter/material.dart';

import '../../../utils/date_formatter.dart';

/// Champ de sélection de date avec formatage.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.selectedDate,
    this.onTap,
    this.onDateSelected,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
  }) : assert(
         onTap != null || onDateSelected != null,
         'Either onTap or onDateSelected must be provided',
       );

  final DateTime selectedDate;

  /// Simple tap callback (legacy support).
  final VoidCallback? onTap;

  /// Callback invoked when a date is selected.
  /// If provided, automatically shows a date picker on tap.
  final ValueChanged<DateTime?>? onDateSelected;

  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }

    if (onDateSelected != null) {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2100),
      );
      onDateSelected!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _handleTap(context) : null,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
        ),
      ),
    );
  }
}
