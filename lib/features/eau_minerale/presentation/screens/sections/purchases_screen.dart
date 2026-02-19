import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/state_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/purchase.dart';
import '../../widgets/purchase_entry_dialog.dart';
import '../../widgets/reception_verification_dialog.dart';
import '../../widgets/supplier_settlement_dialog.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final purchasesAsync = ref.watch(purchasesProvider);

    return purchasesAsync.when(
      data: (purchases) => _PurchasesContent(purchases: purchases),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorDisplayWidget(
        error: error,
        title: 'Achats indisponibles',
        onRetry: () => ref.refresh(purchasesProvider),
      ),
    );
  }
}

class _PurchasesContent extends ConsumerWidget {
  const _PurchasesContent({required this.purchases});

  final List<Purchase> purchases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final poCount = purchases.where((p) => p.isPO).length;
    final confirmedCount = purchases.where((p) => !p.isPO).length;

    return CustomScrollView(
      slivers: [
        // Premium Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "APPROVISIONNEMENTS",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Achats & Bons de Commande",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.extended(
                  onPressed: () => _showPurchaseDialog(context),
                  label: const Text("NOUVEL ACHAT"),
                  icon: const Icon(Icons.add_shopping_cart),
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        // KPI Summary
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _KpiChip(
                    label: "Bons de Commande ($poCount)",
                    color: Colors.orange,
                    isActive: true,
                  ),
                  const SizedBox(width: 12),
                  _KpiChip(
                    label: "Achats Validés ($confirmedCount)",
                    color: Colors.green,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Purchases List
        purchases.isEmpty
            ? const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Aucun achat',
                  message: 'Vos approvisionnements s\'afficheront ici.',
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final purchase = purchases[index];
                      return _PurchaseCard(purchase: purchase);
                    },
                    childCount: purchases.length,
                  ),
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PurchaseEntryDialog(),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.color, required this.isActive});
  final String label;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard({required this.purchase});
  final Purchase purchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: purchase.isPO ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                purchase.isPO ? "PO" : "VALIDÉ",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              purchase.number ?? "Achat #${purchase.id.substring(0, 5)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${dateFormat.format(purchase.date)} - ${purchase.totalAmount} CFA"),
            if (purchase.isCredit)
              Text(
                "Reste à payer: ${purchase.debtAmount} CFA",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ...purchase.items.map((PurchaseItem item) {
                  final isInLots = item.metadata['isInLots'] as bool? ?? false;
                  final quantitySaisie = item.metadata['quantitySaisie'];
                  final displayQty = isInLots && quantitySaisie != null
                      ? "$quantitySaisie lots"
                      : "${item.quantity} ${item.unit}";

                  return ListTile(
                    dense: true,
                    title: Text(item.productName),
                    trailing: Text(
                        "$displayQty x ${item.unitPrice} = ${item.totalPrice} CFA"),
                  );
                }),
                const Divider(),
                if (purchase.isPO)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FilledButton.icon(
                      onPressed: () => _showReceptionDialog(context, ref, purchase),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text("VÉRIFIER RÉCEPTION"),
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  )
                else if (purchase.isCredit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FilledButton.icon(
                      onPressed: () => _showSettlementDialog(context, ref, purchase),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text("RÉGLER LA DETTE"),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReceptionDialog(
      BuildContext context, WidgetRef ref, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => ReceptionVerificationDialog(purchase: purchase),
    );
  }

  void _showSettlementDialog(
      BuildContext context, WidgetRef ref, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => SupplierSettlementDialog(purchase: purchase),
    );
  }
}
