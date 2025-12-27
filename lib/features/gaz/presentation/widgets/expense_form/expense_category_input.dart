import 'package:flutter/material.dart';

import '../../../../domain/entities/expense.dart';

/// Input pour la catégorie de la dépense.
class ExpenseCategoryInput extends StatelessWidget {
  const ExpenseCategoryInput({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final ExpenseCategory selectedCategory;
  final ValueChanged<ExpenseCategory> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpenseCategory>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Catégorie',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: ExpenseCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category.label),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onCategoryChanged(value);
        }
      },
    );
  }
}

