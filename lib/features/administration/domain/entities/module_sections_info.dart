import 'package:flutter/material.dart';

/// Informations sur les sections développées dans un module
class ModuleSectionsInfo {
  const ModuleSectionsInfo({
    required this.moduleId,
    required this.sections,
  });

  final String moduleId;
  final List<ModuleSection> sections;
}

/// Information sur une section d'un module
class ModuleSection {
  const ModuleSection({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
  });

  final String id;
  final String name;
  final IconData icon;
  final String? description;
}

/// Informations sur les sections développées dans chaque module
class ModuleSectionsRegistry {
  static Map<String, List<ModuleSection>> get _sectionsByModule => {
    'eau_minerale': [
      ModuleSection(
        id: 'activity',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec résumé de la journée',
      ),
      ModuleSection(
        id: 'production',
        name: 'Production',
        icon: Icons.factory_outlined,
        description: 'Gestion des sessions de production',
      ),
      ModuleSection(
        id: 'sales',
        name: 'Ventes',
        icon: Icons.point_of_sale,
        description: 'Gestion des ventes de sachets d\'eau',
      ),
      ModuleSection(
        id: 'stock',
        name: 'Stock',
        icon: Icons.inventory_2_outlined,
        description: 'Gestion des stocks (bobines, emballages, produits finis)',
      ),
      ModuleSection(
        id: 'clients',
        name: 'Crédits',
        icon: Icons.credit_card,
        description: 'Gestion des clients et crédits',
      ),
      ModuleSection(
        id: 'finances',
        name: 'Dépenses',
        icon: Icons.receipt_long,
        description: 'Gestion des dépenses',
      ),
      ModuleSection(
        id: 'salaries',
        name: 'Salaires',
        icon: Icons.people,
        description: 'Gestion des salaires',
      ),
      ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.description,
        description: 'Rapports de production, ventes, dépenses, etc.',
      ),
      ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person,
        description: 'Profil utilisateur',
      ),
      ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings,
        description: 'Configuration du module',
      ),
    ],
    'boutique': [
      ModuleSection(
        id: 'dashboard',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec KPIs',
      ),
      ModuleSection(
        id: 'pos',
        name: 'Caisse (POS)',
        icon: Icons.point_of_sale,
        description: 'Point de vente pour les ventes physiques',
      ),
      ModuleSection(
        id: 'catalog',
        name: 'Produits',
        icon: Icons.inventory_2_outlined,
        description: 'Gestion du catalogue de produits',
      ),
      ModuleSection(
        id: 'expenses',
        name: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        description: 'Gestion des dépenses de la boutique',
      ),
      ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.assessment,
        description: 'Rapports de ventes, achats, dépenses, profits',
      ),
      ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'immobilier': [
      ModuleSection(
        id: 'dashboard',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec KPIs',
      ),
      ModuleSection(
        id: 'properties',
        name: 'Propriétés',
        icon: Icons.home_outlined,
        description: 'Liste et gestion des propriétés immobilières',
      ),
      ModuleSection(
        id: 'tenants',
        name: 'Locataires',
        icon: Icons.people_outlined,
        description: 'Gestion des locataires',
      ),
      ModuleSection(
        id: 'contracts',
        name: 'Contrats',
        icon: Icons.description_outlined,
        description: 'Gestion des contrats de location',
      ),
      ModuleSection(
        id: 'payments',
        name: 'Paiements',
        icon: Icons.payment_outlined,
        description: 'Gestion des paiements de loyers',
      ),
      ModuleSection(
        id: 'expenses',
        name: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        description: 'Gestion des dépenses liées aux propriétés',
      ),
      ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.assessment_outlined,
        description: 'Rapports immobiliers',
      ),
      ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'orange_money': [
      ModuleSection(
        id: 'transactions',
        name: 'Transactions',
        icon: Icons.swap_horiz,
        description: 'Nouvelle transaction / Historique',
      ),
      ModuleSection(
        id: 'agents',
        name: 'Agents Affiliés',
        icon: Icons.people_outline,
        description: 'Gestion des agents Orange Money',
      ),
      ModuleSection(
        id: 'liquidity',
        name: 'Liquidité',
        icon: Icons.wallet,
        description: 'Gestion de la liquidité',
      ),
      ModuleSection(
        id: 'commissions',
        name: 'Commissions',
        icon: Icons.account_balance_wallet,
        description: 'Gestion des commissions',
      ),
      ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.description,
        description: 'Rapports des transactions et commissions',
      ),
      ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings,
        description: 'Configuration du module',
      ),
      ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'gaz': [
      ModuleSection(
        id: 'dashboard',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec KPIs',
      ),
      ModuleSection(
        id: 'retail',
        name: 'Vente Détail',
        icon: Icons.store_outlined,
        description: 'Vente au détail de bouteilles de gaz',
      ),
      ModuleSection(
        id: 'wholesale',
        name: 'Vente Gros',
        icon: Icons.local_shipping_outlined,
        description: 'Vente en gros',
      ),
      ModuleSection(
        id: 'stock',
        name: 'Stock',
        icon: Icons.inventory_2_outlined,
        description: 'Gestion des stocks de bouteilles',
      ),
      ModuleSection(
        id: 'approvisionnement',
        name: 'Approvisionnement',
        icon: Icons.inventory_outlined,
        description: 'Gestion des tours d\'approvisionnement',
      ),
      ModuleSection(
        id: 'cylinder_leak',
        name: 'Pertes/Fuites',
        icon: Icons.warning_outlined,
        description: 'Gestion des bouteilles avec fuites/perdus',
      ),
      ModuleSection(
        id: 'expenses',
        name: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        description: 'Gestion des dépenses',
      ),
      ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.description_outlined,
        description: 'Rapports du module gaz',
      ),
      ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings_outlined,
        description: 'Configuration du module',
      ),
      ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
  };

  /// Récupère les sections développées pour un module
  static List<ModuleSection> getSectionsForModule(String moduleId) {
    return _sectionsByModule[moduleId] ?? [];
  }

  /// Récupère toutes les informations de sections pour tous les modules
  static List<ModuleSectionsInfo> getAllModulesSections() {
    return _sectionsByModule.entries
        .map((entry) => ModuleSectionsInfo(
              moduleId: entry.key,
              sections: entry.value,
            ))
        .toList();
  }
}

