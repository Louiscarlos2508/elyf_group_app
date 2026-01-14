import 'package:flutter/material.dart';

/// Widget for selecting a date period with quick actions.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.onTodayPressed,
    this.onSevenDaysPressed,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback? onTodayPressed;
  final VoidCallback? onSevenDaysPressed;

  Future<void> _selectDate(
    BuildContext context,
    ValueChanged<DateTime?> onDateSelected,
    DateTime? initialDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Période de rapport',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              _buildDateField(
                context,
                'Date de début',
                startDate,
                () => _selectDate(context, onStartDateChanged, startDate),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                context,
                'Date de fin',
                endDate,
                () => _selectDate(context, onEndDateChanged, endDate),
              ),
              if (onTodayPressed != null || onSevenDaysPressed != null) ...[
                const SizedBox(height: 16),
                _buildQuickActions(context),
              ],
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  'Date de début',
                  startDate,
                  () => _selectDate(context, onStartDateChanged, startDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  context,
                  'Date de fin',
                  endDate,
                  () => _selectDate(context, onEndDateChanged, endDate),
                ),
              ),
              if (onTodayPressed != null || onSevenDaysPressed != null) ...[
                const SizedBox(width: 16),
                Expanded(child: _buildQuickActions(context)),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(date).isEmpty
                        ? 'Sélectionner une date'
                        : _formatDate(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: date == null
                          ? const Color(0xFF717182)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (onTodayPressed != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onTodayPressed,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text("Aujourd'hui"),
                ),
              ),
            if (onTodayPressed != null && onSevenDaysPressed != null)
              const SizedBox(width: 8),
            if (onSevenDaysPressed != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onSevenDaysPressed,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('7 jours'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
