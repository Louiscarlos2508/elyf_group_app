import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gas_sale_form_dialog.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/gaz_session_guard.dart';
import '../../../application/providers/permission_providers.dart';

import 'retail/retail_new_sale_tab.dart';
import 'sales/sales_history_tab.dart';
import 'wholesale/wholesale_new_sale_tab.dart';
import 'sales/sales_tab_bar.dart';

/// Unified sales screen for the Gaz module.
/// Consolidates Retail and Wholesale sales workflows.
class GazSalesScreen extends ConsumerStatefulWidget {
  const GazSalesScreen({super.key});

  @override
  ConsumerState<GazSalesScreen> createState() => _GazSalesScreenState();
}

class _GazSalesScreenState extends ConsumerState<GazSalesScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    // Initialisation différée après le premier build pour obtenir le rôle
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

  void _showSaleDialog(Cylinder cylinder, [SaleType saleType = SaleType.retail]) {
    try {
      showDialog(
        context: context,
        builder: (context) =>
            GasSaleFormDialog(
              saleType: saleType,
              initialCylinder: cylinder,
            ),
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'ouverture du dialog de vente: $e',
        name: 'gaz.sales',
        error: e,
      );
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isManagerAsync = ref.watch(isGazManagerProvider);
    final enterpriseAsync = ref.watch(activeEnterpriseProvider);

    return isManagerAsync.when(
      data: (isManager) {
        final enterprise = enterpriseAsync.value;
        final isPOS = enterprise?.type == EnterpriseType.gasPointOfSale;
        
        // Wholesale (Gros) is restricted for POS unless manager.
        final showWholesale = !isPOS || isManager;

        final List<String> tabs = ['Détail'];
        if (showWholesale) tabs.add('Gros');
        tabs.add('Historique');

        _initTabController(tabs.length, isManager);
        
        return Container(
          color: theme.colorScheme.surface,
          child: GazSessionGuard(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                GazHeader(
                  title: 'VENTES',
                  subtitle: _getSubtitle(tabs),
                  asSliver: true,
                  bottom: SalesTabBar(
                    tabController: _tabController!,
                    tabs: tabs,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  RetailNewSaleTab(
                    onCylinderTap: (c) => _showSaleDialog(c, SaleType.retail),
                  ),
                  if (showWholesale)
                    WholesaleNewSaleTab(
                      onCylinderTap: (c) => _showSaleDialog(c, SaleType.wholesale),
                    ),
                   const SalesHistoryTab(),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  void _initTabController(int length, bool isManager) {
    if (_tabController != null && _tabController!.length == length && _isManager == isManager) return;
    
    _isManager = isManager;
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    
    _tabController = TabController(
      length: length, 
      vsync: this,
    );
    _tabController!.addListener(_onTabChanged);
  }

  String _getSubtitle(List<String> tabs) {
    if (_tabController == null || _tabController!.index >= tabs.length) return 'Gestion des Ventes';
    
    final currentTab = tabs[_tabController!.index];
    switch (currentTab) {
      case 'Détail':
        return 'Vente au Détail';
      case 'Gros':
        return 'Vente en Gros';
      case 'Historique':
        return 'Historique & Stats';
      case 'Distribution':
        return 'Distribution Stock';
      default:
        return 'Gestion des Ventes';
    }
  }
}

