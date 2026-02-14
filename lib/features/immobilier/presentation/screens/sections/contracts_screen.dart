import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/entities/tenant.dart';
import '../../widgets/contract_card.dart';
import '../../widgets/contract_card_helpers.dart';
import '../../widgets/contract_detail_dialog.dart';
import '../../widgets/contract_filters.dart';
import '../../widgets/contract_form_dialog.dart';
import '../../widgets/payment_detail_dialog.dart';
import '../../widgets/property_detail_dialog.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/tenant_detail_dialog.dart';
import '../../widgets/immobilier_header.dart';

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  final _searchController = TextEditingController();
  ContractStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contract> _filterAndSort(List<Contract> contracts) {
    var filtered = contracts;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c.id.toLowerCase().contains(query) ||
            (c.property != null &&
                c.property!.address.toLowerCase().contains(query)) ||
            (c.tenant != null &&
                c.tenant!.fullName.toLowerCase().contains(query));
      }).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((c) => c.status == _selectedStatus).toList();
    }

    filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
    return filtered;
  }

  void _showContractForm({Contract? contract}) {
    showDialog(
      context: context,
      builder: (context) => ContractFormDialog(contract: contract),
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
        onDelete: () => _deleteContract(contract),
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

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => PaymentDetailDialog(
        payment: payment,
        onContractTap: _showContractDetails,
        onTenantTap: _showTenantDetails,
      ),
    );
  }

  Future<void> _deleteContract(Contract contract) async {
    final isArchived = contract.deletedAt != null;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArchived ? 'Restaurer le contrat' : 'Archiver le contrat'),
        content: Text(
          isArchived 
              ? 'Voulez-vous restaurer ce contrat ?\nIl sera de nouveau visible dans la liste active.' 
              : 'Voulez-vous archiver ce contrat ?\nIl sera déplacé dans les archives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isArchived ? Colors.green : Colors.red,
            ),
            child: Text(isArchived ? 'Restaurer' : 'Archiver'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final controller = ref.read(contractControllerProvider);
        if (isArchived) {
          await controller.restoreContract(contract.id); // Assuming restoreContract exists
          if (mounted) {
            ref.invalidate(contractsProvider);
            NotificationService.showSuccess(
              context,
              'Contrat restauré avec succès',
            );
          }
        } else {
          await controller.deleteContract(contract.id);
          if (mounted) {
            ref.invalidate(contractsProvider);
            NotificationService.showSuccess(
              context,
              'Contrat archivé avec succès',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, 'Erreur: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractsAsync = ref.watch(contractsWithRelationsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContractForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: contractsAsync.when(
        data: (contracts) {
          final filtered = _filterAndSort(contracts);
          final activeCount = contracts
              .where((c) => c.status == ContractStatus.active)
              .length;
          final pendingCount = contracts
              .where((c) => c.status == ContractStatus.pending)
              .length;
          final monthlyRevenue = contracts
              .where((c) => c.status == ContractStatus.active)
              .fold(0, (sum, c) => sum + c.monthlyRent);

          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  // Header
                  ImmobilierHeader(
                    title: 'CONTRATS',
                    subtitle: 'Baux & Locations',
                    additionalActions: [
                      Semantics(
                        label: 'Actualiser',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => ref.invalidate(contractsProvider),
                          tooltip: 'Actualiser',
                        ),
                      ),
                    ],
                  ),

                  // KPI Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.horizontalPadding,
                      child: _buildKpiCards(
                        theme,
                        contracts.length,
                        activeCount,
                        pendingCount,
                        monthlyRevenue,
                      ),
                    ),
                  ),

                  // Section header
                  SliverSectionHeader(
                    title: 'LISTE DES CONTRATS',
                    top: AppSpacing.lg,
                    bottom: AppSpacing.sm,
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
                    child: ContractFilters(
                      selectedStatus: _selectedStatus,
                      selectedArchiveFilter: ref.watch(archiveFilterProvider),
                      onStatusChanged: (status) =>
                          setState(() => _selectedStatus = status),
                      onArchiveFilterChanged: (filter) =>
                          ref.read(archiveFilterProvider.notifier).set(filter),
                      onClear: () {
                        setState(() => _selectedStatus = null);
                        ref
                            .read(archiveFilterProvider.notifier)
                            .set(ArchiveFilter.active);
                      },
                    ),
                  ),

                  // Contracts List
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(theme, contracts.isEmpty),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final contract = filtered[index];
                          return ContractCard(
                            contract: contract,
                            onTap: () => _showContractDetails(contract),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorDisplayWidget(
          error: error,
          title: 'Erreur de chargement',
          message: 'Impossible de charger les contrats.',
          onRetry: () => ref.refresh(contractsProvider),
        ),
      ),
    );
  }

  Widget _buildKpiCards(
    ThemeData theme,
    int total,
    int active,
    int pending,
    int monthlyRevenue,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total',
                value: '$total',
                icon: Icons.description,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Actifs',
                value: '$active',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'En attente',
                value: '$pending',
                icon: Icons.pending,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RevenueCard(monthlyRevenue: monthlyRevenue),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isEmpty) {
    return EmptyState(
      icon: isEmpty ? Icons.description_outlined : Icons.search_off,
      title: isEmpty ? 'Aucun contrat enregistré' : 'Aucun résultat trouvé',
      message: isEmpty
          ? 'Commencez par créer un contrat'
          : 'Essayez de modifier vos critères de recherche',
      action: isEmpty
          ? null
          : TextButton(
              onPressed: () {
                _searchController.clear();
                _selectedStatus = null;
                setState(() {});
              },
              child: const Text('Réinitialiser les filtres'),
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

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.monthlyRevenue});

  final int monthlyRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up, size: 24, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenus Mensuels Attendus',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  ContractCardHelpers.formatCurrency(monthlyRevenue),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
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
