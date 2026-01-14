import 'package:flutter/material.dart';

import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';
import 'collection/collection_list_section.dart';
import 'collection/collection_step_header.dart';
import 'collection/collection_total_card.dart';

/// Contenu de l'étape collecte du tour.
class CollectionStepContent extends StatelessWidget {
  const CollectionStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
  });

  final Tour tour;
  final String enterpriseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Séparer les collections par type
    final wholesalerCollections = tour.collections
        .where((c) => c.type == CollectionType.wholesaler)
        .toList();
    final pointOfSaleCollections = tour.collections
        .where((c) => c.type == CollectionType.pointOfSale)
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectionStepHeader(tour: tour, enterpriseId: enterpriseId),
          const SizedBox(height: 24),
          CollectionListSection(
            tour: tour,
            collections: wholesalerCollections,
            title: 'Grossistes',
          ),
          CollectionListSection(
            tour: tour,
            collections: pointOfSaleCollections,
            title: 'Points de vente',
          ),
          // Message si aucune collecte
          if (tour.collections.isEmpty)
            SizedBox(
              height: 88,
              child: Center(
                child: Text(
                  'Aucune collecte enregistrée',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ),
            ),
          // Total général du chargement
          if (tour.collections.isNotEmpty)
            CollectionTotalCard(collections: tour.collections),
        ],
      ),
    );
  }
}
