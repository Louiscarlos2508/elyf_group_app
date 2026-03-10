import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../point_of_sale_form_dialog.dart';

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
            case 'edit':
              _editPointOfSale(context);
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
        ],
      ),
    );
  }
}
