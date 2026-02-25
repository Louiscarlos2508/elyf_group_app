import 'package:flutter/material.dart';

import '../../../../features/administration/domain/entities/enterprise.dart';
import 'point_of_sale_stock/pos_bottles_summary.dart';
import 'point_of_sale_stock/pos_stock_header.dart';
import 'point_of_sale_stock/pos_stock_table.dart';

/// Card displaying stock information for a point of sale - matches Figma design.
class PointOfSaleStockCard extends StatelessWidget {
  const PointOfSaleStockCard({
    super.key,
    required this.enterprise,
    required this.fullBottles,
    required this.emptyBottles,
    this.issueBottles = 0,
    required this.stockByCapacity,
    this.nominalStocks = const {},
    this.totalInTransit = 0,
  });

  final Enterprise enterprise;
  final int fullBottles;
  final int emptyBottles;
  final int totalInTransit;
  final int issueBottles;
  final Map<int, ({int full, int empty, int inTransit, int defective, int leak})> stockByCapacity;
  final Map<int, int> nominalStocks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with POS info and status badge
          PosStockHeader(enterprise: enterprise),
          const SizedBox(height: 16),
          // Full and empty bottles cards
          PosBottlesSummary(
            fullBottles: fullBottles,
            emptyBottles: emptyBottles,
            inTransitBottles: totalInTransit,
            issueBottles: issueBottles,
          ),
          const SizedBox(height: 16),
          // Stock table by capacity
          PosStockTable(
            stockByCapacity: stockByCapacity,
            nominalStocks: nominalStocks,
          ),
        ],
      ),
    );
  }
}
