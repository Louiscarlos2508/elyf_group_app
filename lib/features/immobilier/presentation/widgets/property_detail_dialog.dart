import 'package:flutter/material.dart';

import '../../domain/entities/property.dart';
import 'property_detail_helpers.dart';
import 'property_detail_widgets.dart';

/// Dialog pour afficher les détails d'une propriété.
class PropertyDetailDialog extends StatelessWidget {
  const PropertyDetailDialog({
    super.key,
    required this.property,
    this.onEdit,
    this.onDelete,
  });

  final Property property;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return Colors.green;
      case PropertyStatus.rented:
        return Colors.blue;
      case PropertyStatus.maintenance:
        return Colors.orange;
      case PropertyStatus.sold:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Détails de la propriété'),
              automaticallyImplyLeading: false,
              actions: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Modifier',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer la propriété'),
                          content: const Text(
                            'Êtes-vous sûr de vouloir supprimer cette propriété ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                onDelete?.call();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Supprimer',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PropertyDetailSection(
                      title: 'Informations générales',
                      children: [
                        PropertyDetailRow(
                          label: 'Adresse',
                          value: property.address,
                          icon: Icons.location_on,
                        ),
                        PropertyDetailRow(
                          label: 'Ville',
                          value: property.city,
                          icon: Icons.location_city,
                        ),
                        PropertyDetailRow(
                          label: 'Type',
                          value: PropertyDetailHelpers.getTypeLabel(property.propertyType),
                          icon: Icons.category,
                        ),
                        PropertyDetailRow(
                          label: 'Statut',
                          value: PropertyDetailHelpers.getStatusLabel(property.status),
                          icon: Icons.info_outline,
                          valueColor: _getStatusColor(property.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PropertyDetailSection(
                      title: 'Caractéristiques',
                      children: [
                        PropertyDetailRow(
                          label: 'Nombre de pièces',
                          value: '${property.rooms}',
                          icon: Icons.bed,
                        ),
                        PropertyDetailRow(
                          label: 'Surface',
                          value: '${property.area} m²',
                          icon: Icons.square_foot,
                        ),
                        PropertyDetailRow(
                          label: 'Loyer mensuel',
                          value: PropertyDetailHelpers.formatCurrency(property.price),
                          icon: Icons.attach_money,
                          valueColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    if (property.description != null && property.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      PropertyDetailSection(
                        title: 'Description',
                        children: [
                          Text(
                            property.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                    if (property.amenities != null && property.amenities!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      PropertyDetailSection(
                        title: 'Équipements',
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: property.amenities!.map((amenity) {
                              return Chip(
                                label: Text(amenity),
                                avatar: const Icon(Icons.check_circle, size: 18),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    PropertyDetailSection(
                      title: 'Informations système',
                      children: [
                        PropertyDetailRow(
                          label: 'Créée le',
                          value: _formatDate(property.createdAt),
                          icon: Icons.calendar_today,
                        ),
                        if (property.updatedAt != null)
                          PropertyDetailRow(
                            label: 'Modifiée le',
                            value: _formatDate(property.updatedAt),
                            icon: Icons.update,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

