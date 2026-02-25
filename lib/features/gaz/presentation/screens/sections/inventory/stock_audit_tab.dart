import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart' as auth;
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/gaz_inventory_audit.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../../domain/services/gaz_calculation_service.dart';

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
    final currentEnterprise = ref.watch(activeEnterpriseProvider).value;
    
    // Restricting audit to mother company / headquarters
    if (currentEnterprise != null && 
        currentEnterprise.type != EnterpriseType.gasCompany && 
        currentEnterprise.type != EnterpriseType.group) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Accès Restreint',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'L\'audit d\'inventaire est réservé à l\'administration de l\'entreprise mère.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

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
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(sites),
            Expanded(
              child: _isAuditing
                  ? _buildAuditForm(enterpriseId)
                  : _buildRecentAudits(_selectedSite?.id ?? enterpriseId),
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
                      child: ElyfButton(
                        onPressed: _isLoading ? null : () => setState(() => _isAuditing = false),
                        variant: ElyfButtonVariant.outlined,
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElyfButton(
                        onPressed: _isLoading ? null : () => _submitAudit(enterpriseId),
                        isLoading: _isLoading,
                        child: const Text('Terminer l\'audit'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (_isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                child: const LoadingIndicator(message: 'Mise à jour de l\'inventaire...'),
              ),
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
    final String targetId = _selectedSite?.id ?? enterpriseId;
    final String? siteIdParam = null;

    final stocksAsync = ref.watch(gazStocksProvider);

    final cylindersAsync = ref.watch(cylindersProvider);
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: targetId,
      moduleId: 'gaz',
    )));
    
    return cylindersAsync.when(
      data: (cylinders) => stocksAsync.when(
        data: (stocks) => settingsAsync.when(
        data: (settings) {
          final theme = Theme.of(context);
          final theoreticalMetrics = GazCalculationService.calculatePosStockMetrics(
            enterpriseId: targetId,
            siteId: siteIdParam,
            allStocks: stocks,
            cylinders: cylinders,
            settings: settings,
          );

          final uniqueCylinders = <int, Cylinder>{};
          for (final c in cylinders) {
            if (c.enterpriseId == targetId || !uniqueCylinders.containsKey(c.weight)) {
              uniqueCylinders[c.weight] = c;
            }
          }

          final auditList = <CylinderStock>[];
          final Map<int, List<CylinderStock>> groupedByWeight = {};

          final isPosAudit = _selectedSite != null;
          final statusesToShow = [
            CylinderStatus.full,
            CylinderStatus.emptyAtStore,
            if (!isPosAudit) CylinderStatus.emptyInTransit,
            CylinderStatus.leak,
            CylinderStatus.defective,
          ];

          for (final cylinder in uniqueCylinders.values) {
            final weightStocks = stocks.where((s) => s.weight == cylinder.weight && s.enterpriseId == targetId).toList();
            
            final weightAuditList = <CylinderStock>[];
            for (final status in statusesToShow) {
              final existing = weightStocks.where((s) => s.status == status && s.cylinderId == cylinder.id && s.siteId == siteIdParam && s.enterpriseId == targetId).firstOrNull;
              if (existing != null) {
                weightAuditList.add(existing);
              } else {
                weightAuditList.add(CylinderStock(
                  id: 'virtual-${status.name}-${cylinder.id}',
                  cylinderId: cylinder.id,
                  weight: cylinder.weight,
                  status: status,
                  quantity: 0,
                  enterpriseId: targetId,
                  siteId: siteIdParam,
                  updatedAt: DateTime.now(),
                ));
              }
            }
            groupedByWeight[cylinder.weight] = weightAuditList;
          }

          if (groupedByWeight.isEmpty) {
            return const Center(child: Text('Aucune configuration de bouteille trouvée.'));
          }

          final sortedWeights = groupedByWeight.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sortedWeights.length,
            itemBuilder: (context, weightIndex) {
              final weight = sortedWeights[weightIndex];
              final weightStocks = groupedByWeight[weight]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Bouteilles ${weight}kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Divider(color: Colors.blue.withValues(alpha: 0.2))),
                      ],
                    ),
                  ),
                  ...weightStocks.map((stock) {
                    final theoretical = _getTheoreticalQuantity(stock, theoreticalMetrics);
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
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildCountBadge('Théorique', theoretical, Colors.grey),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: physical.toString(),
                                    key: ValueKey('${stock.id}-$theoretical'),
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
                                  color: (physical > theoretical ? Colors.green : Colors.red),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  int _getTheoreticalQuantity(CylinderStock stock, PointOfSaleStockMetrics metrics) {
    // Audit should use the raw database quantity as the theoretical reference
    // rather than the grouped/calculated metrics used for general reporting.
    return stock.quantity;
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

    final String targetId = _selectedSite?.id ?? enterpriseId;
    final String? siteIdParam = null;

    try {
      final cylinders = await ref.read(cylindersProvider.future);
      final stocks = await ref.read(gazStocksProvider.future);
      final settings = await ref.read(gazSettingsProvider((
        enterpriseId: targetId,
        moduleId: 'gaz',
      )).future);

      final theoreticalMetrics = GazCalculationService.calculatePosStockMetrics(
        enterpriseId: targetId,
        siteId: siteIdParam,
        allStocks: stocks,
        cylinders: cylinders,
        settings: settings,
      );

      final uniqueCylinders = <int, Cylinder>{};
      for (final c in cylinders) {
        if (c.enterpriseId == targetId || !uniqueCylinders.containsKey(c.weight)) {
          uniqueCylinders[c.weight] = c;
        }
      }

      final isPosAudit = _selectedSite != null;
      final statusesToShow = [
        CylinderStatus.full,
        CylinderStatus.emptyAtStore,
        if (!isPosAudit) CylinderStatus.emptyInTransit,
        CylinderStatus.leak,
        CylinderStatus.defective,
      ];

      final auditItems = <InventoryAuditItem>[];
      for (final cylinder in uniqueCylinders.values) {
        final weightStocks = stocks.where((s) => s.weight == cylinder.weight && s.enterpriseId == targetId).toList();
        for (final status in statusesToShow) {
          final existing = weightStocks
              .where((s) =>
                  s.status == status &&
                  s.cylinderId == cylinder.id &&
                  s.siteId == siteIdParam)
              .firstOrNull;
          final stockId = existing?.id ?? 'virtual-${status.name}-${cylinder.id}';

          // Use raw stock quantity as theoretical reference for audit
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
        enterpriseId: targetId,
        auditDate: DateTime.now(),
        auditedBy: userId,
        siteId: siteIdParam,
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
