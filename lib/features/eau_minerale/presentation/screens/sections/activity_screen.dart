import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/activity_summary.dart';
import '../../widgets/enhanced_kpi_card.dart';
import '../../widgets/section_placeholder.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(activityStateProvider);

    return summary.when(
      data: (data) => _ActivityContent(summary: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => SectionPlaceholder(
        icon: Icons.error_outline,
        title: "Impossible de charger l'activité",
        subtitle: 'Réessaie plus tard.',
        primaryActionLabel: 'Réessayer',
        onPrimaryAction: () => ref.invalidate(activityStateProvider),
      ),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      EnhancedKpiCard(
        label: 'Production (sachets)',
        value: summary.totalProduction.toString(),
        icon: Icons.water_drop,
        color: Colors.blue,
      ),
      EnhancedKpiCard(
        label: 'Ventes (sachets)',
        value: summary.totalSales.toString(),
        icon: Icons.point_of_sale,
        color: Colors.green,
      ),
      EnhancedKpiCard(
        label: 'Crédits clients',
        value: '${summary.pendingCredits} CFA',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.orange,
      ),
      EnhancedKpiCard(
        label: 'MP restantes',
        value: '${summary.rawMaterialDays} j',
        icon: Icons.inventory_2_outlined,
        color: Colors.purple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: cards,
        );
      },
    );
  }
}
