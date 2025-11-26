import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/property.dart';
import 'property_card.dart';
import 'property_detail_dialog.dart';
import 'property_form_dialog.dart';

/// Widget pour le contenu de la liste des propriétés.
class PropertyListContent extends ConsumerWidget {
  const PropertyListContent({
    super.key,
    required this.filteredProperties,
    required this.allProperties,
    required this.onRefresh,
    required this.onPropertyTap,
  });

  final List<Property> filteredProperties;
  final List<Property> allProperties;
  final VoidCallback onRefresh;
  final void Function(Property) onPropertyTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (filteredProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allProperties.isEmpty ? Icons.home_outlined : Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              allProperties.isEmpty
                  ? 'Aucune propriété enregistrée'
                  : 'Aucun résultat trouvé',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredProperties.length,
        itemBuilder: (context, index) {
          final property = filteredProperties[index];
          return PropertyCard(
            property: property,
            onTap: () => onPropertyTap(property),
            onEdit: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => PropertyFormDialog(property: property),
              );
            },
            onDelete: () async {
              Navigator.of(context).pop();
              final controller = ref.read(propertyControllerProvider);
              try {
                await controller.deleteProperty(property.id);
                if (context.mounted) {
                  ref.invalidate(propertiesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Propriété supprimée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}

