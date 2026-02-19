import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gas_sale_form_dialog.dart';
import 'retail/retail_new_sale_tab.dart';
import 'retail/retail_statistics_tab.dart';
import 'retail/retail_tab_bar.dart';
import 'package:flutter/services.dart';
import '../../widgets/gas_sale_form/gas_sale_submit_handler.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/gaz_session_guard.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/gaz_session_guard.dart';

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

  void _handleQuickExchange(Cylinder cylinder) async {
    final enterpriseId = ref.read(activeEnterpriseIdProvider).value;
    if (enterpriseId == null) {
      NotificationService.showError(context, 'Aucune entreprise sélectionnée');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'Échange Rapide'),
        content: Text(
          'Voulez-vous enregistrer un échange standard d\'une bouteille de ${cylinder.weight}kg ?\n\n'
          'Montant: ${CurrencyFormatter.formatDouble(cylinder.sellPrice)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    
    // Afficher un overlay de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final sale = await GasSaleSubmitHandler.submit(
        context: context,
        ref: ref,
        selectedCylinder: cylinder,
        quantity: 1,
        availableStock: 1000, // On laisse le service vérifier le stock réel
        enterpriseId: enterpriseId,
        saleType: SaleType.retail,
        customerName: null,
        customerPhone: null,
        notes: 'Échange Rapide',
        totalAmount: cylinder.sellPrice,
        unitPrice: cylinder.sellPrice,
        emptyReturnedQuantity: 1,
        dealType: GasSaleDealType.exchange,
        onLoadingChanged: () {}, // Géré par l'overlay
      );

      if (mounted) {
        Navigator.pop(context); // Fermer l'overlay
        if (sale != null) {
          NotificationService.showSuccess(context, 'Vente enregistrée !');
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer l'overlay
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
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
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
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
            child: GazSessionGuard(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RetailNewSaleTab(
                    onCylinderTap: _showSaleDialog,
                    onQuickExchange: _handleQuickExchange,
                  ),
                  const RetailStatisticsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
