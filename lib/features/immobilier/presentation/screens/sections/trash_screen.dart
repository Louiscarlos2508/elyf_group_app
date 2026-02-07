import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/permissions/entities/module_permission.dart'; // Added for ActionPermission
import 'package:elyf_groupe_app/core/permissions/modules/immobilier_permissions.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/property.dart';
import '../../../domain/entities/tenant.dart';
import '../../widgets/immobilier_header.dart';
import '../../widgets/permission_guard.dart'; // Corrected path

/// Écran de la corbeille pour voir et restaurer les éléments supprimés de l'immobilier.
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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Permission check handled by the guard inside the build or at route level?
    // Here we wrap the content.
    return ImmobilierPermissionGuard(
      permission: ImmobilierPermissions.viewTrash,
      fallback: Center(
        child: Text(
          'Vous n\'avez pas la permission de voir la corbeille.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const ImmobilierHeader(
              title: 'CORBEILLE',
              subtitle: 'Éléments supprimés',
              gradientColors: [Color(0xFF607D8B), Color(0xFF455A64)], // Slate/Grey generic trash theme
            ),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.home_work), text: 'Propriétés'),
                  Tab(icon: Icon(Icons.person), text: 'Locataires'),
                  Tab(icon: Icon(Icons.description), text: 'Contrats'),
                  Tab(icon: Icon(Icons.payments), text: 'Paiements'),
                  Tab(icon: Icon(Icons.receipt_long), text: 'Dépenses'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _DeletedPropertiesTab(),
                  _DeletedTenantsTab(),
                  _DeletedContractsTab(),
                  _DeletedPaymentsTab(),
                  _DeletedExpensesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TABS ---

class _DeletedPropertiesTab extends ConsumerWidget {
  const _DeletedPropertiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(deletedPropertiesProvider);
    return _DeletedList<Property>(
      asyncData: asyncData,
      emptyMessage: 'Aucune propriété supprimée',
      emptyIcon: Icons.home_work_outlined,
      itemBuilder: (context, property) => _DeletedPropertyCard(property: property),
      onRetry: () => ref.invalidate(deletedPropertiesProvider),
    );
  }
}

class _DeletedTenantsTab extends ConsumerWidget {
  const _DeletedTenantsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(deletedTenantsProvider);
    return _DeletedList<Tenant>(
      asyncData: asyncData,
      emptyMessage: 'Aucun locataire supprimé',
      emptyIcon: Icons.person_off_outlined,
      itemBuilder: (context, tenant) => _DeletedTenantCard(tenant: tenant),
      onRetry: () => ref.invalidate(deletedTenantsProvider),
    );
  }
}

class _DeletedContractsTab extends ConsumerWidget {
  const _DeletedContractsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(deletedContractsProvider);
    return _DeletedList<Contract>(
      asyncData: asyncData,
      emptyMessage: 'Aucun contrat supprimé',
      emptyIcon: Icons.description_outlined,
      itemBuilder: (context, contract) => _DeletedContractCard(contract: contract),
      onRetry: () => ref.invalidate(deletedContractsProvider),
    );
  }
}

class _DeletedPaymentsTab extends ConsumerWidget {
  const _DeletedPaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(deletedPaymentsProvider);
    return _DeletedList<Payment>(
      asyncData: asyncData,
      emptyMessage: 'Aucun paiement supprimé',
      emptyIcon: Icons.payments_outlined,
      itemBuilder: (context, payment) => _DeletedPaymentCard(payment: payment),
      onRetry: () => ref.invalidate(deletedPaymentsProvider),
    );
  }
}

class _DeletedExpensesTab extends ConsumerWidget {
  const _DeletedExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(deletedExpensesProvider);
    return _DeletedList<PropertyExpense>(
      asyncData: asyncData,
      emptyMessage: 'Aucune dépense supprimée',
      emptyIcon: Icons.receipt_long_outlined,
      itemBuilder: (context, expense) => _DeletedExpenseCard(expense: expense),
      onRetry: () => ref.invalidate(deletedExpensesProvider),
    );
  }
}

// --- REUSABLE LIST WIDGET ---

class _DeletedList<T> extends StatelessWidget {
  const _DeletedList({
    required this.asyncData,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.itemBuilder,
    required this.onRetry,
  });

  final AsyncValue<List<T>> asyncData;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return asyncData.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  emptyIcon,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
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
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(context, items[index]),
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
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CARDS ---

class _DeletedPropertyCard extends ConsumerWidget {
  const _DeletedPropertyCard({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BaseDeletedCard(
      title: property.address,
      subtitle: '${property.propertyType.name.toUpperCase()} • ${property.city}',
      deletedAt: property.deletedAt,
      deletedBy: property.deletedBy,
      icon: Icons.home_work,
      permission: ImmobilierPermissions.restoreProperty,
      onRestore: () async {
        await ref.read(propertyControllerProvider).restoreProperty(property.id);
        ref.invalidate(deletedPropertiesProvider);
        ref.invalidate(propertiesProvider);
      },
    );
  }
}

class _DeletedTenantCard extends ConsumerWidget {
  const _DeletedTenantCard({required this.tenant});
  final Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BaseDeletedCard(
      title: tenant.fullName,
      subtitle: tenant.phone,
      deletedAt: tenant.deletedAt,
      deletedBy: tenant.deletedBy,
      icon: Icons.person,
      permission: ImmobilierPermissions.restoreTenant,
      onRestore: () async {
        await ref.read(tenantControllerProvider).restoreTenant(tenant.id);
        ref.invalidate(deletedTenantsProvider);
        ref.invalidate(tenantsProvider);
      },
    );
  }
}

class _DeletedContractCard extends ConsumerWidget {
  const _DeletedContractCard({required this.contract});
  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = contract.property?.address ?? 'Propriété inconnue';
    final tenant = contract.tenant?.fullName ?? 'Locataire inconnu';
    
    return _BaseDeletedCard(
      title: 'Contrat: $property',
      subtitle: 'Locataire: $tenant\nLoyer: ${CurrencyFormatter.formatFCFA(contract.monthlyRent)}',
      deletedAt: contract.deletedAt,
      deletedBy: contract.deletedBy,
      icon: Icons.description,
      permission: ImmobilierPermissions.restoreContract,
      onRestore: () async {
        await ref.read(contractControllerProvider).restoreContract(contract.id);
        ref.invalidate(deletedContractsProvider);
        ref.invalidate(contractsProvider);
      },
    );
  }
}

class _DeletedPaymentCard extends ConsumerWidget {
  const _DeletedPaymentCard({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractInfo = payment.contract?.property?.address ?? payment.contractId;
    return _BaseDeletedCard(
      title: 'Paiement: ${payment.receiptNumber}',
      subtitle: 'Contrat: $contractInfo\nMontant: ${CurrencyFormatter.formatFCFA(payment.amount)}',
      deletedAt: payment.deletedAt,
      deletedBy: payment.deletedBy,
      icon: Icons.payments,
      permission: ImmobilierPermissions.restorePayment,
      onRestore: () async {
        await ref.read(paymentControllerProvider).restorePayment(payment.id);
        ref.invalidate(deletedPaymentsProvider);
        ref.invalidate(paymentsProvider);
      },
    );
  }
}

class _DeletedExpenseCard extends ConsumerWidget {
  const _DeletedExpenseCard({required this.expense});
  final PropertyExpense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final propertyName = expense.property ?? 'Propriété inconnue';
    return _BaseDeletedCard(
      title: '${expense.category.name.toUpperCase()}: ${expense.description}',
      subtitle: '$propertyName\nMontant: ${CurrencyFormatter.formatFCFA(expense.amount)}',
      deletedAt: expense.deletedAt,
      deletedBy: expense.deletedBy,
      icon: Icons.receipt_long,
      permission: ImmobilierPermissions.restoreExpense,
      onRestore: () async {
        await ref.read(expenseControllerProvider).restoreExpense(expense.id);
        ref.invalidate(deletedExpensesProvider);
        ref.invalidate(expensesProvider);
      },
    );
  }
}


// --- BASE CARD ---

class _BaseDeletedCard extends ConsumerWidget {
  const _BaseDeletedCard({
    required this.title,
    required this.subtitle,
    required this.deletedAt,
    required this.deletedBy,
    required this.icon,
    required this.permission,
    required this.onRestore,
  });

  final String title;
  final String subtitle;
  final DateTime? deletedAt;
  final String? deletedBy;
  final IconData icon;
  final ActionPermission permission;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final by = deletedBy ?? 'Inconnu';
    final date = deletedAt != null ? _formatDate(deletedAt!) : 'Date inconnue';

    return ElyfCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      elevation: 1,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supprimé par $by • $date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ImmobilierPermissionGuard(
            permission: permission,
            child: Material(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                icon: const Icon(Icons.restore_rounded, size: 22),
                color: theme.colorScheme.primary,
                tooltip: 'Restaurer',
                onPressed: () => _handleRestore(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer l\'élément ?'),
        content: Text('Voulez-vous restaurer "$title" ?'),
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
        await onRestore();
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Élément restauré avec succès',
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
