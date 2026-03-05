import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/permissions/modules/gaz_permissions.dart';

import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gas_sale_form_dialog.dart';
import '../../widgets/gaz_header.dart';
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

class _GazSalesScreenState extends ConsumerState<GazSalesScreen> {

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
    final isManagerAsync = ref.watch(isGazManagerProvider);
    final enterpriseAsync = ref.watch(activeEnterpriseProvider);

    return isManagerAsync.when(
      data: (isManager) {
        final enterprise = enterpriseAsync.value;
        final isPOS = enterprise?.isPointOfSale ?? false;
        
        // Wholesale (Gros) is restricted for POS unless manager OR has specific permission.
        final hasWholesalePermission = ref.watch(userHasGazPermissionProvider(GazPermissions.viewWholesale.id)).value ?? false;
        final showWholesale = !isPOS || isManager || hasWholesalePermission;

        final List<String> tabs = [];
        if (isPOS) {
          tabs.add('Détail');
          if (showWholesale) tabs.add('Gros');
        }
        tabs.add('Historique');

        return DefaultTabController(
          key: ValueKey(tabs.length),
          length: tabs.length,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              GazHeader(
                title: 'VENTES',
                subtitle: 'Gestion des Ventes',
                asSliver: true,
                showViewToggle: false, // User requested to only show network view for main depot
                bottom: SalesTabBar(
                  tabs: tabs,
                ),
              ),
            ],
            body: TabBarView(
              children: [
                if (isPOS)
                  RetailNewSaleTab(
                    onCylinderTap: (c) => _showSaleDialog(c, SaleType.retail),
                  ),
                if (isPOS && showWholesale)
                  WholesaleNewSaleTab(
                    onCylinderTap: (c) => _showSaleDialog(c, SaleType.wholesale),
                  ),
                const SalesHistoryTab(),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

