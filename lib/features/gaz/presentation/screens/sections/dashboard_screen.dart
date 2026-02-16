import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/core/permissions/modules/gaz_permissions.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/dashboard_stock_by_capacity.dart';
import '../../widgets/permission_guard.dart';
import 'dashboard/dashboard_kpi_section.dart';
import 'dashboard/dashboard_performance_section.dart';
import 'dashboard/dashboard_pos_performance_section.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/dashboard/quick_actions_section.dart';
import '../../widgets/dashboard/reconciliation_section.dart';
import '../../widgets/dashboard/low_stock_alert_section.dart';
import '../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';

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
                ElyfButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.arrow_back,
                  child: const Text('Retour'),
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
    return CustomScrollView(
      slivers: [
        // Header section with Premium Background
        GazHeader(
          title: 'GAZ',
          subtitle: "Tableau de Bord",
          additionalActions: [
            ElyfIconButton(
              icon: Icons.refresh,
              onPressed: () {
                ref.invalidate(gasSalesProvider);
                ref.invalidate(cylindersProvider);
                ref.invalidate(gazExpensesProvider);
              },
              tooltip: 'Actualiser',
            ),
          ],
        ),

        // KPI Cards (4 cards in a row)
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _DashboardKpiSliver(),
          ),
        ),

        // Low Stock Alert section (Story 5.2)
        const SliverToBoxAdapter(
          child: LowStockAlertSection(),
        ),

        // Quick Actions section
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: QuickActionsSection(),
          ),
        ),

        // Reconciliation section (Z-Report)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: const SliverToBoxAdapter(
            child: DashboardReconciliationSection(),
          ),
        ),
        // Stock par capacité section
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: DashboardStockByCapacity(),
          ),
        ),

        // Performance chart (7 derniers jours)
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _DashboardChartsSliver(),
          ),
        ),

        // Performance par point de vente
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: _DashboardPosPerformanceSliver(),
          ),
        ),
      ],
    );
  }
}

/// Specialized widget for Dashboard KPIs to enable granular rebuilds.
class _DashboardKpiSliver extends ConsumerWidget {
  const _DashboardKpiSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(gazDashboardDataProvider);

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
}

/// Specialized widget for Dashboard Charts to enable granular rebuilds.
class _DashboardChartsSliver extends ConsumerWidget {
  const _DashboardChartsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(gazDashboardDataProvider);

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

/// Specialized widget for POS performance to enable granular rebuilds.
class _DashboardPosPerformanceSliver extends ConsumerWidget {
  const _DashboardPosPerformanceSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(gazDashboardDataProvider);

    return dashboardDataAsync.when(
      data: (data) => DashboardPosPerformanceSection(sales: data.sales),
      loading: () => AppShimmers.table(context, rows: 4),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement',
        message: 'Impossible de charger les performances par point de vente.',
        onRetry: () => ref.refresh(gazDashboardDataProvider),
      ),
    );
  }
}
