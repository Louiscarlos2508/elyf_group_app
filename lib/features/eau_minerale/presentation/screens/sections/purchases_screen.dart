import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
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
        ElyfModuleHeader(
          title: "Achats",
          subtitle: "Gestion des approvisionnements et commandes",
          module: EnterpriseModule.eau,
          actions: [
            FloatingActionButton.extended(
              onPressed: () => _showPurchaseDialog(context),
              label: const Text("NOUVEL ACHAT"),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
            ),
          ],
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
                  final isLotBased = item.metadata['isLotBased'] as bool? ?? false;
                  final unitsPerLot = item.metadata['unitsPerLot'] as int? ?? 1;
                  final baseUnit = item.metadata['baseUnit'] as String? ?? "unité";

                  return ListTile(
                    dense: true,
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: isLotBased 
                      ? Text(
                          "P.U. calculé: ${(item.unitPrice / unitsPerLot).toStringAsFixed(1)} CFA / $baseUnit",
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary),
                        ) 
                      : null,
                    trailing: Text(
                      "${item.quantity} ${item.unit} x ${item.unitPrice} = ${item.totalPrice} CFA",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
