import 'package:flutter/material.dart';

import '../../domain/entities/production.dart';
import '../../domain/entities/production_period_config.dart';
import 'production_period_formatter.dart';
import 'raw_materials_chips.dart';

/// Table widget for displaying production history.
class ProductionHistoryTable extends StatelessWidget {
  const ProductionHistoryTable({
    super.key,
    required this.productions,
    required this.periodConfig,
  });

  final List<Production> productions;
  final ProductionPeriodConfig periodConfig;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (productions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucune production enregistrée',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Historique de Production',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                children: [
                  _buildHeaderCell(context, 'Date'),
                  _buildHeaderCell(context, 'Période'),
                  _buildHeaderCell(context, 'Matières Premières'),
                  _buildHeaderCell(context, 'Packs Produits'),
                ],
              ),
              ...productions.map((production) {
                final formatter = ProductionPeriodFormatter(periodConfig);
                final period = periodConfig.getPeriodForDate(production.date);
                return TableRow(
                  children: [
                    _buildDataCellText(
                      context,
                      ProductionPeriodFormatter.formatDate(production.date),
                    ),
                    _buildDataCellText(
                      context,
                      formatter.formatPeriod(period, production.date),
                    ),
                    _buildDataCellWidget(
                      context,
                      RawMaterialsChips(production: production),
                    ),
                    _buildDataCellWidget(
                      context,
                      Text(
                        production.quantity.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDataCellText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDataCellWidget(BuildContext context, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: content,
    );
  }

}

