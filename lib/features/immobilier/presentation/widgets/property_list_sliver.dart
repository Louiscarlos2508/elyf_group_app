import 'package:flutter/material.dart';

import '../../domain/entities/property.dart';
import 'property_card.dart';

/// Widget Sliver pour la liste des propriétés.
class PropertyListSliver extends StatelessWidget {
  const PropertyListSliver({
    super.key,
    required this.properties,
    required this.onPropertyTap,
  });

  final List<Property> properties;
  final void Function(Property) onPropertyTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final property = properties[index];
            return PropertyCard(
              property: property,
              onTap: () => onPropertyTap(property),
            );
          },
          childCount: properties.length,
        ),
      ),
    );
  }
}

