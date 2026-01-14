import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'cylinder_form_dialog.dart';

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
                    Flexible(
                      child: Text(
                        '${cylinder.weight}kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF0A0A0A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: Text(
                  '${numberFormat.format(cylinder.sellPrice.toInt())} FCFA',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF101828),
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
                    color: const Color(0xFF101828),
                  ),
                  overflow: TextOverflow.ellipsis,
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
                        onPressed: onDelete,
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
  }
}
