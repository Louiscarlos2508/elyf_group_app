import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../application/controllers/clients_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/sale.dart';
import '../../widgets/credit_history_dialog.dart';
import '../../widgets/credit_payment_dialog.dart';
import '../../widgets/credits_customers_list.dart';
import '../../widgets/credits_kpi_section.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  Future<void> _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) async {
    final creditRepo = ref.read(creditRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);

    try {

      // Charger les crédits réels du client avec une logique robuste de résolution d'ID
      final allCreditSales = await creditRepo.fetchCreditSales();
      final customerCreditSales = <Sale>[];
      
      // Grouper par ID local pour minimiser les appels au repo
      final salesByLocalId = <String, List<Sale>>{};
      for (final sale in allCreditSales) {
        salesByLocalId.putIfAbsent(sale.customerId, () => []).add(sale);
      }

      // Chercher les ventes correspondant à ce client (directement ou via résolution)
      for (final entry in salesByLocalId.entries) {
        final localId = entry.key;
        final sales = entry.value;

        if (localId == customerId) {
          customerCreditSales.addAll(sales);
        } else {
          // Vérifier si cet ID local correspond au client cible
          final customer = await customerRepo.getCustomer(localId);
          if (customer != null && customer.id == customerId) {
            customerCreditSales.addAll(sales);
          }
        }
      }

      // Filtrer pour ne garder que les vrais crédits (montant restant > 0)
      final activeCredits = customerCreditSales
          .where((s) => s.isCredit && s.remainingAmount > 0)
          .toList();

      if (activeCredits.isEmpty) {
        if (!context.mounted) return;
        NotificationService.showInfo(
          context,
          'Ce client n\'a pas de crédit en cours',
        );
        return;
      }

      // Calculer le crédit total réel
      int totalCreditReal = activeCredits.fold(0, (sum, s) => sum + s.remainingAmount);

      if (totalCreditReal <= 0) {
        if (!context.mounted) return;
        NotificationService.showInfo(
          context,
          'Ce client n\'a pas de crédit en cours',
        );
        return;
      }

      // Récupérer le nom du client
      final customer = await customerRepo.getCustomer(customerId);
      final customerName =
          customer?.name ??
          (activeCredits.isNotEmpty
              ? activeCredits.first.customerName
              : 'Client');

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => CreditPaymentDialog(
          customerId: customerId,
          customerName: customerName,
          totalCredit: totalCreditReal,
          preloadedSales: activeCredits, // Passer les ventes trouvées
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(context, e.toString());
    }
  }

  Future<void> _showHistoryDialog(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) async {
    final creditRepo = ref.read(creditRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);

    try {
      // Vérifier que le client a des crédits
      final allCreditSales = await creditRepo.fetchCreditSales();
      final customerCreditSales = allCreditSales
          .where((s) => s.customerId == customerId && s.isCredit)
          .toList();

      // Récupérer le nom du client
      final customer = await customerRepo.getCustomer(customerId);
      final customerName =
          customer?.name ??
          (customerCreditSales.isNotEmpty
              ? customerCreditSales.first.customerName
              : 'Client');

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => CreditHistoryDialog(
          customerId: customerId,
          customerName: customerName,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientsStateProvider);
    return state.when(
        data: (data) => _CreditsContent(
          state: data,
          onPaymentTap: (customerId) async {
            await _showPaymentDialog(context, ref, customerId);
          },
          onHistoryTap: (customerId) async {
            await _showHistoryDialog(context, ref, customerId);
          },
        ),
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorDisplayWidget(
          error: error,
          title: 'Clients indisponibles',
          message: 'Impossible de charger les comptes clients.',
          onRetry: () => ref.refresh(clientsStateProvider),
        ),
    );
  }
}

class _CreditsContent extends ConsumerWidget {
  const _CreditsContent({
    required this.state,
    required this.onPaymentTap,
    required this.onHistoryTap,
  });

  final ClientsState state;
  final void Function(String customerId) onPaymentTap;
  final void Function(String customerId) onHistoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creditsAsync = ref.watch(creditsDashboardProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return CustomScrollView(
          slivers: [
            // Header
            // Premium Header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF00C2FF), // Cyan for Water Module
                      const Color(0xFF0369A1), // Deep Blue
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GESTION DES CRÉDITS",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Suivi & Paiements",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        // Invalidate both to be sure we get fresh data
                        ref.invalidate(creditsDashboardProvider);
                        ref.invalidate(clientsStateProvider);
                      },
                      tooltip: 'Actualiser les crédits',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // KPI Section and Customers List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: creditsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Erreur: $error'),
                    ),
                  ),
                  data: (data) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Section
                        CreditsKpiSection(
                          totalCredit: data.totalCredit,
                          customersWithCredit: data.customersWithCredit,
                        ),
                        const SizedBox(height: 32),
                        // Customers List
                        CreditsCustomersList(
                          customers: data.mergedCustomers,
                          getCredits: (customer) =>
                              data.creditsMap[customer.id] ?? [],
                          onHistoryTap: onHistoryTap,
                          onPaymentTap: onPaymentTap,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
