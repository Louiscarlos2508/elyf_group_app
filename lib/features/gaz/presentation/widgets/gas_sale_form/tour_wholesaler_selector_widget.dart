import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';

/// Widget pour sélectionner un tour et un grossiste (pour ventes en gros).
class TourWholesalerSelectorWidget extends ConsumerWidget {
  const TourWholesalerSelectorWidget({
    super.key,
    required this.selectedTour,
    required this.selectedWholesalerId,
    required this.selectedWholesalerName,
    required this.enterpriseId,
    required this.onTourChanged,
    required this.onWholesalerChanged,
  });

  final Tour? selectedTour;
  final String? selectedWholesalerId;
  final String? selectedWholesalerName;
  final String enterpriseId;
  final ValueChanged<Tour?> onTourChanged;
  final ValueChanged<({String id, String name})?> onWholesalerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toursAsync = ref.watch(
      toursProvider(
        (enterpriseId: enterpriseId, status: null),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélection du tour
        toursAsync.when(
          data: (tours) {
            // Filtrer les tours actifs (pas clôturés)
            final activeTours = tours
                .where((t) =>
                    t.status != TourStatus.closure &&
                    t.status != TourStatus.cancelled)
                .toList();

            return DropdownButtonFormField<Tour?>(
              value: selectedTour,
              decoration: const InputDecoration(
                labelText: 'Tour d\'approvisionnement *',
                prefixIcon: Icon(Icons.local_shipping),
                border: OutlineInputBorder(),
                helperText: 'Sélectionnez le tour lié à cette vente',
              ),
              items: [
                const DropdownMenuItem<Tour?>(
                  value: null,
                  child: Text('Aucun tour'),
                ),
                ...activeTours.map(
                  (tour) => DropdownMenuItem<Tour?>(
                    value: tour,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tour du ${_formatDate(tour.tourDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${tour.collections.where((c) => c.type == CollectionType.wholesaler).length} grossiste(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                onTourChanged(value);
                // Réinitialiser le grossiste sélectionné quand le tour change
                onWholesalerChanged(null);
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un tour';
                }
                return null;
              },
            );
          },
          loading: () => const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur de chargement des tours: $e',
                    style: TextStyle(color: Colors.red[900], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sélection du grossiste (seulement si un tour est sélectionné)
        if (selectedTour != null)
          _buildWholesalerSelector(selectedTour!),
      ],
    );
  }

  Widget _buildWholesalerSelector(Tour tour) {
    // Filtrer les collections de type grossiste
    final wholesalerCollections = tour.collections
        .where((c) => c.type == CollectionType.wholesaler)
        .toList();

    if (wholesalerCollections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucun grossiste dans ce tour',
                style: TextStyle(color: Colors.orange[900], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedWholesalerId,
      decoration: const InputDecoration(
        labelText: 'Grossiste *',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
        helperText: 'Sélectionnez le grossiste concerné',
      ),
      items: wholesalerCollections.map((collection) {
        return DropdownMenuItem<String>(
          value: collection.clientId,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                collection.clientName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (collection.clientPhone.isNotEmpty)
                Text(
                  collection.clientPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final collection = wholesalerCollections.firstWhere(
            (c) => c.clientId == value,
          );
          onWholesalerChanged((
            id: collection.clientId,
            name: collection.clientName,
          ));
        } else {
          onWholesalerChanged(null);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un grossiste';
        }
        return null;
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

