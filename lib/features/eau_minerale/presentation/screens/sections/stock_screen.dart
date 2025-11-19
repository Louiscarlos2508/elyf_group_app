import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/stock_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/enhanced_list_card.dart';
import '../../widgets/section_placeholder.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockStateProvider);
    return state.when(
      data: (data) => _StockContent(state: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => SectionPlaceholder(
        icon: Icons.inventory_2_outlined,
        title: 'Stocks indisponibles',
        subtitle: 'Impossible de récupérer les inventaires.',
        primaryActionLabel: 'Réessayer',
        onPrimaryAction: () => ref.invalidate(stockStateProvider),
      ),
    );
  }
}

class _StockContent extends StatelessWidget {
  const _StockContent({required this.state});

  final StockState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        final isFinishedGoods = item.type == StockType.finishedGoods;
        return EnhancedListCard(
          title: item.name,
          subtitle: 'Dernière MAJ: ${item.updatedAt}',
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFinishedGoods
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFinishedGoods ? Icons.inventory_2 : Icons.science,
              color: isFinishedGoods ? Colors.blue : Colors.amber,
              size: 24,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} ${item.unit}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(
                  isFinishedGoods ? 'Produit fini' : 'Matière première',
                  style: theme.textTheme.labelSmall,
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }
}
