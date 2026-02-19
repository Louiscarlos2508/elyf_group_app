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
    // Déterminer s'il faut afficher la colonne Solde
    // On l'affiche si tous les mouvements concernent le même produit
    final uniqueProducts = movements.map((m) => m.productName).toSet();
    final isSingleProduct = uniqueProducts.length == 1 && movements.isNotEmpty;

    // Calculer les soldes progressifs si on est sur un seul produit
    final List<double> runningBalances = [];
    if (isSingleProduct) {
      double currentBalance = 0;
      // Inverser pour calculer du plus vieux au plus récent
      final reversedMovements = movements.reversed.toList();
      final balancesFromOldest = <double>[];
      for (final m in reversedMovements) {
        if (m.type == StockMovementType.entry) {
          currentBalance += m.quantity;
        } else {
          currentBalance -= m.quantity;
        }
        balancesFromOldest.add(currentBalance);
      }
      // Remettre dans l'ordre original (plus récent en premier)
      runningBalances.addAll(balancesFromOldest.reversed);
    }

    return ElyfCard(
      padding: EdgeInsets.zero,
      child: Table(
        columnWidths: {
          0: const FlexColumnWidth(1.2), // Date
          1: const FlexColumnWidth(0.8), // Type
          2: const FlexColumnWidth(1.5), // Produit
          3: const FlexColumnWidth(1.2), // Quantité
          4: const FlexColumnWidth(2),   // Raison
          if (isSingleProduct) 5: const FlexColumnWidth(0.8), // Delta
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
              _buildHeaderCell(context, 'Raison'),
              if (isSingleProduct) _buildHeaderCell(context, 'Bilan'),
            ],
          ),
          for (int i = 0; i < movements.length; i++)
            TableRow(
              children: [
                _buildDataCell(context, _formatDateTime(movements[i].date)),
                _buildTypeIndicator(movements[i].type),
                _buildDataCell(context, movements[i].productName, isBold: true),
                _buildDataCell(context, movements[i].quantityLabel ?? '${movements[i].quantity.toStringAsFixed(0)} ${movements[i].unit}'),
                _buildDataCell(context, movements[i].reason, isSecondary: true),
                if (isSingleProduct)
                  _buildDataCell(
                    context, 
                    '${runningBalances[i] > 0 ? '+' : ''}${runningBalances[i].toStringAsFixed(0)}',
                    isBold: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTypeIndicator(StockMovementType type) {
    final isEntry = type == StockMovementType.entry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isEntry ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isEntry ? Colors.green : Colors.red).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEntry ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14,
            color: isEntry ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isEntry ? 'ENTRÉE' : 'SORTIE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isEntry ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<StockMovement> movements) {
    return Column(
      children: movements
          .map((m) => ElyfCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildMobileTypeIcon(m.type),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        m.quantityLabel ?? '${m.quantity.toInt()} ${m.unit}',
                        style: TextStyle(
                          color: m.type == StockMovementType.entry ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(_formatDateTime(m.date)),
                        ],
                      ),
                      if (m.reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          m.reason,
                          style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMobileTypeIcon(StockMovementType type) {
    final isEntry = type == StockMovementType.entry;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isEntry ? Colors.green : Colors.red).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isEntry ? Icons.add : Icons.remove,
        color: isEntry ? Colors.green : Colors.red,
        size: 20,
      ),
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

  Widget _buildDataCell(BuildContext context, String text,
      {bool isBold = false, bool isSecondary = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isBold ? FontWeight.bold : null,
          color: isSecondary ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
    );
  }
}
