import 'package:flutter/material.dart';

import '../../domain/entities/point_of_sale.dart';
import 'point_of_sale_table/pos_table_header.dart';
import 'point_of_sale_table/pos_table_row.dart';

/// Tableau des points de vente selon le design Figma.
class PointOfSaleTable extends StatelessWidget {
  const PointOfSaleTable({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // TODO: Remplacer par un provider réel
    final pointsOfSale = _getMockPointsOfSale();

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
            children: [
              const Icon(
                Icons.store,
                size: 20,
                color: Color(0xFF0A0A0A),
              ),
              const SizedBox(width: 8),
              Text(
                'Points de vente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
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
                const PosTableHeader(),
                // Corps du tableau
                ...pointsOfSale.map((pos) => PosTableRow(pointOfSale: pos)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne des points de vente mock pour le développement.
  List<PointOfSale> _getMockPointsOfSale() {
    return [
      PointOfSale(
        id: 'pos_1',
        name: 'Point de vente 1',
        address: '123 Rue de la Gaz',
        contact: '0123456789',
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        isActive: true,
      ),
      PointOfSale(
        id: 'pos_2',
        name: 'Point de vente 2',
        address: '456 Rue de la Gaz',
        contact: '0987654321',
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        isActive: true,
      ),
    ];
  }
}
