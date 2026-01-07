import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../../application/controllers/cylinder_stock_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/cylinder.dart';

/// Widget pour sélectionner une bouteille avec affichage du stock disponible.
class CylinderSelectorWidget extends ConsumerWidget {
  const CylinderSelectorWidget({
    super.key,
    required this.selectedCylinder,
    required this.onCylinderChanged,
  });

  final Cylinder? selectedCylinder;
  final ValueChanged<Cylinder?> onCylinderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);

    return cylindersAsync.when(
      data: (cylinders) {
        if (cylinders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aucune bouteille disponible',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Cylinder>(
              value: selectedCylinder,
              decoration: InputDecoration(
                labelText: 'Type de bouteille *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.local_fire_department),
              ),
              items: cylinders.map((cylinder) {
                return DropdownMenuItem(
                  value: cylinder,
                  enabled: true,
                  child: Text(
                    '${cylinder.weight} kg - ${CurrencyFormatter.formatDouble(cylinder.sellPrice)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onCylinderChanged,
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une bouteille';
                }
                return null;
              },
            ),
            if (selectedCylinder != null) ...[
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: ref
                    .read(cylinderStockControllerProvider)
                    .getAvailableStock(
                      selectedCylinder!.enterpriseId,
                      selectedCylinder!.weight,
                    ),
                builder: (context, snapshot) {
                  final stock = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: stock <= 5
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          stock <= 5 ? Icons.warning : Icons.inventory_2,
                          size: 16,
                          color: stock <= 5
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stock disponible: $stock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: stock <= 5
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Erreur: ${error.toString()}',
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

