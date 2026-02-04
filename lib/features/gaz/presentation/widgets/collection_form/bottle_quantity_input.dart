import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/presentation/widgets/gaz_button_styles.dart';

/// Formulaire d'ajout de bouteille avec sélection du type et de la quantité.
class BottleQuantityInput extends StatelessWidget {
  const BottleQuantityInput({
    super.key,
    required this.availableWeights,
    required this.selectedWeight,
    required this.quantityController,
    required this.onWeightSelected,
    required this.onAdd,
  });

  final List<int> availableWeights;
  final int? selectedWeight;
  final TextEditingController quantityController;
  final ValueChanged<int> onWeightSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final lightGray = const Color(0xFFF3F3F5);
    final textGray = const Color(0xFF717182);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type dropdown
        Text(
          'Type',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        availableWeights.isEmpty
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucune bouteille créée. Créez d\'abord des types de bouteilles dans les paramètres.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : PopupMenuButton<int>(
                onSelected: onWeightSelected,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedWeight == null ? 'Type' : '${selectedWeight}kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selectedWeight == null
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => availableWeights
                    .map(
                      (weight) => PopupMenuItem(
                        value: weight,
                        child: Text('${weight}kg'),
                      ),
                    )
                    .toList(),
              ),
        const SizedBox(height: 16),
        // Quantité
        Text(
          'Quantité',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: quantityController,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: theme.textTheme.bodyMedium,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 24),
        // Bouton Ajouter
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: onAdd,
            style: GazButtonStyles.filledPrimaryIcon(context),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      ],
    );
  }
}
