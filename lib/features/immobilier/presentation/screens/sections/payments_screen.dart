import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/payment.dart';
import '../../widgets/payment_actions_dialog.dart';
import '../../widgets/payment_card.dart';
import '../../widgets/payment_filters.dart';
import '../../widgets/payment_form_dialog.dart';
import '../../widgets/property_search_bar.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _searchController = TextEditingController();
  PaymentStatus? _selectedStatus;
  PaymentMethod? _selectedMethod;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Payment> _filterAndSort(List<Payment> payments) {
    var filtered = payments;

    // Filtrage par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return p.id.toLowerCase().contains(query) ||
            (p.receiptNumber != null && p.receiptNumber!.toLowerCase().contains(query)) ||
            (p.contract != null && p.contract!.property != null && 
             p.contract!.property!.address.toLowerCase().contains(query));
      }).toList();
    }

    // Filtrage par statut
    if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    // Filtrage par méthode
    if (_selectedMethod != null) {
      filtered = filtered.where((p) => p.paymentMethod == _selectedMethod).toList();
    }

    // Tri par date (plus récents en premier)
    filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return filtered;
  }

  Future<void> _showPaymentForm({Payment? payment}) async {
    final result = await showDialog<Payment>(
      context: context,
      builder: (context) => PaymentFormDialog(payment: payment),
    );

    // Si un paiement a été créé/mis à jour, proposer impression/PDF
    if (result != null && mounted) {
      _showPaymentActions(result);
    }
  }

  void _showPaymentActions(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => PaymentActionsDialog(payment: payment),
    );
  }

  void _showPaymentDetails(Payment payment) {
    // TODO: Ouvrir le dialog de détails
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: _showPaymentForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Paiement'),
                ),
              ),
            ),
          ),
          PropertySearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
          PaymentFilters(
            selectedStatus: _selectedStatus,
            selectedMethod: _selectedMethod,
            onStatusChanged: (status) => setState(() => _selectedStatus = status),
            onMethodChanged: (method) => setState(() => _selectedMethod = method),
            onClear: () {
              setState(() {
                _selectedStatus = null;
                _selectedMethod = null;
              });
            },
          ),
          Expanded(
            child: paymentsAsync.when(
              data: (payments) {
                final filtered = _filterAndSort(payments);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          payments.isEmpty ? Icons.payment_outlined : Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          payments.isEmpty
                              ? 'Aucun paiement enregistré'
                              : 'Aucun résultat trouvé',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (payments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _selectedStatus = null;
                              _selectedMethod = null;
                              setState(() {});
                            },
                            child: const Text('Réinitialiser les filtres'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(paymentsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final payment = filtered[index];
                      return PaymentCard(
                        payment: payment,
                        onTap: () => _showPaymentDetails(payment),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: $error',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ref.invalidate(paymentsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
