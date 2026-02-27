import 'package:flutter/material.dart';

import '../../../../administration/domain/entities/enterprise.dart';
import '../../../domain/entities/orange_money_enterprise_extensions.dart';
import 'agents_format_helpers.dart';

/// Bannière d'alerte pour les agents avec liquidité faible.
class AgentsLowLiquidityBanner extends StatelessWidget {
  const AgentsLowLiquidityBanner({super.key, required this.agents});

  final List<Enterprise> agents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 24,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${agents.length} agent(s) avec liquidité faible (< 50 000 F)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.error,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: agents.map((agent) {
                    final balance = agent.floatBalance ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${agent.name}: ${AgentsFormatHelpers.formatCurrencyCompact(balance)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
