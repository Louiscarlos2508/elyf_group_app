import 'package:flutter/material.dart';

/// Informations sur les sections développées dans un module
class ModuleSectionsInfo {
  const ModuleSectionsInfo({required this.moduleId, required this.sections});

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
      const ModuleSection(
        id: 'activity',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec résumé de la journée',
      ),
      const ModuleSection(
        id: 'production',
        name: 'Production',
        icon: Icons.factory_outlined,
        description: 'Gestion des sessions de production',
      ),
      const ModuleSection(
        id: 'sales',
        name: 'Ventes',
        icon: Icons.point_of_sale,
        description: 'Gestion des ventes de sachets d\'eau',
      ),
      const ModuleSection(
        id: 'stock',
        name: 'Stock',
        icon: Icons.inventory_2_outlined,
        description: 'Gestion des stocks (bobines, emballages, produits finis)',
      ),
      const ModuleSection(
        id: 'clients',
        name: 'Crédits',
        icon: Icons.credit_card,
        description: 'Gestion des clients et crédits',
      ),
      const ModuleSection(
        id: 'finances',
        name: 'Dépenses',
        icon: Icons.receipt_long,
        description: 'Gestion des dépenses',
      ),
      const ModuleSection(
        id: 'salaries',
        name: 'Salaires',
        icon: Icons.people,
        description: 'Gestion des salaires',
      ),
      const ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.description,
        description: 'Rapports de production, ventes, dépenses, etc.',
      ),
      const ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person,
        description: 'Profil utilisateur',
      ),
      const ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings,
        description: 'Configuration du module',
      ),
    ],
    'boutique': [
      const ModuleSection(
        id: 'dashboard',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec KPIs',
      ),
      const ModuleSection(
        id: 'pos',
        name: 'Caisse (POS)',
        icon: Icons.point_of_sale,
        description: 'Point de vente pour les ventes physiques',
      ),
      const ModuleSection(
        id: 'catalog',
        name: 'Produits',
        icon: Icons.inventory_2_outlined,
        description: 'Gestion du catalogue de produits',
      ),
      const ModuleSection(
        id: 'expenses',
        name: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        description: 'Gestion des dépenses de la boutique',
      ),
      const ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.assessment,
        description: 'Rapports de ventes, achats, dépenses, profits',
      ),
      const ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'immobilier': [
      const ModuleSection(
        id: 'dashboard',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec KPIs',
      ),
      const ModuleSection(
        id: 'properties',
        name: 'Propriétés',
        icon: Icons.home_outlined,
        description: 'Liste et gestion des propriétés immobilières',
      ),
      const ModuleSection(
        id: 'tenants',
        name: 'Locataires',
        icon: Icons.people_outlined,
        description: 'Gestion des locataires',
      ),
      const ModuleSection(
        id: 'contracts',
        name: 'Contrats',
        icon: Icons.description_outlined,
        description: 'Gestion des contrats de location',
      ),
      const ModuleSection(
        id: 'payments',
        name: 'Paiements',
        icon: Icons.payment_outlined,
        description: 'Gestion des paiements de loyers',
      ),
      const ModuleSection(
        id: 'expenses',
        name: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        description: 'Gestion des dépenses liées aux propriétés',
      ),
      const ModuleSection(
        id: 'maintenance',
        name: 'Maintenance',
        icon: Icons.build_outlined,
        description: 'Tickets de maintenance des propriétés',
      ),
      const ModuleSection(
        id: 'treasury',
        name: 'Trésorerie',
        icon: Icons.account_balance_outlined,
        description: 'Opérations de trésorerie',
      ),
      const ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.assessment_outlined,
        description: 'Rapports immobiliers',
      ),
      const ModuleSection(
        id: 'trash',
        name: 'Corbeille',
        icon: Icons.delete_outline,
        description: 'Éléments supprimés (restauration)',
      ),
      const ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings_outlined,
        description: 'Configuration du module',
      ),
      const ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'orange_money': [
      const ModuleSection(
        id: 'transactions',
        name: 'Transactions',
        icon: Icons.swap_horiz,
        description: 'Nouvelle transaction / Historique',
      ),
      const ModuleSection(
        id: 'agents',
        name: 'Agents Affiliés',
        icon: Icons.people_outline,
        description: 'Gestion des agents Orange Money',
      ),
      const ModuleSection(
        id: 'liquidity',
        name: 'Liquidité',
        icon: Icons.wallet,
        description: 'Gestion de la liquidité',
      ),
      const ModuleSection(
        id: 'commissions',
        name: 'Commissions',
        icon: Icons.account_balance_wallet,
        description: 'Gestion des commissions',
      ),
      const ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.description,
        description: 'Rapports des transactions et commissions',
      ),
      const ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings,
        description: 'Configuration du module',
      ),
      const ModuleSection(
        id: 'hierarchy',
        name: 'Réseau & Hiérarchie',
        icon: Icons.account_tree_outlined,
        description: 'Gestion du réseau et des permissions de visibilité multiniveaux',
      ),
      const ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'gaz': [
      const ModuleSection(
        id: 'dashboard',
        name: 'Tableau',
        icon: Icons.dashboard_outlined,
        description: 'Vue d\'ensemble avec KPIs',
      ),
      const ModuleSection(
        id: 'retail',
        name: 'Vente Détail',
        icon: Icons.store_outlined,
        description: 'Vente au détail de bouteilles de gaz',
      ),
      const ModuleSection(
        id: 'wholesale',
        name: 'Vente Gros',
        icon: Icons.local_shipping_outlined,
        description: 'Vente en gros',
      ),
      const ModuleSection(
        id: 'stock',
        name: 'Stock',
        icon: Icons.inventory_2_outlined,
        description: 'Gestion des stocks de bouteilles',
      ),
      const ModuleSection(
        id: 'approvisionnement',
        name: 'Approvisionnement',
        icon: Icons.inventory_outlined,
        description: 'Gestion des tours d\'approvisionnement',
      ),
      const ModuleSection(
        id: 'cylinder_leak',
        name: 'Pertes/Fuites',
        icon: Icons.warning_outlined,
        description: 'Gestion des bouteilles avec fuites/perdus',
      ),
      const ModuleSection(
        id: 'expenses',
        name: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        description: 'Gestion des dépenses',
      ),
      const ModuleSection(
        id: 'reports',
        name: 'Rapports',
        icon: Icons.description_outlined,
        description: 'Rapports du module gaz',
      ),
      const ModuleSection(
        id: 'settings',
        name: 'Paramètres',
        icon: Icons.settings_outlined,
        description: 'Configuration du module',
      ),
      const ModuleSection(
        id: 'profile',
        name: 'Profil',
        icon: Icons.person_outline,
        description: 'Profil utilisateur',
      ),
    ],
    'administration': [
      const ModuleSection(
        id: 'enterprises',
        name: 'Entreprises',
        icon: Icons.business,
        description: 'Gestion des entreprises et de la hiérarchie',
      ),
      const ModuleSection(
        id: 'users',
        name: 'Utilisateurs',
        icon: Icons.people_alt_outlined,
        description: 'Gestion des utilisateurs et de leurs comptes',
      ),
      const ModuleSection(
        id: 'roles',
        name: 'Rôles & Permissions',
        icon: Icons.shield_outlined,
        description: 'Définition des rôles et des droits d\'accès',
      ),
      const ModuleSection(
        id: 'modules',
        name: 'Modules',
        icon: Icons.view_module_outlined,
        description: 'Activation et configuration des modules métiers',
      ),
      const ModuleSection(
        id: 'audit',
        name: 'Journal d\'Audit',
        icon: Icons.history_edu_outlined,
        description: 'Historique des actions effectuées sur le système',
      ),
      const ModuleSection(
        id: 'profile',
        name: 'Profil & Sécurité',
        icon: Icons.manage_accounts_outlined,
        description: 'Gestion du profil administrateur et mot de passe',
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
        .map(
          (entry) =>
              ModuleSectionsInfo(moduleId: entry.key, sections: entry.value),
        )
        .toList();
  }
}
