import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../../../core/pdf/boutique_stock_report_pdf_service.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/purchase_form_dialog.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  Future<void> _downloadStockReport(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch products directly from controller
      final controller = ref.read(storeControllerProvider);
      final products = await controller.fetchProducts();

      final pdfService = BoutiqueStockReportPdfService();
      final file = await pdfService.generateReport(products: products);

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

  void _showProductInfo(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock actuel: ${product.stock}'),
              const SizedBox(height: 8),
              Text('Prix de vente: ${_formatCurrency(product.price)}'),
              if (product.purchasePrice != null) ...[
                const SizedBox(height: 8),
                Text('Prix d\'achat: ${_formatCurrency(product.purchasePrice!)}'),
                if (product.profitMargin != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Marge: ${_formatCurrency(product.profitMargin!)} (${product.profitMarginPercentage!.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Note: Le stock ne peut être modifié que via les achats (qui augmentent le stock) et les ventes (qui diminuent le stock).',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (_) => const PurchaseFormDialog(),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Enregistrer un achat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final productsAsync = ref.watch(productsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion du Stock',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadStockReport(context),
                  tooltip: 'Télécharger rapport PDF',
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const PurchaseFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Nouvel Achat'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: lowStockAsync.when(
              data: (lowStockProducts) {
                if (lowStockProducts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${lowStockProducts.length} produit(s) en stock faible',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Aucun produit',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    final isLowStock = product.stock <= 10;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.inventory_2,
                            color: isLowStock ? Colors.orange : Colors.green,
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          product.category ?? 'Sans catégorie',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Stock: ${product.stock}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isLowStock ? Colors.orange : null,
                              ),
                            ),
                            Text(
                              'Vente: ${_formatCurrency(product.price)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (product.purchasePrice != null) ...[
                              Text(
                                'Achat: ${_formatCurrency(product.purchasePrice!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (product.profitMargin != null)
                                Text(
                                  'Marge: ${_formatCurrency(product.profitMargin!)} (${product.profitMarginPercentage!.toStringAsFixed(1)}%)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ],
                        ),
                        onTap: () => _showProductInfo(context, product),
                      ),
                    );
                  },
                  childCount: products.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Erreur de chargement',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

