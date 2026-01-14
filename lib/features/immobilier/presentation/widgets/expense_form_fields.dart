import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/property.dart';

/// Widgets de champs pour le formulaire de dépense.
class ExpenseFormFields {
  ExpenseFormFields._();

  static Widget propertyField({
    required Property? selectedProperty,
    required List<Property> properties,
    required ValueChanged<Property?> onChanged,
    required String? Function(Property?) validator,
  }) {
    return DropdownButtonFormField<Property>(
      initialValue: selectedProperty,
      decoration: const InputDecoration(
        labelText: 'Propriété *',
        prefixIcon: Icon(Icons.home),
      ),
      items: properties.map((property) {
        return DropdownMenuItem(
          value: property,
          child: Text('${property.address}, ${property.city}'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  static Widget dateField({
    required DateTime expenseDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date de dépense *',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${expenseDate.day.toString().padLeft(2, '0')}/'
          '${expenseDate.month.toString().padLeft(2, '0')}/'
          '${expenseDate.year}',
        ),
      ),
    );
  }

  static Widget amountField({
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Montant (FCFA) *',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
    );
  }

  static Widget categoryField({
    required ExpenseCategory value,
    required ValueChanged<ExpenseCategory?> onChanged,
  }) {
    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Catégorie *',
        prefixIcon: Icon(Icons.category),
      ),
      items: ExpenseCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(getCategoryIcon(category), size: 20),
              const SizedBox(width: 12),
              Text(_getCategoryLabel(category)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget descriptionField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Description *',
        hintText: 'Description de la dépense...',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La description est requise';
        }
        return null;
      },
    );
  }

  static Widget receiptField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Numéro de reçu',
        hintText: 'REC-2024-001',
        prefixIcon: Icon(Icons.receipt),
      ),
    );
  }

  static IconData getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.repair:
        return Icons.handyman;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.insurance:
        return Icons.shield;
      case ExpenseCategory.taxes:
        return Icons.receipt_long;
      case ExpenseCategory.cleaning:
        return Icons.cleaning_services;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  static String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.repair:
        return 'Réparation';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.insurance:
        return 'Assurance';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.cleaning:
        return 'Nettoyage';
      case ExpenseCategory.other:
        return 'Autre';
    }
  }
}
