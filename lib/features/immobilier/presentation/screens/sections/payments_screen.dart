import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/refresh_button.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/entities/tenant.dart';
import '../../widgets/contract_detail_dialog.dart';
import '../../widgets/payment_actions_dialog.dart';
import '../../widgets/payment_card.dart';
import '../../widgets/payment_card_helpers.dart';
import '../../widgets/payment_detail_dialog.dart';
import '../../widgets/payment_filters.dart';
import '../../widgets/payment_form_dialog.dart';
import '../../widgets/property_detail_dialog.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/tenant_detail_dialog.dart';

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

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return p.id.toLowerCase().contains(query) ||
            (p.receiptNumber != null && p.receiptNumber!.toLowerCase().contains(query)) ||
            (p.contract != null && p.contract!.property != null && 
             p.contract!.property!.address.toLowerCase().contains(query)) ||
            (p.contract != null && p.contract!.tenant != null &&
             p.contract!.tenant!.fullName.toLowerCase().contains(query));
      }).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    if (_selectedMethod != null) {
      filtered = filtered.where((p) => p.paymentMethod == _selectedMethod).toList();
    }

    filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return filtered;
  }

  Future<void> _showPaymentForm({Payment? payment}) async {
    final result = await showDialog<Payment>(
      context: context,
      builder: (context) => PaymentFormDialog(payment: payment),
    );

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
    showDialog(
      context: context,
      builder: (context) => PaymentDetailDialog(
        payment: payment,
        onContractTap: _showContractDetails,
        onTenantTap: _showTenantDetails,
        onPropertyTap: _showPropertyDetails,
        onDelete: () => _deletePayment(payment),
        onPrint: () => _showPaymentActions(payment),
      ),
    );
  }

  void _showContractDetails(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => ContractDetailDialog(
        contract: contract,
        onTenantTap: _showTenantDetails,
        onPropertyTap: _showPropertyDetails,
        onPaymentTap: _showPaymentDetails,
      ),
    );
  }

  void _showTenantDetails(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => TenantDetailDialog(
        tenant: tenant,
        onContractTap: _showContractDetails,
        onPaymentTap: _showPaymentDetails,
      ),
    );
  }

  void _showPropertyDetails(Property property) {
    showDialog(
      context: context,
      builder: (context) => PropertyDetailDialog(
        property: property,
        onEdit: () => Navigator.of(context).pop(),
        onDelete: () {},
      ),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le paiement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce paiement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final controller = ref.read(paymentControllerProvider);
        await controller.deletePayment(payment.id);
        ref.invalidate(paymentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      body: paymentsAsync.when(
        data: (payments) {
          final filtered = _filterAndSort(payments);
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);

          final paidCount = payments.where((p) => p.status == PaymentStatus.paid).length;
          final overdueCount = payments.where((p) => p.status == PaymentStatus.overdue).length;
          final monthTotal = payments
              .where((p) => 
                  p.status == PaymentStatus.paid && 
                  p.paymentDate.isAfter(monthStart.subtract(const Duration(days: 1))))
              .fold(0, (sum, p) => sum + p.amount);
          final overdueTotal = payments
              .where((p) => p.status == PaymentStatus.overdue)
              .fold(0, (sum, p) => sum + p.amount);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, isWide ? 24 : 16),
                      child: isWide
                          ? Row(
                              children: [
                                Text(
                                  'Paiements',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                RefreshButton(
                                  onRefresh: () => ref.invalidate(paymentsProvider),
                                  tooltip: 'Actualiser',
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () => _showPaymentForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouveau Paiement'),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Paiements',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    RefreshButton(
                                      onRefresh: () => ref.invalidate(paymentsProvider),
                                      tooltip: 'Actualiser',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _showPaymentForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouveau Paiement'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // KPI Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  label: 'Total',
                                  value: '${payments.length}',
                                  icon: Icons.payment,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiCard(
                                  label: 'Payés',
                                  value: '$paidCount',
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiCard(
                                  label: 'En retard',
                                  value: '$overdueCount',
                                  icon: Icons.warning,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _AmountCard(
                                  label: 'Encaissé ce mois',
                                  amount: monthTotal,
                                  icon: Icons.trending_up,
                                  color: Colors.green,
                                  backgroundColor: const Color(0xFFE8F5E9),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AmountCard(
                                  label: 'Impayés',
                                  amount: overdueTotal,
                                  icon: Icons.trending_down,
                                  color: Colors.red,
                                  backgroundColor: const Color(0xFFFFF0F0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        'LISTE DES PAIEMENTS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: PropertySearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),

                  // Filters
                  SliverToBoxAdapter(
                    child: PaymentFilters(
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
                  ),

                  // Payments List
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(theme, payments.isEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final payment = filtered[index];
                            return PaymentCard(
                              payment: payment,
                              onTap: () => _showPaymentDetails(payment),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(theme, error),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEmpty ? Icons.payment_outlined : Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'Aucun paiement enregistré' : 'Aucun résultat trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isEmpty) ...[
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

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(paymentsProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  PaymentCardHelpers.formatCurrency(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
