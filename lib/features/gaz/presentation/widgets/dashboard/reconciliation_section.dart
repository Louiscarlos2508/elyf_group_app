import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart' as auth;
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_session.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import '../gaz_session_opening_dialog.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_session_calculation_service.dart';

/// Section du dashboard pour la réconciliation journalière (Z-Report).
class DashboardReconciliationSection extends ConsumerStatefulWidget {
  const DashboardReconciliationSection({super.key});

  @override
  ConsumerState<DashboardReconciliationSection> createState() => _DashboardReconciliationSectionState();
}

class _DashboardReconciliationSectionState extends ConsumerState<DashboardReconciliationSection> {
  final _physicalCashController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _physicalCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(todayGazSessionProvider);
    final dashboardDataAsync = ref.watch(gazLocalDashboardDataProvider);

    return sessionAsync.when(
      data: (session) {
        if (session == null || !session.isOpen) {
          return _buildOpenSessionCard(context, ref);
        }

        return dashboardDataAsync.when(
          data: (data) {
            final metrics = GazSessionCalculationService.calculateDailyReconciliation(
              date: DateTime.now(),
              allSales: data.sales,
              allExpenses: data.expenses,
              cylinders: data.cylinders,
              stocks: data.stocks.where((s) => s.status == CylinderStatus.full).toList(),
              openingCash: session.openingCash,
            );

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
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
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(context, session),
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
                            onPressed: () => _confirmDayClosure(context, ref, metrics, session),
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
      },
      loading: () => AppShimmers.statsGrid(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOpenSessionCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      color: theme.colorScheme.primary.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_open_rounded, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Prêt à commencer ?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ouvrez une session pour enregistrer vos ventes aujourd\'hui.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleOpenSession(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Ouvrir la Session de Vente'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOpenSession(BuildContext context, WidgetRef ref) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GazSessionOpeningDialog(),
    );

    if (success == true) {
      ref.invalidate(todayGazSessionProvider);
      if (context.mounted) {
        NotificationService.showSuccess(context, 'Session ouverte avec succès. Vous pouvez maintenant vendre.');
      }
    }
  }

  Widget _buildStatusChip(BuildContext context, GazSession session) {
    final theme = Theme.of(context);
    final openedAtStr = ' depuis ${session.openedAt.hour}:${session.openedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Session Active$openedAtStr',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
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
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Future<void> _confirmDayClosure(BuildContext context, WidgetRef ref, ReconciliationMetrics metrics, GazSession session) async {
    // Controllers for physical stock counts
    final stockControllers = <int, TextEditingController>{};
    for (final weight in metrics.theoreticalStock.keys) {
      stockControllers[weight] = TextEditingController(
        text: (metrics.theoreticalStock[weight] ?? 0).toString(),
      );
    }

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
                controller: _physicalCashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Espèces Physiques (En caisse)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Stock Physique (Bouteilles Pleines)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...metrics.theoreticalStock.keys.map((weight) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text('${weight}kg')),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: stockControllers[weight],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Théorique: ${metrics.theoreticalStock[weight]}'),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
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
      final physicalCash = double.tryParse(_physicalCashController.text) ?? 0.0;
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? '';
      final userId = ref.read(auth.currentUserIdProvider) ?? '';

      final physicalStock = stockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? metrics.theoreticalStock[k] ?? 0));

      final newSession = GazSession.fromMetrics(
        id: DateTime.now().toIso8601String(),
        enterpriseId: enterpriseId,
        metrics: metrics,
        physicalCash: physicalCash,
        closedBy: userId,
        physicalStock: physicalStock,
        openingFullStock: session.openingFullStock,
        openingEmptyStock: session.openingEmptyStock,
        openingCash: session.openingCash,
        notes: _notesController.text,
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
