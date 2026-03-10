import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../application/providers.dart';

/// Widget pour afficher les alertes de stock faible.
class StockAlertsWidget extends ConsumerWidget {
  const StockAlertsWidget({super.key});

  String _formatQuantity(int quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stockState = ref.watch(stockStateProvider);

    return stockState.when(
      data: (state) {
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
