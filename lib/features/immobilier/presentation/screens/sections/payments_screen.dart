import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/entities/tenant.dart';
import '../../widgets/contract_detail_dialog.dart';
import '../../widgets/payment_actions_dialog.dart';
import '../../widgets/payment_card.dart';
import '../../widgets/payment_detail_dialog.dart';
import '../../widgets/payment_filters.dart';
import '../../widgets/payment_form_dialog.dart';
import '../../widgets/property_detail_dialog.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/tenant_detail_dialog.dart';
import '../../widgets/payments/payments_kpi_cards.dart';
import '../../widgets/payments/rent_matrix_view.dart';
import '../../widgets/immobilier_header.dart';

/// Screen for managing payments.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _searchController = TextEditingController();
  PaymentMethod? _selectedMethod;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Payment> _filterAndSort(List<Payment> payments, WidgetRef ref) {
    // Utiliser le service de filtrage pour extraire la logique métier
    final filterService = ref.read(paymentFilterServiceProvider);
    final selectedStatus = ref.watch(paymentListFilterProvider);
    return filterService.filterAndSort(
      payments: payments,
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text,
      status: selectedStatus,
      method: _selectedMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsWithRelationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showPaymentForm(),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau'),
        ),
        body: Column(
          children: [
            // Standard Immobilier Header
            ImmobilierHeader(
              title: 'PAIEMENTS',
              subtitle: 'Gestion & Suivi',
              asSliver: false,
              additionalActions: [
                Semantics(
                  label: 'Actualiser',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      final _ = ref.refresh(paymentsWithRelationsProvider);
                      ref.invalidate(rentMatrixProvider);
                    },
                    tooltip: 'Actualiser',
                  ),
                ),
              ],
              bottom: TabBar(
                tabs: const [
                  Tab(text: 'HISTORIQUE'),
                  Tab(text: 'SUIVI MENSUEL'),
                ],
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                indicatorWeight: 3,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Historique (Current view)
                  _buildHistoryTab(paymentsAsync, theme),
                  // Tab 2: Suivi Mensuel (New Matrix view)
                  const RentMatrixView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<Payment>> paymentsAsync, ThemeData theme) {
    return paymentsAsync.when(
      data: (payments) {
        final filtered = _filterAndSort(payments, ref);
        final metrics = _calculateMetrics(payments);

        return CustomScrollView(
          slivers: [
            _buildKpiSection(theme, payments.length, metrics),
            _buildSectionHeader(theme),
            _buildSearchBar(),
            _buildFilters(),
            _buildPaymentsList(theme, filtered, payments.isEmpty),
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement',
        message: 'Impossible de charger les paiements.',
        onRetry: () => ref.refresh(paymentsProvider),
      ),
    );
  }

  _PaymentMetrics _calculateMetrics(List<Payment> payments) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final paidCount = payments
        .where((p) => p.status == PaymentStatus.paid)
        .length;
    final overdueCount = payments
        .where((p) => p.status == PaymentStatus.overdue)
        .length;
    final monthTotal = payments
        .where(
          (p) =>
              p.status == PaymentStatus.paid &&
              p.paymentDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ),
        )
        .fold(0, (sum, p) => sum + p.amount);
    final overdueTotal = payments
        .where((p) => p.status == PaymentStatus.overdue)
        .fold(0, (sum, p) => sum + p.amount);

    return _PaymentMetrics(
      paidCount: paidCount,
      overdueCount: overdueCount,
      monthTotal: monthTotal,
      overdueTotal: overdueTotal,
    );
  }

  Widget _buildKpiSection(
    ThemeData theme,
    int totalCount,
    _PaymentMetrics metrics,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PaymentsKpiCard(
                    label: 'Total',
                    value: '$totalCount',
                    icon: Icons.payment,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaymentsKpiCard(
                    label: 'Payés',
                    value: '${metrics.paidCount}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaymentsKpiCard(
                    label: 'En retard',
                    value: '${metrics.overdueCount}',
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
                  child: PaymentsAmountCard(
                    label: 'Encaissé ce mois',
                    amount: metrics.monthTotal,
                    icon: Icons.trending_up,
                    color: Colors.green,
                    backgroundColor: const Color(0xFFE8F5E9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaymentsAmountCard(
                    label: 'Impayés',
                    amount: metrics.overdueTotal,
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
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return SliverSectionHeader(
      title: 'LISTE DES PAIEMENTS',
      top: AppSpacing.lg,
      bottom: AppSpacing.sm,
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: PropertySearchBar(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        onClear: () => setState(() {}),
      ),
    );
  }

  Widget _buildFilters() {
    final selectedStatus = ref.watch(paymentListFilterProvider);
    return SliverToBoxAdapter(
      child: PaymentFilters(
        selectedStatus: selectedStatus,
        selectedMethod: _selectedMethod,
        onStatusChanged: (status) =>
            ref.read(paymentListFilterProvider.notifier).set(status),
        onMethodChanged: (method) => setState(() => _selectedMethod = method),
        onClear: () {
          ref.read(paymentListFilterProvider.notifier).set(null);
          setState(() {
            _selectedMethod = null;
          });
        },
      ),
    );
  }

  Widget _buildPaymentsList(
    ThemeData theme,
    List<Payment> filtered,
    bool isEmpty,
  ) {
    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(theme, isEmpty),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final payment = filtered[index];
          return PaymentCard(
            payment: payment,
            onTap: () => _showPaymentDetails(payment),
          );
        }, childCount: filtered.length),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isEmpty) {
    return EmptyState(
      icon: isEmpty ? Icons.payment_outlined : Icons.search_off,
      title: isEmpty ? 'Aucun paiement enregistré' : 'Aucun résultat trouvé',
      message: isEmpty
          ? 'Commencez par enregistrer un paiement'
          : 'Essayez de modifier vos critères de recherche',
      action: isEmpty
          ? null
          : TextButton(
              onPressed: () {
                _searchController.clear();
                ref.read(paymentListFilterProvider.notifier).set(null);
                _selectedMethod = null;
                setState(() {});
              },
              child: const Text('Réinitialiser les filtres'),
            ),
    );
  }


  // Dialog methods

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
        ref.invalidate(paymentsWithRelationsProvider);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Paiement supprimé avec succès',
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, 'Erreur: $e');
        }
      }
    }
  }
}

/// Internal data class for payment metrics.
class _PaymentMetrics {
  const _PaymentMetrics({
    required this.paidCount,
    required this.overdueCount,
    required this.monthTotal,
    required this.overdueTotal,
  });

  final int paidCount;
  final int overdueCount;
  final int monthTotal;
  final int overdueTotal;
}
