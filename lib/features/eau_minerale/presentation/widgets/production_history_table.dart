import 'package:flutter/material.dart';

import '../../domain/entities/production.dart';
import '../../domain/entities/production_period_config.dart';

/// Table widget for displaying production history.
class ProductionHistoryTable extends StatelessWidget {
  const ProductionHistoryTable({
    super.key,
    required this.productions,
    required this.periodConfig,
  });

  final List<Production> productions;
  final ProductionPeriodConfig periodConfig;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatPeriod(Production production) {
    final now = DateTime.now();
    final month = production.date.month;
    final year = production.date.year;
    final day = production.date.day;
    
    final period = periodConfig.getPeriodForDate(production.date);
    final daysPerPeriod = periodConfig.daysPerPeriod;
    
    int periodStartDay;
    int periodEndDay;
    
    if (period == 1) {
      periodStartDay = 1;
      periodEndDay = daysPerPeriod;
    } else if (period == 2) {
      periodStartDay = daysPerPeriod + 1;
      periodEndDay = daysPerPeriod * 2;
    } else {
      periodStartDay = daysPerPeriod * 2 + 1;
      periodEndDay = 31;
    }
    
    final startMonth = _getMonthName(month);
    final endMonth = _getMonthName(month);
    
    if (periodStartDay == periodEndDay) {
      return '$periodStartDay $startMonth $year';
    }
    return '$periodStartDay-$periodEndDay $startMonth $year';
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return months[month - 1];
  }

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
                return TableRow(
                  children: [
                    _buildDataCellText(
                      context,
                      _formatDate(production.date),
                    ),
                    _buildDataCellText(
                      context,
                      _formatPeriod(production),
                    ),
                    _buildDataCellWidget(
                      context,
                      _buildRawMaterialsChips(context, production),
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

  Widget _buildRawMaterialsChips(
    BuildContext context,
    Production production,
  ) {
    if (production.rawMaterialsUsed == null ||
        production.rawMaterialsUsed!.isEmpty) {
      return Text(
        '-',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: production.rawMaterialsUsed!.map((material) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${material.productName}: ${material.quantity}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }
}

