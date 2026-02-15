import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/entities/supplier_settlement.dart';
import 'widgets/add_edit_supplier_dialog.dart';
import 'widgets/supplier_settlement_dialog.dart';

import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, in_debt, settled

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return CustomScrollView(
      slivers: [
        BoutiqueHeader(
          title: "FOURNISSEURS",
          subtitle: "Gestion des Partenaires & Dettes",
          gradientColors: const [
            Color(0xFF6366F1), // Indigo 500
            Color(0xFF4F46E5), // Indigo 600
          ],
          shadowColor: const Color(0xFF6366F1),
          additionalActions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddEditSupplierDialog(context),
            ),
          ],
        ),

        // Statistics Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: suppliersAsync.when(
              data: (suppliers) {
                final totalDebt =
                    suppliers.fold<double>(0, (sum, s) => sum + s.balance);
                final activeSuppliers = suppliers.length;
                final debtPercentage = suppliers.isEmpty
                    ? 0
                    : (suppliers.where((s) => s.balance > 0).length /
                            suppliers.length *
                            100)
                        .round();

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: "Dette Totale",
                        value: "${NumberFormat('#,###').format(totalDebt)} CFA",
                        icon: Icons.account_balance_wallet,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: "Partenaires",
                        value: "$activeSuppliers actifs",
                        icon: Icons.group,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: "Taux d'impayés",
                        value: "$debtPercentage%",
                        icon: Icons.pie_chart,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur: $e'),
            ),
          ),
        ),

        // Search and Filter UI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Rechercher un fournisseur...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _filterStatus == 'all',
                        onSelected: (v) => setState(() => _filterStatus = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Avec Dette'),
                        selected: _filterStatus == 'in_debt',
                        onSelected: (v) => setState(() => _filterStatus = 'in_debt'),
                        selectedColor: Colors.red.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Réglés'),
                        selected: _filterStatus == 'settled',
                        onSelected: (v) => setState(() => _filterStatus = 'settled'),
                        selectedColor: Colors.green.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Suppliers List
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: suppliersAsync.when(
            data: (suppliers) {
              // Apply filtering and searching
              final filtered = suppliers.where((s) {
                final matchSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                   (s.phone?.contains(_searchQuery) ?? false);
                
                final matchFilter = _filterStatus == 'all' || 
                                    (_filterStatus == 'in_debt' && s.balance > 0) ||
                                    (_filterStatus == 'settled' && s.balance <= 0);
                
                return matchSearch && matchFilter;
              }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                    child: Center(child: Text('Aucun fournisseur correspondant')));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final supplier = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(supplier.name[0].toUpperCase()),
                        ),
                        title: Text(supplier.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.phone != null &&
                                supplier.phone!.isNotEmpty)
                              Text(supplier.phone!,
                                  style: const TextStyle(fontSize: 12)),
                            if (supplier.category != null &&
                                supplier.category!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(supplier.category!,
                                      style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${NumberFormat('#,###').format(supplier.balance)} CFA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: supplier.balance > 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                Text(
                                  supplier.balance > 0 ? 'Dette en cours' : 'À jour',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (supplier.balance > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.payment,
                                      color: Colors.blue),
                                  tooltip: 'Régler la dette',
                                  onPressed: () =>
                                      _showSettlementDialog(context, supplier),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.history, color: Colors.blueGrey),
                              tooltip: 'Historique des règlements',
                              onPressed: () => _showSettlementHistory(context, supplier),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteSupplier(context, supplier),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditSupplierDialog(context,
                            supplier: supplier),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(
                child: Center(child: Text('Erreur: $e'))),
          ),
        ),
      ],
    );
  }

  void _showAddEditSupplierDialog(BuildContext context, {Supplier? supplier}) {
    showDialog(
      context: context,
      builder: (context) => AddEditSupplierDialog(supplier: supplier),
    );
  }

  void _showSettlementDialog(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => SupplierSettlementDialog(supplier: supplier),
    );
  }

  void _showSettlementHistory(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => _SupplierHistoryDialog(supplier: supplier),
    );
  }

  Future<void> _deleteSupplier(BuildContext context, Supplier supplier) async {
    if (supplier.balance != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer un fournisseur avec une dette en cours.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le fournisseur ${supplier.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(storeControllerProvider).deleteSupplier(supplier.id);
      if (mounted) NotificationService.showSuccess(context, 'Fournisseur supprimé');
    }
  }
}

class _SupplierHistoryDialog extends ConsumerWidget {
  final Supplier supplier;

  const _SupplierHistoryDialog({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsStream = ref.watch(storeControllerProvider).watchSettlements(supplierId: supplier.id);

    return AlertDialog(
      title: Text('Historique : ${supplier.name}'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: StreamBuilder<List<SupplierSettlement>>(
          stream: settlementsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Aucun règlement trouvé'));
            }

            final settlements = snapshot.data!;
            return ListView.builder(
              itemCount: settlements.length,
              itemBuilder: (context, index) {
                final s = settlements[index];
                return ListTile(
                  title: Text('${NumberFormat('#,###').format(s.amount)} CFA'),
                  subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(s.date)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmer l\'annulation'),
                          content: const Text('Voulez-vous vraiment annuler ce règlement ? La dette sera restaurée et la caisse débitée.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, Annuler')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(storeControllerProvider).deleteSupplierSettlement(s.id);
                        if (context.mounted) {
                          NotificationService.showSuccess(context, 'Règlement annulé avec succès');
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
