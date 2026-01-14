import 'package:flutter/material.dart';

/// Widget pour filtrer les dépenses par période et catégories.
class ExpenseBalanceFilters extends StatelessWidget {
  const ExpenseBalanceFilters({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedCategories,
    required this.allCategories,
    required this.getCategoryLabel,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onCategoriesChanged,
  });

  final DateTime startDate;
  final DateTime endDate;
  final Set<String> selectedCategories;
  final List<String> allCategories;
  final String Function(String) getCategoryLabel;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<Set<String>> onCategoriesChanged;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isStartDate) {
        onStartDateChanged(picked);
      } else {
        onEndDateChanged(picked);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date début',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_formatDate(startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date fin',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_formatDate(endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Catégories', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Toutes'),
                  selected: selectedCategories.length == allCategories.length,
                  onSelected: (selected) {
                    if (selected) {
                      onCategoriesChanged(allCategories.toSet());
                    }
                  },
                ),
                ...allCategories.map((category) {
                  final isSelected = selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(getCategoryLabel(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newCategories = Set<String>.from(
                        selectedCategories,
                      );
                      if (selected) {
                        newCategories.add(category);
                      } else {
                        newCategories.remove(category);
                      }
                      onCategoriesChanged(newCategories);
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
