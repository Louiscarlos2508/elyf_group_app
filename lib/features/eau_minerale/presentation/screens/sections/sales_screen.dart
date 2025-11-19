import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/sales_controller.dart';
import '../../../application/providers.dart';
import '../../widgets/enhanced_list_card.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/sale_form.dart';
import '../../widgets/section_placeholder.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<SaleFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Nouvelle vente',
        child: SaleForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesStateProvider);
    return Scaffold(
      body: state.when(
        data: (data) => _SalesList(state: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.point_of_sale,
          title: 'Ventes indisponibles',
          subtitle: 'Impossible de récupérer les dernières ventes.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(salesStateProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_fab',
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nouvelle vente'),
      ),
    );
  }
}

class _SalesList extends StatelessWidget {
  const _SalesList({required this.state});

  final SalesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenus du jour',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${state.todayRevenue} CFA',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.sales.length,
            itemBuilder: (context, index) {
              final sale = state.sales[index];
              final isCredit = sale.isCredit;
              final isPaid = sale.isFullyPaid;
              return EnhancedListCard(
                title: sale.customerName,
                subtitle: '${sale.quantity} paquets • ${sale.productName}',
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCredit ? Icons.receipt_long : Icons.shopping_bag,
                    color: isCredit ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${sale.totalPrice} CFA',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        isPaid ? 'Payé' : 'En attente',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                      backgroundColor: (isPaid ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.1),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
