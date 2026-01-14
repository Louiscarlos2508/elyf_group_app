import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/retail_kpi_card.dart';

/// Onglet statistiques pour la vente au détail.
class RetailStatisticsTab extends ConsumerWidget {
  const RetailStatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          child: RetailKpiCard(
                            title: 'Ventes aujourd\'hui',
                            value: '${todaySales.length}',
                            icon: Icons.shopping_cart,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: RetailKpiCard(
                            title: 'Total du jour',
                            value: CurrencyFormatter.formatDouble(todayRevenue),
                            subtitle: 'FCFA',
                            icon: Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Ligne 2: Cette semaine et ce mois
                    Row(
                      children: [
                        Expanded(
                          child: RetailKpiCard(
                            title: 'Cette semaine',
                            value: CurrencyFormatter.formatDouble(weekRevenue),
                            subtitle: 'FCFA',
                            icon: Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: RetailKpiCard(
                            title: 'Ce mois',
                            value: CurrencyFormatter.formatDouble(monthRevenue),
                            subtitle: 'FCFA',
                            icon: Icons.calendar_month,
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
                        color: const Color(0xFF101828),
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune vente enregistrée',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les ventes effectuées apparaîtront ici',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
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
                        color: const Color(0xFF101828),
                      ),
                    ),
                    if (sale.customerPhone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sale.customerPhone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF4A5565),
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CurrencyFormatter.formatDouble(sale.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B82F6),
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
                  color: const Color(0xFF4A5565),
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
                  color: const Color(0xFF4A5565),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
