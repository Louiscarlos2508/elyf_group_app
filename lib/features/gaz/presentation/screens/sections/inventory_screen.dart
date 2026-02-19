import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../../../core/tenant/tenant_provider.dart';
import '../../../../../core/auth/providers.dart' as auth;
import '../../../application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gaz_inventory_audit.dart';
import '../../../domain/entities/point_of_sale.dart';
import '../../widgets/replenishment_dialog.dart';
import '../../widgets/deposit_refund_dialog.dart';

class GazInventoryScreen extends ConsumerStatefulWidget {
  const GazInventoryScreen({super.key});

  @override
  ConsumerState<GazInventoryScreen> createState() => _GazInventoryScreenState();
}

class _GazInventoryScreenState extends ConsumerState<GazInventoryScreen> {
  PointOfSale? _selectedSite;
  bool _isAuditing = false;
  final Map<String, int> _physicalCounts = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id;

    if (enterpriseId == null) {
      return const Center(child: Text('Aucune entreprise sélectionnée'));
    }

    final pointsOfSaleAsync = ref.watch(pointsOfSaleProvider((
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
    )));

    return Scaffold(
      appBar: ElyfAppBar(
        title: 'Inventaire & Audit',
        actions: [
          EnterpriseSelectorWidget(style: EnterpriseSelectorStyle.appBar),
          if (!_isAuditing) ...[
            IconButton(
              onPressed: () => _showReplenishmentDialog(context),
              icon: const Icon(Icons.add_business),
              tooltip: 'Réception Stock',
            ),
            IconButton(
              onPressed: () => _showRefundDialog(context),
              icon: const Icon(Icons.keyboard_return),
              tooltip: 'Retour Bouteille',
            ),
          ],
          if (_isAuditing)
            TextButton.icon(
              onPressed: _isLoading ? null : () => _submitAudit(enterpriseId),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Terminer l\'audit'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
        ],
      ),
      body: pointsOfSaleAsync.when(
        data: (sites) => _buildContent(context, sites, enterpriseId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: !_isAuditing
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _isAuditing = true),
              label: const Text('Nouvel Audit'),
              icon: const Icon(Icons.inventory),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, List<PointOfSale> sites, String enterpriseId) {
    return Column(
      children: [
        _buildHeader(sites),
        Expanded(
          child: _isAuditing
              ? _buildAuditForm(enterpriseId)
              : _buildRecentAudits(enterpriseId),
        ),
      ],
    );
  }

  Widget _buildHeader(List<PointOfSale> sites) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.grey.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.grey),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PointOfSale?>(
                value: _selectedSite,
                hint: const Text('Sélectionner un site audit'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Global / Entrepôt')),
                  ...sites.map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                ],
                onChanged: _isAuditing ? null : (v) => setState(() => _selectedSite = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditForm(String enterpriseId) {
    final stocksAsync = ref.watch(cylinderStocksProvider((
      enterpriseId: enterpriseId,
      status: null,
      siteId: _selectedSite?.id,
    )));

    return stocksAsync.when(
      data: (stocks) {
        if (stocks.isEmpty) {
          return const Center(child: Text('Aucun stock trouvé pour ce site.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index];
            final theoretical = stock.quantity;
            final physical = _physicalCounts[stock.id] ?? theoretical;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(stock.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stock.status.label,
                            style: TextStyle(
                              color: _getStatusColor(stock.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bouteille ${stock.weight}kg',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCountBadge('Théorique', theoretical, Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: theoretical.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantité Physique',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _physicalCounts[stock.id] = int.tryParse(v) ?? theoretical;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (physical != theoretical) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Écart: ${physical - theoretical > 0 ? "+" : ""}${physical - theoretical}',
                        style: TextStyle(
                          color: physical == theoretical ? Colors.grey : (physical > theoretical ? Colors.green : Colors.red),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildRecentAudits(String enterpriseId) {
    final historyAsync = ref.watch(auditHistoryProvider(enterpriseId));

    return historyAsync.when(
      data: (audits) {
        if (audits.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Historique des audits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les audits complétés apparaîtront ici.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElyfButton(
                onPressed: () => setState(() => _isAuditing = true),
                child: const Text('Commencer un audit maintenant'),
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: audits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _AuditHistoryCard(audit: audits[index]),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(CylinderStatus status) {
    switch (status) {
      case CylinderStatus.full:
        return Colors.green;
      case CylinderStatus.emptyAtStore:
        return Colors.blue;
      case CylinderStatus.emptyInTransit:
        return Colors.orange;
      case CylinderStatus.leak:
        return Colors.red;
      case CylinderStatus.defective:
        return Colors.brown;
    }
  }

  Future<void> _submitAudit(String enterpriseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'audit'),
        content: const Text(
          'Cela mettra à jour tous les stocks sélectionnés avec les quantités physiques saisies. '
          'Cette action sera enregistrée dans l\'historique d\'audit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final stocks = await ref.read(cylinderStocksProvider((
        enterpriseId: enterpriseId,
        status: null,
        siteId: _selectedSite?.id,
      )).future);

      final auditItems = <InventoryAuditItem>[];
      for (final stock in stocks) {
        final physical = _physicalCounts[stock.id] ?? stock.quantity;
        auditItems.add(InventoryAuditItem(
          stockId: stock.id,
          cylinderId: stock.cylinderId,
          weight: stock.weight,
          status: stock.status,
          theoreticalQuantity: stock.quantity,
          physicalQuantity: physical,
        ));
      }

      final userId = ref.read(auth.currentUserIdProvider) ?? '';
      final transactionService = ref.read(transactionServiceProvider);

      final audit = GazInventoryAudit(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        auditDate: DateTime.now(),
        auditedBy: userId,
        siteId: _selectedSite?.id,
        items: auditItems,
        status: InventoryAuditStatus.completed,
      );

      await transactionService.executeInventoryAudit(
        audit: audit,
        userId: userId,
      );

      if (mounted) {
        NotificationService.showSuccess(context, 'Inventaire mis à jour avec succès');
        setState(() {
          _isAuditing = false;
          _physicalCounts.clear();
        });
        // Rafraîchir les données
        ref.invalidate(cylinderStocksProvider);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'audit: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReplenishmentDialog(BuildContext context) {
    ReplenishmentDialog.show(context, siteId: _selectedSite?.id);
  }

  void _showRefundDialog(BuildContext context) {
    DepositRefundDialog.show(context, siteId: _selectedSite?.id);
  }
}

class _AuditHistoryCard extends StatelessWidget {
  const _AuditHistoryCard({required this.audit});

  final GazInventoryAudit audit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDiscrepancy = audit.items.fold<int>(0, (sum, item) => sum + item.discrepancy.abs());

    return Card(
      child: ExpansionTile(
        title: Text(
          'Audit du ${audit.auditDate.toIso8601String().substring(0, 10)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${audit.items.length} types | Écart total: $totalDiscrepancy',
          style: TextStyle(
            color: totalDiscrepancy == 0 ? Colors.green : Colors.orange,
          ),
        ),
        leading: Icon(
          Icons.inventory_2_outlined,
          color: totalDiscrepancy == 0 ? Colors.green : Colors.orange,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...audit.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.weight}kg - ${item.status.name}'),
                          Text(
                            'T: ${item.theoreticalQuantity} | P: ${item.physicalQuantity} (${item.discrepancy > 0 ? "+" : ""}${item.discrepancy})',
                            style: TextStyle(
                              color: item.discrepancy == 0
                                  ? Colors.grey
                                  : (item.discrepancy > 0 ? Colors.green : Colors.red),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (audit.notes != null) ...[
                  const Divider(),
                  Text('Note: ${audit.notes}', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
