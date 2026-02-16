import '../entities/module_permission.dart';

/// Permissions for the Gaz module using the centralized system.
class GazPermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'gaz',
    description: 'Permet de voir le tableau de bord',
  );

  // Sales
  static const viewSales = ActionPermission(
    id: 'view_sales',
    name: 'Voir les ventes',
    module: 'gaz',
    description: 'Permet de voir les ventes de gaz',
  );

  static const createSale = ActionPermission(
    id: 'create_sale',
    name: 'Créer une vente',
    module: 'gaz',
    description: 'Permet de créer une nouvelle vente',
  );

  static const editSale = ActionPermission(
    id: 'edit_sale',
    name: 'Modifier une vente',
    module: 'gaz',
    description: 'Permet de modifier une vente existante',
  );

  static const deleteSale = ActionPermission(
    id: 'delete_sale',
    name: 'Supprimer une vente',
    module: 'gaz',
    description: 'Permet de supprimer une vente',
  );

  // Wholesale
  static const viewWholesale = ActionPermission(
    id: 'view_wholesale',
    name: 'Voir les ventes en gros',
    module: 'gaz',
    description: 'Permet de voir les ventes en gros',
  );

  static const createWholesale = ActionPermission(
    id: 'create_wholesale',
    name: 'Créer une vente en gros',
    module: 'gaz',
    description: 'Permet de créer une vente en gros',
  );

  // Stock
  static const viewStock = ActionPermission(
    id: 'view_stock',
    name: 'Voir le stock',
    module: 'gaz',
    description: 'Permet de voir le stock de bouteilles',
  );

  static const editStock = ActionPermission(
    id: 'edit_stock',
    name: 'Modifier le stock',
    module: 'gaz',
    description: 'Permet de modifier le stock',
  );

  // Cylinders
  static const viewCylinders = ActionPermission(
    id: 'view_cylinders',
    name: 'Voir les bouteilles',
    module: 'gaz',
    description: 'Permet de voir les bouteilles de gaz',
  );

  static const manageCylinders = ActionPermission(
    id: 'manage_cylinders',
    name: 'Gérer les bouteilles',
    module: 'gaz',
    description: 'Permet de gérer les bouteilles',
  );

  // Tours
  static const viewTours = ActionPermission(
    id: 'view_tours',
    name: 'Voir les tournées',
    module: 'gaz',
    description: 'Permet de voir les tournées',
  );

  static const createTour = ActionPermission(
    id: 'create_tour',
    name: 'Créer une tournée',
    module: 'gaz',
    description: 'Permet de créer une tournée',
  );

  static const editTour = ActionPermission(
    id: 'edit_tour',
    name: 'Modifier une tournée',
    module: 'gaz',
    description: 'Permet de modifier une tournée',
  );

  // Leaks
  static const viewLeaks = ActionPermission(
    id: 'view_leaks',
    name: 'Voir les fuites',
    module: 'gaz',
    description: 'Permet de voir les fuites de bouteilles',
  );

  static const reportLeak = ActionPermission(
    id: 'report_leak',
    name: 'Signaler une fuite',
    module: 'gaz',
    description: 'Permet de signaler une fuite',
  );

  // Expenses
  static const viewExpenses = ActionPermission(
    id: 'view_expenses',
    name: 'Voir les dépenses',
    module: 'gaz',
    description: 'Permet de voir les dépenses',
  );

  static const createExpense = ActionPermission(
    id: 'create_expense',
    name: 'Créer une dépense',
    module: 'gaz',
    description: 'Permet de créer une dépense',
  );

  static const editExpense = ActionPermission(
    id: 'edit_expense',
    name: 'Modifier une dépense',
    module: 'gaz',
    description: 'Permet de modifier une dépense',
  );

  static const deleteExpense = ActionPermission(
    id: 'delete_expense',
    name: 'Supprimer une dépense',
    module: 'gaz',
    description: 'Permet de supprimer une dépense',
  );

  // Treasury
  static const viewTreasury = ActionPermission(
    id: 'view_treasury',
    name: 'Voir la trésorerie',
    module: 'gaz',
    description: 'Permet de voir le dashboard de trésorerie',
  );

  static const manageTreasury = ActionPermission(
    id: 'manage_treasury',
    name: 'Gérer la trésorerie',
    module: 'gaz',
    description: 'Permet de faire des dépôts/retraits manuels',
  );

  // Reports
  static const viewReports = ActionPermission(
    id: 'view_reports',
    name: 'Voir les rapports',
    module: 'gaz',
    description: 'Permet de voir les rapports',
  );

  static const downloadReports = ActionPermission(
    id: 'download_reports',
    name: 'Télécharger les rapports',
    module: 'gaz',
    description: 'Permet de télécharger les rapports',
  );

  // Settings
  static const viewSettings = ActionPermission(
    id: 'view_settings',
    name: 'Voir les paramètres',
    module: 'gaz',
    description: 'Permet de voir les paramètres',
  );

  static const editSettings = ActionPermission(
    id: 'edit_settings',
    name: 'Modifier les paramètres',
    module: 'gaz',
    description: 'Permet de modifier les paramètres',
  );

  // Profile
  static const viewProfile = ActionPermission(
    id: 'view_profile',
    name: 'Voir le profil',
    module: 'gaz',
    description: 'Permet de voir son profil',
  );

  static const editProfile = ActionPermission(
    id: 'edit_profile',
    name: 'Modifier le profil',
    module: 'gaz',
    description: 'Permet de modifier son profil',
  );

  static const changePassword = ActionPermission(
    id: 'change_password',
    name: 'Changer le mot de passe',
    module: 'gaz',
    description: 'Permet de changer son mot de passe',
  );

  static const viewDeliveries = ActionPermission(
    id: 'view_deliveries',
    name: 'Voir les livraisons',
    module: 'gaz',
    description: 'Permet de voir les livraisons assignées',
  );

  static const manageInventory = ActionPermission(
    id: 'manage_inventory',
    name: 'Gérer l\'inventaire',
    module: 'gaz',
    description: 'Permet d\'effectuer des audits d\'inventaire complets',
  );
  /// All permissions for the module
  static const all = [
    viewDashboard,
    viewSales,
    createSale,
    editSale,
    deleteSale,
    viewWholesale,
    createWholesale,
    viewStock,
    editStock,
    viewCylinders,
    manageCylinders,
    viewTours,
    createTour,
    editTour,
    viewLeaks,
    reportLeak,
    viewExpenses,
    createExpense,
    editExpense,
    deleteExpense,
    viewReports,
    downloadReports,
    viewSettings,
    editSettings,
    viewProfile,
    editProfile,
    changePassword,
    viewDeliveries,
    manageInventory,
    viewTreasury,
    manageTreasury,
  ];
}
