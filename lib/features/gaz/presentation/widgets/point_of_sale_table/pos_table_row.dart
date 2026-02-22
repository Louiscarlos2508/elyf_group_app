import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../point_of_sale_form_dialog.dart';
import 'pos_stock_dialog.dart';
import 'pos_types_dialog.dart';

/// Ligne du tableau des points de vente.
class PosTableRow extends ConsumerWidget {
  const PosTableRow({
    super.key,
    required this.enterprise,
    required this.enterpriseId,
    required this.moduleId,
  });

  final Enterprise enterprise;
  final String enterpriseId;
  final String moduleId;

  Future<void> _showStockDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) =>
          PosStockDialog(enterprise: enterprise, enterpriseId: enterpriseId),
    );
  }

  Future<void> _showTypesDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => PosTypesDialog(
        enterprise: enterprise,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
    );
  }

  Future<void> _editPointOfSale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PointOfSaleFormDialog(
        enterprise: enterprise,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      ),
    );

    if (result == true && context.mounted) {
      // Le provider sera invalidé dans le dialog
    }
  }

  Future<void> _deletePointOfSale(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le point de vente'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${enterprise.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          ElyfButton(
            onPressed: () => Navigator.of(context).pop(false),
            variant: ElyfButtonVariant.text,
            child: const Text('Annuler'),
          ),
          ElyfButton(
            onPressed: () => Navigator.of(context).pop(true),
            backgroundColor: theme.colorScheme.error,
            textColor: theme.colorScheme.onError,
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final controller = ref.read(enterpriseControllerProvider);
      await controller.deleteEnterprise(enterprise.id);

      if (!context.mounted) return;

      ref.invalidate(
        enterprisesByParentAndTypeProvider((parentId: enterpriseId, type: EnterpriseType.gasPointOfSale)),
      );

      NotificationService.showSuccess(
        context,
        'Point de vente supprimé avec succès',
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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.storefront_outlined,
          size: 24,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              enterprise.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enterprise.isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              enterprise.isActive ? 'Actif' : 'Inactif',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: enterprise.isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: enterprise.address ?? 'Aucune adresse',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const TextSpan(text: '  •  '),
            TextSpan(
              text: enterprise.phone ?? 'Aucun contact',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          switch (value) {
            case 'stock':
              _showStockDialog(context, ref);
              break;
            case 'types':
              _showTypesDialog(context, ref);
              break;
            case 'edit':
              _editPointOfSale(context);
              break;
            case 'delete':
              _deletePointOfSale(context, ref);
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'stock',
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 20),
                SizedBox(width: 12),
                Text('Stock'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'types',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 20),
                SizedBox(width: 12),
                Text('Types Bouteilles'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 12),
                Text('Modifier'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text('Supprimer', style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
