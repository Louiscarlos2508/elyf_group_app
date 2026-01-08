import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gaz_settings.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'cylinder_form_dialog.dart';

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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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

      NotificationService.showSuccess(context, 'Type de bouteille supprimé avec succès');
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(context, 'Erreur lors de la suppression: ${e.toString()}');
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

        // Récupérer les settings pour chaque cylinder (peut avoir des enterpriseId/moduleId différents)
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
                      // Le bouton "Modifier" global n'est plus nécessaire
                      // car chaque ligne a ses propres actions
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
                    child: Column(
                      children: [
                        // En-tête du tableau
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7.99,
                            vertical: 8.97,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF000000),
                                width: 1.305,
                                style: BorderStyle.solid,
                              ),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text(
                                  'Type de bouteille',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Prix détail',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Prix gros',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Statut',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Actions',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Corps du tableau
                        ...cylinders.map((cylinder) {
                          // Récupérer les settings pour ce cylinder spécifique
                          final cylinderSettingsAsync = ref.watch(
                            gazSettingsProvider(
                              (
                                enterpriseId: cylinder.enterpriseId,
                                moduleId: cylinder.moduleId,
                              ),
                            ),
                          );

                          return cylinderSettingsAsync.when(
                            data: (cylinderSettings) {
                              final wholesalePrice =
                                  cylinderSettings?.getWholesalePrice(cylinder.weight);
                              final numberFormat = NumberFormat('#,###', 'fr_FR');

                              return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.99,
                              vertical: 14.64,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  width: 1.305,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.inventory_2,
                                        size: 16,
                                        color: Color(0xFF0A0A0A),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${cylinder.weight}kg',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          color: const Color(0xFF0A0A0A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${numberFormat.format(cylinder.sellPrice.toInt())} FCFA',
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF101828),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    wholesalePrice != null && wholesalePrice! > 0
                                        ? '${numberFormat.format(wholesalePrice!.toInt())} FCFA'
                                        : '-',
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF101828),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF030213),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Actif',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Color(0xFF0A0A0A),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => CylinderFormDialog(
                                                cylinder: cylinder,
                                              ),
                                            );
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          tooltip: 'Modifier',
                                        ),
                                        const SizedBox(width: 2),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Color(0xFFE7000B),
                                          ),
                                          onPressed: () => _deleteCylinder(
                                            context,
                                            ref,
                                            cylinder,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                            },
                            loading: () => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.99,
                                vertical: 14.64,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            error: (e, _) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.99,
                                vertical: 14.64,
                              ),
                              child: Text('Erreur: $e'),
                            ),
                          );
                        }).toList(),
                      ],
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

