import '../entities/module_permission.dart';

/// Permissions for the Immobilier module using the centralized system.
class ImmobilierPermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'immobilier',
    description: 'Permet de voir le tableau de bord',
  );

  // Properties
  static const viewProperties = ActionPermission(
    id: 'view_properties',
    name: 'Voir les propriétés',
    module: 'immobilier',
    description: 'Permet de voir les propriétés',
  );

  static const createProperty = ActionPermission(
    id: 'create_property',
    name: 'Créer une propriété',
    module: 'immobilier',
    description: 'Permet de créer une nouvelle propriété',
  );

  static const editProperty = ActionPermission(
    id: 'edit_property',
    name: 'Modifier une propriété',
    module: 'immobilier',
    description: 'Permet de modifier une propriété',
  );

  static const deleteProperty = ActionPermission(
    id: 'delete_property',
    name: 'Supprimer une propriété',
    module: 'immobilier',
    description: 'Permet de supprimer une propriété',
  );

  // Tenants
  static const viewTenants = ActionPermission(
    id: 'view_tenants',
    name: 'Voir les locataires',
    module: 'immobilier',
    description: 'Permet de voir les locataires',
  );

  static const createTenant = ActionPermission(
    id: 'create_tenant',
    name: 'Créer un locataire',
    module: 'immobilier',
    description: 'Permet de créer un nouveau locataire',
  );

  static const editTenant = ActionPermission(
    id: 'edit_tenant',
    name: 'Modifier un locataire',
    module: 'immobilier',
    description: 'Permet de modifier un locataire',
  );

  static const deleteTenant = ActionPermission(
    id: 'delete_tenant',
    name: 'Supprimer un locataire',
    module: 'immobilier',
    description: 'Permet de supprimer un locataire',
  );

  // Contracts
  static const viewContracts = ActionPermission(
    id: 'view_contracts',
    name: 'Voir les contrats',
    module: 'immobilier',
    description: 'Permet de voir les contrats de location',
  );

  static const createContract = ActionPermission(
    id: 'create_contract',
    name: 'Créer un contrat',
    module: 'immobilier',
    description: 'Permet de créer un nouveau contrat',
  );

  static const editContract = ActionPermission(
    id: 'edit_contract',
    name: 'Modifier un contrat',
    module: 'immobilier',
    description: 'Permet de modifier un contrat',
  );

  static const terminateContract = ActionPermission(
    id: 'terminate_contract',
    name: 'Résilier un contrat',
    module: 'immobilier',
    description: 'Permet de résilier un contrat',
  );

  // Payments
  static const viewPayments = ActionPermission(
    id: 'view_payments',
    name: 'Voir les paiements',
    module: 'immobilier',
    description: 'Permet de voir les paiements de loyers',
  );

  static const createPayment = ActionPermission(
    id: 'create_payment',
    name: 'Enregistrer un paiement',
    module: 'immobilier',
    description: 'Permet d\'enregistrer un paiement de loyer',
  );

  static const editPayment = ActionPermission(
    id: 'edit_payment',
    name: 'Modifier un paiement',
    module: 'immobilier',
    description: 'Permet de modifier un paiement',
  );

  // Expenses
  static const viewExpenses = ActionPermission(
    id: 'view_expenses',
    name: 'Voir les dépenses',
    module: 'immobilier',
    description: 'Permet de voir les dépenses liées aux propriétés',
  );

  static const createExpense = ActionPermission(
    id: 'create_expense',
    name: 'Créer une dépense',
    module: 'immobilier',
    description: 'Permet de créer une dépense',
  );

  static const editExpense = ActionPermission(
    id: 'edit_expense',
    name: 'Modifier une dépense',
    module: 'immobilier',
    description: 'Permet de modifier une dépense',
  );

  static const deleteExpense = ActionPermission(
    id: 'delete_expense',
    name: 'Supprimer une dépense',
    module: 'immobilier',
    description: 'Permet de supprimer une dépense',
  );

  // Reports
  static const viewReports = ActionPermission(
    id: 'view_reports',
    name: 'Voir les rapports',
    module: 'immobilier',
    description: 'Permet de voir les rapports',
  );

  static const downloadReports = ActionPermission(
    id: 'download_reports',
    name: 'Télécharger les rapports',
    module: 'immobilier',
    description: 'Permet de télécharger les rapports',
  );

  // Profile
  static const viewProfile = ActionPermission(
    id: 'view_profile',
    name: 'Voir le profil',
    module: 'immobilier',
    description: 'Permet de voir son profil',
  );

  static const editProfile = ActionPermission(
    id: 'edit_profile',
    name: 'Modifier le profil',
    module: 'immobilier',
    description: 'Permet de modifier son profil',
  );

  static const changePassword = ActionPermission(
    id: 'change_password',
    name: 'Changer le mot de passe',
    module: 'immobilier',
    description: 'Permet de changer son mot de passe',
  );

  // Trash & Restore
  static const viewTrash = ActionPermission(
    id: 'view_trash',
    name: 'Voir la corbeille',
    module: 'immobilier',
    description: 'Permet de voir les éléments supprimés',
  );

  static const restoreProperty = ActionPermission(
    id: 'restore_property',
    name: 'Restaurer une propriété',
    module: 'immobilier',
    description: 'Permet de restaurer une propriété supprimée',
  );

  static const restoreTenant = ActionPermission(
    id: 'restore_tenant',
    name: 'Restaurer un locataire',
    module: 'immobilier',
    description: 'Permet de restaurer un locataire supprimé',
  );

  static const deleteContract = ActionPermission(
    id: 'delete_contract',
    name: 'Supprimer un contrat',
    module: 'immobilier',
    description: 'Permet de supprimer un contrat',
  );

  static const restoreContract = ActionPermission(
    id: 'restore_contract',
    name: 'Restaurer un contrat',
    module: 'immobilier',
    description: 'Permet de restaurer un contrat supprimé',
  );

  static const deletePayment = ActionPermission(
    id: 'delete_payment',
    name: 'Supprimer un paiement',
    module: 'immobilier',
    description: 'Permet de supprimer un paiement',
  );

  static const restorePayment = ActionPermission(
    id: 'restore_payment',
    name: 'Restaurer un paiement',
    module: 'immobilier',
    description: 'Permet de restaurer un paiement supprimé',
  );

  static const restoreExpense = ActionPermission(
    id: 'restore_expense',
    name: 'Restaurer une dépense',
    module: 'immobilier',
    description: 'Permet de restaurer une dépense supprimée',
  );

  // Maintenance
  static const viewMaintenance = ActionPermission(
    id: 'view_maintenance',
    name: 'Voir la maintenance',
    module: 'immobilier',
    description: 'Permet de voir les tickets de maintenance',
  );

  static const createMaintenance = ActionPermission(
    id: 'create_maintenance',
    name: 'Créer un ticket de maintenance',
    module: 'immobilier',
    description: 'Permet de créer un ticket de maintenance',
  );

  static const editMaintenance = ActionPermission(
    id: 'edit_maintenance',
    name: 'Modifier un ticket de maintenance',
    module: 'immobilier',
    description: 'Permet de modifier un ticket de maintenance',
  );

  static const deleteMaintenance = ActionPermission(
    id: 'delete_maintenance',
    name: 'Supprimer un ticket de maintenance',
    module: 'immobilier',
    description: 'Permet de supprimer un ticket de maintenance',
  );

  // Treasury
  static const viewTreasury = ActionPermission(
    id: 'view_treasury',
    name: 'Voir la trésorerie',
    module: 'immobilier',
    description: 'Permet de voir la trésorerie',
  );

  static const createTreasuryOperation = ActionPermission(
    id: 'create_treasury_operation',
    name: 'Créer une opération de trésorerie',
    module: 'immobilier',
    description: 'Permet de créer une opération de trésorerie',
  );
  
  static const manageSettings = ActionPermission(
    id: 'manage_settings',
    name: 'Gérer les paramètres',
    module: 'immobilier',
    description: 'Permet de gérer les paramètres du module',
  );

  /// All permissions for the module
  static const all = [
    viewDashboard,
    viewProperties,
    createProperty,
    editProperty,
    deleteProperty,
    viewTenants,
    createTenant,
    editTenant,
    deleteTenant,
    viewContracts,
    createContract,
    editContract,
    terminateContract,
    viewPayments,
    createPayment,
    editPayment,
    viewExpenses,
    createExpense,
    editExpense,
    deleteExpense,
    viewReports,
    downloadReports,
    viewProfile,
    editProfile,
    changePassword,
    viewTrash,
    restoreProperty,
    restoreTenant,
    deleteContract,
    restoreContract,
    deletePayment,
    restorePayment,
    restoreExpense,
    viewMaintenance,
    createMaintenance,
    editMaintenance,
    deleteMaintenance,
    viewTreasury,
    createTreasuryOperation,
    manageSettings,
  ];
}
