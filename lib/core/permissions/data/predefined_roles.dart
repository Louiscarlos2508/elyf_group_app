import 'package:elyf_groupe_app/core/permissions/entities/user_role.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

/// Rôles prédéfinis alignés strictement sur les personas des PRD.
/// Chaque module métier définit ses propres personas — aucun rôle global.
class PredefinedRoles {
  PredefinedRoles._();

  // ========================================
  // MODULE GAZ (PRD: 2 personas)
  // ========================================

  /// Gaz Enterprise Manager (PRD Persona: Enterprise / Module Level)
  /// Full Module Sovereignty: stock, pricing, POS networks, staff, reporting.
  static final gazEnterpriseManager = UserRole(
    id: 'gaz_enterprise_manager',
    name: 'Responsable Gaz',
    description:
        'Souveraineté totale sur le module : stock, prix, réseau POS, personnel et rapports',
    moduleId: 'gaz',
    allowedEnterpriseTypes: {EnterpriseType.gasCompany},
    permissions: {
      // Dashboard & Reports
      'view_dashboard',
      'view_reports',
      'download_reports',
      // Sales (retail + wholesale)
      'view_sales',
      'create_sale',
      'edit_sale',
      'delete_sale',
      'view_wholesale',
      'create_wholesale',
      // Stock & Cylinders
      'view_stock',
      'edit_stock',
      'view_cylinders',
      'manage_cylinders',
      'manage_inventory',
      // Tours & Logistics
      'view_tours',
      'create_tour',
      'edit_tour',
      // Leaks
      'view_leaks',
      'report_leak',
      // Expenses
      'view_expenses',
      'create_expense',
      'edit_expense',
      'delete_expense',
      // Treasury
      'view_treasury',
      'manage_treasury',
      // Settings
      'view_settings',
      'edit_settings',
      // Deliveries
      'view_deliveries',
      // Profile
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  /// Gas Retail Seller (PRD Persona: Operational Level)
  /// Front-line execution: high-speed sales, local stock, receipt printing.
  /// No access to management, settings, or global reports.
  static final gazRetailSeller = UserRole(
    id: 'gaz_retail_seller',
    name: 'Vendeur Gaz',
    description:
        'Exécution terrain : ventes rapides, consultation stock local, impression reçus',
    moduleId: 'gaz',
    allowedEnterpriseTypes: {EnterpriseType.gasPointOfSale},
    permissions: {
      'view_dashboard',
      'create_sale',
      'view_sales',
      'view_stock',
      'view_deliveries',
      'report_leak',
      'view_leaks',
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  // ========================================
  // MODULE EAU MINÉRALE (PRD: 2 personas)
  // ========================================

  /// Water Manager (PRD Persona: Enterprise Level)
  /// Supervision complète: production, stocks, fournisseurs, trésorerie.
  static final waterManager = UserRole(
    id: 'water_manager',
    name: 'Responsable Eau Minérale',
    description:
        'Supervision complète : production, stocks, fournisseurs, trésorerie et rapports',
    moduleId: 'eau_minerale',
    allowedEnterpriseTypes: {EnterpriseType.waterEntity},
    permissions: {
      // Dashboard & Reports
      'view_dashboard',
      'view_reports',
      'download_reports',
      // Production
      'view_production',
      'create_production',
      'edit_production',
      'delete_production',
      'configure_production',
      // Sales
      'view_sales',
      'create_sale',
      'edit_sale',
      'delete_sale',
      // Stock
      'view_stock',
      'edit_stock',
      // Credits
      'view_credits',
      'collect_payment',
      'view_credit_history',
      // Suppliers & Purchases
      'view_suppliers',
      'manage_suppliers',
      'view_purchases',
      'create_purchase',
      'validate_po',
      // Treasury & Sessions
      'close_session',
      'view_treasury',
      // Finances
      'view_finances',
      'create_expense',
      'edit_expense',
      'delete_expense',
      // Salaries
      'view_salaries',
      'create_salary',
      'edit_salary',
      'delete_salary',
      // Settings & Products
      'view_settings',
      'edit_settings',
      'manage_products',
      // Profile
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  /// Water Field Agent / Seller (PRD Persona: Operational Level)
  /// Vente directe, encaissement crédits, petite caisse.
  static final waterFieldAgent = UserRole(
    id: 'water_field_agent',
    name: 'Agent Terrain Eau',
    description:
        'Vente directe sur le terrain, encaissement crédits, gestion petite caisse',
    moduleId: 'eau_minerale',
    allowedEnterpriseTypes: {
      EnterpriseType.waterPointOfSale,
      EnterpriseType.waterFactory,
    },
    permissions: {
      'view_dashboard',
      'create_sale',
      'view_sales',
      'view_stock',
      'view_credits',
      'collect_payment',
      'view_credit_history',
      'create_expense',
      'view_finances',
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  // ========================================
  // MODULE BOUTIQUE (PRD: 1 persona)
  // ========================================

  /// Boutique Owner (PRD Persona: Manager / Agent — single-persona model)
  /// Total Ownership: catalogue, inventaire, approvisionnement, vente POS.
  static final boutiqueOwner = UserRole(
    id: 'boutique_owner',
    name: 'Propriétaire Boutique',
    description:
        'Propriété totale : catalogue, inventaire, approvisionnement et caisse POS',
    moduleId: 'boutique',
    allowedEnterpriseTypes: {EnterpriseType.shop},
    permissions: {
      // Dashboard & Reports
      'view_dashboard',
      'view_reports',
      'download_reports',
      // Sales & POS
      'view_sales',
      'create_sale',
      'edit_sale',
      'delete_sale',
      'use_pos',
      // Products
      'view_products',
      'create_product',
      'edit_product',
      'delete_product',
      // Stock
      'view_stock',
      'edit_stock',
      // Purchases
      'view_purchases',
      'create_purchase',
      'edit_purchase',
      // Expenses
      'view_expenses',
      'create_expense',
      'edit_expense',
      'delete_expense',
      // Treasury
      'view_treasury',
      'edit_treasury',
      // Suppliers
      'view_suppliers',
      'edit_suppliers',
      // Settings
      'view_settings',
      // Profile
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  // ========================================
  // MODULE IMMOBILIER (PRD: 1 persona)
  // ========================================

  /// Immobilier Manager (PRD Persona: Enterprise / Operational)
  /// Full Sovereignty: portfolio, contrats, encaissements, maintenance.
  static final immobilierManager = UserRole(
    id: 'immobilier_manager',
    name: 'Responsable Immobilier',
    description:
        'Souveraineté totale : portfolio, contrats, encaissements loyers, maintenance et rapports',
    moduleId: 'immobilier',
    allowedEnterpriseTypes: {EnterpriseType.realEstateAgency},
    permissions: {
      // Dashboard & Reports
      'view_dashboard',
      'view_reports',
      'download_reports',
      // Properties
      'view_properties',
      'create_property',
      'edit_property',
      'delete_property',
      // Tenants
      'view_tenants',
      'create_tenant',
      'edit_tenant',
      'delete_tenant',
      // Contracts
      'view_contracts',
      'create_contract',
      'edit_contract',
      'terminate_contract',
      'delete_contract',
      // Payments
      'view_payments',
      'create_payment',
      'edit_payment',
      'delete_payment',
      // Expenses
      'view_expenses',
      'create_expense',
      'edit_expense',
      'delete_expense',
      // Maintenance
      'view_maintenance',
      'create_maintenance',
      'edit_maintenance',
      'delete_maintenance',
      // Treasury
      'view_treasury',
      'create_treasury_operation',
      // Trash & Restore
      'view_trash',
      'restore_property',
      'restore_tenant',
      'restore_contract',
      'restore_payment',
      'restore_expense',
      // Settings
      'manage_settings',
      // Profile
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  // ========================================
  // MODULE ORANGE MONEY (PRD: 2 personas)
  // ========================================

  /// OM Manager (PRD Persona: Enterprise Level)
  /// Gestion réseau: transactions, float, commissions, sous-agents.
  static final omManager = UserRole(
    id: 'om_manager',
    name: 'Responsable Orange Money',
    description:
        'Gestion complète du réseau : transactions, sous-agents, commissions, liquidité et rapports',
    moduleId: 'orange_money',
    allowedEnterpriseTypes: {EnterpriseType.mobileMoneyAgent},
    permissions: {
      'view_dashboard',
      'view_network_dashboard',
      'create_transaction',
      'view_transactions',
      'edit_transaction',
      'cancel_transaction',
      'view_child_transactions',
      // Agents
      'view_agents',
      'create_agent',
      'edit_agent',
      'delete_agent',
      // Float & Liquidity
      'view_liquidity',
      'create_checkpoint',
      'validate_liquidity_discrepancy',
      // Commissions
      'view_commissions',
      'calculate_commissions',
      'pay_commissions',
      // Reports
      'view_reports',
      'download_reports',
      // Settings
      'view_settings',
      'edit_settings',
      // Profile
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  /// OM Agent (PRD Persona: Operational Level)
  /// Front-line: transactions, gestion caisse, déclaration commissions.
  static final omAgent = UserRole(
    id: 'om_agent',
    name: 'Agent Orange Money',
    description: 'Effectue les transactions et gère sa caisse',
    moduleId: 'orange_money',
    allowedEnterpriseTypes: {
      EnterpriseType.mobileMoneySubAgent,
      EnterpriseType.mobileMoneyKiosk,
    },
    permissions: {
      'view_dashboard',
      'create_transaction',
      'view_transactions',
      'view_liquidity',
      'create_checkpoint',
      'declare_commission',
      'view_commissions',
      'view_profile',
      'edit_profile',
      'change_password',
    },
    isSystemRole: true,
  );

  // ========================================
  // LISTES ET UTILITAIRES
  // ========================================

  /// Tous les rôles prédéfinis organisés par module
  static final Map<String, List<UserRole>> rolesByModule = {
    'gaz': [gazEnterpriseManager, gazRetailSeller],
    'eau_minerale': [waterManager, waterFieldAgent],
    'boutique': [boutiqueOwner],
    'immobilier': [immobilierManager],
    'orange_money': [omManager, omAgent],
  };

  /// Tous les rôles prédéfinis (liste plate)
  static final List<UserRole> allRoles = [
    // Gaz
    gazEnterpriseManager,
    gazRetailSeller,
    // Eau Minérale
    waterManager,
    waterFieldAgent,
    // Boutique
    boutiqueOwner,
    // Immobilier
    immobilierManager,
    // Orange Money
    omManager,
    omAgent,
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
