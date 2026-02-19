import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/services/gaz_calculation_service.dart';
import '../../widgets/wholesale_date_filter_card.dart';
import '../../widgets/wholesale_empty_state.dart';
import '../../widgets/wholesale_sale_card.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/gaz_session_guard.dart';
import '../wholesaler_management_screen.dart';
import '../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';
import '../../widgets/wholesale/independent_collection_dialog.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

/// Écran des ventes en gros - matches Figma design.
class GazWholesaleScreen extends ConsumerStatefulWidget {
  const GazWholesaleScreen({super.key});

  @override
  ConsumerState<GazWholesaleScreen> createState() => _GazWholesaleScreenState();
}

class _GazWholesaleScreenState extends ConsumerState<GazWholesaleScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);

    return GazSessionGuard(
      child: CustomScrollView(
        slivers: [
          // Header section with Premium Background
          GazHeader(
            title: 'VENTES GROS',
            subtitle: 'Suivi des ventes',
            additionalActions: [
              ElyfIconButton(
                icon: Icons.people_outline,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WholesalerManagementScreen(),
                  ),
                ),
                tooltip: 'Gérer les grossistes',
              ),
              ElyfIconButton(
                icon: Icons.add_circle_outline,
                onPressed: () {
                  final enterprise = ref.read(activeEnterpriseProvider).value;
                  if (enterprise != null) {
                    showDialog(
                      context: context,
                      builder: (context) => IndependentCollectionDialog(
                        enterpriseId: enterprise.id,
                      ),
                    );
                  }
                },
                tooltip: 'Nouvelle Collecte',
              ),
              ElyfIconButton(
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(gasSalesProvider),
                tooltip: 'Actualiser',
              ),
            ],
          ),

          // Filter section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: WholesaleDateFilterCard(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateChanged: (date) {
                  setState(() {
                    _startDate = date;
                  });
                },
                onEndDateChanged: (date) {
                  setState(() {
                    _endDate = date;
                  });
                },
              ),
            ),
          ),

          // KPI Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: salesAsync.when(
                data: (allSales) {
                  // Use calculation service for business logic
                  final metrics = GazCalculationService.calculateWholesaleMetrics(
                    allSales,
                    startDate: _startDate,
                    endDate: _endDate,
                  );

                  return _WholesaleKpiGrid(metrics: metrics);
                },
                loading: () => AppShimmers.statsGrid(context),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Empty state or sales list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: salesAsync.when(
                data: (allSales) {
                  final metrics = GazCalculationService.calculateWholesaleMetrics(
                    allSales,
                    startDate: _startDate,
                    endDate: _endDate,
                  );

                  if (metrics.sales.isEmpty) {
                    return const WholesaleEmptyState();
                  }

                  return _WholesaleSalesList(sales: metrics.sales, theme: theme);
                },
                loading: () => AppShimmers.list(context),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget privé pour afficher la grille de KPIs.
class _WholesaleKpiGrid extends StatelessWidget {
  const _WholesaleKpiGrid({required this.metrics});

  final WholesaleMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: ElyfStatsCard(
                  label: 'Nombre de ventes',
                  value: '${metrics.salesCount}',
                  icon: Icons.shopping_cart,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElyfStatsCard(
                  label: 'Total vendu',
                  value: metrics.totalSold.toStringAsFixed(0),
                  subtitle: 'FCFA',
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElyfStatsCard(
                  label: 'Encaissé',
                  value: metrics.collected.toStringAsFixed(0),
                  subtitle: 'FCFA',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElyfStatsCard(
                  label: 'Crédit',
                  value: metrics.credit.toStringAsFixed(0),
                  subtitle: 'FCFA',
                  icon: Icons.error_outline,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          );
        }

        // Mobile: grid
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElyfStatsCard(
                    label: 'Ventes',
                    value: '${metrics.salesCount}',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElyfStatsCard(
                    label: 'Total',
                    value: metrics.totalSold.toStringAsFixed(0),
                    subtitle: 'FCFA',
                    icon: Icons.trending_up,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElyfStatsCard(
                    label: 'Encaissé',
                    value: metrics.collected.toStringAsFixed(0),
                    subtitle: 'FCFA',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElyfStatsCard(
                    label: 'Crédit',
                    value: metrics.credit.toStringAsFixed(0),
                    subtitle: 'FCFA',
                    icon: Icons.error_outline,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Widget privé pour afficher la liste des ventes.
class _WholesaleSalesList extends StatelessWidget {
  const _WholesaleSalesList({required this.sales, required this.theme});

  final List<dynamic> sales;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventes enregistrées (${sales.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...sales.map(
          (sale) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WholesaleSaleCard(sale: sale),
          ),
        ),
      ],
    );
  }
}
