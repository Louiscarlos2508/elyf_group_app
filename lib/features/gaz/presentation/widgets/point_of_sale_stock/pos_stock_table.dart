import 'package:flutter/material.dart';

/// Table de stock par capacité.
class PosStockTable extends StatelessWidget {
  const PosStockTable({
    super.key,
    required this.stockByCapacity,
    this.nominalStocks = const {},
  });

  final Map<int, ({int full, int empty, int inTransit, int defective, int leak})> stockByCapacity;
  final Map<int, int> nominalStocks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : const Color(0xFFE5E7EB), 
                  width: 1.3,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Capacité',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Pleines',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Vides',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Transit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Fuites',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table body
          if (stockByCapacity.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aucun stock configuré',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: isDark ? theme.colorScheme.onSurfaceVariant : const Color(0xFF6A7282),
                  ),
                ),
              ),
            )
          else
            ...stockByCapacity.entries.map((entry) {
              final weight = entry.key;
              final full = entry.value.full;
              final empty = entry.value.empty;
              final inTransit = entry.value.inTransit;
              final defective = entry.value.defective;
              final leak = entry.value.leak;
              final issues = defective + leak;
              final total = full + empty + inTransit + issues;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.1) : const Color(0xFFE5E7EB), 
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '$weight kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '$full',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '$empty',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '$inTransit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: inTransit > 0 ? Colors.orange : theme.colorScheme.onSurface,
                            fontWeight: inTransit > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '$issues',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: issues > 0 ? theme.colorScheme.error : theme.colorScheme.onSurface,
                            fontWeight: issues > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
