import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/entities/property.dart';


class MaintenanceFormFields {
  MaintenanceFormFields._();

  static Widget propertyField({
    required Property? selectedProperty,
    required List<Property> properties,
    required ValueChanged<Property?> onChanged,
    required String? Function(Property?) validator,
  }) {
    return DropdownButtonFormField<Property>(
      key: ValueKey(selectedProperty),
      initialValue: selectedProperty,
      decoration: const InputDecoration(
        labelText: 'Propriété *',
        prefixIcon: Icon(Icons.home),
      ),
      items: properties.map((property) {
        return DropdownMenuItem(
          value: property,
          child: Text(property.address),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  static Widget descriptionField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Description du problème *',
        hintText: 'Ex: Fuite d\'eau dans la cuisine...',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La description est requise';
        }
        return null;
      },
      textCapitalization: TextCapitalization.sentences,
    );
  }

  static Widget priorityField({
    required MaintenancePriority value,
    required ValueChanged<MaintenancePriority?> onChanged,
  }) {
    return DropdownButtonFormField<MaintenancePriority>(
      key: ValueKey(value),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Priorité',
        prefixIcon: Icon(Icons.flag),
      ),
      items: MaintenancePriority.values.map((priority) {
        return DropdownMenuItem(
          value: priority,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: _getPriorityColor(priority),
              ),
              const SizedBox(width: 8),
              Text(_getPriorityLabel(priority)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget statusField({
    required MaintenanceStatus value,
    required ValueChanged<MaintenanceStatus?> onChanged,
  }) {
    return DropdownButtonFormField<MaintenanceStatus>(
      key: ValueKey(value),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Statut',
        prefixIcon: Icon(Icons.info_outline),
      ),
      items: MaintenanceStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(_getStatusLabel(status)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget costField({
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Coût estimé (FCFA)',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  static Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.critical:
        return Colors.purple;
    }
  }

  static String _getPriorityLabel(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return 'Basse';
      case MaintenancePriority.medium:
        return 'Moyenne';
      case MaintenancePriority.high:
        return 'Haute';
      case MaintenancePriority.critical:
        return 'Critique';
    }
  }

  static String _getStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.open:
        return 'Ouvert';
      case MaintenanceStatus.inProgress:
        return 'En cours';
      case MaintenanceStatus.resolved:
        return 'Résolu';
      case MaintenanceStatus.closed:
        return 'Fermé';
    }
  }
}
