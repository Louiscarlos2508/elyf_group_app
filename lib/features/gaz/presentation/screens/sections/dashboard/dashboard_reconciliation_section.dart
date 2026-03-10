import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/site_logistics_record.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:intl/intl.dart';

class DashboardReconciliationSection extends ConsumerWidget {
  const DashboardReconciliationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(gazReconciliationRecordsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0, locale: 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suivi Financier des Points de Vente (Compte Courant)',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(gazNavigationIndexProvider.notifier).state = 5; // Index of "Suivi POS"
                },
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Voir Détails'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        recordsAsync.when(
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
      ],
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
          Text(
            'Aucune donnée de réconciliation disponible',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
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
            DataColumn(label: Text('Valeur Bouteilles Confiées', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total Montant Versé', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Déduction Pertes/Fuites', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Reste à Verser', style: TextStyle(fontWeight: FontWeight.bold))),
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
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
