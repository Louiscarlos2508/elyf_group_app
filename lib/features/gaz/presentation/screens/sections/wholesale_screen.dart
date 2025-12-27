import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/wholesale_date_filter_card.dart';
import '../../widgets/wholesale_empty_state.dart';
import '../../widgets/wholesale_kpi_card.dart';

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


  List<GasSale> _filterSales(List<GasSale> sales) {
    if (_startDate == null && _endDate == null) {
      return sales;
    }

    final start = _startDate ?? DateTime(2020);
    final end = _endDate ?? DateTime.now();

    return sales.where((s) {
      final saleDate = DateTime(
        s.saleDate.year,
        s.saleDate.month,
        s.saleDate.day,
      );
      return saleDate.isAfter(start.subtract(const Duration(days: 1))) &&
          saleDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

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
                final wholesaleSales = allSales
                    .where((s) => s.saleType == SaleType.wholesale)
                    .toList();
                final filteredSales = _filterSales(wholesaleSales);

                // Calculate metrics
                final salesCount = filteredSales.length;
                final totalSold = filteredSales.fold<double>(
                  0,
                  (sum, s) => sum + s.totalAmount,
                );
                // For now, assume all sales are paid (encaissé)
                // TODO: Add payment status to GasSale entity
                final collected = totalSold;
                final credit = 0.0; // TODO: Calculate actual credit

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            child: WholesaleKpiCard(
                              title: 'Nombre de ventes',
                              value: '$salesCount',
                              icon: Icons.shopping_cart,
                              iconColor: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: WholesaleKpiCard(
                              title: 'Total vendu',
                              value: totalSold.toStringAsFixed(0),
                              subtitle: 'FCFA',
                              icon: Icons.trending_up,
                              iconColor: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: WholesaleKpiCard(
                              title: 'Encaissé',
                              value: collected.toStringAsFixed(0),
                              subtitle: 'FCFA',
                              icon: Icons.trending_up,
                              iconColor: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: WholesaleKpiCard(
                              title: 'Crédit',
                              value: credit.toStringAsFixed(0),
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
                                value: '$salesCount',
                                icon: Icons.shopping_cart,
                                iconColor: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: WholesaleKpiCard(
                                title: 'Total vendu',
                                value: totalSold.toStringAsFixed(0),
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
                                value: collected.toStringAsFixed(0),
                                subtitle: 'FCFA',
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: WholesaleKpiCard(
                                title: 'Crédit',
                                value: credit.toStringAsFixed(0),
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
                final wholesaleSales = allSales
                    .where((s) => s.saleType == SaleType.wholesale)
                    .toList();
                final filteredSales = _filterSales(wholesaleSales);

                if (filteredSales.isEmpty) {
                  return const WholesaleEmptyState();
                }

                // TODO: Add sales list view here if needed
                return const WholesaleEmptyState();
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

