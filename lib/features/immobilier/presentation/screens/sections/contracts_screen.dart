import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../widgets/contract_card.dart';
import '../../widgets/contract_filters.dart';
import '../../widgets/contract_form_dialog.dart';
import '../../widgets/property_search_bar.dart';

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

    // Filtrage par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c.id.toLowerCase().contains(query) ||
            (c.property != null && c.property!.address.toLowerCase().contains(query)) ||
            (c.tenant != null && c.tenant!.fullName.toLowerCase().contains(query));
      }).toList();
    }

    // Filtrage par statut
    if (_selectedStatus != null) {
      filtered = filtered.where((c) => c.status == _selectedStatus).toList();
    }

    // Tri par date de début (plus récents en premier)
    filtered.sort((a, b) => b.startDate.compareTo(a.startDate));

    return filtered;
  }

  void _showContractForm() {
    showDialog(
      context: context,
      builder: (context) => const ContractFormDialog(),
    );
  }

  void _showContractDetails(Contract contract) {
    // TODO: Ouvrir le dialog de détails
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrats'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: _showContractForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Contrat'),
                ),
              ),
            ),
          ),
          PropertySearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
          ContractFilters(
            selectedStatus: _selectedStatus,
            onStatusChanged: (status) => setState(() => _selectedStatus = status),
            onClear: () => setState(() => _selectedStatus = null),
          ),
          Expanded(
            child: contractsAsync.when(
              data: (contracts) {
                final filtered = _filterAndSort(contracts);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          contracts.isEmpty ? Icons.description_outlined : Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          contracts.isEmpty
                              ? 'Aucun contrat enregistré'
                              : 'Aucun résultat trouvé',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (contracts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _selectedStatus = null;
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
                    ref.invalidate(contractsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contract = filtered[index];
                      return ContractCard(
                        contract: contract,
                        onTap: () => _showContractDetails(contract),
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
                        ref.invalidate(contractsProvider);
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
