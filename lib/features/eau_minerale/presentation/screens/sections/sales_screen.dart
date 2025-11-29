import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/sales_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/permissions/eau_minerale_permissions.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/sale_detail_dialog.dart';
import '../../widgets/sale_form.dart';
import '../../widgets/sales_table.dart';
import '../../widgets/section_placeholder.dart';

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
    final state = ref.watch(salesStateProvider);
    return Scaffold(
      body: state.when(
        data: (data) => _SalesContent(
          state: data,
          onNewSale: () => _showForm(context),
          onActionTap: (sale, action) {
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
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.point_of_sale,
          title: 'Ventes indisponibles',
          subtitle: 'Impossible de récupérer les dernières ventes.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(salesStateProvider),
        ),
      ),
    );
  }
}

class _SalesContent extends StatelessWidget {
  const _SalesContent({
    required this.state,
    required this.onNewSale,
    required this.onActionTap,
  });

  final SalesState state;
  final VoidCallback onNewSale;
  final void Function(Sale sale, String action) onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Row(
                  children: [
                    Text(
                      'Ventes',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                            const Spacer(),
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
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Liste des Ventes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: SalesTable(
                          sales: state.sales,
                          onActionTap: onActionTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}
