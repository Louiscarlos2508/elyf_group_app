import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/site_logistics_record.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/pos_remittance.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/gaz_header.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

import '../../../../../core/tenant/tenant_provider.dart';

class GazPOSReconciliationScreen extends ConsumerWidget {
  const GazPOSReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(gazReconciliationRecordsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0, locale: 'fr_FR');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const GazHeader(
            title: 'GAZ',
            subtitle: 'Suivi Financier des POS',
            showViewToggle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: recordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return _buildEmptyState(context, theme);
                  }
                  return _buildReconciliationTable(context, ref, records, currencyFormat, theme);
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                )),
                error: (err, _) => Center(child: Text('Erreur: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, 
            size: 48, 
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Aucune donnée de réconciliation disponible',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationTable(
    BuildContext context, 
    WidgetRef ref, 
    List<GazSiteLogisticsRecord> records, 
    NumberFormat fmt,
    ThemeData theme
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(theme.primaryColor.withValues(alpha: 0.05)),
          columns: const [
            DataColumn(label: Text('Point de Vente', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Valeur Bouteilles', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total Versé', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Déduction Pertes', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Net à Verser', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: records.map((record) {
            final enterpriseAsync = ref.watch(enterpriseByIdProvider(record.siteId));
            final posName = enterpriseAsync.when(
              data: (e) => e?.name ?? 'POS Inconnu',
              loading: () => 'Chargement...',
              error: (_, __) => 'Erreur',
            );

            final balance = record.currentBalance;
            final balanceColor = balance > 0 ? theme.colorScheme.error : AppColors.success;

            return DataRow(cells: [
              DataCell(Text(posName, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(fmt.format(record.totalConsignedValue))),
              DataCell(Text(fmt.format(record.totalRemittedValue), style: const TextStyle(color: AppColors.success))),
              DataCell(Text(fmt.format(record.totalLeakValue), style: const TextStyle(color: AppColors.warning))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: balanceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    fmt.format(balance),
                    style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _showRemittanceDialog(context, ref, record, posName),
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: const Text('Encaisser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showRemittanceDialog(BuildContext context, WidgetRef ref, GazSiteLogisticsRecord record, String posName) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Nouvel Encaissement : $posName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Mode de Paiement',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: [
                  DropdownMenuItem(
                    value: PaymentMethod.cash,
                    child: Text(PaymentMethod.cash.label),
                  ),
                  const DropdownMenuItem(
                    value: PaymentMethod.mobileMoney,
                    child: Text('Orange Money'), // Label explicite pour OM
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedMethod = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Référence',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;

                final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';
                final repository = ref.read(gazPOSRemittanceRepositoryProvider);
                
                try {
                  // Créer le versement
                  await repository.createRemittance(GazPOSRemittance(
                    id: '', // Sera généré par l'offline repository
                    enterpriseId: activeEnterpriseId,
                    posId: record.siteId,
                    amount: amount,
                    remittanceDate: DateTime.now(),
                    status: RemittanceStatus.validated, // Directement validé par l'admin qui encaisse
                    paymentMethod: selectedMethod,
                    notes: notesController.text,
                  ));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Encaissement enregistré avec succès')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de l\'encaissement: $e')),
                    );
                  }
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }
}
