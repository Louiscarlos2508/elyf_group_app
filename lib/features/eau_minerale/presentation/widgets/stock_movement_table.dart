import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../domain/entities/stock_movement.dart';

/// Table widget for displaying stock movement history.
class StockMovementTable extends StatelessWidget {
  const StockMovementTable({super.key, required this.movements});

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
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
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
            _buildSummaryCard(
              context,
              totalEntries,
              totalExits,
              netMovement,
              movements.length,
            ),
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

    return ElyfCard(
      isGlass: true,
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              'Entrées',
              totalEntries,
              Colors.green,
              Icons.arrow_downward,
            ),
          ),
          _buildDivider(theme),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Sorties',
              totalExits,
              Colors.red,
              Icons.arrow_upward,
            ),
          ),
          _buildDivider(theme),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Net',
              netMovement,
              netMovement >= 0 ? Colors.green : Colors.red,
              Icons.balance,
            ),
          ),
          _buildDivider(theme),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Total',
              totalMovements.toDouble(),
              theme.colorScheme.primary,
              Icons.history,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<StockMovement> movements) {
    final theme = Theme.of(context);
    return ElyfCard(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(3),
          3: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            children: [
              _buildHeaderCell(context, 'Date'),
              _buildHeaderCell(context, 'Type'),
              _buildHeaderCell(context, 'Produit'),
              _buildHeaderCell(context, 'Quantité'),
            ],
          ),
          ...movements.map((m) => TableRow(
                children: [
                  _buildDataCell(context, _formatDateTime(m.date)),
                  _buildDataCell(
                    context,
                    m.type == StockMovementType.entry ? 'ENTRÉE' : 'SORTIE',
                    color: m.type == StockMovementType.entry ? Colors.green : Colors.red,
                  ),
                  _buildDataCell(context, m.productName),
                  _buildDataCell(context, '${m.quantity} ${m.unit}'),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<StockMovement> movements) {
    return Column(
      children: movements
          .map((m) => ElyfCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    m.type == StockMovementType.entry ? Icons.arrow_downward : Icons.arrow_upward,
                    color: m.type == StockMovementType.entry ? Colors.green : Colors.red,
                  ),
                  title: Text(m.productName),
                  subtitle: Text(_formatDateTime(m.date)),
                  trailing: Text(
                    '${m.quantity} ${m.unit}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
            ),
      ),
    );
  }
}
