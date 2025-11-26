import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/tenant.dart';
import '../../widgets/property_search_bar.dart';
import '../../widgets/tenant_card.dart';
import '../../widgets/tenant_form_dialog.dart';

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
      builder: (context) => AlertDialog(
        title: Text(tenant.fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Téléphone', value: tenant.phone),
              _DetailRow(label: 'Email', value: tenant.email),
              if (tenant.address != null)
                _DetailRow(label: 'Adresse', value: tenant.address!),
              if (tenant.idNumber != null)
                _DetailRow(label: 'Pièce d\'identité', value: tenant.idNumber!),
              if (tenant.emergencyContact != null)
                _DetailRow(
                  label: 'Contact d\'urgence',
                  value: tenant.emergencyContact!,
                ),
              if (tenant.notes != null && tenant.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tenant.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showTenantForm(tenant: tenant);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locataires'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: () => _showTenantForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Locataire'),
                ),
              ),
            ),
          ),
          PropertySearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
          Expanded(
            child: tenantsAsync.when(
              data: (tenants) {
                final filtered = _filterTenants(tenants);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tenants.isEmpty ? Icons.people_outline : Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tenants.isEmpty
                              ? 'Aucun locataire enregistré'
                              : 'Aucun résultat trouvé',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (tenants.isNotEmpty) ...[
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
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tenantsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tenant = filtered[index];
                      return TenantCard(
                        tenant: tenant,
                        onTap: () => _showTenantDetails(tenant),
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
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: $error',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ref.invalidate(tenantsProvider);
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
