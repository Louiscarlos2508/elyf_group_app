import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gas_sale_form_dialog.dart';

/// Écran des ventes au détail.
class GazRetailScreen extends ConsumerWidget {
  const GazRetailScreen({super.key});

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) +
        ' F';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);
    final cylindersAsync = ref.watch(cylindersProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                Icon(
                  Icons.store,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Ventes au Détail',
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
                        builder: (context) => const GasSaleFormDialog(
                          saleType: SaleType.retail,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isMobile ? 'Vendre' : 'Nouvelle vente'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Quick sale cards
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: cylindersAsync.when(
              data: (cylinders) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vente rapide',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cylinders.map((c) {
                      return _QuickSaleCard(
                        label: '${c.type.label}\n${c.weight} kg',
                        price: _formatCurrency(c.sellPrice),
                        stock: c.stock,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => GasSaleFormDialog(
                              saleType: SaleType.retail,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Recent sales
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: Text(
              'Ventes récentes (détail)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        salesAsync.when(
          data: (sales) {
            final retailSales = sales
                .where((s) => s.saleType == SaleType.retail)
                .toList()
              ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

            if (retailSales.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune vente au détail',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les ventes au détail apparaîtront ici',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              sliver: SliverList.separated(
                itemCount: retailSales.length.clamp(0, 10),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _SaleCard(
                  sale: retailSales[index],
                  formatCurrency: _formatCurrency,
                ),
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

class _QuickSaleCard extends StatelessWidget {
  const _QuickSaleCard({
    required this.label,
    required this.price,
    required this.stock,
    required this.onTap,
  });

  final String label;
  final String price;
  final int stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = stock <= 5;

    return InkWell(
      onTap: stock > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: stock > 0
                ? [
                    Colors.orange.shade400,
                    Colors.deepOrange.shade400,
                  ]
                : [Colors.grey.shade400, Colors.grey.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (stock > 0 ? Colors.orange : Colors.grey)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$stock en stock',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isLowStock ? Colors.yellow : Colors.white,
                  fontWeight: isLowStock ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.formatCurrency,
  });

  final GasSale sale;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.green),
        ),
        title: Text(
          '${sale.quantity} bouteille${sale.quantity > 1 ? 's' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          sale.customerName ?? 'Client anonyme',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Text(
          formatCurrency(sale.totalAmount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
