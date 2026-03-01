import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/tenant.dart';
import '../../widgets/contract_detail_dialog.dart';
import '../../widgets/payment_detail_dialog.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/tenant_card.dart';
import '../../widgets/tenant_detail_dialog.dart';
import '../../widgets/tenant_form_dialog.dart';
import '../../widgets/tenant_filters.dart';
import '../../widgets/immobilier_header.dart';

class TenantsScreen extends ConsumerStatefulWidget {
  const TenantsScreen({super.key});

  @override
  ConsumerState<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends ConsumerState<TenantsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Tenant> _filterTenants(List<Tenant> tenants) {
    if (_searchController.text.isEmpty) {
      return tenants;
    }
    final query = _searchController.text.toLowerCase();
    return tenants.where((tenant) {
      return tenant.fullName.toLowerCase().contains(query) ||
          tenant.phone.contains(query) ||
          (tenant.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showTenantForm({Tenant? tenant}) {
    showDialog(
      context: context,
      builder: (context) => TenantFormDialog(tenant: tenant),
    );
  }

  void _showTenantDetails(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => TenantDetailDialog(
        tenant: tenant,
        onContractTap: _showContractDetails,
        onPaymentTap: _showPaymentDetails,
        onDelete: () => _deleteTenant(tenant),
      ),
    );
  }

  Future<void> _deleteTenant(Tenant tenant) async {
    try {
      final controller = ref.read(tenantControllerProvider);
      final isArchived = tenant.deletedAt != null;

      if (isArchived) {
        await controller.restoreTenant(tenant.id);
        if (mounted) {
          ref.invalidate(tenantsProvider);
          NotificationService.showSuccess(
            context,
            'Locataire restauré avec succès',
          );
        }
      } else {
        await controller.deleteTenant(tenant.id);
        if (mounted) {
          ref.invalidate(tenantsProvider);
          NotificationService.showSuccess(
            context,
            'Locataire archivé avec succès',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  void _showContractDetails(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => ContractDetailDialog(
        contract: contract,
        onTenantTap: _showTenantDetails,
        onPaymentTap: _showPaymentDetails,
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

  int _countActiveContracts(String tenantId, List<Contract> allContracts) {
    return allContracts
        .where(
          (c) => c.tenantId == tenantId && c.status == ContractStatus.active,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantsAsync = ref.watch(tenantsProvider);
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTenantForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: tenantsAsync.when(
        data: (tenants) {
          final filtered = _filterTenants(tenants);
          final contracts = contractsAsync.value ?? [];
          final activeTenantsCount = tenants
              .where(
                (t) => contracts.any(
                  (c) =>
                      c.tenantId == t.id && c.status == ContractStatus.active,
                ),
              )
              .length;

          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  // Header
                  ImmobilierHeader(
                    title: 'LOCATAIRES',
                    subtitle: 'Gestion des locataires',
                    actions: [
                      Semantics(
                        label: 'Actualiser',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            ref.invalidate(tenantsProvider);
                            ref.invalidate(contractsProvider);
                          },
                          tooltip: 'Actualiser',
                        ),
                      ),
                    ],
                  ),

                  // KPI Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.horizontalPadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              label: 'Total Locataires',
                              value: '${tenants.length}',
                              icon: Icons.people,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KpiCard(
                              label: 'Actifs',
                              value: '$activeTenantsCount',
                              icon: Icons.person_pin,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section header
                  SliverSectionHeader(
                    title: 'LISTE DES LOCATAIRES',
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
                    child: TenantFilters(
                      selectedArchiveFilter: ref.watch(archiveFilterProvider),
                      onArchiveFilterChanged: (filter) =>
                          ref.read(archiveFilterProvider.notifier).set(filter),
                      onClear: () =>
                          ref.read(archiveFilterProvider.notifier).set(
                              ArchiveFilter.active),
                    ),
                  ),

                  // Tenants List
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(theme, tenants.isEmpty),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final tenant = filtered[index];
                          final activeCount = _countActiveContracts(
                            tenant.id,
                            contracts,
                          );
                          return TenantCard(
                            tenant: tenant,
                            activeContractsCount: activeCount,
                            onTap: () => _showTenantDetails(tenant),
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
          message: 'Impossible de charger les locataires.',
          onRetry: () {
            ref.invalidate(tenantsProvider);
            ref.invalidate(contractsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isEmpty) {
    return EmptyState(
      icon: isEmpty ? Icons.people_outline : Icons.search_off,
      title: isEmpty ? 'Aucun locataire enregistré' : 'Aucun résultat trouvé',
      message: isEmpty
          ? 'Commencez par ajouter un locataire'
          : 'Essayez de modifier vos critères de recherche',
      action: isEmpty
          ? null
          : TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Text('Réinitialiser la recherche'),
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
