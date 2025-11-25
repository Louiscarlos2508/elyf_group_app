import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/clients_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/customer_credit.dart';
import '../../../domain/repositories/customer_repository.dart' show CustomerSummary;
import '../../widgets/credit_history_dialog.dart';
import '../../widgets/credit_payment_dialog.dart';
import '../../widgets/credits_customers_list.dart';
import '../../widgets/credits_kpi_section.dart';
import '../../widgets/section_placeholder.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  void _showPaymentDialog(BuildContext context, WidgetRef ref, String customerId) {
    final state = ref.read(clientsStateProvider);
    state.whenData((data) {
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
    });
  }

  void _showHistoryDialog(BuildContext context, WidgetRef ref, String customerId) {
    final state = ref.read(clientsStateProvider);
    state.whenData((data) {
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
    });
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

class _CreditsContent extends StatelessWidget {
  const _CreditsContent({
    required this.state,
    required this.onPaymentTap,
    required this.onHistoryTap,
  });

  final ClientsState state;
  final void Function(String customerId) onPaymentTap;
  final void Function(String customerId) onHistoryTap;

  List<CustomerCredit> _getMockCredits(CustomerSummary customer) {
    if (customer.totalCredit == 0) {
      return [];
    }
    // Create a mock credit entry based on customer's total credit
    return [
      CustomerCredit(
        id: '25',
        saleId: 'sale-${customer.id}',
        amount: customer.totalCredit,
        amountPaid: 0,
        date: customer.lastPurchaseDate ?? DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 30)),
      ),
    ];
  }

  int get totalCredit => state.totalCredit;
  int get customersWithCredit => state.customers.where((c) => c.totalCredit > 0).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersWithCredit = this.customersWithCredit;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Gestion des Crédits',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CreditsKpiSection(
                  totalCredit: totalCredit,
                  customersWithCredit: customersWithCredit,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: CreditsCustomersList(
                  customers: state.customers,
                  getMockCredits: _getMockCredits,
                  onHistoryTap: onHistoryTap,
                  onPaymentTap: onPaymentTap,
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
}
