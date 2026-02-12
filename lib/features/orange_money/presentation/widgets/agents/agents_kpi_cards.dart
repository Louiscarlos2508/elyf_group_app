import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Widget pour afficher les cartes KPI des agents.
class AgentsKpiCards extends StatelessWidget {
  const AgentsKpiCards({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final recharges = stats['rechargesToday'] as int? ?? 0;
    final retraits = stats['withdrawalsToday'] as int? ?? 0;
    final alertes = stats['lowLiquidityAlerts'] as int? ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        
        return Column(
          children: [
            if (isNarrow) ...[
              ElyfStatsCard(
                label: 'Recharges (Jour)',
                value: CurrencyFormatter.formatFCFA(recharges),
                icon: Icons.south_west_rounded,
                color: const Color(0xFF00C897),
                isGlass: true,
              ),
              const SizedBox(height: 16),
              ElyfStatsCard(
                label: 'Retraits (Jour)',
                value: CurrencyFormatter.formatFCFA(retraits),
                icon: Icons.north_east_rounded,
                color: const Color(0xFFFF4D4D),
                isGlass: true,
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: ElyfStatsCard(
                      label: 'Recharges (Jour)',
                      value: CurrencyFormatter.formatFCFA(recharges),
                      icon: Icons.south_west_rounded,
                      color: const Color(0xFF00C897),
                      isGlass: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: 'Retraits (Jour)',
                      value: CurrencyFormatter.formatFCFA(retraits),
                      icon: Icons.north_east_rounded,
                      color: const Color(0xFFFF4D4D),
                      isGlass: true,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            ElyfStatsCard(
              label: 'Alertes Liquidité',
              value: alertes.toString(),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFFB319),
              isGlass: true,
            ),
          ],
        );
      },
    );
  }
}
