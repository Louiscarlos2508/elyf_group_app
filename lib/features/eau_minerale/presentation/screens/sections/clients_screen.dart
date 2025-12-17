import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/clients_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/customer_credit.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../../widgets/credit_history_dialog.dart';
import '../../widgets/credit_payment_dialog.dart';
import '../../widgets/credits_customers_list.dart';
import '../../widgets/credits_kpi_section.dart';
import '../../widgets/section_placeholder.dart';

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
      // Charger les crédits réels du client
      final allCreditSales = await creditRepo.fetchCreditSales();
      final customerCreditSales = allCreditSales
          .where((s) => s.customerId == customerId && s.isCredit)
          .toList();
      
      if (customerCreditSales.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce client n\'a pas de crédit en cours')),
        );
        return;
      }
      
      // Calculer le crédit total réel
      // Note: sale.amountPaid est déjà mis à jour avec les paiements via updateSaleAmountPaid
      // donc on utilise directement remainingAmount
      int totalCreditReal = 0;
      for (final sale in customerCreditSales) {
        if (sale.remainingAmount > 0) {
          totalCreditReal += sale.remainingAmount;
        }
      }
      
      if (totalCreditReal <= 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce client n\'a pas de crédit en cours')),
        );
        return;
      }
      
      // Récupérer le nom du client
      final customer = await customerRepo.getCustomer(customerId);
      final customerName = customer?.name ?? 
          (customerCreditSales.isNotEmpty ? customerCreditSales.first.customerName : 'Client');
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => CreditPaymentDialog(
          customerId: customerId,
          customerName: customerName,
          totalCredit: totalCreditReal,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
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
      final customerName = customer?.name ?? 
          (customerCreditSales.isNotEmpty ? customerCreditSales.first.customerName : 'Client');
      
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
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

class _CreditsContent extends ConsumerStatefulWidget {
  const _CreditsContent({
    required this.state,
    required this.onPaymentTap,
    required this.onHistoryTap,
  });

  final ClientsState state;
  final void Function(String customerId) onPaymentTap;
  final void Function(String customerId) onHistoryTap;

  @override
  ConsumerState<_CreditsContent> createState() => _CreditsContentState();
}

class _CreditsContentState extends ConsumerState<_CreditsContent> {
  int _refreshKey = 0;

  void _refresh() {
    ref.invalidate(clientsStateProvider);
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            // Header - Style uniforme avec les autres pages
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: isWide
                    ? Row(
                        children: [
                          Text(
                            'Gestion des Crédits Clients',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refresh,
                            tooltip: 'Actualiser les crédits',
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Gestion des Crédits Clients',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refresh,
                            tooltip: 'Actualiser les crédits',
                          ),
                        ],
                      ),
              ),
            ),
            // KPI Section and Customers List (calculated from real credits)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: FutureBuilder<_CreditsData>(
                  key: ValueKey(_refreshKey),
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

                    final creditsData = snapshot.data ?? _CreditsData(
                      creditsMap: <String, List<CustomerCredit>>{},
                      customersMap: <String, CustomerSummary>{},
                    );
                    final creditsMap = creditsData.creditsMap;
                    final allCustomersMap = creditsData.customersMap;
                    
                    // Combiner les clients de widget.state.customers avec ceux qui ont des crédits
                    final allCustomersList = <CustomerSummary>[];
                    final existingCustomerIds = widget.state.customers.map((c) => c.id).toSet();
                    
                    // Ajouter les clients de widget.state.customers
                    allCustomersList.addAll(widget.state.customers);
                    
                    // Ajouter les clients qui ont des crédits mais ne sont pas dans state.customers
                    for (final entry in allCustomersMap.entries) {
                      if (!existingCustomerIds.contains(entry.key)) {
                        allCustomersList.add(entry.value);
                      }
                    }
                    
                    // Calculer les KPI à partir des crédits réels
                    int totalCreditReal = 0;
                    int customersWithCreditReal = 0;
                    
                    for (final customer in allCustomersList) {
                      final credits = creditsMap[customer.id] ?? [];
                      final totalCreditFromCredits = credits.fold<int>(
                        0,
                        (sum, credit) => sum + credit.remainingAmount,
                      );
                      if (totalCreditFromCredits > 0) {
                        totalCreditReal += totalCreditFromCredits;
                        customersWithCreditReal++;
                      }
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Section
                        CreditsKpiSection(
                          totalCredit: totalCreditReal,
                          customersWithCredit: customersWithCreditReal,
                        ),
                        const SizedBox(height: 32),
                        // Customers List
                        CreditsCustomersList(
                          customers: allCustomersList,
                          getCredits: (customer) => creditsMap[customer.id] ?? [],
                          onHistoryTap: widget.onHistoryTap,
                          onPaymentTap: widget.onPaymentTap,
                        ),
                      ],
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

  Future<_CreditsData> _loadAllCredits(WidgetRef ref) async {
    final creditRepo = ref.read(creditRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);
    final creditsMap = <String, List<CustomerCredit>>{};
    final customersMap = <String, CustomerSummary>{};

    // Charger toutes les ventes en crédit validées (pas seulement celles des clients dans state.customers)
    final allCreditSales = await creditRepo.fetchCreditSales();
    
    // Grouper les ventes par customerId
    final salesByCustomer = <String, List<Sale>>{};
    for (final sale in allCreditSales) {
      if (sale.customerId.isNotEmpty && !sale.customerId.startsWith('temp-')) {
        salesByCustomer.putIfAbsent(sale.customerId, () => []).add(sale);
      }
    }

    // Charger les crédits pour chaque client ayant des ventes en crédit
    for (final entry in salesByCustomer.entries) {
      final customerId = entry.key;
      final creditSales = entry.value;
      
      try {
        // Essayer de récupérer le client depuis le repository
        CustomerSummary? customer = await customerRepo.getCustomer(customerId);
        
        // Si le client n'existe pas, créer un CustomerSummary temporaire à partir de la première vente
        if (customer == null && creditSales.isNotEmpty) {
          final firstSale = creditSales.first;
          customer = CustomerSummary(
            id: customerId,
            name: firstSale.customerName,
            phone: firstSale.customerPhone,
            totalCredit: 0, // Sera calculé plus tard
            purchaseCount: creditSales.length,
            lastPurchaseDate: creditSales.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b),
            cnib: firstSale.customerCnib,
          );
        }
        
        if (customer == null) continue;
        
        // Utiliser directement sale.amountPaid car il est déjà mis à jour par CreditService
        final credits = creditSales.map((sale) {
          return CustomerCredit(
            id: sale.id,
            saleId: sale.id,
            amount: sale.totalPrice,
            amountPaid: sale.amountPaid,
            date: sale.date,
            dueDate: sale.date.add(const Duration(days: 30)),
          );
        }).toList();
        
        // Ne garder que les crédits avec un montant restant > 0
        final validCredits = credits.where((c) => c.remainingAmount > 0).toList();
        if (validCredits.isNotEmpty) {
          creditsMap[customerId] = validCredits;
          customersMap[customerId] = customer;
        }
      } catch (e) {
        // Ignorer les erreurs pour ce client
      }
    }

    return _CreditsData(creditsMap: creditsMap, customersMap: customersMap);
  }
}

class _CreditsData {
  const _CreditsData({
    required this.creditsMap,
    required this.customersMap,
  });

  final Map<String, List<CustomerCredit>> creditsMap;
  final Map<String, CustomerSummary> customersMap;
}
