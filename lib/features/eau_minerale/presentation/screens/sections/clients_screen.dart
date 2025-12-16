import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/clients_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/customer_credit.dart';
import '../../widgets/credit_history_dialog.dart';
import '../../widgets/credit_payment_dialog.dart';
import '../../widgets/credits_customers_list.dart';
import '../../widgets/credits_kpi_section.dart';
import '../../widgets/section_placeholder.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  void _showPaymentDialog(BuildContext context, WidgetRef ref, String customerId) {
    final state = ref.read(clientsStateProvider);
    state.when(
      data: (data) {
        if (data.customers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun client trouvé')),
          );
          return;
        }
        
        final customer = data.customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => data.customers.first,
        );
        
        if (customer.totalCredit > 0) {
          showDialog(
            context: context,
            builder: (context) => CreditPaymentDialog(
              customerId: customerId,
              customerName: customer.name,
              totalCredit: customer.totalCredit,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ce client n\'a pas de crédit en cours')),
          );
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chargement en cours...')),
        );
      },
      error: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${error.toString()}')),
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context, WidgetRef ref, String customerId) {
    final state = ref.read(clientsStateProvider);
    state.when(
      data: (data) {
        if (data.customers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun client trouvé')),
          );
          return;
        }
        
        final customer = data.customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => data.customers.first,
        );
        
        showDialog(
          context: context,
          builder: (context) => CreditHistoryDialog(
            customerId: customerId,
            customerName: customer.name,
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chargement en cours...')),
        );
      },
      error: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${error.toString()}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientsStateProvider);
    return state.when(
      data: (data) => _CreditsContent(
        state: data,
        onPaymentTap: (customerId) => _showPaymentDialog(context, ref, customerId),
        onHistoryTap: (customerId) => _showHistoryDialog(context, ref, customerId),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => SectionPlaceholder(
        icon: Icons.people_alt_outlined,
        title: 'Clients indisponibles',
        subtitle: 'Impossible de charger les comptes clients.',
        primaryActionLabel: 'Réessayer',
        onPrimaryAction: () => ref.invalidate(clientsStateProvider),
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
    final customersWithCredit = state.customers.where((c) => c.totalCredit > 0).length;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion des Crédits Clients',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suivi et encaissement des crédits clients',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // KPI Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CreditsKpiSection(
                  totalCredit: state.totalCredit,
                  customersWithCredit: customersWithCredit,
                ),
              ),
            ),
            // Customers List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: FutureBuilder<Map<String, List<CustomerCredit>>>(
                  future: _loadAllCredits(ref),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final creditsMap = snapshot.data ?? {};
                    
                    return CreditsCustomersList(
                      customers: state.customers,
                      getCredits: (customer) => creditsMap[customer.id] ?? [],
                      onHistoryTap: onHistoryTap,
                      onPaymentTap: onPaymentTap,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, List<CustomerCredit>>> _loadAllCredits(WidgetRef ref) async {
    final creditRepo = ref.read(creditRepositoryProvider);
    final creditsMap = <String, List<CustomerCredit>>{};

    for (final customer in state.customers) {
      try {
        // Charger uniquement les ventes en crédit validées
        final sales = await creditRepo.fetchCustomerCredits(customer.id);
        final creditSales = sales.where((s) => s.isCredit && s.isValidated).toList();
        
        if (creditSales.isEmpty) {
          creditsMap[customer.id] = [];
          continue;
        }
        
        final credits = await Future.wait(
          creditSales.map((sale) async {
            // Récupérer les paiements supplémentaires enregistrés
            final payments = await creditRepo.fetchSalePayments(sale.id);
            final totalPaidFromPayments = payments.fold<int>(0, (sum, p) => sum + p.amount);
            
            // Le montant total payé = montant payé initial + paiements supplémentaires
            final totalAmountPaid = sale.amountPaid + totalPaidFromPayments;
            
            return CustomerCredit(
              id: sale.id,
              saleId: sale.id,
              amount: sale.totalPrice,
              amountPaid: totalAmountPaid,
              date: sale.date,
              dueDate: sale.date.add(const Duration(days: 30)),
            );
          }),
        );
        
        // Ne garder que les crédits avec un montant restant > 0
        final validCredits = credits.where((c) => c.remainingAmount > 0).toList();
        creditsMap[customer.id] = validCredits;
      } catch (e) {
        creditsMap[customer.id] = [];
      }
    }

    return creditsMap;
  }
}
