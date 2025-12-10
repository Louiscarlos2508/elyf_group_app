import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../../../core/pdf/eau_minerale_stock_report_pdf_service.dart';
import '../../../application/controllers/stock_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../widgets/finished_products_card.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/raw_materials_card.dart';
import '../../widgets/section_placeholder.dart';
import '../../widgets/stock_movement_table.dart';
import '../../widgets/stock_operation_form.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  void _showStockOperation(BuildContext context) {
    final formKey = GlobalKey<StockOperationFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Opération Stock',
        child: StockOperationForm(key: formKey),
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
    final state = ref.watch(stockStateProvider);
    return state.when(
      data: (data) => _StockContent(
        state: data,
        onStockOperation: () => _showStockOperation(context),
      ),
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

class _StockContent extends ConsumerWidget {
  const _StockContent({
    required this.state,
    required this.onStockOperation,
  });

  final StockState state;
  final VoidCallback onStockOperation;

  Future<void> _downloadStockReport(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfService = EauMineraleStockReportPdfService();
      final file = await pdfService.generateReport(
        stockItems: state.items,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF généré: ${file.path}'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<StockMovement> _getMockMovements() {
    return List.generate(5, (index) => StockMovement.sample(index));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final movements = _getMockMovements();
    
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
                      'Gestion des Stocks',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadStockReport(context),
                      tooltip: 'Télécharger rapport PDF',
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: FilledButton.icon(
                        onPressed: onStockOperation,
                        icon: const Icon(Icons.add),
                        label: const Text('Opération Stock'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RawMaterialsCard(items: state.items),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FinishedProductsCard(items: state.items),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          RawMaterialsCard(items: state.items),
                          const SizedBox(height: 16),
                          FinishedProductsCard(items: state.items),
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des Mouvements',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Traçabilité complète de tous les mouvements de stock',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StockMovementTable(movements: movements),
                  ],
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
