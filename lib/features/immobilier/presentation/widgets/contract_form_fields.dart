import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/contract.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'deposit_field.dart';

/// Widgets de champs pour le formulaire de contrat.
class ContractFormFields {
  ContractFormFields._();

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

  static Widget tenantField({
    required Tenant? selectedTenant,
    required List<Tenant> tenants,
    required ValueChanged<Tenant?> onChanged,
    required String? Function(Tenant?) validator,
  }) {
    return DropdownButtonFormField<Tenant>(
      initialValue: selectedTenant,
      decoration: const InputDecoration(
        labelText: 'Locataire *',
        prefixIcon: Icon(Icons.person),
      ),
      items: tenants.map((tenant) {
        return DropdownMenuItem(value: tenant, child: Text(tenant.fullName));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  static Widget dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}',
        ),
      ),
    );
  }

  static Widget monthlyRentField({
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Loyer mensuel (FCFA) *',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
    );
  }

  static Widget depositField({
    required TextEditingController depositController,
    required TextEditingController depositInMonthsController,
    required int? monthlyRent,
    int? initialDeposit,
    int? initialDepositInMonths,
  }) {
    return DepositField(
      depositController: depositController,
      depositInMonthsController: depositInMonthsController,
      monthlyRent: monthlyRent,
      initialDeposit: initialDeposit,
      initialDepositInMonths: initialDepositInMonths,
    );
  }

  static Widget paymentDayField({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Jour de paiement',
        prefixIcon: Icon(Icons.calendar_today),
      ),
      items: List.generate(31, (index) => index + 1).map((day) {
        return DropdownMenuItem(
          value: day,
          child: Text('Le $day de chaque mois'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget statusField({
    required ContractStatus value,
    required ValueChanged<ContractStatus?> onChanged,
  }) {
    return DropdownButtonFormField<ContractStatus>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Statut *',
        prefixIcon: Icon(Icons.info_outline),
      ),
      items: ContractStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(_getStatusLabel(status)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget notesField({required TextEditingController controller}) {
    return TextFormField(
      textCapitalization: TextCapitalization.sentences,
    );
  }

  static Widget inventoryField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? 'Description de l\'état des lieux...',
        prefixIcon: Icon(icon),
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  static String _getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return 'Actif';
      case ContractStatus.pending:
        return 'En attente';
      case ContractStatus.expired:
        return 'Expiré';
      case ContractStatus.terminated:
        return 'Résilié';
    }
  }
}
