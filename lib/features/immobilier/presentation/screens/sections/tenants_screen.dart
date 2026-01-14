import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
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
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';

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
          tenant.email.toLowerCase().contains(query) ||
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
      ),
    );
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
              final isWide = constraints.maxWidth > 600;

              return CustomScrollView(
                slivers: [
                  // Header
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
                                  'Locataires',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                RefreshButton(
                                  onRefresh: () {
                                    ref.invalidate(tenantsProvider);
                                    ref.invalidate(contractsProvider);
                                  },
                                  tooltip: 'Actualiser',
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () => _showTenantForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouveau Locataire'),
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
                                        'Locataires',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    RefreshButton(
                                      onRefresh: () {
                                        ref.invalidate(tenantsProvider);
                                        ref.invalidate(contractsProvider);
                                      },
                                      tooltip: 'Actualiser',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _showTenantForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouveau Locataire'),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        'LISTE DES LOCATAIRES',
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

                  // Tenants List
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(theme, tenants.isEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
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
            isEmpty ? Icons.people_outline : Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'Aucun locataire enregistré' : 'Aucun résultat trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Text('Réinitialiser la recherche'),
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
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(tenantsProvider),
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
