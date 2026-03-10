import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/gaz_settings.dart';
import '../../application/providers.dart';
import '../../../administration/domain/entities/enterprise.dart';
import '../../../../core/utils/formatters.dart';


class PosSalesSummaryDialog extends ConsumerWidget {
  final Enterprise pos;

  const PosSalesSummaryDialog({super.key, required this.pos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(posSalesProvider(pos.id));
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: pos.id,
      moduleId: 'gaz',
    )));

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pos.name, style: theme.textTheme.titleLarge),
          Text(
            'Récapitulatif des Ventes',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: salesAsync.when(
          data: (sales) {
            if (sales.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Aucune vente enregistrée.')),
              );
            }

            final retailSales = sales.where((s) => s.saleType == SaleType.retail).toList();
            final wholesaleSales = sales.where((s) => s.saleType == SaleType.wholesale).toList();

            final totalRetailQty = retailSales.fold<double>(0, (sum, s) => sum + s.quantity);
            final totalRetailAmount = retailSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

            final totalWholesaleQty = wholesaleSales.fold<double>(0, (sum, s) => sum + s.quantity);
            final totalWholesaleAmount = wholesaleSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

            final totalRevenue = totalRetailAmount + totalWholesaleAmount;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryItem(
                  context,
                  title: 'VENTES DÉTAIL',
                  quantity: totalRetailQty,
                  amount: totalRetailAmount,
                  icon: Icons.person_outline,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                
                // Show Wholesale if enabled or has sales
                if (wholesaleSales.isNotEmpty || (settingsAsync.value?.wholesalePrices.isNotEmpty ?? false))
                  _buildSummaryItem(
                    context,
                    title: 'VENTES GROS',
                    quantity: totalWholesaleQty,
                    amount: totalWholesaleAmount,
                    icon: Icons.groups_outlined,
                    color: AppColors.warning,
                  ),
                
                const Divider(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL RECETTES',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                        Formatters.formatCurrency(totalRevenue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('FERMER'),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String title,
    required double quantity,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${quantity.toInt()} bouteilles',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      Formatters.formatCurrency(amount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
