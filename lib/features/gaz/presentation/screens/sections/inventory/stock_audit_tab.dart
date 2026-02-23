import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart' as auth;
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/gaz_inventory_audit.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../widgets/replenishment_dialog.dart';
import '../../../widgets/deposit_refund_dialog.dart';

class StockAuditTab extends ConsumerStatefulWidget {
  const StockAuditTab({super.key, required this.enterpriseId});

  final String enterpriseId;

  @override
  ConsumerState<StockAuditTab> createState() => _StockAuditTabState();
}

class _StockAuditTabState extends ConsumerState<StockAuditTab> {
  Enterprise? _selectedSite;
  bool _isAuditing = false;
  final Map<String, int> _physicalCounts = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointsOfSaleAsync = ref.watch(enterprisesByParentAndTypeProvider((
      parentId: widget.enterpriseId,
      type: EnterpriseType.gasPointOfSale,
    )));

    return pointsOfSaleAsync.when(
      data: (sites) => _buildContent(context, sites, widget.enterpriseId),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildContent(BuildContext context, List<Enterprise> sites, String enterpriseId) {
    return Column(
      children: [
        _buildHeader(sites),
        Expanded(
          child: _isAuditing
              ? _buildAuditForm(enterpriseId)
              : _buildRecentAudits(enterpriseId),
        ),
        if (!_isAuditing) 
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: ElyfButton(
                    onPressed: () => setState(() => _isAuditing = true),
                    icon: Icons.inventory,
                    child: const Text('Nouvel Audit'),
                  ),
                ),
              ],
            ),
          ),
        if (_isAuditing)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isAuditing = false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _submitAudit(enterpriseId),
                    child: const Text('Terminer l\'audit'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(List<Enterprise> sites) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.grey.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.grey),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Enterprise?>(
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

    final cylindersAsync = ref.watch(cylindersProvider);
    
    return cylindersAsync.when(
      data: (cylinders) => stocksAsync.when(
        data: (stocks) {
          final auditList = <CylinderStock>[];
          for (final cylinder in cylinders) {
            // Find existing entries for this weight
            final weightStocks = stocks.where((s) => s.weight == cylinder.weight).toList();
            
            // We want at least FULL and EMPTY for each weight
            final statusesToShow = [CylinderStatus.full, CylinderStatus.emptyAtStore, CylinderStatus.leak];
            
            for (final status in statusesToShow) {
              final existing = weightStocks.where((s) => s.status == status && s.cylinderId == cylinder.id).firstOrNull;
              if (existing != null) {
                auditList.add(existing);
              } else {
                // Add virtual entry for initial audit
                auditList.add(CylinderStock(
                  id: 'virtual-${status.name}-${cylinder.id}',
                  cylinderId: cylinder.id,
                  weight: cylinder.weight,
                  status: status,
                  quantity: 0,
                  enterpriseId: enterpriseId,
                  siteId: _selectedSite?.id,
                  updatedAt: DateTime.now(),
                ));
              }
            }
          }

          if (auditList.isEmpty) {
            return const Center(child: Text('Aucune configuration de bouteille trouvée.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: auditList.length,
            itemBuilder: (context, index) {
              final stock = auditList[index];
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildRecentAudits(String enterpriseId) {
    final historyAsync = ref.watch(auditHistoryProvider(enterpriseId));

    return historyAsync.when(
      data: (audits) {
        if (audits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Historique des audits vide'),
              ],
            ),
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
          'Cela mettra à jour tous les stocks sélectionnés avec les quantités physiques saisies.',
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
      final cylinders = await ref.read(cylindersProvider.future);
      final stocks = await ref.read(cylinderStocksProvider((
        enterpriseId: enterpriseId,
        status: null,
        siteId: _selectedSite?.id,
      )).future);

      final auditItems = <InventoryAuditItem>[];
      for (final cylinder in cylinders) {
        final statusesToShow = [CylinderStatus.full, CylinderStatus.emptyAtStore, CylinderStatus.leak];
        for (final status in statusesToShow) {
          final existing = stocks.where((s) => s.status == status && s.cylinderId == cylinder.id).firstOrNull;
          final stockId = existing?.id ?? 'virtual-${status.name}-${cylinder.id}';
          final theoretical = existing?.quantity ?? 0;
          final physical = _physicalCounts[stockId] ?? theoretical;

          auditItems.add(InventoryAuditItem(
            stockId: stockId,
            cylinderId: cylinder.id,
            weight: cylinder.weight,
            status: status,
            theoreticalQuantity: theoretical,
            physicalQuantity: physical,
          ));
        }
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
}

class _AuditHistoryCard extends StatelessWidget {
  const _AuditHistoryCard({required this.audit});
  final GazInventoryAudit audit;

  @override
  Widget build(BuildContext context) {
    final totalDiscrepancy = audit.items.fold<int>(0, (sum, item) => sum + item.discrepancy.abs());

    return Card(
      child: ExpansionTile(
        title: Text(
          'Audit du ${audit.auditDate.toIso8601String().substring(0, 10)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Écart total: $totalDiscrepancy',
          style: TextStyle(
            color: totalDiscrepancy == 0 ? Colors.green : Colors.orange,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: audit.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.weight}kg - ${item.status.name}'),
                    Text(
                      'T: ${item.theoreticalQuantity} | P: ${item.physicalQuantity} (${item.discrepancy})',
                      style: TextStyle(
                        color: item.discrepancy == 0 ? Colors.grey : (item.discrepancy > 0 ? Colors.green : Colors.red),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
