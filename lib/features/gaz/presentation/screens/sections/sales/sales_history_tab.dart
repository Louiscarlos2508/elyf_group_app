import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/wholesale_date_filter_card.dart';
import '../../../widgets/wholesale_empty_state.dart';
import '../../../widgets/wholesale_sale_card.dart';
import '../../wholesaler_management_screen.dart';
import '../../../widgets/gaz_kpi_card.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

class SalesHistoryTab extends ConsumerStatefulWidget {
  const SalesHistoryTab({super.key});

  @override
  ConsumerState<SalesHistoryTab> createState() => _SalesHistoryTabState();
}

class _SalesHistoryTabState extends ConsumerState<SalesHistoryTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  SaleType? _selectedType; // null means "All"

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);
    final isManagerAsync = ref.watch(isGazManagerProvider);
    final enterpriseAsync = ref.watch(activeEnterpriseProvider);

    return isManagerAsync.when(
      data: (isManager) {
        final enterprise = enterpriseAsync.value;
        final isPOS = enterprise?.type == EnterpriseType.gasPointOfSale;
        final showWholesale = !isPOS || isManager;

        return CustomScrollView(
          slivers: [
            // Action Buttons Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WholesalerManagementScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Gérer grossistes'),
                    ),
                  ],
                ),
              ),
            ),

            // Filter section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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

            // KPI Cards & Type Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: salesAsync.when(
                  data: (allSales) {
                    final filteredSales = _selectedType == null 
                        ? allSales 
                        : allSales.where((s) => s.saleType == _selectedType).toList();

                    final metrics = GazCalculationService.calculateWholesaleMetrics(
                      filteredSales,
                      startDate: _startDate,
                      endDate: _endDate,
                      isWholesaleOnly: _selectedType == SaleType.wholesale,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTypeFilter(showWholesale),
                        const SizedBox(height: 16),
                        _WholesaleKpiGrid(metrics: metrics),
                      ],
                    );
                  },
                  loading: () => AppShimmers.statsGrid(context),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Sales list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: salesAsync.when(
                  data: (allSales) {
                    final filteredSales = _selectedType == null 
                        ? allSales 
                        : allSales.where((s) => s.saleType == _selectedType).toList();

                    final metrics = GazCalculationService.calculateWholesaleMetrics(
                      filteredSales,
                      startDate: _startDate,
                      endDate: _endDate,
                      isWholesaleOnly: _selectedType == SaleType.wholesale,
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildTypeFilter(bool showWholesale) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _HistoryFilterChip(
            label: 'Tous',
            isSelected: _selectedType == null,
            onSelected: () => setState(() => _selectedType = null),
          ),
          const SizedBox(width: 8),
          _HistoryFilterChip(
            label: 'Détail',
            isSelected: _selectedType == SaleType.retail,
            onSelected: () => setState(() => _selectedType = SaleType.retail),
          ),
          if (showWholesale) ...[
            const SizedBox(width: 8),
            _HistoryFilterChip(
              label: 'Gros',
              isSelected: _selectedType == SaleType.wholesale,
              onSelected: () => setState(() => _selectedType = SaleType.wholesale),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

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
                child: GazKpiCard(
                  title: 'Ventes',
                  value: '${metrics.salesCount}',
                  icon: Icons.shopping_cart_outlined,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GazKpiCard(
                  title: 'Total',
                  value: metrics.totalSold.toStringAsFixed(0),
                  subtitle: 'CFA',
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GazKpiCard(
                  title: 'Encaissé',
                  value: metrics.collected.toStringAsFixed(0),
                  subtitle: 'CFA',
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GazKpiCard(
                  title: 'Crédit',
                  value: metrics.credit.toStringAsFixed(0),
                  subtitle: 'CFA',
                  icon: Icons.error_outline,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GazKpiCard(
                    title: 'Ventes',
                    value: '${metrics.salesCount}',
                    icon: Icons.shopping_cart_outlined,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GazKpiCard(
                    title: 'Total',
                    value: metrics.totalSold.toStringAsFixed(0),
                    subtitle: 'CFA',
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
                  child: GazKpiCard(
                    title: 'Encaissé',
                    value: metrics.collected.toStringAsFixed(0),
                    subtitle: 'CFA',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GazKpiCard(
                    title: 'Crédit',
                    value: metrics.credit.toStringAsFixed(0),
                    subtitle: 'CFA',
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
