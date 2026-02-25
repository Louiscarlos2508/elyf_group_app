import 'package:flutter/material.dart';

/// Formulaire d'ajout de bouteille avec sélection du type et de la quantité.
class BottleQuantityInput extends StatelessWidget {
  const BottleQuantityInput({
    super.key,
    required this.availableWeights,
    required this.selectedWeight,
    required this.quantityController,
    required this.onWeightSelected,
    required this.onAdd,
    this.maxQuantity,
  });

  final List<int> availableWeights;
  final int? selectedWeight;
  final TextEditingController quantityController;
  final ValueChanged<int> onWeightSelected;
  final VoidCallback onAdd;
  final int? maxQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type dropdown
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
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
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
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
                                  selectedWeight == null ? 'Choisir' : '${selectedWeight}kg',
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Quantité
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantité',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: quantityController,
                    textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        hintText: '0',
                        helperText: maxQuantity != null ? '$maxQuantity disponible' : null,
                        helperStyle: theme.textTheme.labelSmall?.copyWith(
                          color: (maxQuantity ?? 0) > 0 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
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
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                    style: theme.textTheme.bodyMedium,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Bouton Ajouter
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
