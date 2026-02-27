import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'cylinder_form_dialog.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';

/// Ligne du tableau des tarifs des bouteilles.
class BottlePriceTableRow extends ConsumerWidget {
  const BottlePriceTableRow({
    super.key,
    required this.cylinder,
    required this.onDelete,
  });

  final Cylinder cylinder;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylinderSettingsAsync = ref.watch(
      gazSettingsProvider((
        enterpriseId: cylinder.enterpriseId,
        moduleId: cylinder.moduleId,
      )),
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
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cylinder.weight}kg',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Actif',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détail: ${numberFormat.format(cylinder.sellPrice.toInt())} FCFA',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Gros: ${wholesalePrice != null && wholesalePrice > 0 ? "${numberFormat.format(wholesalePrice.toInt())} FCFA" : "-"}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElyfIconButton(
                              icon: Icons.edit,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => CylinderFormDialog(
                                    cylinder: cylinder,
                                    enterpriseId: cylinder.enterpriseId,
                                    moduleId: cylinder.moduleId,
                                  ),
                                );
                              },
                              useGlassEffect: false,
                              size: 32,
                              iconSize: 16,
                              tooltip: 'Modifier',
                            ),
                            const SizedBox(width: 8),
                            ElyfIconButton(
                              icon: Icons.delete_outline,
                              onPressed: onDelete,
                              useGlassEffect: false,
                              size: 32,
                              iconSize: 16,
                              iconColor: theme.colorScheme.error,
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${cylinder.weight}kg',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            '${numberFormat.format(cylinder.sellPrice.toInt())} FCFA',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(
                            wholesalePrice != null && wholesalePrice > 0
                                ? '${numberFormat.format(wholesalePrice.toInt())} FCFA'
                                : '-',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Actif',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                          ElyfIconButton(
                            icon: Icons.edit,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => CylinderFormDialog(
                                  cylinder: cylinder,
                                  enterpriseId: cylinder.enterpriseId,
                                  moduleId: cylinder.moduleId,
                                ),
                              );
                            },
                            useGlassEffect: false,
                            size: 32,
                            iconSize: 16,
                            tooltip: 'Modifier',
                          ),
                          const SizedBox(width: 2),
                          ElyfIconButton(
                            icon: Icons.delete_outline,
                            onPressed: onDelete,
                            useGlassEffect: false,
                            size: 32,
                            iconSize: 16,
                            iconColor: theme.colorScheme.error,
                            tooltip: 'Supprimer',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
  }
}
