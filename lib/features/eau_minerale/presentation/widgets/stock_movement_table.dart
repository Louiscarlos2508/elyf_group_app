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

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (movements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun mouvement de stock enregistré',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les mouvements apparaîtront ici après les opérations de stock',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Calculer les statistiques
    final totalEntries = movements
        .where((m) => m.type == StockMovementType.entry)
        .fold<double>(0, (sum, m) => sum + m.quantity);
    final totalExits = movements
        .where((m) => m.type == StockMovementType.exit)
        .fold<double>(0, (sum, m) => sum + m.quantity);
    final netMovement = totalEntries - totalExits;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé des mouvements
            _buildSummaryCard(context, totalEntries, totalExits, netMovement, movements.length),
            const SizedBox(height: 16),
            // Tableau ou liste des mouvements
            if (isWide)
              _buildDesktopTable(context, movements)
            else
              _buildMobileList(context, movements),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalEntries,
    double totalExits,
    double netMovement,
    int totalMovements,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                context,
                'Total Entrées',
                totalEntries,
                Colors.green,
                Icons.arrow_downward,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildSummaryItem(
                context,
                'Total Sorties',
                totalExits,
                Colors.red,
                Icons.arrow_upward,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildSummaryItem(
                context,
                'Mouvement Net',
                netMovement,
                netMovement >= 0 ? Colors.green : Colors.red,
                Icons.swap_horiz,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildSummaryItem(
                context,
                'Total Mouvements',
                totalMovements.toDouble(),
                theme.colorScheme.primary,
                Icons.list,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
          0: FlexColumnWidth(1.8),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1.3),
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
              _buildHeaderCell(context, 'Date/Heure'),
              _buildHeaderCell(context, 'Produit'),
              _buildHeaderCell(context, 'Type'),
              _buildHeaderCell(context, 'Motif'),
              _buildHeaderCell(context, 'Quantité'),
              _buildHeaderCell(context, 'Machine'),
            ],
          ),
          ...movements.map((movement) {
            final reasonText = movement.productionId != null
                ? '${movement.reason} (Production)'
                : movement.reason;
            // Extraire le nom de la machine depuis les notes si disponible
            String? machineName;
            if (movement.notes != null) {
              // Les notes peuvent contenir "Installation en production - {machineName}"
              final match = RegExp(r'Installation.*- (.+)|machine[:\s]+(.+)', caseSensitive: false)
                  .firstMatch(movement.notes!);
              if (match != null) {
                machineName = match.group(1) ?? match.group(2);
              }
            }
            return TableRow(
              children: [
                _buildDataCellText(context, _formatDateTime(movement.date)),
                _buildDataCellText(context, movement.productName),
                _buildDataCellWidget(
                  context,
                  _buildTypeChip(context, movement.type),
                ),
                _buildDataCellText(context, reasonText),
                _buildDataCellText(
                  context,
                  '${movement.quantity.toStringAsFixed(0)} ${movement.unit}',
                ),
                _buildDataCellText(
                  context,
                  machineName ?? '-',
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
                'Date: ${_formatDateTime(movement.date)}',
                style: theme.textTheme.bodySmall,
              ),
              if (movement.productionId != null) ...[
                Builder(
                  builder: (context) {
                    final prodId = movement.productionId!;
                    final shortId = prodId.length > 8 
                        ? '${prodId.substring(0, 8)}...' 
                        : prodId;
                    return Text(
                      'Production: $shortId',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
              ],
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
              if (movement.notes != null) ...[
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    // Extraire le nom de la machine depuis les notes
                    final match = RegExp(r'Installation.*- (.+)|machine[:\s]+(.+)', caseSensitive: false)
                        .firstMatch(movement.notes!);
                    if (match != null) {
                      final machineName = match.group(1) ?? match.group(2);
                      return Text(
                        'Machine: $machineName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
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

