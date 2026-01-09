import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/services/dashboard_calculation_service.dart';
import '../../widgets/dashboard_alerts_section.dart';
import '../../widgets/dashboard_header_v2.dart';
import '../../widgets/dashboard_month_section_v2.dart';
import '../../widgets/dashboard_today_section_v2.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';

/// Professional dashboard screen for immobilier module.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final contractsAsync = ref.watch(contractsProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final calculationService =
        ref.watch(immobilierDashboardCalculationServiceProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: DashboardHeaderV2(
                      date: DateTime.now(),
                      role: 'Gestionnaire',
                    ),
                  ),
                  RefreshButton(
                    onRefresh: () {
                      ref.invalidate(propertiesProvider);
                      ref.invalidate(contractsProvider);
                      ref.invalidate(paymentsProvider);
                      ref.invalidate(expensesProvider);
                      ref.invalidate(tenantsProvider);
                    },
                    tooltip: 'Actualiser le tableau de bord',
                  ),
                ],
              ),
            ),
          ),

          // Today section header
          _buildSectionHeader("AUJOURD'HUI", 8, 8),

          // Today KPIs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: _DashboardTodayKpis(paymentsAsync: paymentsAsync),
            ),
          ),

          // Month section header
          _buildSectionHeader('CE MOIS', 0, 8),

          // Month KPIs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: _DashboardMonthKpis(
                propertiesAsync: propertiesAsync,
                tenantsAsync: tenantsAsync,
                contractsAsync: contractsAsync,
                paymentsAsync: paymentsAsync,
                expensesAsync: expensesAsync,
                calculationService: calculationService,
              ),
            ),
          ),

          // Alerts section header
          _buildSectionHeader('ALERTES', 0, 8),

          // Alerts
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverToBoxAdapter(
              child: _DashboardAlerts(
                paymentsAsync: paymentsAsync,
                contractsAsync: contractsAsync,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double top, double bottom) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Widget privé pour les KPIs d'aujourd'hui.
class _DashboardTodayKpis extends StatelessWidget {
  const _DashboardTodayKpis({required this.paymentsAsync});

  final AsyncValue<List<Payment>> paymentsAsync;

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      data: (payments) {
        final today = DateTime.now();
        final todayPayments = payments
            .where((p) =>
                p.paymentDate.year == today.year &&
                p.paymentDate.month == today.month &&
                p.paymentDate.day == today.day)
            .toList();
        return DashboardTodaySectionV2(todayPayments: todayPayments);
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget privé pour les KPIs du mois.
class _DashboardMonthKpis extends StatelessWidget {
  const _DashboardMonthKpis({
    required this.propertiesAsync,
    required this.tenantsAsync,
    required this.contractsAsync,
    required this.paymentsAsync,
    required this.expensesAsync,
    required this.calculationService,
  });

  final AsyncValue<List<Property>> propertiesAsync;
  final AsyncValue tenantsAsync;
  final AsyncValue<List<Contract>> contractsAsync;
  final AsyncValue<List<Payment>> paymentsAsync;
  final AsyncValue expensesAsync;
  final ImmobilierDashboardCalculationService calculationService;

  @override
  Widget build(BuildContext context) {
    return propertiesAsync.when(
      data: (properties) {
        return tenantsAsync.when(
          data: (tenants) {
            return contractsAsync.when(
              data: (contracts) {
                return paymentsAsync.when(
                  data: (payments) {
                    return expensesAsync.when(
                      data: (expenses) {
                        // Use calculation service for business logic
                        final metrics = calculationService.calculateMonthlyMetrics(
                          properties: properties,
                          tenants: tenants as List,
                          contracts: contracts,
                          payments: payments,
                          expenses: expenses as List,
                        );

                        return DashboardMonthSectionV2(
                          monthRevenue: metrics.monthRevenue,
                          monthPaymentsCount: 0,
                          monthExpensesAmount: metrics.monthExpensesTotal,
                          monthProfit: metrics.netRevenue,
                          occupancyRate: metrics.occupancyRate,
                        );
                      },
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget privé pour les alertes.
class _DashboardAlerts extends StatelessWidget {
  const _DashboardAlerts({
    required this.paymentsAsync,
    required this.contractsAsync,
  });

  final AsyncValue<List<Payment>> paymentsAsync;
  final AsyncValue<List<Contract>> contractsAsync;

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      data: (payments) {
        final unpaidPayments = payments
            .where((p) =>
                p.status == PaymentStatus.pending ||
                p.status == PaymentStatus.overdue)
            .toList();

        return contractsAsync.when(
          data: (contracts) {
            final now = DateTime.now();
            final expiringContracts = contracts
                .where((c) =>
                    c.status == ContractStatus.active &&
                    c.endDate.difference(now).inDays <= 30 &&
                    c.endDate.isAfter(now))
                .toList();

            return DashboardAlertsSection(
              unpaidPayments: unpaidPayments,
              expiringContracts: expiringContracts,
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}