import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/expense.dart' show PropertyExpense;
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/entities/maintenance_ticket.dart';
import '../../../domain/services/dashboard_calculation_service.dart';
import '../../widgets/dashboard_alerts_section.dart';
import '../../widgets/immobilier_header.dart';
import '../../widgets/dashboard_month_section_v2.dart';
import '../../widgets/dashboard_today_section_v2.dart';

/// Professional dashboard screen for immobilier module.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final contractsAsync = ref.watch(contractsProvider);
    final paymentsAsync = ref.watch(paymentsWithRelationsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final ticketsAsync = ref.watch(maintenanceTicketsProvider);
    final calculationService = ref.watch(
      immobilierDashboardCalculationServiceProvider,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          // Header
          ImmobilierHeader(
            title: 'TABLEAU DE BORD',
            subtitle: "Vue d'ensemble",
            additionalActions: [
              Semantics(
                label: 'Actualiser le tableau de bord',
                hint: 'Recharge toutes les données affichées',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    ref.invalidate(propertiesProvider);
                    ref.invalidate(contractsProvider);
                    ref.invalidate(paymentsProvider);
                    ref.invalidate(expensesProvider);
                    ref.invalidate(tenantsProvider);
                    ref.invalidate(immobilierMonthlyMetricsProvider);
                    ref.invalidate(immobilierAlertsProvider);
                  },
                  tooltip: 'Actualiser le tableau de bord',
                ),
              ),
            ],
          ),

          // Today section header
          SliverSectionHeader(
            title: "AUJOURD'HUI",
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),

          // Today KPIs
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: SliverToBoxAdapter(
              child: _DashboardTodayKpis(
                ref: ref,
                paymentsAsync: paymentsAsync,
              ),
            ),
          ),

          // Month section header
          const SliverSectionHeader(
            title: 'CE MOIS',
            bottom: AppSpacing.sm,
          ),

          // Month KPIs
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: SliverToBoxAdapter(
              child: _DashboardMonthKpis(
                propertiesAsync: propertiesAsync,
                tenantsAsync: tenantsAsync,
                contractsAsync: contractsAsync,
                paymentsAsync: paymentsAsync,
                expensesAsync: expensesAsync,
                ticketsAsync: ticketsAsync,
                calculationService: calculationService,
                onRevenueTap: () => _navigateToSection(context, ref, 'Paiements',
                    onNavigation: () {
                  ref.read(paymentListFilterProvider.notifier).set(null);
                }),
                onExpensesTap: () => _navigateToSection(context, ref, 'Dépenses'),
                onProfitTap: () => _navigateToSection(context, ref, 'Rapports'),
                onOccupancyTap: () =>
                    _navigateToSection(context, ref, 'Propriétés',
                        onNavigation: () {
                  ref.read(propertyListFilterProvider.notifier).set(
                      PropertyStatus.rented);
                }),
                onMaintenanceTap: () => _navigateToSection(context, ref, 'Maintenance'),
              ),
            ),
          ),

          // Alerts section header
          const SliverSectionHeader(
            title: 'ALERTES',
            bottom: AppSpacing.sm,
          ),

          // Alerts
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: _DashboardAlerts(ref: ref),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSection(
    BuildContext context,
    WidgetRef ref,
    String label, {
    VoidCallback? onNavigation,
  }) {
    final sections =
        ref.read(accessibleImmobilierSectionsProvider).asData?.value ?? [];
    final index = sections.indexWhere((s) => s.label == label);
    if (index != -1) {
      onNavigation?.call();
      context
          .findAncestorStateOfType<BaseModuleShellScreenState>()
          ?.navigateToIndex(index);
    }
  }
}

/// Widget privé pour les KPIs d'aujourd'hui.
class _DashboardTodayKpis extends StatelessWidget {
  const _DashboardTodayKpis({
    required this.ref,
    required this.paymentsAsync,
  });

  final WidgetRef ref;
  final AsyncValue<List<Payment>> paymentsAsync;

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      data: (payments) {
        final today = DateTime.now();
        final todayPayments = payments
            .where(
              (p) =>
                  p.paymentDate.year == today.year &&
                  p.paymentDate.month == today.month &&
                  p.paymentDate.day == today.day,
            )
            .toList();
        return DashboardTodaySectionV2(todayPayments: todayPayments);
      },
      loading: () => AppShimmers.statsGrid(context),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        onRetry: () => ref.refresh(paymentsProvider),
      ),
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
    required this.ticketsAsync,
    required this.calculationService,
    this.onRevenueTap,
    this.onExpensesTap,
    this.onProfitTap,
    this.onOccupancyTap,
    this.onMaintenanceTap,
  });

  final AsyncValue<List<Property>> propertiesAsync;
  final AsyncValue tenantsAsync;
  final AsyncValue<List<Contract>> contractsAsync;
  final AsyncValue<List<Payment>> paymentsAsync;
  final AsyncValue expensesAsync;
  final AsyncValue<List<MaintenanceTicket>> ticketsAsync;
  final ImmobilierDashboardCalculationService calculationService;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onExpensesTap;
  final VoidCallback? onProfitTap;
  final VoidCallback? onOccupancyTap;
  final VoidCallback? onMaintenanceTap;

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
                        return ticketsAsync.when(
                          data: (tickets) {
                             // Use calculation service for business logic
                            final metrics = calculationService
                                .calculateMonthlyMetrics(
                                  properties: properties,
                                  tenants: (tenants as List).cast<Tenant>(),
                                  contracts: contracts,
                                  payments: payments,
                                  expenses: (expenses as List)
                                      .cast<PropertyExpense>(),
                                  tickets: tickets,
                                );

                            return DashboardMonthSectionV2(
                              monthRevenue: metrics.monthRevenue,
                              monthPaymentsCount: metrics.monthPaymentsCount,
                              monthExpensesAmount: metrics.monthExpensesTotal,
                              monthProfit: metrics.netRevenue,
                              occupancyRate: metrics.occupancyRate,
                              collectionRate: metrics.collectionRate,
                              openTickets: metrics.totalOpenTickets,
                              highPriorityTickets: metrics.highPriorityTickets,
                              onRevenueTap: onRevenueTap,
                              onExpensesTap: onExpensesTap,
                              onProfitTap: onProfitTap,
                              onOccupancyTap: onOccupancyTap,
                              onMaintenanceTap: onMaintenanceTap,
                            );
                          },
                          loading: () => AppShimmers.statsGrid(context),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                      loading: () => AppShimmers.statsGrid(context),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => AppShimmers.statsGrid(context),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => AppShimmers.statsGrid(context),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => AppShimmers.statsGrid(context),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => AppShimmers.statsGrid(context),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// Widget privé pour les alertes.
class _DashboardAlerts extends StatelessWidget {
  const _DashboardAlerts({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(immobilierAlertsProvider);

    return alertsAsync.when(
      data: (data) {
        final unpaidPayments = data.payments
            .where(
              (p) =>
                  p.status == PaymentStatus.pending ||
                  p.status == PaymentStatus.overdue,
            )
            .toList();

        final now = DateTime.now();
        final expiringContracts = data.contracts
            .where(
              (c) =>
                  c.status == ContractStatus.active &&
                  c.endDate != null &&
                  c.endDate!.difference(now).inDays <= 30 &&
                  c.endDate!.isAfter(now),
            )
            .toList();

        return DashboardAlertsSection(
          unpaidPayments: unpaidPayments,
          expiringContracts: expiringContracts,
        );
      },
      loading: () => AppShimmers.list(context, itemCount: 2),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des alertes',
        onRetry: () => ref.refresh(immobilierAlertsProvider),
      ),
    );
  }
}
