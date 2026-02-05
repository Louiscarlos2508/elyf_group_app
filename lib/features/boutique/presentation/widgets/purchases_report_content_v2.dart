import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';

// Import SupplierSummary from report_data

/// Content widget for purchases report tab - style eau_minerale.
class PurchasesReportContentV2 extends ConsumerWidget {
  const PurchasesReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final purchasesReportAsync = ref.watch(
      purchasesReportProvider((
        period: ReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: purchasesReportAsync.when(
        data: (data) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Détail des Achats',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.purchasesCount} achats • Total: ${CurrencyFormatter.formatFCFA(data.totalAmount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Statistiques
              Text(
                'Statistiques',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatistics(theme, data),

              const SizedBox(height: 24),

              // Top fournisseurs
              Text(
                'Top Fournisseurs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (data.topSuppliers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Aucun fournisseur pour cette période',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...data.topSuppliers.map(
                  (supplier) => _buildSupplierCard(theme, supplier),
                ),
            ],
          );
        },
        loading: () => AppShimmers.list(context, itemCount: 3),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildStatistics(ThemeData theme, PurchasesReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow(
            theme,
            'Total articles achetés',
            '${data.totalItemsPurchased}',
          ),
          const Divider(),
          _buildStatRow(theme, 'Nombre d\'achats', '${data.purchasesCount}'),
          const Divider(),
          _buildStatRow(
            theme,
            'Achat moyen',
            CurrencyFormatter.formatFCFA(data.averagePurchaseAmount),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(ThemeData theme, SupplierSummary supplier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.supplierName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${supplier.purchasesCount} achat(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatFCFA(supplier.totalAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}
