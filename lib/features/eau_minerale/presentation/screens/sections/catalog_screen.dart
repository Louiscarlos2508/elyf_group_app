import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/product_form_dialog.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: productsAsync.when(
        data: (products) => _CatalogContent(products: products),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Erreur: $error")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const ProductFormDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text("NOUVEAU PRODUIT"),
      ),
    );
  }
}

class _CatalogContent extends StatefulWidget {
  const _CatalogContent({required this.products});
  final List<Product> products;

  @override
  State<_CatalogContent> createState() => _CatalogContentState();
}

class _CatalogContentState extends State<_CatalogContent> {
  ProductType? _filterType;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredProducts = widget.products.where((p) {
      final matchesType = _filterType == null || p.type == _filterType;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  const Color(0xFF00C2FF),
                  const Color(0xFF0369A1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CATALOGUE",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Gestion des Produits",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Rechercher un produit...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ProductType?>(
                      value: _filterType,
                      hint: const Text("Tous les types"),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Tous")),
                        const DropdownMenuItem(value: ProductType.rawMaterial, child: Text("Matières Premières")),
                        const DropdownMenuItem(value: ProductType.finishedGood, child: Text("Produits Finis")),
                      ],
                      onChanged: (v) => setState(() => _filterType = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = filteredProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElyfCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => ProductFormDialog(product: product),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: product.type == ProductType.rawMaterial
                                ? Colors.amber.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            product.type == ProductType.rawMaterial
                                ? Icons.inventory_2_outlined
                                : Icons.shopping_bag_outlined,
                            color: product.type == ProductType.rawMaterial
                                ? Colors.amber.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                product.type == ProductType.rawMaterial
                                    ? "Matière Première"
                                    : "Produit Fini",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (product.type == ProductType.rawMaterial && product.supplyUnit != null && product.unitsPerLot > 1)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    "1 ${product.supplyUnit} = ${product.unitsPerLot} ${product.unit}",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${product.unitPrice} CFA",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              "/ ${product.unit}",
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
              childCount: filteredProducts.length,
            ),
          ),
        ),
      ],
    );
  }
}
