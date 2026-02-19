import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';

class BoutiqueCategoryFilter extends StatelessWidget {
  const BoutiqueCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            context,
            label: 'Tout',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          ...categories.map((category) {
            return _buildChip(
              context,
              label: category.name,
              isSelected: selectedCategory == category.id,
              onTap: () => onCategorySelected(category.id),
              color: category.colorValue != null ? Color(category.colorValue!) : null,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: color != null ? CircleAvatar(backgroundColor: color, radius: 6) : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: isSelected && color != null ? color.withValues(alpha: 0.2) : colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected 
              ? (color ?? colorScheme.onPrimaryContainer) 
              : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected 
                ? (color ?? colorScheme.primary) 
                : colorScheme.outline.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
