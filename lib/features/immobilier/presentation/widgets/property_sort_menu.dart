import 'package:flutter/material.dart';

/// Menu de tri pour les propriétés.
enum PropertySortOption {
  priceAsc,
  priceDesc,
  areaAsc,
  areaDesc,
  roomsAsc,
  roomsDesc,
  dateNewest,
  dateOldest,
}

class PropertySortMenu extends StatelessWidget {
  const PropertySortMenu({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final PropertySortOption selectedSort;
  final ValueChanged<PropertySortOption> onSortChanged;

  String _getSortLabel(PropertySortOption sort) {
    switch (sort) {
      case PropertySortOption.priceAsc:
        return 'Prix croissant';
      case PropertySortOption.priceDesc:
        return 'Prix décroissant';
      case PropertySortOption.areaAsc:
        return 'Surface croissante';
      case PropertySortOption.areaDesc:
        return 'Surface décroissante';
      case PropertySortOption.roomsAsc:
        return 'Pièces croissantes';
      case PropertySortOption.roomsDesc:
        return 'Pièces décroissantes';
      case PropertySortOption.dateNewest:
        return 'Plus récentes';
      case PropertySortOption.dateOldest:
        return 'Plus anciennes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<PropertySortOption>(
      icon: Icon(Icons.sort, color: theme.colorScheme.onSurfaceVariant),
      tooltip: 'Trier',
      onSelected: onSortChanged,
      itemBuilder: (context) => PropertySortOption.values.map((sort) {
        return PopupMenuItem<PropertySortOption>(
          value: sort,
          child: Row(
            children: [
              if (selectedSort == sort)
                Icon(Icons.check, size: 20, color: theme.colorScheme.primary)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              Text(_getSortLabel(sort)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
