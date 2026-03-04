import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// Widget pour afficher les cartes KPI des agents avec un design premium.
class AgentsKpiCards extends StatelessWidget {
  const AgentsKpiCards({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final recharges = stats['rechargesToday'] as int? ?? 0;
    final retraits = stats['withdrawalsToday'] as int? ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: ElyfStatsCard(
              label: 'RECHARGES (JOUR)',
              value: CurrencyFormatter.formatFCFA(recharges),
              icon: Icons.south_west_rounded,
              color: AppColors.success,
              isGlass: false,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElyfStatsCard(
              label: 'RETRAITS (JOUR)',
              value: CurrencyFormatter.formatFCFA(retraits),
              icon: Icons.north_east_rounded,
              color: AppColors.danger,
              isGlass: false,
            ),
          ),
        ],
      ),
    );
  }
}
