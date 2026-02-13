import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/stock_adjustment_dialog.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return CustomScrollView(
      slivers: [
        const BoutiqueHeader(
          title: "INVENTAIRE",
          subtitle: "Gestion & Mouvements de Stock",
          gradientColors: [
            Color(0xFF0284C7), // Sky 600
            Color(0xFF0369A1), // Sky 700
          ],
          shadowColor: Color(0xFF0284C7),
        ),

        // Statistics Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: productsAsync.when(
              data: (products) {
                final totalValue = products.fold<double>(0, (sum, p) => sum + (p.stock * (p.purchasePrice ?? 0)));
                final lowStockCount = products.where((p) => p.stock <= p.lowStockThreshold).length;
                final outOfStockCount = products.where((p) => p.stock <= 0).length;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: "Valeur Totale",
                        value: "${NumberFormat('#,###').format(totalValue)} CFA",
                        icon: Icons.account_balance,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: "Stock Faible",
                        value: "$lowStockCount articles",
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: "Rupture",
                        value: "$outOfStockCount articles",
                        icon: Icons.error_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur: $e'),
            ),
          ),
        ),

        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Text(
              "État du Stock Actuel",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Stock List
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: productsAsync.when(
            data: (products) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  final isLow = product.stock <= product.lowStockThreshold;
                  final isOut = product.stock <= 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: (isOut ? Colors.red : (isLow ? Colors.orange : Colors.green)).withOpacity(0.1),
                        child: Icon(
                          isOut ? Icons.block : (isLow ? Icons.warning : Icons.check_circle),
                          color: isOut ? Colors.red : (isLow ? Colors.orange : Colors.green),
                        ),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Seuil d'alerte: ${product.lowStockThreshold}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${product.stock}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isOut ? Colors.red : (isLow ? Colors.orange : Colors.black),
                                ),
                              ),
                              const Text("unités", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              if (value == 'toggle_status') {
                                await ref.read(storeControllerProvider).toggleProductStatus(product.id);
                                if (context.mounted) {
                                  NotificationService.showSuccess(
                                    context, 
                                    'Produit ${product.isActive ? "archivé" : "réactivé"}'
                                  );
                                }
                              } else if (value == 'adjust') {
                                showDialog(
                                  context: context,
                                  builder: (context) => StockAdjustmentDialog(product: product),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'adjust',
                                child: ListTile(
                                  leading: Icon(Icons.tune),
                                  title: Text('Ajuster le stock'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_status',
                                child: ListTile(
                                  leading: Icon(product.isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
                                  title: Text(product.isActive ? 'Archiver' : 'Réactiver'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => StockAdjustmentDialog(product: product),
                        );
                      },
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
