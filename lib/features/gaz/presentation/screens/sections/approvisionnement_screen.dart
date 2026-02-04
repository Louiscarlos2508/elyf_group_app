import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import '../../../../../core/tenant/tenant_provider.dart';
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

  void _showNewTourDialog() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const TourFormDialog(),
      );
      if (result == true && mounted) {
        ref.invalidate(
          toursProvider((enterpriseId: _enterpriseId!, status: null)),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'ouverture du dialog d\'approvisionnement: $e',
        name: 'gaz.approvisionnement',
        error: e,
      );
      if (!mounted) return;
      NotificationService.showError(context, 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);

    return activeEnterpriseAsync.when(
      data: (activeEnterprise) {
        if (activeEnterprise == null) {
          return Container(
            color: const Color(0xFFF9FAFB),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucune entreprise sélectionnée'),
              ),
            ),
          );
        }

        _enterpriseId = activeEnterprise.id;

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
      },
      loading: () => Container(
        color: const Color(0xFFF9FAFB),
        child: AppShimmers.list(context),
      ),
      error: (error, stack) => Container(
        color: const Color(0xFFF9FAFB),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement de l\'entreprise',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
