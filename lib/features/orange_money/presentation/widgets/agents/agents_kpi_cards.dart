import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

/// Widget pour afficher les cartes KPI des agents avec un design premium.
class AgentsKpiCards extends StatelessWidget {
  const AgentsKpiCards({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final recharges = stats['rechargesToday'] as int? ?? 0;
    final retraits = stats['withdrawalsToday'] as int? ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          ElyfStatsCard(
            label: 'RECHARGES (JOUR)',
            value: CurrencyFormatter.formatFCFA(recharges),
            icon: Icons.south_west_rounded,
            color: const Color(0xFF00C897), // Semantic Green
            isGlass: true,
          ),
          ElyfStatsCard(
            label: 'RETRAITS (JOUR)',
            value: CurrencyFormatter.formatFCFA(retraits),
            icon: Icons.north_east_rounded,
            color: const Color(0xFFFF4D4D), // Semantic Red
            isGlass: true,
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.orangeMoneyGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.orangeMoneyGradient[0].withValues(alpha: 0.85),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
        );
      },
    );
  }
}
