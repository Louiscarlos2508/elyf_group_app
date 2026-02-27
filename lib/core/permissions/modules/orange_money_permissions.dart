import '../entities/module_permission.dart';

/// Permissions for the Orange Money module using the centralized system.
class OrangeMoneyPermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'orange_money',
    description: 'Permet de voir le tableau de bord',
  );

  // Transactions
  static const viewTransactions = ActionPermission(
    id: 'view_transactions',
    name: 'Voir les transactions',
    module: 'orange_money',
    description: 'Permet de voir les transactions',
  );

  static const createTransaction = ActionPermission(
    id: 'create_transaction',
    name: 'Créer une transaction',
    module: 'orange_money',
    description: 'Permet de créer une transaction (cash-in/cash-out)',
  );

  static const editTransaction = ActionPermission(
    id: 'edit_transaction',
    name: 'Modifier une transaction',
    module: 'orange_money',
    description: 'Permet de modifier une transaction',
  );

  static const cancelTransaction = ActionPermission(
    id: 'cancel_transaction',
    name: 'Annuler une transaction',
    module: 'orange_money',
    description: 'Permet d\'annuler une transaction',
  );

  // Agents
  static const viewAgents = ActionPermission(
    id: 'view_agents',
    name: 'Voir les agents',
    module: 'orange_money',
    description: 'Permet de voir les agents',
  );

  static const createAgent = ActionPermission(
    id: 'create_agent',
    name: 'Créer un agent',
    module: 'orange_money',
    description: 'Permet de créer un nouvel agent',
  );

  static const editAgent = ActionPermission(
    id: 'edit_agent',
    name: 'Modifier un agent',
    module: 'orange_money',
    description: 'Permet de modifier un agent',
  );

  static const deleteAgent = ActionPermission(
    id: 'delete_agent',
    name: 'Supprimer un agent',
    module: 'orange_money',
    description: 'Permet de supprimer un agent',
  );

  // Commissions
  static const viewCommissions = ActionPermission(
    id: 'view_commissions',
    name: 'Voir les commissions',
    module: 'orange_money',
    description: 'Permet de voir les commissions',
  );

  static const calculateCommissions = ActionPermission(
    id: 'calculate_commissions',
    name: 'Calculer les commissions',
    module: 'orange_money',
    description: 'Permet de calculer les commissions',
  );

  static const payCommissions = ActionPermission(
    id: 'pay_commissions',
    name: 'Payer les commissions',
    module: 'orange_money',
    description: 'Permet de payer les commissions',
  );

  // Liquidity
  static const viewLiquidity = ActionPermission(
    id: 'view_liquidity',
    name: 'Voir la liquidité',
    module: 'orange_money',
    description: 'Permet de voir la liquidité',
  );

  static const createCheckpoint = ActionPermission(
    id: 'create_checkpoint',
    name: 'Créer un point de contrôle',
    module: 'orange_money',
    description: 'Permet de créer un point de contrôle de liquidité',
  );

  static const manageInternalSupply = ActionPermission(
    id: 'manage_internal_supply',
    name: 'Gérer l\'approvisionnement interne',
    module: 'orange_money',
    description: 'Permet de recharger ou retirer de la liquidité aux agents/agences',
  );

  // Reports
  static const viewReports = ActionPermission(
    id: 'view_reports',
    name: 'Voir les rapports',
    module: 'orange_money',
    description: 'Permet de voir les rapports',
  );

  static const downloadReports = ActionPermission(
    id: 'download_reports',
    name: 'Télécharger les rapports',
    module: 'orange_money',
    description: 'Permet de télécharger les rapports',
  );

  // Settings
  static const viewSettings = ActionPermission(
    id: 'view_settings',
    name: 'Voir les paramètres',
    module: 'orange_money',
    description: 'Permet de voir les paramètres',
  );

  static const editSettings = ActionPermission(
    id: 'edit_settings',
    name: 'Modifier les paramètres',
    module: 'orange_money',
    description: 'Permet de modifier les paramètres',
  );

  // Profile
  static const viewProfile = ActionPermission(
    id: 'view_profile',
    name: 'Voir le profil',
    module: 'orange_money',
    description: 'Permet de voir son profil',
  );

  static const editProfile = ActionPermission(
    id: 'edit_profile',
    name: 'Modifier le profil',
    module: 'orange_money',
    description: 'Permet de modifier son profil',
  );

  static const changePassword = ActionPermission(
    id: 'change_password',
    name: 'Changer le mot de passe',
    module: 'orange_money',
    description: 'Permet de changer son mot de passe',
  );

  /// All permissions for the module
  static const all = [
    viewDashboard,
    viewTransactions,
    createTransaction,
    editTransaction,
    cancelTransaction,
    viewAgents,
    createAgent,
    editAgent,
    deleteAgent,
    viewCommissions,
    calculateCommissions,
    payCommissions,
    viewLiquidity,
    createCheckpoint,
    viewReports,
    downloadReports,
    viewSettings,
    editSettings,
    viewProfile,
    editProfile,
    changePassword,
    manageInternalSupply,
    
    // Hierarchy & Validation
    viewNetworkDashboard,
    viewChildTransactions,
    validateLiquidityDiscrepancy,
    declareCommission,
  ];

  // Hierarchy
  static const viewNetworkDashboard = ActionPermission(
    id: 'view_network_dashboard',
    name: 'Voir le tableau de bord réseau',
    module: 'orange_money',
    description: 'Permet de voir les statistiques consolidées du réseau',
  );

  static const viewChildTransactions = ActionPermission(
    id: 'view_child_transactions',
    name: 'Voir les transactions des sous-agents',
    module: 'orange_money',
    description: 'Permet de voir les transactions des entités filles',
  );

  static const validateLiquidityDiscrepancy = ActionPermission(
    id: 'validate_liquidity_discrepancy',
    name: 'Valider les écarts de liquidité',
    module: 'orange_money',
    description: 'Permet de valider les justifications d\'écart de liquidité',
  );

  static const declareCommission = ActionPermission(
    id: 'declare_commission',
    name: 'Déclarer une commission',
    module: 'orange_money',
    description: 'Permet de déclarer une commission mensuelle',
  );
}
