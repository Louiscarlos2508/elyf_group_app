import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

/// Widget for selecting a cylinder type.
class CylinderSelectorField extends ConsumerWidget {
  const CylinderSelectorField({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
    this.selectedPointOfSale,
    this.selectedCylinder,
    this.onCylinderChanged,
    this.validator,
  });

  final String enterpriseId;
  final String moduleId;
  final Enterprise? selectedPointOfSale;
  final Cylinder? selectedCylinder;
  final ValueChanged<Cylinder?>? onCylinderChanged;
  final FormFieldValidator<Cylinder>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If a point of sale is selected, use its cylinders
    if (selectedPointOfSale != null) {
      final cylindersAsync = ref.watch(
        pointOfSaleCylindersProvider((
          pointOfSaleId: selectedPointOfSale!.id,
          enterpriseId: enterpriseId,
          moduleId: moduleId,
        )),
      );

      return cylindersAsync.when(
        data: (cylinders) {
          if (cylinders.isEmpty) {
            return _buildEmptyState(
              'Aucun type de bouteille configuré pour ce point de vente',
            );
          }

          return _buildDropdown(cylinders);
        },
        loading: () => const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _buildErrorState('Erreur de chargement: $e'),
      );
    }

    // If no point of sale is selected, show all cylinders
    final allCylindersAsync = ref.watch(cylindersProvider);
    return allCylindersAsync.when(
      data: (cylinders) {
        if (cylinders.isEmpty) {
          return _buildEmptyState('Aucun type de bouteille disponible');
        }

        return _buildDropdown(cylinders);
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildErrorState('Erreur de chargement: $e'),
    );
  }

  Widget _buildDropdown(List<Cylinder> cylinders) {
    return DropdownButtonFormField<Cylinder>(
      initialValue: selectedCylinder,
      decoration: const InputDecoration(
        labelText: 'Type de bouteille *',
        prefixIcon: Icon(Icons.scale),
        border: OutlineInputBorder(),
        helperText: 'Sélectionnez le type de bouteille',
      ),
      items: cylinders.map((cylinder) {
        return DropdownMenuItem<Cylinder>(
          value: cylinder,
          child: Text('${cylinder.weight} kg'),
        );
      }).toList(),
      onChanged: onCylinderChanged,
      validator: validator,
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
