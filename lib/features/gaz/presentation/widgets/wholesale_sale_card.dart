import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/gas_sale.dart';
import 'gas_print_receipt_button.dart';
import '../../domain/services/gaz_sale_pdf_service.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

class WholesaleSaleCard extends ConsumerWidget {
  const WholesaleSaleCard({super.key, required this.sales});

  final List<GasSale> sales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sales.isEmpty) return const SizedBox.shrink();
    
    final mainSale = sales.first;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final cylinders = ref.watch(cylindersProvider).value ?? [];
    
    final totalAmount = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalQty = sales.fold<int>(0, (sum, s) => sum + s.quantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec date et montant global
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dateFormat.format(mainSale.saleDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'GROUPE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (mainSale.wholesalerName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mainSale.wholesalerName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.print_outlined,
                      size: 20,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    onPressed: () => _showPrintOptions(context, ref),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      CurrencyFormatter.formatDouble(totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tableau des Détails par poids
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                ...sales.map((item) {
                  final cyl = cylinders.where((c) => c.id == item.cylinderId).firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cyl?.label ?? "${cyl?.weight}kg"}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${item.quantity} x ${CurrencyFormatter.formatDouble(item.unitPrice)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          CurrencyFormatter.formatDouble(item.totalAmount),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL BTL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('$totalQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 40),
                    Text(CurrencyFormatter.formatDouble(totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Options d\'impression (Groupe)',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GasPrintReceiptButton(
              sales: sales, // Passez la liste ici
              onPrintSuccess: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _generateAndOpenPdf(context, ref),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Générer PDF (Facture Groupée)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndOpenPdf(BuildContext context, WidgetRef ref) async {
     try {
      final enterprise = ref.read(activeEnterpriseProvider).value;
      // Note: GazSalePdfService will need an update to handle list of sales
      final file = await GazSalePdfService.instance.generateBatchSaleReceipt(
        sales: sales,
        enterpriseName: enterprise?.name,
      );
      
      if (context.mounted) {
        Navigator.pop(context); 
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur PDF: $e');
      }
    }
  }
}
