import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/core/permissions/modules/gaz_permissions.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/cylinder.dart';
import '../../widgets/dashboard_stock_by_capacity.dart';
import '../../widgets/permission_guard.dart';
import 'dashboard/dashboard_kpi_section.dart';
import 'dashboard/dashboard_performance_section.dart';
import 'dashboard/dashboard_pos_performance_section.dart';

/// Professional dashboard screen for gaz module - matches Figma design.
class GazDashboardScreen extends ConsumerWidget {
  const GazDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Protéger l'accès au dashboard avec PermissionGuard
    return GazPermissionGuard(
      permission: GazPermissions.viewDashboard,
      fallback: Scaffold(
        appBar: AppBar(
          title: const Text('Tableau de bord'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Accès restreint',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vous n\'avez pas les autorisations nécessaires pour consulter ce tableau de bord.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      ),
      child: _DashboardContent(),
    );
  }
}

/// Contenu du dashboard (séparé pour éviter la reconstruction du guard)
class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(gazDashboardDataProvider);

    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Vue d'ensemble",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tableau de bord de gestion du gaz',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Actualiser le tableau de bord',
                  hint: 'Recharge toutes les données affichées',
                  button: true,
                  child: RefreshButton(
                    onRefresh: () {
                      ref.invalidate(gasSalesProvider);
                      ref.invalidate(cylindersProvider);
                      ref.invalidate(gazExpensesProvider);
                    },
                    tooltip: 'Actualiser le tableau de bord',
                  ),
                ),
              ],
            ),
          ),
        ),

        // KPI Cards (4 cards in a row)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildKpiSection(context, ref, dashboardDataAsync),
          ),
        ),

        // Stock par capacité section
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: const SliverToBoxAdapter(
            child: DashboardStockByCapacity(),
          ),
        ),

        // Performance chart (7 derniers jours)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildPerformanceSection(context, ref, dashboardDataAsync),
          ),
        ),

        // Performance par point de vente
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: dashboardDataAsync.when(
              data: (data) => DashboardPosPerformanceSection(sales: data.sales),
              loading: () => AppShimmers.table(context, rows: 4),
              error: (error, stackTrace) => ErrorDisplayWidget(
                error: error,
                title: 'Erreur de chargement',
                message: 'Impossible de charger les performances par point de vente.',
                onRetry: () => ref.refresh(gazDashboardDataProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<
        ({List<GasSale> sales, List<GazExpense> expenses, List<Cylinder> cylinders})>
        dashboardDataAsync,
  ) {
    return dashboardDataAsync.when(
      data: (data) => DashboardKpiSection(
        sales: data.sales,
        expenses: data.expenses,
        cylinders: data.cylinders,
      ),
      loading: () => AppShimmers.statsGrid(context),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des données',
        onRetry: () => ref.refresh(gazDashboardDataProvider),
      ),
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<
        ({List<GasSale> sales, List<GazExpense> expenses, List<Cylinder> cylinders})>
        dashboardDataAsync,
  ) {
    return dashboardDataAsync.when(
      data: (data) => DashboardPerformanceSection(
        sales: data.sales,
        expenses: data.expenses,
      ),
      loading: () => AppShimmers.chart(context),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des performances',
        onRetry: () => ref.refresh(gazDashboardDataProvider),
      ),
    );
  }
}
