import 'package:flutter/material.dart';

import '../../../../domain/entities/collection.dart';
import '../../../../domain/entities/tour.dart';
import '../../collection_item_widget.dart';

/// Section de liste des collections par type.
class CollectionListSection extends StatelessWidget {
  const CollectionListSection({
    super.key,
    required this.tour,
    required this.collections,
    required this.title,
  });

  final Tour tour;
  final List<Collection> collections;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xFF364153)),
        ),
        const SizedBox(height: 8),
        ...collections.map((collection) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CollectionItemWidget(
              tour: tour,
              collection: collection,
              onEdit: () async {
                // TODO: Implémenter l'édition
              },
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
