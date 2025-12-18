import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../widgets/cylinder_card.dart';
import '../../widgets/cylinder_form_dialog.dart';
import '../../widgets/stock_adjustment_dialog.dart';

/// Écran de gestion du stock de bouteilles.
class GazStockScreen extends ConsumerWidget {
  const GazStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylinders = ref.watch(cylindersProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Gestion du Stock',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 20 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => const CylinderFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isMobile ? 'Ajouter' : 'Nouvelle bouteille'),
                  ),
                ),
              ],
            ),
          ),
        ),
        cylinders.when(
          data: (list) {
            if (list.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune bouteille enregistrée',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cylinder = list[index];
                  return CylinderCard(
                    cylinder: cylinder,
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => CylinderFormDialog(
                          cylinder: cylinder,
                        ),
                      );
                    },
                    onAdjustStock: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => StockAdjustmentDialog(
                          cylinder: cylinder,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
