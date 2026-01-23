import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/collection.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../application/providers.dart';
import '../../collection_item_widget.dart';
import '../../collection_edit_dialog.dart';
import '../../../../../../shared.dart';

/// Section de liste des collections par type.
class CollectionListSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              onEdit: () => _showEditDialog(context, ref, collection),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CollectionEditDialog(
          tour: tour,
          collection: collection,
        ),
      );
      if (result == true && context.mounted) {
        ref.invalidate(toursProvider((enterpriseId: tour.enterpriseId, status: null)));
        ref.invalidate(tourProvider(tour.id));
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Erreur lors de l\'édition: $e',
        );
      }
    }
  }
}
