import 'package:flutter/material.dart';

import '../../../domain/entities/point_of_sale.dart';
import '../../../../../shared/presentation/widgets/gaz_button_styles.dart';

/// Ligne du tableau des points de vente.
class PosTableRow extends StatelessWidget {
  const PosTableRow({
    super.key,
    required this.pointOfSale,
  });

  final PointOfSale pointOfSale;

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      // TODO: Ouvrir le stock
                    },
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
                    onPressed: () {
                      // TODO: Ouvrir les types
                    },
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
                    onPressed: () {
                      // TODO: Modifier le point de vente
                    },
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
                    onPressed: () {
                      // TODO: Supprimer le point de vente
                    },
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

