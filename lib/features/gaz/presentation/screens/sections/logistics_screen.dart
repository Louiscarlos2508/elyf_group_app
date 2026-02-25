import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
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

  Future<void> _handleNewTour() async {
    final activeEnterprise = ref.read(activeEnterpriseProvider).value;
    if (activeEnterprise == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau tour'),
        content: const Text(
          'Voulez-vous démarrer un nouveau tour d\'approvisionnement pour aujourd\'hui ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final controller = ref.read(tourControllerProvider);
        final tour = Tour(
          id: '',
          enterpriseId: activeEnterprise.id,
          tourDate: DateTime.now(),
          status: TourStatus.open,
        );

        await controller.createTour(tour);
        
        if (mounted) {
          NotificationService.showSuccess(context, 'Nouveau tour démarré');
          // No need to invalidate manually if watchTours is used in the list tab
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, 'Erreur lors de la création: $e');
        }
      }
    }
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
                onPressed: _handleNewTour,
                icon: const Icon(Icons.add_road, color: Colors.white),
                tooltip: 'Démarrer un tour',
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
              onNewTour: _handleNewTour,
            ),
            ToursListTab(
              enterpriseId: enterpriseId,
              tourStatus: TourStatus.closed,
              title: 'Historique des tours',
              onNewTour: _handleNewTour,
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
