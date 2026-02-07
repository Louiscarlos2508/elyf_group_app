import 'package:flutter/material.dart';
import '../../../../../../shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

/// Widget for Stock par capacité section (placeholder for now).
class DashboardStockByCapacity extends StatelessWidget {
  const DashboardStockByCapacity({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElyfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock par capacité',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Placeholder for future content
          SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'Indicateurs de gestion des stocks imminents',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
