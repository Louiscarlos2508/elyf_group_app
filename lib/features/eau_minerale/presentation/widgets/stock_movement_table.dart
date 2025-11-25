import 'package:flutter/material.dart';

import '../../domain/entities/stock_movement.dart';

/// Table widget for displaying stock movement history.
class StockMovementTable extends StatelessWidget {
  const StockMovementTable({
    super.key,
    required this.movements,
  });

  final List<StockMovement> movements;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (movements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          'Aucun mouvement de stock enregistré',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        
        if (isWide) {
          return _buildDesktopTable(context, movements);
        } else {
          return _buildMobileList(context, movements);
        }
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<StockMovement> movements) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(1.5),
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
              _buildHeaderCell(context, 'Produit'),
              _buildHeaderCell(context, 'Type'),
              _buildHeaderCell(context, 'Motif'),
              _buildHeaderCell(context, 'Quantité'),
            ],
          ),
          ...movements.map((movement) {
            return TableRow(
              children: [
                _buildDataCellText(context, _formatDate(movement.date)),
                _buildDataCellText(context, movement.productName),
                _buildDataCellWidget(
                  context,
                  _buildTypeChip(context, movement.type),
                ),
                _buildDataCellText(context, movement.reason),
                _buildDataCellText(
                  context,
                  '${movement.quantity.toStringAsFixed(0)} ${movement.unit}',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<StockMovement> movements) {
    final theme = Theme.of(context);
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final movement = movements[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    movement.productName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildTypeChip(context, movement.type),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${_formatDate(movement.date)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Motif: ${movement.reason}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Quantité: ${movement.quantity.toStringAsFixed(0)} ${movement.unit}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildTypeChip(BuildContext context, StockMovementType type) {
    final theme = Theme.of(context);
    final isEntry = type == StockMovementType.entry;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isEntry ? Colors.green : Colors.red).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isEntry ? 'Entrée' : 'Sortie',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isEntry ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

