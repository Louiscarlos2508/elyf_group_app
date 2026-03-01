import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../../../../core/tenant/tenant_provider.dart';

import '../../widgets/gaz_header.dart';
import '../../widgets/deposit_refund_dialog.dart';
import 'inventory/inventory_tab_bar.dart';
import 'inventory/stock_status_tab.dart';
import 'inventory/stock_audit_tab.dart';
import 'inventory/leak_tracking_tab.dart';
import 'sales/collection_history_tab.dart';
import 'sales/distribution_tab.dart';
import '../../../application/providers/permission_providers.dart';

/// Unified Inventory & Stock management screen for the Gaz module.
/// Consolidates Stock Status, Audits, and Leak Tracking.
class GazInventoryScreen extends ConsumerStatefulWidget {
  const GazInventoryScreen({super.key});

  @override
  ConsumerState<GazInventoryScreen> createState() => _GazInventoryScreenState();
}

class _GazInventoryScreenState extends ConsumerState<GazInventoryScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    // Initialized in build when data is available
  }

  void _initTabs(Enterprise? enterprise, bool isManager) {
    final isPOS = enterprise?.type.isPointOfSale == true;
    final List<String> newTabs = ['Stock'];
    if (!isPOS) {
      newTabs.add('Collectes');
    }
    if (isManager) {
      newTabs.add('Distribution');
    }
    if (!(enterprise?.isPointOfSale ?? false)) {
      newTabs.add('Audits');
    }
    newTabs.add('Fuites');

    // If tabs are already initialized and length matches, we are good
    if (_tabs.isNotEmpty && _tabs.length == newTabs.length) return;

    // Dispose old controller if exists
    if (_tabController != null) {
      _tabController!.removeListener(_onTabChanged);
      _tabController!.dispose();
    }

    _tabs.clear();
    _tabs.addAll(newTabs);
    
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = enterprise?.id;
    final isManager = ref.watch(isGazManagerProvider).value ?? false;

    if (enterpriseId == null) {
      return Scaffold(
        appBar: ElyfAppBar(title: 'Stock'),
        body: const Center(child: Text('Aucune entreprise sélectionnée')),
      );
    }

    _initTabs(enterprise, isManager);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GazHeader(
            title: 'STOCK',
            subtitle: _getSubtitle(),
            asSliver: true,
            actions: [

              IconButton(
                onPressed: () => DepositRefundDialog.show(context),
                icon: const Icon(Icons.keyboard_return, color: Colors.white),
                tooltip: 'Retour Bouteille',
              ),
            ],
            bottom: InventoryTabBar(
              tabController: _tabController!,
              tabs: _tabs,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            StockStatusTab(
              enterpriseId: enterpriseId,
              moduleId: 'gaz',
            ),
            if (enterprise?.type.isPointOfSale != true)
              const CollectionHistoryTab(),
            if (isManager)
              const DistributionTab(),
            if (!(enterprise?.isPointOfSale ?? false))
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
    if (_tabs.isEmpty || _tabController == null) return 'Gestion du Stock';
    return _tabs[_tabController!.index];
  }
}

