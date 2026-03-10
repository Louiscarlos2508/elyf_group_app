import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

import '../../widgets/gaz_header.dart';
import 'inventory/inventory_tab_bar.dart';
import 'inventory/stock_status_tab.dart';
import 'inventory/leak_tracking_tab.dart';
import 'inventory/stock_history_tab.dart';
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
    final isPOS = enterprise?.isPointOfSale ?? false;
    final List<String> newTabs = ['Stock'];
    if (isPOS) {
      newTabs.add('Fuites');
      newTabs.add('Historique');
    }

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
    final isPOS = enterprise?.isPointOfSale ?? false;

    if (enterpriseId == null) {
      return const Scaffold(
        appBar: ElyfAppBar(
          title: 'Stock',
          module: EnterpriseModule.gaz,
        ),
        body: Center(child: Text('Aucune entreprise sélectionnée')),
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
            showViewToggle: false, // User requested to only show network view for main depot
            actions: const [


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
            if (isPOS)
              LeakTrackingTab(
                enterpriseId: enterpriseId,
                moduleId: 'gaz',
              ),
            if (isPOS)
              StockHistoryTab(enterpriseId: enterpriseId),

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

