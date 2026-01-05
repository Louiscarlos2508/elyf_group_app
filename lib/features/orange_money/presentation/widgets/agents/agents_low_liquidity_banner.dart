import 'package:flutter/material.dart';

import '../../../domain/entities/agent.dart';
import 'agents_format_helpers.dart';

/// Bannière d'alerte pour les agents avec liquidité faible.
class AgentsLowLiquidityBanner extends StatelessWidget {
  const AgentsLowLiquidityBanner({
    super.key,
    required this.agents,
  });

  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25.219, 17.219, 1.219, 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        border: Border.all(
          color: const Color(0xFFFFF085),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Color(0xFF894B00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ ${agents.length} agent(s) avec liquidité faible (< 50 000 F)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF894B00),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: agents.map((agent) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9.219,
                        vertical: 3.219,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFDC700),
                          width: 1.219,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${agent.name}: ${AgentsFormatHelpers.formatCurrencyCompact(agent.liquidity)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFFA65F00),
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

