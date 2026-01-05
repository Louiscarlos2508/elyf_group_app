import '../../../../core/permissions/entities/module_permission.dart';

/// Permissions for the Eau Minérale module using the centralized system.
class EauMineralePermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'eau_minerale',
    description: 'Permet de voir le tableau de bord',
  );

  // Production
  static const viewProduction = ActionPermission(
    id: 'view_production',
    name: 'Voir la production',
    module: 'eau_minerale',
    description: 'Permet de voir les productions',
  );

  static const createProduction = ActionPermission(
    id: 'create_production',
    name: 'Créer une production',
    module: 'eau_minerale',
    description: 'Permet de créer une nouvelle production',
  );

  static const editProduction = ActionPermission(
    id: 'edit_production',
    name: 'Modifier une production',
    module: 'eau_minerale',
    description: 'Permet de modifier une production existante',
  );

  static const deleteProduction = ActionPermission(
    id: 'delete_production',
    name: 'Supprimer une production',
    module: 'eau_minerale',
    description: 'Permet de supprimer une production',
  );

  // Sales
  static const viewSales = ActionPermission(
    id: 'view_sales',
    name: 'Voir les ventes',
    module: 'eau_minerale',
    description: 'Permet de voir les ventes',
  );

  static const createSale = ActionPermission(
    id: 'create_sale',
    name: 'Créer une vente',
    module: 'eau_minerale',
    description: 'Permet de créer une nouvelle vente',
  );

  static const editSale = ActionPermission(
    id: 'edit_sale',
    name: 'Modifier une vente',
    module: 'eau_minerale',
    description: 'Permet de modifier une vente existante',
  );

  static const deleteSale = ActionPermission(
    id: 'delete_sale',
    name: 'Supprimer une vente',
    module: 'eau_minerale',
    description: 'Permet de supprimer une vente',
  );

  // Stock
  static const viewStock = ActionPermission(
    id: 'view_stock',
    name: 'Voir le stock',
    module: 'eau_minerale',
    description: 'Permet de voir le stock',
  );

  static const editStock = ActionPermission(
    id: 'edit_stock',
    name: 'Modifier le stock',
    module: 'eau_minerale',
    description: 'Permet de modifier le stock',
  );

  // Credits
  static const viewCredits = ActionPermission(
    id: 'view_credits',
    name: 'Voir les crédits',
    module: 'eau_minerale',
    description: 'Permet de voir les crédits clients',
  );

  static const collectPayment = ActionPermission(
    id: 'collect_payment',
    name: 'Encaisser un paiement',
    module: 'eau_minerale',
    description: 'Permet d\'encaisser un paiement client',
  );

  static const viewCreditHistory = ActionPermission(
    id: 'view_credit_history',
    name: 'Voir l\'historique des crédits',
    module: 'eau_minerale',
    description: 'Permet de voir l\'historique des crédits',
  );

  // Finances
  static const viewFinances = ActionPermission(
    id: 'view_finances',
    name: 'Voir les finances',
    module: 'eau_minerale',
    description: 'Permet de voir les dépenses',
  );

  static const createExpense = ActionPermission(
    id: 'create_expense',
    name: 'Créer une dépense',
    module: 'eau_minerale',
    description: 'Permet de créer une nouvelle dépense',
  );

  static const editExpense = ActionPermission(
    id: 'edit_expense',
    name: 'Modifier une dépense',
    module: 'eau_minerale',
    description: 'Permet de modifier une dépense existante',
  );

  static const deleteExpense = ActionPermission(
    id: 'delete_expense',
    name: 'Supprimer une dépense',
    module: 'eau_minerale',
    description: 'Permet de supprimer une dépense',
  );

  // Salaries
  static const viewSalaries = ActionPermission(
    id: 'view_salaries',
    name: 'Voir les salaires',
    module: 'eau_minerale',
    description: 'Permet de voir les salaires',
  );

  static const createSalary = ActionPermission(
    id: 'create_salary',
    name: 'Créer un salaire',
    module: 'eau_minerale',
    description: 'Permet de créer un paiement de salaire',
  );

  static const editSalary = ActionPermission(
    id: 'edit_salary',
    name: 'Modifier un salaire',
    module: 'eau_minerale',
    description: 'Permet de modifier un paiement de salaire',
  );

  static const deleteSalary = ActionPermission(
    id: 'delete_salary',
    name: 'Supprimer un salaire',
    module: 'eau_minerale',
    description: 'Permet de supprimer un paiement de salaire',
  );

  // Reports
  static const viewReports = ActionPermission(
    id: 'view_reports',
    name: 'Voir les rapports',
    module: 'eau_minerale',
    description: 'Permet de voir les rapports',
  );

  static const downloadReports = ActionPermission(
    id: 'download_reports',
    name: 'Télécharger les rapports',
    module: 'eau_minerale',
    description: 'Permet de télécharger les rapports',
  );

  // Settings
  static const viewSettings = ActionPermission(
    id: 'view_settings',
    name: 'Voir les paramètres',
    module: 'eau_minerale',
    description: 'Permet de voir les paramètres',
  );

  static const editSettings = ActionPermission(
    id: 'edit_settings',
    name: 'Modifier les paramètres',
    module: 'eau_minerale',
    description: 'Permet de modifier les paramètres généraux',
  );

  static const manageProducts = ActionPermission(
    id: 'manage_products',
    name: 'Gérer les produits',
    module: 'eau_minerale',
    description: 'Permet de gérer le catalogue de produits',
  );

  static const configureProduction = ActionPermission(
    id: 'configure_production',
    name: 'Configurer la production',
    module: 'eau_minerale',
    description: 'Permet de configurer les périodes de production',
  );

  // Profile
  static const viewProfile = ActionPermission(
    id: 'view_profile',
    name: 'Voir le profil',
    module: 'eau_minerale',
    description: 'Permet de voir son profil',
  );

  static const editProfile = ActionPermission(
    id: 'edit_profile',
    name: 'Modifier le profil',
    module: 'eau_minerale',
    description: 'Permet de modifier son profil',
  );

  static const changePassword = ActionPermission(
    id: 'change_password',
    name: 'Changer le mot de passe',
    module: 'eau_minerale',
    description: 'Permet de changer son mot de passe',
  );

  /// All permissions for the module
  static const all = [
    viewDashboard,
    viewProduction,
    createProduction,
    editProduction,
    deleteProduction,
    viewSales,
    createSale,
    editSale,
    deleteSale,
    viewStock,
    editStock,
    viewCredits,
    collectPayment,
    viewCreditHistory,
    viewFinances,
    createExpense,
    editExpense,
    deleteExpense,
    viewSalaries,
    createSalary,
    editSalary,
    deleteSalary,
    viewReports,
    downloadReports,
    viewSettings,
    editSettings,
    manageProducts,
    configureProduction,
    viewProfile,
    editProfile,
    changePassword,
  ];
}

