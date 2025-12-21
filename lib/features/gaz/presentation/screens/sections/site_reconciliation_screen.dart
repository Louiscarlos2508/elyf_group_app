import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/site_reconciliation.dart';
import '../../widgets/site_reconciliation_form_dialog.dart';

/// Écran de réconciliation cash-bouteilles pour sites distants.
class SiteReconciliationScreen extends ConsumerStatefulWidget {
  const SiteReconciliationScreen({super.key});

  @override
  ConsumerState<SiteReconciliationScreen> createState() =>
      _SiteReconciliationScreenState();
}

class _SiteReconciliationScreenState
    extends ConsumerState<SiteReconciliationScreen> {
  String? _enterpriseId;
  String _selectedSiteId = 'bogande'; // TODO: Récupérer depuis contexte

  Color _getStatusColor(ReconciliationStatus status) {
    switch (status) {
      case ReconciliationStatus.pending:
        return Colors.orange;
      case ReconciliationStatus.verified:
        return Colors.green;
      case ReconciliationStatus.discrepancy:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    final reconciliationsAsync = ref.watch(
      siteReconciliationsProvider(
        (enterpriseId: _enterpriseId!, siteId: _selectedSiteId),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Réconciliations de Site',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 20 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => SiteReconciliationFormDialog(
                          siteId: _selectedSiteId,
                        ),
                      );
                      if (result == true && mounted) {
                        ref.invalidate(
                          siteReconciliationsProvider(
                            (enterpriseId: _enterpriseId!, siteId: _selectedSiteId),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isMobile ? 'Nouveau' : 'Nouvelle réconciliation'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        reconciliationsAsync.when(
          data: (reconciliations) {
            if (reconciliations.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune réconciliation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              sliver: SliverList.separated(
                itemCount: reconciliations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final recon = reconciliations[index];
                  final statusColor = _getStatusColor(recon.status);
                  final dateStr = '${recon.reconciliationDate.day}/${recon.reconciliationDate.month}/${recon.reconciliationDate.year}';
                  String _formatCurrency(double amount) {
                    return amount.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]} ',
                        ) +
                        ' FCFA';
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  recon.status.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                dateStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cash transféré: ${_formatCurrency(recon.totalCashTransferred)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (recon.hasDiscrepancy) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Écart détecté',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}