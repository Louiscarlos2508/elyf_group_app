import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/services/gaz_calculation_service.dart';
import '../../widgets/wholesale_date_filter_card.dart';
import '../../widgets/wholesale_empty_state.dart';
import '../../widgets/wholesale_kpi_card.dart';
import '../../widgets/wholesale_sale_card.dart';

/// Écran des ventes en gros - matches Figma design.
class GazWholesaleScreen extends ConsumerStatefulWidget {
  const GazWholesaleScreen({super.key});

  @override
  ConsumerState<GazWholesaleScreen> createState() =>
      _GazWholesaleScreenState();
}

class _GazWholesaleScreenState extends ConsumerState<GazWholesaleScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivi des ventes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consultez les ventes effectuées',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF4A5565),
                  ),
                ),
              ],
            ),
          ),
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
              loading: () => const SizedBox(
                height: 115,
                child: Center(child: CircularProgressIndicator()),
              ),
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

                return _WholesaleSalesList(
                  sales: metrics.sales,
                  theme: theme,
                );
              },
              loading: () => const SizedBox(
                height: 163,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
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
                child: WholesaleKpiCard(
                  title: 'Nombre de ventes',
                  value: '${metrics.salesCount}',
                  icon: Icons.shopping_cart,
                  iconColor: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WholesaleKpiCard(
                  title: 'Total vendu',
                  value: metrics.totalSold.toStringAsFixed(0),
                  subtitle: 'FCFA',
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WholesaleKpiCard(
                  title: 'Encaissé',
                  value: metrics.collected.toStringAsFixed(0),
                  subtitle: 'FCFA',
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WholesaleKpiCard(
                  title: 'Crédit',
                  value: metrics.credit.toStringAsFixed(0),
                  subtitle: 'FCFA',
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFFF97316),
                ),
              ),
            ],
          );
        }

        // Mobile: 2x2 grid
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: WholesaleKpiCard(
                    title: 'Nombre de ventes',
                    value: '${metrics.salesCount}',
                    icon: Icons.shopping_cart,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WholesaleKpiCard(
                    title: 'Total vendu',
                    value: metrics.totalSold.toStringAsFixed(0),
                    subtitle: 'FCFA',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: WholesaleKpiCard(
                    title: 'Encaissé',
                    value: metrics.collected.toStringAsFixed(0),
                    subtitle: 'FCFA',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WholesaleKpiCard(
                    title: 'Crédit',
                    value: metrics.credit.toStringAsFixed(0),
                    subtitle: 'FCFA',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFFF97316),
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
  const _WholesaleSalesList({
    required this.sales,
    required this.theme,
  });

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
            color: const Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 16),
        ...sales.map((sale) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WholesaleSaleCard(sale: sale),
            )),
      ],
    );
  }
}

