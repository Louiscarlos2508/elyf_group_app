import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/state_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/supplier.dart';
import '../../widgets/supplier_form_dialog.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final suppliersAsync = ref.watch(suppliersProvider);

    return suppliersAsync.when(
      data: (suppliers) => _SuppliersContent(suppliers: suppliers),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorDisplayWidget(
        error: error,
        title: 'Fournisseurs indisponibles',
        onRetry: () => ref.refresh(suppliersProvider),
      ),
    );
  }
}

class _SuppliersContent extends ConsumerWidget {
  const _SuppliersContent({required this.suppliers});

  final List<Supplier> suppliers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // Premium Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  const Color(0xFF00C2FF),
                  const Color(0xFF0369A1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FOURNISSEURS",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Gestion des Partenaires",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.extended(
                  onPressed: () => _showAddSupplierDialog(context),
                  label: const Text("NOUVEAU"),
                  icon: const Icon(Icons.add),
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SearchBar(
              hintText: "Rechercher un fournisseur...",
              leading: const Icon(Icons.search),
              onChanged: (value) {
                // Implement search logic if needed
              },
            ),
          ),
        ),

        // Suppliers List
        suppliers.isEmpty
            ? const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'Aucun fournisseur',
                  message: 'Commencez par ajouter votre premier fournisseur.',
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final supplier = suppliers[index];
                      return _SupplierCard(supplier: supplier);
                    },
                    childCount: suppliers.length,
                  ),
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SupplierFormDialog(),
    );
  }
}

class _SupplierCard extends ConsumerWidget {
  const _SupplierCard({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            supplier.name.substring(0, 1).toUpperCase(),
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(
          supplier.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.phone != null)
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(supplier.phone!),
                ],
              ),
            Text(
              "Dette: ${supplier.balance} CFA",
              style: TextStyle(
                color: supplier.balance > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (context) => SupplierFormDialog(supplier: supplier),
              );
            } else if (value == 'delete') {
              // Confirm delete
            }
          },
        ),
      ),
    );
  }
}
