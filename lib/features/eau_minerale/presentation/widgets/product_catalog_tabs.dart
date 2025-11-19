import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/product.dart';

/// Tabs for filtering products by type.
class ProductCatalogTabs extends ConsumerWidget {
  const ProductCatalogTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ProductType? selectedFilter;
  final ValueChanged<ProductType?> onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        final allCount = products.length;
        final mpCount = products.where((p) => p.isRawMaterial).length;
        final pfCount = products.where((p) => p.isFinishedGood).length;

        return Row(
          children: [
            _TabButton(
              label: 'Tous ($allCount)',
              isSelected: selectedFilter == null,
              onTap: () => onFilterChanged(null),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'MP ($mpCount)',
              icon: Icons.inventory_2_outlined,
              isSelected: selectedFilter == ProductType.rawMaterial,
              onTap: () => onFilterChanged(ProductType.rawMaterial),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'PF ($pfCount)',
              icon: Icons.description_outlined,
              isSelected: selectedFilter == ProductType.finishedGood,
              onTap: () => onFilterChanged(ProductType.finishedGood),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.grey.shade200
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

