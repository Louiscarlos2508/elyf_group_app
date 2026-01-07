import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/point_of_sale.dart';
import '../../../../shared.dart';
import '../point_of_sale_form_dialog.dart';
import 'pos_stock_dialog.dart';
import 'pos_types_dialog.dart';

/// Ligne du tableau des points de vente.
class PosTableRow extends ConsumerWidget {
  const PosTableRow({
    super.key,
    required this.pointOfSale,
    required this.enterpriseId,
    required this.moduleId,
  });

  final PointOfSale pointOfSale;
  final String enterpriseId;
  final String moduleId;

  Future<void> _showStockDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => PosStockDialog(
        pointOfSale: pointOfSale,
        enterpriseId: enterpriseId,
      ),
    );
  }

  Future<void> _showTypesDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => PosTypesDialog(
        pointOfSale: pointOfSale,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
    );
  }

  Future<void> _editPointOfSale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PointOfSaleFormDialog(
        pointOfSale: pointOfSale,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
    );

    if (result == true && context.mounted) {
      // Le provider sera invalidé dans le dialog
    }
  }

  Future<void> _deletePointOfSale(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le point de vente'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${pointOfSale.name}" ?\n\nCette action est irréversible.',
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
      final controller = ref.read(pointOfSaleControllerProvider);
      await controller.deletePointOfSale(pointOfSale.id);

      if (!context.mounted) return;

      ref.invalidate(
        pointsOfSaleProvider(
          (enterpriseId: enterpriseId, moduleId: moduleId),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Point de vente supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
            width: 200,
            child: Row(
              children: [
                const Icon(
                  Icons.store,
                  size: 16,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pointOfSale.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: Color(0xFF4A5565),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pointOfSale.address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF4A5565),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 12,
                  color: Color(0xFF4A5565),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pointOfSale.contact,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF4A5565),
                    ),
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
                  color: pointOfSale.isActive
                      ? const Color(0xFF030213)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pointOfSale.isActive ? 'Actif' : 'Inactif',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: GazButtonStyles.outlined.copyWith(
                      padding: const MaterialStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      ),
                      minimumSize: const MaterialStatePropertyAll(Size(60, 28)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showStockDialog(context, ref),
                    icon: const Icon(Icons.inventory_2, size: 14),
                    label: const Text(
                      'Stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  OutlinedButton.icon(
                    style: GazButtonStyles.outlined.copyWith(
                      padding: const MaterialStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      ),
                      minimumSize: const MaterialStatePropertyAll(Size(60, 28)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showTypesDialog(context, ref),
                    icon: const Icon(Icons.settings, size: 14),
                    label: const Text(
                      'Types',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color(0xFF0A0A0A),
                    ),
                    onPressed: () => _editPointOfSale(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Modifier',
                  ),
                  const SizedBox(width: 3),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFFE7000B),
                    ),
                    onPressed: () => _deletePointOfSale(context, ref),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
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
  }
}
