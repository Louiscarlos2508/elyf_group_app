import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';

/// Onglet statistiques pour la vente au détail.
class RetailStatisticsTab extends ConsumerWidget {
  const RetailStatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);

    return salesAsync.when(
      data: (allSales) {
        final retailSales =
            allSales.where((s) => s.saleType == SaleType.retail).toList()
              ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

        // Calculs pour aujourd'hui
        final todaySales = GazCalculationService.calculateTodaySalesByType(
          retailSales,
          SaleType.retail,
        );
        final todayRevenue = GazCalculationService.calculateTodayRevenueByType(
          retailSales,
          SaleType.retail,
        );

        // Calculs pour cette semaine
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        final weekSales = retailSales.where((s) {
          return s.saleDate.isAfter(
            weekStartDate.subtract(const Duration(seconds: 1)),
          );
        }).toList();
        final weekRevenue = weekSales.fold<double>(
          0,
          (sum, s) => sum + s.totalAmount,
        );

        // Calculs pour ce mois
        final monthStart = DateTime(now.year, now.month, 1);
        final monthSales = retailSales.where((s) {
          return s.saleDate.isAfter(
            monthStart.subtract(const Duration(seconds: 1)),
          );
        }).toList();
        final monthRevenue = monthSales.fold<double>(
          0,
          (sum, s) => sum + s.totalAmount,
        );

        return CustomScrollView(
          slivers: [
            // KPI Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    // Ligne 1: Aujourd'hui
                    Row(
                      children: [
                        Expanded(
                          child: ElyfStatsCard(
                            label: 'Ventes aujourd\'hui',
                            value: '${todaySales.length}',
                            icon: Icons.shopping_cart,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElyfStatsCard(
                            label: 'Total du jour',
                            value: CurrencyFormatter.formatDouble(todayRevenue),
                            subtitle: 'FCFA',
                            icon: Icons.attach_money,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Ligne 2: Cette semaine et ce mois
                    Row(
                      children: [
                        Expanded(
                          child: ElyfStatsCard(
                            label: 'Cette semaine',
                            value: CurrencyFormatter.formatDouble(weekRevenue),
                            subtitle: 'FCFA',
                            icon: Icons.calendar_today,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElyfStatsCard(
                            label: 'Ce mois',
                            value: CurrencyFormatter.formatDouble(monthRevenue),
                            subtitle: 'FCFA',
                            icon: Icons.calendar_month,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Liste des ventes récentes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventes récentes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Liste des ventes
            retailSales.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune vente enregistrée',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Les ventes effectuées apparaîtront ici',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final sale = retailSales[index];
                      return _RetailSaleItem(sale: sale);
                    }, childCount: retailSales.length),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher un item de vente dans la liste.
class _RetailSaleItem extends StatelessWidget {
  const _RetailSaleItem({required this.sale});

  final GasSale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.customerName ?? 'Client anonyme',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (sale.customerPhone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sale.customerPhone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CurrencyFormatter.formatDouble(sale.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${sale.quantity} bouteille${sale.quantity > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(sale.saleDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
