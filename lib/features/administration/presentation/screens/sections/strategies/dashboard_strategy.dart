import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/presentation/widgets/audit/audit_log_item.dart';
import 'package:elyf_groupe_app/features/administration/presentation/screens/sections/admin_audit_trail_section.dart';

/// Strategy interface for building module-specific dashboards
abstract class EnterpriseDashboardStrategy {
  /// Returns the list of tabs available for this strategy
  List<Tab> getTabs();

  /// Builds the content for the tab at the given index
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise);

  /// Factory method to get the correct strategy based on enterprise type
  static EnterpriseDashboardStrategy fromEnterprise(Enterprise enterprise) {
    if (enterprise.type.isGas) {
      if (enterprise.type == EnterpriseType.gasWarehouse) return _GazWarehouseStrategy();
      if (enterprise.type == EnterpriseType.gasPointOfSale) return _GazPosStrategy();
      return _GazStrategy();
    }
    if (enterprise.type.isMobileMoney) return _MobileMoneyStrategy();
    if (enterprise.type.isWater) return _EauMineraleStrategy();
    if (enterprise.type.isRealEstate) return _ImmobilierStrategy();
    if (enterprise.type.isShop) return _BoutiqueStrategy();
    
    return _GenericStrategy();
  }
}

// --- Concrete Strategies ---

class _GenericStrategy implements EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs() => const [
    Tab(text: 'Aperçu', icon: Icon(Icons.dashboard_outlined)),
    Tab(text: 'Équipe', icon: Icon(Icons.people_outline)),
    Tab(text: 'Info', icon: Icon(Icons.info_outline)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
    switch (index) {
      case 0: return const Center(child: Text('Aperçu Général'));
      case 1: return const Center(child: Text('Gestion Équipe'));
      case 2: return const Center(child: Text('Informations Légales'));
      case 3: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

class _GazStrategy implements EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs() => const [
    Tab(text: 'Aperçu', icon: Icon(Icons.dashboard_outlined)),
    Tab(text: 'Stock', icon: Icon(Icons.propane_tank_outlined)),
    Tab(text: 'Livraisons', icon: Icon(Icons.local_shipping_outlined)),
    Tab(text: 'Équipe', icon: Icon(Icons.people_outline)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
    switch (index) {
      case 0: return const Center(child: Text('Aperçu Gaz (Ventes, Rotations)'));
      case 1: return const Center(child: Text('Stock Bouteilles (Pleines/Vides/Consignées)'));
      case 2: return const Center(child: Text('Suivi Camions & Livraisons'));
      case 3: return const Center(child: Text('Équipe Gaz'));
      case 4: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

class _GazPosStrategy extends _GazStrategy {
   @override
  List<Tab> getTabs() => const [
    Tab(text: 'Aperçu', icon: Icon(Icons.dashboard_outlined)),
    Tab(text: 'Stock', icon: Icon(Icons.propane_tank_outlined)),
    Tab(text: 'Ventes', icon: Icon(Icons.receipt_long_outlined)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

    @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
    switch (index) {
      case 0: return const Center(child: Text('Aperçu Point de Vente'));
      case 1: return const Center(child: Text('Inventaire Bouteilles'));
      case 2: return const Center(child: Text('Historique Ventes'));
      case 3: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

class _GazWarehouseStrategy extends _GazStrategy {
  // Warehouse specific implementation - inherits from _GazStrategy for now
}

class _MobileMoneyStrategy implements EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs() => const [
    Tab(text: 'Trésorerie', icon: Icon(Icons.account_balance_wallet_outlined)),
    Tab(text: 'Commissions', icon: Icon(Icons.percent_outlined)),
    Tab(text: 'Opérations', icon: Icon(Icons.history_edu_outlined)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
     switch (index) {
      case 0: return const Center(child: Text('Solde Flottant & Espèces'));
      case 1: return const Center(child: Text('Commissions & Objectifs'));
      case 2: return const Center(child: Text('Journal des Transactions'));
      case 3: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

class _EauMineraleStrategy implements EnterpriseDashboardStrategy {
    @override
  List<Tab> getTabs() => const [
    Tab(text: 'Production', icon: Icon(Icons.water_drop_outlined)),
    Tab(text: 'Stock', icon: Icon(Icons.inventory_2_outlined)),
    Tab(text: 'Distribution', icon: Icon(Icons.local_shipping_outlined)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
     switch (index) {
      case 0: return const Center(child: Text('Sessions de Production'));
      case 1: return const Center(child: Text('Stock Sachets & Matières Premières'));
      case 2: return const Center(child: Text('Livraisons Eau'));
      case 3: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

class _ImmobilierStrategy implements EnterpriseDashboardStrategy {
      @override
  List<Tab> getTabs() => const [
    Tab(text: 'Biens', icon: Icon(Icons.home_work_outlined)),
    Tab(text: 'Loyers', icon: Icon(Icons.monetization_on_outlined)),
    Tab(text: 'Contrats', icon: Icon(Icons.description_outlined)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
     switch (index) {
      case 0: return const Center(child: Text('Parc Immobilier'));
      case 1: return const Center(child: Text('Suivi des Loyers'));
      case 2: return const Center(child: Text('Contrats de Bail'));
      case 3: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

class _BoutiqueStrategy implements EnterpriseDashboardStrategy {
    @override
  List<Tab> getTabs() => const [
    Tab(text: 'Ventes', icon: Icon(Icons.point_of_sale_outlined)),
    Tab(text: 'Stock', icon: Icon(Icons.inventory_2_outlined)),
    Tab(text: 'Caisse', icon: Icon(Icons.payments_outlined)),
    Tab(text: 'Audit', icon: Icon(Icons.history_outlined)),
  ];

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise) {
     switch (index) {
      case 0: return const Center(child: Text('Ventes Quotidiennes'));
      case 1: return const Center(child: Text('Inventaire Rayons'));
      case 2: return const Center(child: Text('Fermeture de Caisse'));
      case 3: return _buildAuditTab(context, ref, enterprise);
      default: return const SizedBox();
    }
  }
}

Widget _buildAuditTab(BuildContext context, WidgetRef ref, Enterprise enterprise) {
  final logsAsync = ref.watch(auditLogsForEntityProvider((type: 'enterprise', id: enterprise.id)));

  return logsAsync.when(
    data: (logs) {
      if (logs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Aucune activité enregistrée', 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) => AuditLogItem(log: logs[index]),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, s) => Center(child: Text('Erreur: $e')),
  );
}
