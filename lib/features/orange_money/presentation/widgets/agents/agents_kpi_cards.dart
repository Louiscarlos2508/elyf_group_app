import 'package:flutter/material.dart';

import '../../widgets/kpi_card.dart';
import 'agents_format_helpers.dart';

/// Widget pour afficher les cartes KPI des agents.
class AgentsKpiCards extends StatelessWidget {
  const AgentsKpiCards({
    super.key,
    required this.stats,
  });

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final recharges = stats['rechargesToday'] as int? ?? 0;
    final retraits = stats['withdrawalsToday'] as int? ?? 0;
    final alertes = stats['lowLiquidityAlerts'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: KpiCard(
            label: 'Recharges (jour)',
            value: AgentsFormatHelpers.formatCurrencyCompact(recharges),
            icon: Icons.arrow_downward,
            valueColor: const Color(0xFF00A63E),
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFF00A63E),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'Retraits (jour)',
            value: AgentsFormatHelpers.formatCurrencyCompact(retraits),
            icon: Icons.arrow_upward,
            valueColor: const Color(0xFFE7000B),
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFFE7000B),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            label: 'Alertes liquidité',
            value: alertes.toString(),
            icon: Icons.warning,
            valueColor: const Color(0xFFD08700),
            valueStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: Color(0xFFD08700),
            ),
          ),
        ),
      ],
    );
  }
}

