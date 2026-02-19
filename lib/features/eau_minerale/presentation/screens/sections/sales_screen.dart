import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/sale.dart';
import '../../widgets/centralized_permission_guard.dart';
// Already imported via widgets.dart
import '../../widgets/sale_detail_dialog.dart';
import '../../widgets/sale_form.dart';
import '../../widgets/sales_table.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<SaleFormState>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FormDialog(
        title: 'Nouvelle vente',
        child: SaleForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SalesContent(
      onNewSale: () => _showForm(context),
      onActionTap: (sale, action) => _handleAction(context, ref, sale, action),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, Sale sale, String action) {
    if (action == 'view') {
      showDialog(
        context: context,
        builder: (context) => SaleDetailDialog(sale: sale),
      );
    } else if (action == 'edit' || action == 'void') {
      _showVoidConfirmation(context, ref, sale);
    }
  }

  void _showVoidConfirmation(BuildContext context, WidgetRef ref, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Annuler la vente',
        message: 'Êtes-vous sûr de vouloir annuler cette vente ? Cette action est irréversible et restaurera le stock.',
        confirmLabel: 'Annuler la vente',
        confirmColor: Theme.of(context).colorScheme.error,
        onConfirm: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            final userId = ref.read(currentUserIdProvider);
            await ref.read(salesControllerProvider).voidSale(sale.id, userId);
            
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Vente annulée avec succès')),
            );
            
            // Rafraîchir les données
            ref.invalidate(salesStateProvider);
            ref.invalidate(stockStateProvider);
          } catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'annulation : $e')),
            );
          }
        },
      ),
    );
  }
}

class _SalesContent extends ConsumerWidget {
  const _SalesContent({
    required this.onNewSale,
    required this.onActionTap,
  });

  final VoidCallback onNewSale;
  final void Function(Sale sale, String action) onActionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesStateAsync = ref.watch(salesStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            // Premium Header for Sales
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
                      const Color(0xFF2563EB), // Premium Blue
                      const Color(0xFF1E40AF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GESTION DES VENTES",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Commandes & Revenus",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => ref.invalidate(salesStateProvider),
                          tooltip: 'Actualiser',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    EauMineralePermissionGuard(
                      permission: EauMineralePermissions.createSale,
                      child: FilledButton.icon(
                        onPressed: onNewSale,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 22),
                        label: const Text(
                          'Nouvelle Vente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: salesStateAsync.when(
                  data: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.sales.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ventes récentes',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  '${state.sales.length} ventes',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SalesTable(sales: state.sales, onActionTap: onActionTap),
                      ] else
                        ElyfCard(
                          isGlass: true,
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.point_of_sale_rounded,
                                size: 64,
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Aucune vente enregistrée',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enregistrez votre première vente pour voir l\'activité ici',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => ErrorDisplayWidget(
                    error: error,
                    onRetry: () => ref.refresh(salesStateProvider),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}
