import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'bottle_price_table_header.dart';
import 'bottle_price_table_row.dart';

/// Tableau des tarifs des bouteilles selon le design Figma.
class BottlePriceTable extends ConsumerWidget {
  const BottlePriceTable({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  Future<void> _deleteCylinder(
    BuildContext context,
    WidgetRef ref,
    Cylinder cylinder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le type de bouteille'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la bouteille de ${cylinder.weight}kg ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final controller = ref.read(cylinderControllerProvider);
      await controller.deleteCylinder(cylinder.id);

      if (!context.mounted) return;

      ref.invalidate(cylindersProvider);

      NotificationService.showSuccess(
        context,
        'Type de bouteille supprimé avec succès',
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(
        context,
        'Erreur lors de la suppression: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);

    return cylindersAsync.when(
      data: (cylinders) {
        if (cylinders.isEmpty) {
          return Container(
            padding: const EdgeInsets.fromLTRB(25.285, 25.285, 1.305, 1.305),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.305,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucune bouteille créée'),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(25.285, 25.285, 1.305, 1.305),
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
              // En-tête de la carte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 20,
                        color: Color(0xFF0A0A0A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tarifs des bouteilles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 42),
              // Tableau
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.305,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 100,
                    ),
                    child: Column(
                      children: [
                        const BottlePriceTableHeader(),
                        ...cylinders.map(
                          (cylinder) => BottlePriceTableRow(
                            cylinder: cylinder,
                            onDelete: () => _deleteCylinder(
                              context,
                              ref,
                              cylinder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}
