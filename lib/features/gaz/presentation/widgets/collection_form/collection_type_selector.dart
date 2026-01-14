import 'package:flutter/material.dart';

import '../../../domain/entities/collection.dart';

/// Sélecteur de type de collecte (Grossiste ou Point de vente).
class CollectionTypeSelector extends StatelessWidget {
  const CollectionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final CollectionType selectedType;
  final ValueChanged<CollectionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de collecte',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                label: 'Grossiste',
                isSelected: selectedType == CollectionType.wholesaler,
                onTap: () => onTypeChanged(CollectionType.wholesaler),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TypeButton(
                label: 'Point de vente',
                isSelected: selectedType == CollectionType.pointOfSale,
                onTap: () => onTypeChanged(CollectionType.pointOfSale),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final darkColor = const Color(0xFF030213);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? darkColor : Colors.white,
          border: isSelected
              ? null
              : Border.all(
                  color: const Color(0xFF000000).withValues(alpha: 0.1),
                  width: 1.3,
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
          ),
        ),
      ),
    );
  }
}
