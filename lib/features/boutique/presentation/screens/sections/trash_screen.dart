import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/permission_guard.dart';

/// Écran de la corbeille pour voir et restaurer les éléments supprimés.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BoutiquePermissionGuard(
      permission: BoutiquePermissions.viewTrash,
      fallback: Center(
        child: Text(
          'Vous n\'avez pas la permission de voir la corbeille.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Corbeille',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.inventory_2), text: 'Produits'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Dépenses'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_DeletedProductsTab(), _DeletedExpensesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglet pour les produits supprimés.
class _DeletedProductsTab extends ConsumerWidget {
  const _DeletedProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deletedProductsAsync = ref.watch(deletedProductsProvider);

    return deletedProductsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun produit supprimé',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _DeletedProductCard(product: product);
          },
        );
      },
      loading: () => AppShimmers.list(context, itemCount: 5),
      error: (error, stack) => Center(
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
              onPressed: () => ref.invalidate(deletedProductsProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglet pour les dépenses supprimées.
class _DeletedExpensesTab extends ConsumerWidget {
  const _DeletedExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deletedExpensesAsync = ref.watch(deletedExpensesProvider);

    return deletedExpensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune dépense supprimée',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _DeletedExpenseCard(expense: expense);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
              onPressed: () => ref.invalidate(deletedExpensesProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte pour un produit supprimé.
class _DeletedProductCard extends ConsumerWidget {
  const _DeletedProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deletedDate = product.deletedAt;
    final deletedBy = product.deletedBy ?? 'Inconnu';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.inventory_2_outlined,
          color: theme.colorScheme.error,
        ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CurrencyFormatter.formatFCFA(product.price),
              style: theme.textTheme.bodySmall,
            ),
            if (deletedDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Supprimé le ${_formatDate(deletedDate)} par $deletedBy',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: BoutiquePermissionGuard(
          permission: BoutiquePermissions.restoreProduct,
          child: IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restaurer',
            onPressed: () => _restoreProduct(context, ref),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreProduct(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer le produit ?'),
        content: Text('Voulez-vous restaurer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storeControllerProvider).restoreProduct(product.id);
        ref.invalidate(deletedProductsProvider);
        ref.invalidate(productsProvider);
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Produit restauré avec succès',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(
            context,
            'Erreur lors de la restauration: ${e.toString()}',
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Carte pour une dépense supprimée.
class _DeletedExpenseCard extends ConsumerWidget {
  const _DeletedExpenseCard({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deletedDate = expense.deletedAt;
    final deletedBy = expense.deletedBy ?? 'Inconnu';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.receipt_long_outlined,
          color: theme.colorScheme.error,
        ),
        title: Text(
          expense.label,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CurrencyFormatter.formatFCFA(expense.amountCfa),
              style: theme.textTheme.bodySmall,
            ),
            if (deletedDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Supprimé le ${_formatDate(deletedDate)} par $deletedBy',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: BoutiquePermissionGuard(
          permission: BoutiquePermissions.restoreExpense,
          child: IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restaurer',
            onPressed: () => _restoreExpense(context, ref),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreExpense(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer la dépense ?'),
        content: Text('Voulez-vous restaurer "${expense.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storeControllerProvider).restoreExpense(expense.id);
        ref.invalidate(deletedExpensesProvider);
        ref.invalidate(expensesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Dépense restaurée avec succès',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(
            context,
            'Erreur lors de la restauration: ${e.toString()}',
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Provider pour les produits supprimés.
final deletedProductsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(storeControllerProvider).getDeletedProducts(),
);

/// Provider pour les dépenses supprimées.
final deletedExpensesProvider = FutureProvider.autoDispose<List<Expense>>(
  (ref) => ref.watch(storeControllerProvider).getDeletedExpenses(),
);
