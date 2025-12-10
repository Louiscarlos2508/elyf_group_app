import 'package:flutter/material.dart';

import '../../../core/domain/entities/treasury.dart';

/// Widget pour afficher les cartes de résumé de trésorerie.
class TreasurySummaryCards extends StatelessWidget {
  const TreasurySummaryCards({
    super.key,
    required this.treasury,
  });

  final Treasury treasury;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            context,
            'Solde Cash',
            _formatCurrency(treasury.soldeCash),
            Icons.money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            context,
            'Solde Orange Money',
            _formatCurrency(treasury.soldeOrangeMoney),
            Icons.account_balance_wallet,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            context,
            'Solde Total',
            _formatCurrency(treasury.soldeTotal),
            Icons.account_balance,
            theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

