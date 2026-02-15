import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gas_sale_form_dialog.dart';
import 'retail/retail_new_sale_tab.dart';
import 'retail/retail_statistics_tab.dart';
import 'retail/retail_tab_bar.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import '../../widgets/gaz_header.dart';

/// Écran de vente au détail - matches Figma design.
class GazRetailScreen extends ConsumerStatefulWidget {
  const GazRetailScreen({super.key});

  @override
  ConsumerState<GazRetailScreen> createState() => _GazRetailScreenState();
}

class _GazRetailScreenState extends ConsumerState<GazRetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Callback appelé lors du changement d'onglet.
  /// Vérifie que le widget est toujours monté avant d'appeler setState()
  /// pour éviter les erreurs si le listener se déclenche après dispose().
  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showSaleDialog(Cylinder cylinder) {
    try {
      showDialog(
        context: context,
        builder: (context) =>
            GasSaleFormDialog(
              saleType: SaleType.retail,
              initialCylinder: cylinder,
            ),
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'ouverture du dialog de vente: $e',
        name: 'gaz.retail',
        error: e,
      );
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Header section with Premium Background
          GazHeader(
            title: 'GAZ',
            subtitle: 'Vente Détail',
            asSliver: false,
            bottom: RetailTabBar(tabController: _tabController),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RetailNewSaleTab(onCylinderTap: _showSaleDialog),
                const RetailStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
