import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../widgets/dashboard_kpi_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final propertiesAsync = ref.watch(propertiesProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final contractsAsync = ref.watch(contractsProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tableau de Bord',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: propertiesAsync.when(
              data: (properties) => tenantsAsync.when(
                data: (tenants) => contractsAsync.when(
                  data: (contracts) => paymentsAsync.when(
                    data: (payments) => expensesAsync.when(
                      data: (expenses) {
                        return DashboardKpiGrid(
                          properties: properties,
                          tenants: tenants,
                          contracts: contracts,
                          payments: payments,
                          expenses: expenses,
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}
