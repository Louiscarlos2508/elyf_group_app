import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../domain/entities/property.dart';
import 'property_detail_helpers.dart';
import 'property_detail_widgets.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// Dialog pour afficher les détails d'une propriété.
class PropertyDetailDialog extends ConsumerWidget {
  const PropertyDetailDialog({
    super.key,
    required this.property,
    this.onEdit,
    this.onDelete,
    this.onAddContract,
    this.onAddExpense,
  });

  final Property property;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddContract;
  final VoidCallback? onAddExpense;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profitabilityAsync = ref.watch(propertyProfitabilityProvider(property.id));

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
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
                          value: PropertyDetailHelpers.getTypeLabel(
                            property.propertyType,
                          ),
                          icon: Icons.category,
                        ),
                        PropertyDetailRow(
                          label: 'Statut',
                          value: PropertyDetailHelpers.getStatusLabel(
                            property.status,
                          ),
                          icon: Icons.info_outline,
                          valueColor: _getStatusColor(property.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Profitability KPI Card
                    profitabilityAsync.when(
                      data: (data) => _buildProfitabilityCard(theme, data),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) => Text('Erreur rentabilité: $e'),
                    ),
                    const SizedBox(height: 16),
                    // Quick Actions
                    Row(
                      children: [
                        if (onAddContract != null &&
                            property.status == PropertyStatus.available) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onAddContract?.call();
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Nouveau Contrat'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onAddExpense != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onAddExpense?.call();
                              },
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Ajouter Dépense'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
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
                          value: PropertyDetailHelpers.formatCurrency(
                            property.price,
                          ),
                          icon: Icons.attach_money,
                          valueColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    if (property.description != null &&
                        property.description!.isNotEmpty) ...[
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
                    if (property.amenities != null &&
                        property.amenities!.isNotEmpty) ...[
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
                                avatar: const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Colors.green,
                                ),
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

  Widget _buildProfitabilityCard(ThemeData theme, ({int revenue, int expenses, int net}) data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE FINANCIÈRE',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(theme, 'Recettes', data.revenue, Colors.green),
              _buildMetricItem(theme, 'Dépenses', data.expenses, Colors.red),
              _buildMetricItem(theme, 'Rendement Net', data.net, Colors.blue, isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(ThemeData theme, String label, int amount, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(
          CurrencyFormatter.formatFCFA(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
