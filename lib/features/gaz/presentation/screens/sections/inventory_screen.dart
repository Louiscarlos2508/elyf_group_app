import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../core/tenant/tenant_provider.dart';

import '../../widgets/gaz_header.dart';
import '../../widgets/replenishment_dialog.dart';
import '../../widgets/deposit_refund_dialog.dart';
import 'inventory/inventory_tab_bar.dart';
import 'inventory/stock_status_tab.dart';
import 'inventory/stock_audit_tab.dart';
import 'inventory/leak_tracking_tab.dart';
import '../../../domain/entities/gaz_inventory_audit.dart';
import '../../../domain/entities/cylinder.dart';

/// Unified Inventory & Stock management screen for the Gaz module.
/// Consolidates Stock Status, Audits, and Leak Tracking.
class GazInventoryScreen extends ConsumerStatefulWidget {
  const GazInventoryScreen({super.key});

  @override
  ConsumerState<GazInventoryScreen> createState() => _GazInventoryScreenState();
}

class _GazInventoryScreenState extends ConsumerState<GazInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id;

    if (enterpriseId == null) {
      return Scaffold(
        appBar: ElyfAppBar(title: 'Stock'),
        body: const Center(child: Text('Aucune entreprise sélectionnée')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GazHeader(
            title: 'STOCK',
            subtitle: _getSubtitle(),
            asSliver: true,
            additionalActions: [

              IconButton(
                onPressed: () => DepositRefundDialog.show(context),
                icon: const Icon(Icons.keyboard_return, color: Colors.white),
                tooltip: 'Retour Bouteille',
              ),
            ],
            bottom: InventoryTabBar(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            StockStatusTab(
              enterpriseId: enterpriseId,
              moduleId: 'gaz',
            ),
            StockAuditTab(enterpriseId: enterpriseId),
            LeakTrackingTab(
              enterpriseId: enterpriseId,
              moduleId: 'gaz',
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_tabController.index) {
      case 0:
        return 'État des Stocks';
      case 1:
        return 'Audits & Inventaires';
      case 2:
        return 'Suivi des Fuites';
      default:
        return 'Gestion du Stock';
    }
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
            padding: const EdgeInsets.all(16.0),
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
