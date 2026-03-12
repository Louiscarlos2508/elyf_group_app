import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../widgets/wholesale_date_filter_card.dart';
import '../../../widgets/wholesale_empty_state.dart';
import '../../../widgets/wholesale_sale_card.dart';
import '../../wholesaler_management_screen.dart';
import '../../../widgets/wholesale_remittance_card.dart';
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
    final isPOS = ref.watch(activeEnterpriseProvider).value?.type == EnterpriseType.gasPointOfSale;
    final isManagerAsync = ref.watch(isGazManagerProvider);
    
    // Choose provider based on user type
    final eventsAsync = isPOS 
        ? ref.watch(gasSalesProvider).whenData((sales) {
            // Map sales to SaleEvents for consistent processing
            final Map<String, List<GasSale>> grouped = {};
            for (final sale in sales) {
              final key = sale.sessionId ?? 
                  '${sale.wholesalerId}_${sale.saleDate.year}${sale.saleDate.month}${sale.saleDate.day}${sale.saleDate.hour}${sale.saleDate.minute}';
              grouped.putIfAbsent(key, () => []).add(sale);
            }
            return grouped.values.map((group) => SaleEvent(
              date: group.first.saleDate,
              amount: group.fold(0, (sum, s) => sum + s.totalAmount),
              sales: group,
            )).toList()..sort((a, b) => b.date.compareTo(a.date));
          })
        : ref.watch(gazUnifiedFinancialEventsProvider);

    return isManagerAsync.when(
      data: (isManager) {
        const showWholesale = true;

        return CustomScrollView(
          slivers: [
            // Action Buttons Row (Wholesaler management for Parent)
            if (!isPOS)
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

            // Filter section (Date only)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: WholesaleDateFilterCard(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateChanged: (date) => setState(() => _startDate = date),
                  onEndDateChanged: (date) => setState(() => _endDate = date),
                ),
              ),
            ),

            // KPI Cards & Type Filter (Type filter only for POS)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: eventsAsync.when(
                  data: (allEvents) {
                    final filteredEvents = allEvents.where((e) {
                      final hasCorrectDate = (_startDate == null || !e.date.isBefore(_startDate!)) &&
                          (_endDate == null || !e.date.isAfter(_endDate!.add(const Duration(days: 1))));
                      
                      if (!hasCorrectDate) return false;
                      
                      if (isPOS && _selectedType != null) {
                        return e is SaleEvent && e.sales.first.saleType == _selectedType;
                      }
                      return true;
                    }).toList();

                    final totalSales = filteredEvents.whereType<SaleEvent>().fold<double>(0, (sum, e) => sum + e.amount);
                    final totalRemittances = filteredEvents.whereType<RemittanceEvent>().fold<double>(0, (sum, e) => sum + e.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPOS) ...[
                          _buildTypeFilter(showWholesale),
                          const SizedBox(height: 16),
                        ],
                        _FinancialKpiGrid(
                          totalSales: totalSales, 
                          totalRemittances: totalRemittances,
                          isParent: !isPOS,
                        ),
                      ],
                    );
                  },
                  loading: () => AppShimmers.statsGrid(context),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Unified Events list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: eventsAsync.when(
                  data: (allEvents) {
                    final filteredEvents = allEvents.where((e) {
                      final hasCorrectDate = (_startDate == null || !e.date.isBefore(_startDate!)) &&
                          (_endDate == null || !e.date.isAfter(_endDate!.add(const Duration(days: 1))));
                      
                      if (!hasCorrectDate) return false;
                      
                      if (isPOS && _selectedType != null) {
                        return e is SaleEvent && e.sales.first.saleType == _selectedType;
                      }
                      return true;
                    }).toList();

                    if (filteredEvents.isEmpty) {
                      return const WholesaleEmptyState();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flux financier (${filteredEvents.length} entrées)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...filteredEvents.map((event) {
                          if (event is SaleEvent) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WholesaleSaleCard(sales: event.sales),
                            );
                          } else if (event is RemittanceEvent) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WholesaleRemittanceCard(remittance: event.remittance),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    );
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

class _FinancialKpiGrid extends StatelessWidget {
  const _FinancialKpiGrid({
    required this.totalSales,
    required this.totalRemittances,
    required this.isParent,
  });

  final double totalSales;
  final double totalRemittances;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final totalEntries = totalSales + totalRemittances;

    return Row(
      children: [
        Expanded(
          child: GazKpiCard(
            title: 'Ventes',
            value: totalSales.toStringAsFixed(0),
            subtitle: 'CFA',
            icon: Icons.trending_up,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (isParent) ...[
          Expanded(
            child: GazKpiCard(
              title: 'Versements',
              value: totalRemittances.toStringAsFixed(0),
              subtitle: 'CFA',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GazKpiCard(
              title: 'Total',
              value: totalEntries.toStringAsFixed(0),
              subtitle: 'CFA',
              icon: Icons.payments_outlined,
              color: AppColors.primary,
            ),
          ),
        ] else
          Expanded(
            child: GazKpiCard(
              title: 'Recettes',
              value: totalEntries.toStringAsFixed(0),
              subtitle: 'CFA',
              icon: Icons.payments_outlined,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}


