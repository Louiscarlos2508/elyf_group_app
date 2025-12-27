import 'package:flutter/material.dart';

/// Table de stock par capacité.
class PosStockTable extends StatelessWidget {
  const PosStockTable({
    super.key,
    required this.stockByCapacity,
  });

  final Map<int, ({int full, int empty})> stockByCapacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
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
                      color: const Color(0xFF0A0A0A),
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
                        color: const Color(0xFF0A0A0A),
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
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF0A0A0A),
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
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ),
            )
          else
            ...stockByCapacity.entries.map((entry) {
              final weight = entry.key;
              final full = entry.value.full;
              final empty = entry.value.empty;
              final total = full + empty;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE5E7EB),
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
                          color: const Color(0xFF0A0A0A),
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
                            color: const Color(0xFF0A0A0A),
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
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF0A0A0A),
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

