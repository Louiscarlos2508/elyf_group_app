import 'package:elyf_groupe_app/core/permissions/entities/user_role.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

/// Rôles prédéfinis pour tous les modules de l'application
/// Organisés par module et niveau hiérarchique
class PredefinedRoles {
  PredefinedRoles._();

  // ========================================
  // MODULE GAZ
  // ========================================

  /// Directeur Régional Gaz (Niveau Société)
  /// Supervise plusieurs points de vente, accès aux statistiques consolidées
  static final directeurRegionalGaz = UserRole(
    id: 'directeur_regional_gaz',
    name: 'Directeur Régional',
    description:
        'Supervise plusieurs points de vente, accès aux statistiques consolidées et gestion des tours',
    moduleId: 'gaz',
    allowedEnterpriseTypes: {EnterpriseType.gasCompany},
    permissions: {
      // Visualisation
      'view_dashboard',
      'view_reports',
      'view_sales',
      'view_stock',
      'view_expenses',

      // Gestion globale
      'manage_tours',
      'view_all_pos',
      'compare_pos_performance',
      'manage_suppliers',
    },
    isSystemRole: true,
  );

  /// Gestionnaire Logistique Gaz (Niveau Société)
  /// Gère les approvisionnements et tours pour tous les points de vente
  static final gestionnaireLogistiqueGaz = UserRole(
    id: 'gestionnaire_logistique_gaz',
    name: 'Gestionnaire Logistique',
    description:
        'Gère les approvisionnements, tours et transferts de stock entre points de vente',
    moduleId: 'gaz',
    allowedEnterpriseTypes: {EnterpriseType.gasCompany},
    permissions: {
      'manage_tours',
      'view_stock',
      'transfer_stock',
      'manage_suppliers',
      'view_dashboard',
      'view_reports',
    },
    isSystemRole: true,
  );

  /// Gérant Point de Vente Gaz (Niveau POS)
  /// Gestion complète d'un point de vente spécifique
  static final gerantPosGaz = UserRole(
    id: 'gerant_pos_gaz',
    name: 'Gérant Point de Vente',
    description:
        'Gestion complète d\'un point de vente : ventes, stock, dépenses, personnel',
    moduleId: 'gaz',
    allowedEnterpriseTypes: {EnterpriseType.gasPointOfSale},
    permissions: {
      'view_dashboard',
      'create_sale',
      'view_sales',
      'manage_local_stock',
      'view_stock',
      'create_expense',
      'view_expenses',
      'view_tours',
      'manage_pos_staff',
    },
    isSystemRole: true,
  );

  /// Vendeur Gaz (Niveau POS)
  /// Effectue les ventes et consulte le stock
  static final vendeurGaz = UserRole(
    id: 'vendeur_gaz',
    name: 'Vendeur',
    description: 'Effectue les ventes et consulte le stock disponible',
    moduleId: 'gaz',
    allowedEnterpriseTypes: {EnterpriseType.gasPointOfSale},
    permissions: {'create_sale', 'view_sales', 'view_stock', 'view_dashboard'},
    isSystemRole: true,
  );

  // ========================================
  // MODULE EAU MINÉRALE
  // ========================================

  /// Directeur Eau Minérale (Niveau Société)
  /// Supervise la production et la distribution
  static final directeurEau = UserRole(
    id: 'directeur_eau',
    name: 'Directeur Eau Minérale',
    description:
        'Supervise la production, les ventes et la distribution d\'eau minérale',
    moduleId: 'eau_minerale',
    allowedEnterpriseTypes: {EnterpriseType.waterEntity},
    permissions: {
      'view_dashboard',
      'view_reports',
      'view_production',
      'view_sales',
      'view_stock',
      'view_expenses',
      'view_salaries',
      'manage_suppliers',
    },
    isSystemRole: true,
  );

  /// Responsable Production (Niveau Usine)
  /// Gère les sessions de production
  static final responsableProduction = UserRole(
    id: 'responsable_production',
    name: 'Responsable Production',
    description:
        'Gère les sessions de production, le personnel et les équipements',
    moduleId: 'eau_minerale',
    allowedEnterpriseTypes: {EnterpriseType.waterFactory},
    permissions: {
      'view_dashboard',
      'create_production_session',
      'manage_production',
      'view_production',
      'manage_local_stock',
      'view_stock',
      'create_expense',
      'view_expenses',
      'manage_salaries',
      'view_salaries',
    },
    isSystemRole: true,
  );

  /// Gérant Point de Vente Eau (Niveau POS)
  /// Gestion d'un point de vente d'eau
  static final gerantPosEau = UserRole(
    id: 'gerant_pos_eau',
    name: 'Gérant Point de Vente Eau',
    description: 'Gestion complète d\'un point de vente d\'eau minérale',
    moduleId: 'eau_minerale',
    allowedEnterpriseTypes: {EnterpriseType.waterPointOfSale},
    permissions: {
      'view_dashboard',
      'create_sale',
      'view_sales',
      'manage_local_stock',
      'view_stock',
      'create_expense',
      'view_expenses',
      'manage_credits',
    },
    isSystemRole: true,
  );

  /// Vendeur Eau (Niveau POS)
  /// Effectue les ventes d'eau
  static final vendeurEau = UserRole(
    id: 'vendeur_eau',
    name: 'Vendeur Eau',
    description: 'Effectue les ventes d\'eau minérale',
    moduleId: 'eau_minerale',
    allowedEnterpriseTypes: {EnterpriseType.waterPointOfSale},
    permissions: {'create_sale', 'view_sales', 'view_stock', 'view_dashboard'},
    isSystemRole: true,
  );

  // ========================================
  // MODULE BOUTIQUE
  // ========================================

  /// Gérant Boutique (Niveau Principal)
  /// Gestion complète de la boutique
  static final gerantBoutique = UserRole(
    id: 'gerant_boutique',
    name: 'Gérant Boutique',
    description:
        'Gestion complète de la boutique : produits, ventes, stock, commandes',
    moduleId: 'boutique',
    allowedEnterpriseTypes: {EnterpriseType.shop},
    permissions: {
      'view_dashboard',
      'manage_products',
      'create_sale',
      'view_sales',
      'manage_stock',
      'view_stock',
      'manage_orders',
      'view_orders',
      'create_expense',
      'view_expenses',
      'manage_customers',
    },
    isSystemRole: true,
  );

  /// Vendeur Boutique (Niveau Principal)
  /// Effectue les ventes en boutique
  static final vendeurBoutique = UserRole(
    id: 'vendeur_boutique',
    name: 'Vendeur Boutique',
    description: 'Effectue les ventes et gère les commandes clients',
    moduleId: 'boutique',
    allowedEnterpriseTypes: {EnterpriseType.shop},
    permissions: {
      'create_sale',
      'view_sales',
      'view_products',
      'view_stock',
      'create_order',
      'view_orders',
      'view_dashboard',
    },
    isSystemRole: true,
  );

  // ========================================
  // MODULE MOBILE MONEY
  // ========================================

  /// Administrateur Orange Money (Agent Principal)
  /// Gère tout le réseau, transactions, liquidité et commissions
  static final omAdmin = UserRole(
    id: 'om_admin',
    name: 'Administrateur Orange Money',
    description:
        'Gestion complète du réseau Orange Money : transactions, sous-agents, commissions, liquidité',
    moduleId: 'orange_money',
    allowedEnterpriseTypes: {EnterpriseType.mobileMoneyAgent},
    permissions: {
      'view_dashboard',
      'view_network_dashboard',
      'create_transaction',
      'view_transactions',
      'view_child_transactions',
      'manage_float',
      'view_float',
      'manage_sub_agents',
      'view_commissions',
      'calculate_commissions',
      'pay_commissions',
      'validate_liquidity_discrepancy',
      'view_reports',
      'create_checkpoint',
      'view_liquidity',
    },
    isSystemRole: true,
  );

  /// Superviseur Orange Money
  /// Valide les commissions et surveille le réseau
  static final omSupervisor = UserRole(
    id: 'om_supervisor',
    name: 'Superviseur Orange Money',
    description:
        'Supervision du réseau, validation des commissions et écarts de liquidité',
    moduleId: 'orange_money',
    allowedEnterpriseTypes: {EnterpriseType.mobileMoneyAgent},
    permissions: {
      'view_dashboard',
      'view_network_dashboard',
      'view_transactions',
      'view_child_transactions',
      'view_float',
      'view_commissions',
      'validate_commissions',
      'validate_liquidity_discrepancy',
      'view_reports',
      'view_liquidity',
    },
    isSystemRole: true,
  );

  /// Agent Orange Money (Sous-Agent/Vendeur)
  /// Effectue les transactions et déclare ses commissions
  static final omAgent = UserRole(
    id: 'om_agent',
    name: 'Agent Orange Money',
    description: 'Effectue les transactions et gère sa caisse',
    moduleId: 'orange_money',
    allowedEnterpriseTypes: {EnterpriseType.mobileMoneySubAgent, EnterpriseType.mobileMoneyKiosk},
    permissions: {
      'view_dashboard',
      'create_transaction',
      'view_transactions',
      'view_float',
      'create_checkpoint',
      'view_liquidity',
      'declare_commission',
      'view_commissions',
    },
    isSystemRole: true,
  );

  // ========================================
  // RÔLES GÉNÉRIQUES (Tous modules)
  // ========================================

  /// Administrateur (Tous niveaux)
  /// Accès complet à toutes les fonctionnalités
  static final administrateur = UserRole(
    id: 'administrateur',
    name: 'Administrateur',
    description: 'Accès complet à toutes les fonctionnalités du système',
    moduleId: 'administration',
    allowedEnterpriseTypes: {}, // Tous niveaux
    permissions: {
      // Administration
      'manage_users',
      'manage_roles',
      'manage_enterprises',
      'manage_modules',

      // Toutes les permissions métier
      'view_dashboard',
      'view_reports',
      'manage_products',
      'create_sale',
      'view_sales',
      'manage_stock',
      'view_stock',
      'create_expense',
      'view_expenses',
      'manage_tours',
      'manage_production',
      'manage_salaries',
      'manage_suppliers',
    },
    isSystemRole: true,
  );

  /// Auditeur (Tous niveaux)
  /// Accès en lecture seule pour audit
  static final auditeur = UserRole(
    id: 'auditeur',
    name: 'Auditeur',
    description: 'Accès en lecture seule pour audit et contrôle',
    moduleId: 'administration',
    allowedEnterpriseTypes: {}, // Tous niveaux
    permissions: {
      'view_dashboard',
      'view_reports',
      'view_sales',
      'view_stock',
      'view_expenses',
      'view_production',
      'view_salaries',
      'view_transactions',
    },
    isSystemRole: true,
  );

  // ========================================
  // LISTE COMPLÈTE DES RÔLES
  // ========================================

  /// Tous les rôles prédéfinis organisés par module
  static final Map<String, List<UserRole>> rolesByModule = {
    'gaz': [
      directeurRegionalGaz,
      gestionnaireLogistiqueGaz,
      gerantPosGaz,
      vendeurGaz,
    ],
    'eau_minerale': [
      directeurEau,
      responsableProduction,
      gerantPosEau,
      vendeurEau,
    ],
    'boutique': [gerantBoutique, vendeurBoutique],
    'orange_money': [omAdmin, omSupervisor, omAgent],
    'administration': [administrateur, auditeur],
  };

  /// Tous les rôles prédéfinis (liste plate)
  static final List<UserRole> allRoles = [
    // Gaz
    directeurRegionalGaz,
    gestionnaireLogistiqueGaz,
    gerantPosGaz,
    vendeurGaz,

    // Eau Minérale
    directeurEau,
    responsableProduction,
    gerantPosEau,
    vendeurEau,

    // Boutique
    gerantBoutique,
    vendeurBoutique,

    // Mobile Money
    omAdmin,
    omSupervisor,
    omAgent,

    // Génériques
    administrateur,
    auditeur,
  ];

  /// Obtenir les rôles pour un module spécifique
  static List<UserRole> getRolesForModule(String moduleId) {
    return rolesByModule[moduleId] ?? [];
  }

  /// Obtenir les rôles compatibles avec un type d'entreprise
  static List<UserRole> getRolesForEnterpriseType(EnterpriseType type) {
    return allRoles.where((role) => role.canBeAssignedTo(type)).toList();
  }
}
