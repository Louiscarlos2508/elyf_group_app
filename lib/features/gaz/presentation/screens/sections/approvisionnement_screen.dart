import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/tour.dart';
import '../../widgets/tour_form_dialog.dart';
import 'approvisionnement/approvisionnement_header.dart';
import 'approvisionnement/approvisionnement_tab_bar.dart';
import 'approvisionnement/tours_list_tab.dart';

/// Écran de gestion des tours d'approvisionnement.
class ApprovisionnementScreen extends ConsumerStatefulWidget {
  const ApprovisionnementScreen({super.key});

  @override
  ConsumerState<ApprovisionnementScreen> createState() =>
      _ApprovisionnementScreenState();
}

class _ApprovisionnementScreenState
    extends ConsumerState<ApprovisionnementScreen>
    with SingleTickerProviderStateMixin {
  String? _enterpriseId;
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

  void _showNewTourDialog() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const TourFormDialog(),
      );
      if (result == true && mounted) {
        ref.invalidate(
          toursProvider(
            (enterpriseId: _enterpriseId!, status: null),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Header
          ApprovisionnementHeader(
            isMobile: isMobile,
            onNewTour: _showNewTourDialog,
          ),
          // Tabs and content
          Expanded(
            child: Column(
              children: [
                // Custom tab bar
                ApprovisionnementTabBar(tabController: _tabController),
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ToursListTab(
                        enterpriseId: _enterpriseId!,
                        tourStatus: null,
                        title: 'Tours en cours',
                        onNewTour: _showNewTourDialog,
                      ),
                      ToursListTab(
                        enterpriseId: _enterpriseId!,
                        tourStatus: TourStatus.closure,
                        title: 'Historique',
                        onNewTour: _showNewTourDialog,
                        emptyStateMessage: 'Aucun tour dans l\'historique',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
