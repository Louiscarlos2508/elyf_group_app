import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../widgets/tour_form_dialog.dart';
import 'approvisionnement/approvisionnement_tab_bar.dart';
import 'approvisionnement/tours_list_tab.dart';
import '../../widgets/gaz_header.dart';
import '../../../domain/entities/tour.dart';

/// Unified Logistics screen for the Gaz module.
/// Previously known as 'Approvisionnement'.
class GazLogisticsScreen extends ConsumerStatefulWidget {
  const GazLogisticsScreen({super.key});

  @override
  ConsumerState<GazLogisticsScreen> createState() => _GazLogisticsScreenState();
}

class _GazLogisticsScreenState extends ConsumerState<GazLogisticsScreen>
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

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showNewTourDialog() {
    showDialog(
      context: context,
      builder: (context) => const TourFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? '';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GazHeader(
            title: 'LOGISTIQUE',
            subtitle: _getSubtitle(),
            asSliver: true,
            additionalActions: [
              IconButton(
                onPressed: _showNewTourDialog,
                icon: const Icon(Icons.add_road, color: Colors.white),
                tooltip: 'Nouveau tour',
              ),
            ],
            bottom: ApprovisionnementTabBar(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            ToursListTab(
              enterpriseId: enterpriseId,
              tourStatus: null, // null filters for non-closed tours in ToursListTab logic
              title: 'Tours en cours',
              onNewTour: _showNewTourDialog,
            ),
            ToursListTab(
              enterpriseId: enterpriseId,
              tourStatus: TourStatus.closed,
              title: 'Historique des tours',
              onNewTour: _showNewTourDialog,
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_tabController.index) {
      case 0:
        return 'Tours en cours';
      case 1:
        return 'Historique des tours';
      default:
        return 'Gestion Logistique';
    }
  }
}
