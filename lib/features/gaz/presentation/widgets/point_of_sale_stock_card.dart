import 'package:flutter/material.dart';

import '../../domain/entities/point_of_sale.dart';
import 'point_of_sale_stock/pos_bottles_summary.dart';
import 'point_of_sale_stock/pos_stock_header.dart';
import 'point_of_sale_stock/pos_stock_table.dart';

/// Card displaying stock information for a point of sale - matches Figma design.
class PointOfSaleStockCard extends StatelessWidget {
  const PointOfSaleStockCard({
    super.key,
    required this.pointOfSale,
    required this.fullBottles,
    required this.emptyBottles,
    required this.stockByCapacity,
  });

  final PointOfSale pointOfSale;
  final int fullBottles;
  final int emptyBottles;
  final Map<int, ({int full, int empty})> stockByCapacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with POS info and status badge
          PosStockHeader(pointOfSale: pointOfSale),
          const SizedBox(height: 16),
          // Full and empty bottles cards
          PosBottlesSummary(
            fullBottles: fullBottles,
            emptyBottles: emptyBottles,
          ),
          const SizedBox(height: 16),
          // Stock table by capacity
          PosStockTable(stockByCapacity: stockByCapacity),
        ],
      ),
    );
  }
}
