import '../entities/module_permission.dart';

/// Permissions for the Administration module using the centralized system.
class AdministrationPermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'administration',
    description: 'Permet de voir le tableau de bord d\'administration',
  );

  // Enterprises
  static const viewEnterprises = ActionPermission(
    id: 'view_enterprises',
    name: 'Voir les entreprises',
    module: 'administration',
    description: 'Permet de voir les entreprises',
  );

  static const createEnterprise = ActionPermission(
    id: 'create_enterprise',
    name: 'Créer une entreprise',
    module: 'administration',
    description: 'Permet de créer une nouvelle entreprise',
  );

  static const editEnterprise = ActionPermission(
    id: 'edit_enterprise',
    name: 'Modifier une entreprise',
    module: 'administration',
    description: 'Permet de modifier une entreprise',
  );

  static const deleteEnterprise = ActionPermission(
    id: 'delete_enterprise',
    name: 'Supprimer une entreprise',
    module: 'administration',
    description: 'Permet de supprimer une entreprise',
  );

  // Users
  static const viewUsers = ActionPermission(
    id: 'view_users',
    name: 'Voir les utilisateurs',
    module: 'administration',
    description: 'Permet de voir les utilisateurs',
  );

  static const createUser = ActionPermission(
    id: 'create_user',
    name: 'Créer un utilisateur',
    module: 'administration',
    description: 'Permet de créer un nouvel utilisateur',
  );

  static const editUser = ActionPermission(
    id: 'edit_user',
    name: 'Modifier un utilisateur',
    module: 'administration',
    description: 'Permet de modifier un utilisateur',
  );

  static const deleteUser = ActionPermission(
    id: 'delete_user',
    name: 'Supprimer un utilisateur',
    module: 'administration',
    description: 'Permet de supprimer un utilisateur',
  );

  static const assignUserToEnterprise = ActionPermission(
    id: 'assign_user_to_enterprise',
    name: 'Assigner un utilisateur',
    module: 'administration',
    description: 'Permet d\'assigner un utilisateur à une entreprise',
  );

  // Roles
  static const viewRoles = ActionPermission(
    id: 'view_roles',
    name: 'Voir les rôles',
    module: 'administration',
    description: 'Permet de voir les rôles',
  );

  static const createRole = ActionPermission(
    id: 'create_role',
    name: 'Créer un rôle',
    module: 'administration',
    description: 'Permet de créer un nouveau rôle',
  );

  static const editRole = ActionPermission(
    id: 'edit_role',
    name: 'Modifier un rôle',
    module: 'administration',
    description: 'Permet de modifier un rôle',
  );

  static const deleteRole = ActionPermission(
    id: 'delete_role',
    name: 'Supprimer un rôle',
    module: 'administration',
    description: 'Permet de supprimer un rôle',
  );

  // Modules
  static const viewModules = ActionPermission(
    id: 'view_modules',
    name: 'Voir les modules',
    module: 'administration',
    description: 'Permet de voir les modules',
  );

  static const manageModules = ActionPermission(
    id: 'manage_modules',
    name: 'Gérer les modules',
    module: 'administration',
    description: 'Permet de gérer les modules',
  );

  // Audit Trail
  static const viewAuditTrail = ActionPermission(
    id: 'view_audit_trail',
    name: 'Voir le journal d\'audit',
    module: 'administration',
    description: 'Permet de voir le journal d\'audit',
  );

  static const exportAuditTrail = ActionPermission(
    id: 'export_audit_trail',
    name: 'Exporter le journal d\'audit',
    module: 'administration',
    description: 'Permet d\'exporter le journal d\'audit',
  );

  // Profile
  static const viewProfile = ActionPermission(
    id: 'view_profile',
    name: 'Voir le profil',
    module: 'administration',
    description: 'Permet de voir son profil',
  );

  static const editProfile = ActionPermission(
    id: 'edit_profile',
    name: 'Modifier le profil',
    module: 'administration',
    description: 'Permet de modifier son profil',
  );

  static const changePassword = ActionPermission(
    id: 'change_password',
    name: 'Changer le mot de passe',
    module: 'administration',
    description: 'Permet de changer son mot de passe',
  );

  /// All permissions for the module
  static const all = [
    viewDashboard,
    viewEnterprises,
    createEnterprise,
    editEnterprise,
    deleteEnterprise,
    viewUsers,
    createUser,
    editUser,
    deleteUser,
    assignUserToEnterprise,
    viewRoles,
    createRole,
    editRole,
    deleteRole,
    viewModules,
    manageModules,
    viewAuditTrail,
    exportAuditTrail,
    viewProfile,
    editProfile,
    changePassword,
  ];
}
