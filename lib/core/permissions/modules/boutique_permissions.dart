import '../entities/module_permission.dart';

/// Permissions for the Boutique module using the centralized system.
class BoutiquePermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'boutique',
    description: 'Permet de voir le tableau de bord',
  );

  // Sales
  static const viewSales = ActionPermission(
    id: 'view_sales',
    name: 'Voir les ventes',
    module: 'boutique',
    description: 'Permet de voir les ventes',
  );

  static const createSale = ActionPermission(
    id: 'create_sale',
    name: 'Créer une vente',
    module: 'boutique',
    description: 'Permet de créer une nouvelle vente',
  );

  static const editSale = ActionPermission(
    id: 'edit_sale',
    name: 'Modifier une vente',
    module: 'boutique',
    description: 'Permet de modifier une vente',
  );

  static const deleteSale = ActionPermission(
    id: 'delete_sale',
    name: 'Supprimer une vente',
    module: 'boutique',
    description: 'Permet de supprimer une vente',
  );

  // Point of Sale (POS)
  static const usePos = ActionPermission(
    id: 'use_pos',
    name: 'Utiliser la caisse',
    module: 'boutique',
    description: 'Permet d\'utiliser le point de vente',
  );

  // Products
  static const viewProducts = ActionPermission(
    id: 'view_products',
    name: 'Voir les produits',
    module: 'boutique',
    description: 'Permet de voir les produits',
  );

  static const createProduct = ActionPermission(
    id: 'create_product',
    name: 'Créer un produit',
    module: 'boutique',
    description: 'Permet de créer un nouveau produit',
  );

  static const editProduct = ActionPermission(
    id: 'edit_product',
    name: 'Modifier un produit',
    module: 'boutique',
    description: 'Permet de modifier un produit',
  );

  static const deleteProduct = ActionPermission(
    id: 'delete_product',
    name: 'Supprimer un produit',
    module: 'boutique',
    description: 'Permet de supprimer un produit',
  );

  // Stock
  static const viewStock = ActionPermission(
    id: 'view_stock',
    name: 'Voir le stock',
    module: 'boutique',
    description: 'Permet de voir le stock',
  );

  static const editStock = ActionPermission(
    id: 'edit_stock',
    name: 'Modifier le stock',
    module: 'boutique',
    description: 'Permet de modifier le stock',
  );

  // Purchases
  static const viewPurchases = ActionPermission(
    id: 'view_purchases',
    name: 'Voir les achats',
    module: 'boutique',
    description: 'Permet de voir les achats',
  );

  static const createPurchase = ActionPermission(
    id: 'create_purchase',
    name: 'Créer un achat',
    module: 'boutique',
    description: 'Permet de créer un nouvel achat',
  );

  static const editPurchase = ActionPermission(
    id: 'edit_purchase',
    name: 'Modifier un achat',
    module: 'boutique',
    description: 'Permet de modifier un achat',
  );

  // Expenses
  static const viewExpenses = ActionPermission(
    id: 'view_expenses',
    name: 'Voir les dépenses',
    module: 'boutique',
    description: 'Permet de voir les dépenses',
  );

  static const createExpense = ActionPermission(
    id: 'create_expense',
    name: 'Créer une dépense',
    module: 'boutique',
    description: 'Permet de créer une dépense',
  );

  static const editExpense = ActionPermission(
    id: 'edit_expense',
    name: 'Modifier une dépense',
    module: 'boutique',
    description: 'Permet de modifier une dépense',
  );

  static const deleteExpense = ActionPermission(
    id: 'delete_expense',
    name: 'Supprimer une dépense',
    module: 'boutique',
    description: 'Permet de supprimer une dépense',
  );

  // Reports
  static const viewReports = ActionPermission(
    id: 'view_reports',
    name: 'Voir les rapports',
    module: 'boutique',
    description: 'Permet de voir les rapports',
  );

  static const downloadReports = ActionPermission(
    id: 'download_reports',
    name: 'Télécharger les rapports',
    module: 'boutique',
    description: 'Permet de télécharger les rapports',
  );

  // Treasury
  static const viewTreasury = ActionPermission(
    id: 'view_treasury',
    name: 'Voir la trésorerie',
    module: 'boutique',
    description: 'Permet de voir les soldes et l\'historique de la trésorerie',
  );

  static const editTreasury = ActionPermission(
    id: 'edit_treasury',
    name: 'Gérer la trésorerie',
    module: 'boutique',
    description: 'Permet d\'effectuer des transferts et ajustements de trésorerie',
  );

  // Suppliers
  static const viewSuppliers = ActionPermission(
    id: 'view_suppliers',
    name: 'Voir les fournisseurs',
    module: 'boutique',
    description: 'Permet de voir la liste des fournisseurs',
  );

  static const editSuppliers = ActionPermission(
    id: 'edit_suppliers',
    name: 'Gérer les fournisseurs',
    module: 'boutique',
    description: 'Permet d\'ajouter ou modifier des fournisseurs',
  );

  // Settings
  static const viewSettings = ActionPermission(
    id: 'view_settings',
    name: 'Voir les paramètres',
    module: 'boutique',
    description: 'Permet d\'accéder aux paramètres du module',
  );

  // Profile
  static const viewProfile = ActionPermission(
    id: 'view_profile',
    name: 'Voir le profil',
    module: 'boutique',
    description: 'Permet de voir son profil',
  );

  static const editProfile = ActionPermission(
    id: 'edit_profile',
    name: 'Modifier le profil',
    module: 'boutique',
    description: 'Permet de modifier son profil',
  );

  static const changePassword = ActionPermission(
    id: 'change_password',
    name: 'Changer le mot de passe',
    module: 'boutique',
    description: 'Permet de changer son mot de passe',
  );

  /// All permissions for the module
  static const all = [
    viewDashboard,
    viewSales,
    createSale,
    editSale,
    deleteSale,
    usePos,
    viewProducts,
    createProduct,
    editProduct,
    deleteProduct,
    viewStock,
    editStock,
    viewPurchases,
    createPurchase,
    editPurchase,
    viewExpenses,
    createExpense,
    editExpense,
    deleteExpense,
    viewReports,
    downloadReports,
    viewTreasury,
    editTreasury,
    viewSuppliers,
    editSuppliers,
    viewProfile,
    editProfile,
    changePassword,
    viewSettings,
  ];
}
