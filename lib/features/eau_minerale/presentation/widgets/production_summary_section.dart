import 'package:flutter/material.dart';

import 'production_summary_card.dart';

/// Summary section for production screen.
class ProductionSummarySection extends StatelessWidget {
  const ProductionSummarySection({
    super.key,
    required this.todayProduction,
    required this.weekProduction,
  });

  final int todayProduction;
  final int weekProduction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return isWide
            ? Row(
                children: [
                  Expanded(
                    child: ProductionSummaryCard(
                      title: 'Aujourd\'hui',
                      value: todayProduction,
                      label: 'packs produits',
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ProductionSummaryCard(
                      title: 'Cette Semaine',
                      value: weekProduction,
                      label: 'packs produits',
                      color: Colors.blue,
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  ProductionSummaryCard(
                    title: 'Aujourd\'hui',
                    value: todayProduction,
                    label: 'packs produits',
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                  const SizedBox(height: 16),
                  ProductionSummaryCard(
                    title: 'Cette Semaine',
                    value: weekProduction,
                    label: 'packs produits',
                    color: Colors.blue,
                    icon: Icons.trending_up,
                  ),
                ],
              );
      },
    );
  }
}

