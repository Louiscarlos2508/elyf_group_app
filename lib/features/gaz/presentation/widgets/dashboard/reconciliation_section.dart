import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart' as auth;
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Section du dashboard pour la réconciliation journalière (Z-Report).
class DashboardReconciliationSection extends ConsumerWidget {
  const DashboardReconciliationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardDataAsync = ref.watch(gazDashboardDataProvider);

    return dashboardDataAsync.when(
      data: (data) {
        final metrics = GazCalculationService.calculateDailyReconciliation(
          date: DateTime.now(),
          allSales: data.sales,
          allExpenses: data.expenses,
          cylinders: data.cylinders,
        );

        if (metrics.totalSales == 0 && metrics.totalExpenses == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réconciliation du Jour',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Résumé théorique de la session',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusChip(context, metrics, ref),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Primary Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Ventes Totales',
                        value: CurrencyFormatter.formatDouble(metrics.totalSales),
                        icon: Icons.point_of_sale,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Cash Théorique',
                        value: CurrencyFormatter.formatDouble(metrics.theoreticalCash),
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                        subtitle: 'Après dépenses',
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: AppSpacing.xl),
                
                // Breakdown Sections
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Methods Breakdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Par Mode de Paiement',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...metrics.salesByPaymentMethod.entries.where((e) => e.value > 0).map(
                            (e) => _buildBreakdownRow(
                              e.key.label,
                              CurrencyFormatter.formatDouble(e.value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Cylinder Breakdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Par Format (Bouteilles)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...metrics.salesByCylinderWeight.entries.where((e) => e.value > 0).map(
                            (e) => _buildBreakdownRow(
                              '${e.key}kg',
                              '${e.value} unités',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showExportPreview(context, ref, metrics),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Imprimer Z-Report'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _confirmDayClosure(context, ref, metrics),
                        icon: const Icon(Icons.lock_clock),
                        label: const Text('Clôturer la Journée'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => AppShimmers.statsGrid(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusChip(BuildContext context, ReconciliationMetrics metrics, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            'Session Ouverte',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportPreview(
    BuildContext context,
    WidgetRef ref,
    ReconciliationMetrics metrics,
  ) async {
    final printingService = ref.read(gazPrintingServiceProvider);
    final enterpriseName = ref.read(activeEnterpriseProvider).value?.name;

    NotificationService.showInfo(context, 'Impression du Z-Report...');

    final success = await printingService.printDailySummary(
      metrics: metrics,
      enterpriseName: enterpriseName,
    );

    if (context.mounted) {
      if (success) {
        NotificationService.showSuccess(context, 'Z-Report imprimé avec succès');
      } else {
        NotificationService.showError(
          context,
          'Erreur lors de l\'impression. Vérifiez l\'imprimante.',
        );
      }
    }
  }

  Future<void> _confirmDayClosure(BuildContext context, WidgetRef ref, ReconciliationMetrics metrics) async {
    final sessionAsync = ref.read(todayGazSessionProvider);
    final session = sessionAsync.value;

    if (session != null) {
      NotificationService.showInfo(context, 'La session est déjà clôturée pour aujourd\'hui.');
      return;
    }

    final physicalCashController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer la journée'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Théorique: ${CurrencyFormatter.formatDouble(metrics.theoreticalCash)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: physicalCashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Espèces Physiques (En caisse)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes / Observations',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer la Clôture'),
          ),
        ],
      ),
    );

    if (result == true) {
      final physicalCash = double.tryParse(physicalCashController.text) ?? 0.0;
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? '';
      final userId = ref.read(currentUserIdProvider);

      final newSession = GazCalculationService.createSessionClosure(
        id: DateTime.now().toIso8601String(),
        enterpriseId: enterpriseId,
        metrics: metrics,
        physicalCash: physicalCash,
        closedBy: userId,
        notes: notesController.text,
      );

      try {
        await ref.read(gazSessionControllerProvider).confirmSessionClosure(newSession);
        ref.invalidate(todayGazSessionProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Journée clôturée avec succès');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, 'Erreur lors de la clôture: $e');
        }
      }
    }
  }
}
