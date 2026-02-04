import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../core/permissions/modules/eau_minerale_permissions.dart';
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

  void _handleAction(BuildContext context, Sale sale, String action) {
    if (action == 'view') {
      showDialog(
        context: context,
        builder: (context) => SaleDetailDialog(sale: sale),
      );
    } else if (action == 'edit') {
      final formKey = GlobalKey<SaleFormState>();
      showDialog(
        context: context,
        builder: (context) => FormDialog(
          title: 'Modifier la vente',
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: _SalesContent(
        onNewSale: () => _showForm(context),
        onActionTap: (sale, action) => _handleAction(context, sale, action),
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
        final isWide = constraints.maxWidth > 600;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, isWide ? 24 : 16),
                child: isWide
                    ? Row(
                        children: [
                          Text(
                            'Ventes',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          RefreshButton(
                            onRefresh: () => ref.invalidate(salesStateProvider),
                            tooltip: 'Actualiser les ventes',
                          ),
                          const SizedBox(width: 8),
                          EauMineralePermissionGuard(
                            permission: EauMineralePermissions.createSale,
                            child: IntrinsicWidth(
                              child: FilledButton.icon(
                                onPressed: onNewSale,
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvelle Vente'),
                              ),
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
                                  'Ventes',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              RefreshButton(
                                onRefresh: () =>
                                    ref.invalidate(salesStateProvider),
                                tooltip: 'Actualiser les ventes',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          EauMineralePermissionGuard(
                            permission: EauMineralePermissions.createSale,
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: onNewSale,
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvelle Vente'),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: salesStateAsync.when(
                  data: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.sales.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ventes récentes',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final count = ref.watch(
                                      salesStateProvider.select(
                                        (s) => s.value?.sales.length ?? 0,
                                      ),
                                    );
                                    return Text(
                                      '$count',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SalesTable(sales: state.sales, onActionTap: onActionTap),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.point_of_sale_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune vente enregistrée',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Créez votre première vente en cliquant sur le bouton ci-dessus',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  loading: () => const LoadingIndicator(),
                  error: (error, stackTrace) => ErrorDisplayWidget(
                    error: error,
                    onRetry: () => ref.refresh(salesStateProvider),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
