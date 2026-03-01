
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/purchase.dart';
import '../../widgets/purchases_table.dart';
import '../../widgets/purchase_entry_dialog.dart';
import '../../widgets/boutique_header.dart';
import '../../widgets/permission_guard.dart';
import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:open_file/open_file.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final purchasesAsync = ref.watch(purchasesProvider);

    return Scaffold(
      body: purchasesAsync.when(
        data: (purchases) {
          return CustomScrollView(
            slivers: [
              BoutiqueHeader(
                title: "APPROVISIONNEMENT",
                subtitle: "Historique des Achats",
                gradientColors: [
                  const Color(0xFF0F766E), // Teal 700
                  const Color(0xFF134E4A), // Teal 900
                ],
                shadowColor: const Color(0xFF0F766E),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => ref.invalidate(purchasesProvider),
                    tooltip: 'Actualiser',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _exportData(context, ref, purchases),
                    tooltip: 'Exporter CSV',
                  ),
                  const SizedBox(width: 8),
                  BoutiquePermissionGuard(
                    permission: BoutiquePermissions.createPurchase,
                    child: FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const PurchaseEntryDialog(),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvel Achat'),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: AppSpacing.sectionPadding,
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: PurchasesTable(
                      purchases: purchases,
                      formatCurrency: CurrencyFormatter.formatFCFA,
                      onActionTap: (purchase, action) {
                        if (action == 'view') {
                          _showPurchaseDetail(context, purchase);
                        } else if (action == 'delete') {
                          _confirmDelete(context, ref, purchase);
                        }
                      },
                    ),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => AppShimmers.table(context),
        error: (error, stackTrace) => ErrorDisplayWidget(
          error: error,
          onRetry: () => ref.refresh(purchasesProvider),
        ),
      ),
    );
  }

  void _showPurchaseDetail(BuildContext context, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'Achat'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Fournisseur', purchase.supplierId ?? '-'),
              _buildDetailRow('Date', '${purchase.date.day}/${purchase.date.month}/${purchase.date.year}'),
              const Divider(height: 24),
              const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...purchase.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.productName}')),
                    Text(CurrencyFormatter.formatFCFA(item.totalPrice)),
                  ],
                ),
              )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    CurrencyFormatter.formatFCFA(purchase.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDetailRow('Notes', purchase.notes!),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'achat ?'),
        content: const Text('Voulez-vous vraiment supprimer cet enregistrement d\'approvisionnement ? Cela n\'annulera pas l\'entrée en stock déjà effectuée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(storeControllerProvider).deletePurchase(purchase.id);
              ref.invalidate(purchasesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                NotificationService.showSuccess(context, 'Achat supprimé de l\'historique');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, List<Purchase> purchases) async {
    if (purchases.isEmpty) {
      NotificationService.showInfo(context, 'Aucune donnée à exporter');
      return;
    }

    try {
      NotificationService.showInfo(context, 'Génération du fichier CSV...');
      final file = await ref.read(boutiqueExportServiceProvider).exportPurchases(purchases);
      await OpenFile.open(file.path);
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'export: $e');
      }
    }
  }
}
