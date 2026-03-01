import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import '../../widgets/sales_table.dart';
import '../../widgets/boutique_header.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/sale_detail_dialog.dart';
import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:open_file/open_file.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      body: salesAsync.when(
        data: (sales) {
          return CustomScrollView(
            slivers: [
              BoutiqueHeader(
                title: "JOURNAL DES VENTES",
                subtitle: "Historique des Transactions",
                gradientColors: [
                  const Color(0xFF0D9488), // Teal 600
                  const Color(0xFF0F766E), // Teal 700
                ],
                shadowColor: const Color(0xFF0D9488),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => ref.invalidate(recentSalesProvider),
                    tooltip: 'Actualiser',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _exportData(context, ref, sales),
                    tooltip: 'Exporter CSV',
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
                    child: SalesTable(
                      sales: sales,
                      formatCurrency: CurrencyFormatter.formatFCFA,
                      onActionTap: (sale, action) {
                        if (action == 'view') {
                          _showSaleDetail(context, sale);
                        } else if (action == 'delete') {
                          _confirmDelete(context, ref, sale);
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
          onRetry: () => ref.refresh(recentSalesProvider),
        ),
      ),
    );
  }

  void _showSaleDetail(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => SaleDetailDialog(sale: sale),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la vente ?'),
        content: const Text('Voulez-vous vraiment annuler cette vente ? Le stock sera automatiquement restauré et un mouvement d\'annulation sera enregistré en trésorerie.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
          BoutiquePermissionGuard(
            permission: BoutiquePermissions.deleteSale,
            child: FilledButton(
              onPressed: () async {
                await ref.read(storeControllerProvider).deleteSale(sale.id);
                ref.invalidate(recentSalesProvider);
                ref.invalidate(productsProvider); // Refresh stock
                ref.invalidate(treasuryBalancesProvider); // Refresh treasury
                if (context.mounted) {
                  Navigator.of(context).pop();
                  NotificationService.showSuccess(context, 'Vente annulée avec succès');
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirmer l\'Annulation'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, List<Sale> sales) async {
    if (sales.isEmpty) {
      NotificationService.showInfo(context, 'Aucune donnée à exporter');
      return;
    }

    try {
      NotificationService.showInfo(context, 'Génération du fichier CSV...');
      final file = await ref.read(boutiqueExportServiceProvider).exportSales(sales);
      await OpenFile.open(file.path);
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'export: $e');
      }
    }
  }
}
