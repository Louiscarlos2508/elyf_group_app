import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gas_sale_form_dialog.dart';
import 'retail/retail_header.dart';
import 'retail/retail_new_sale_tab.dart';
import 'retail/retail_statistics_tab.dart';
import 'retail/retail_tab_bar.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showSaleDialog(Cylinder cylinder) {
    try {
      showDialog(
        context: context,
        builder: (context) => const GasSaleFormDialog(
          saleType: SaleType.retail,
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Header
          const RetailHeader(),
          // Tabs
          RetailTabBar(tabController: _tabController),
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
