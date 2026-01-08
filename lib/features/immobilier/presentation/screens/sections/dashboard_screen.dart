import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
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
              child: paymentsAsync.when(
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
              ),
            ),
          ),

          // Month section header
          _buildSectionHeader('CE MOIS', 0, 8),

          // Month KPIs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: _buildMonthKpis(
                propertiesAsync,
                contractsAsync,
                paymentsAsync,
                expensesAsync,
              ),
            ),
          ),

          // Alerts section header
          _buildSectionHeader('ALERTES', 0, 8),

          // Alerts
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverToBoxAdapter(
              child: _buildAlerts(paymentsAsync, contractsAsync),
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

  Widget _buildMonthKpis(
    AsyncValue<List<Property>> propertiesAsync,
    AsyncValue<List<Contract>> contractsAsync,
    AsyncValue<List<Payment>> paymentsAsync,
    AsyncValue expensesAsync,
  ) {
    return propertiesAsync.when(
      data: (properties) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        final totalProperties = properties.length;
        final rentedProperties =
            properties.where((p) => p.status == PropertyStatus.rented).length;
        final occupancyRate =
            totalProperties > 0 ? (rentedProperties / totalProperties) * 100 : 0.0;

        return paymentsAsync.when(
          data: (payments) {
            final monthPayments = payments
                .where((p) =>
                    p.paymentDate.isAfter(
                        monthStart.subtract(const Duration(days: 1))) &&
                    p.status == PaymentStatus.paid)
                .toList();
            final monthRevenue =
                monthPayments.fold(0, (sum, p) => sum + p.amount);

            return expensesAsync.when(
              data: (expenses) {
                final monthExpenses = (expenses as List)
                    .where((e) => e.expenseDate
                        .isAfter(monthStart.subtract(const Duration(days: 1))))
                    .toList();
                final monthExpensesAmount =
                    monthExpenses.fold<int>(0, (sum, e) => sum + (e.amount as int));

                final monthProfit = monthRevenue - monthExpensesAmount;

                return DashboardMonthSectionV2(
                  monthRevenue: monthRevenue,
                  monthPaymentsCount: monthPayments.length,
                  monthExpensesAmount: monthExpensesAmount,
                  monthProfit: monthProfit,
                  occupancyRate: occupancyRate,
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

  Widget _buildAlerts(
    AsyncValue<List<Payment>> paymentsAsync,
    AsyncValue<List<Contract>> contractsAsync,
  ) {
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