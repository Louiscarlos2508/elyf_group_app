/// Represents a permission for a specific module action.
enum ModulePermission {
  // Dashboard
  viewDashboard,

  // Production
  viewProduction,
  createProduction,
  editProduction,
  deleteProduction,

  // Sales
  viewSales,
  createSale,
  editSale,
  deleteSale,

  // Stock
  viewStock,
  editStock,

  // Credits
  viewCredits,
  collectPayment,
  viewCreditHistory,

  // Finances
  viewFinances,
  createExpense,
  editExpense,
  deleteExpense,

  // Salaries
  viewSalaries,
  createSalary,
  editSalary,
  deleteSalary,

  // Reports
  viewReports,
  downloadReports,

  // Settings
  viewSettings,
  editSettings,
  manageProducts,
  configureProduction,

  // Profile
  viewProfile,
  editProfile,
  changePassword,
}

/// User role in the eau minérale module.
enum EauMineraleRole {
  /// Full access to all features
  responsable,

  /// Access to most features except settings
  gestionnaire,

  /// Access to sales only
  vendeur,

  /// Access to production only
  producteur,

  /// Access to finances and reports
  comptable,

  /// Read-only access to dashboard and reports
  lecteur,
}

/// Permission configuration for each role.
class RolePermissions {
  const RolePermissions({required this.role, required this.permissions});

  final EauMineraleRole role;
  final Set<ModulePermission> permissions;

  bool hasPermission(ModulePermission permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(Set<ModulePermission> requiredPermissions) {
    return requiredPermissions.any((p) => permissions.contains(p));
  }

  bool hasAllPermissions(Set<ModulePermission> requiredPermissions) {
    return requiredPermissions.every((p) => permissions.contains(p));
  }

  /// Default permissions for each role.
  static Map<EauMineraleRole, Set<ModulePermission>> get defaultPermissions {
    return {
      EauMineraleRole.responsable: {
        // Full access
        ...ModulePermission.values,
      },
      EauMineraleRole.gestionnaire: {
        ModulePermission.viewDashboard,
        ModulePermission.viewProduction,
        ModulePermission.createProduction,
        ModulePermission.editProduction,
        ModulePermission.viewSales,
        ModulePermission.createSale,
        ModulePermission.editSale,
        ModulePermission.viewStock,
        ModulePermission.editStock,
        ModulePermission.viewCredits,
        ModulePermission.collectPayment,
        ModulePermission.viewCreditHistory,
        ModulePermission.viewFinances,
        ModulePermission.createExpense,
        ModulePermission.editExpense,
        ModulePermission.viewSalaries,
        ModulePermission.viewReports,
        ModulePermission.downloadReports,
        ModulePermission.viewProfile,
        ModulePermission.editProfile,
        ModulePermission.changePassword,
      },
      EauMineraleRole.vendeur: {
        ModulePermission.viewDashboard,
        ModulePermission.viewSales,
        ModulePermission.createSale,
        ModulePermission.editSale,
        ModulePermission.viewStock,
        ModulePermission.viewCredits,
        ModulePermission.collectPayment,
        ModulePermission.viewProfile,
        ModulePermission.editProfile,
      },
      EauMineraleRole.producteur: {
        ModulePermission.viewDashboard,
        ModulePermission.viewProduction,
        ModulePermission.createProduction,
        ModulePermission.viewStock,
        ModulePermission.viewProfile,
        ModulePermission.editProfile,
      },
      EauMineraleRole.comptable: {
        ModulePermission.viewDashboard,
        ModulePermission.viewFinances,
        ModulePermission.createExpense,
        ModulePermission.editExpense,
        ModulePermission.viewSalaries,
        ModulePermission.viewReports,
        ModulePermission.downloadReports,
        ModulePermission.viewProfile,
        ModulePermission.editProfile,
      },
      EauMineraleRole.lecteur: {
        ModulePermission.viewDashboard,
        ModulePermission.viewProduction,
        ModulePermission.viewSales,
        ModulePermission.viewStock,
        ModulePermission.viewCredits,
        ModulePermission.viewFinances,
        ModulePermission.viewReports,
        ModulePermission.viewProfile,
      },
    };
  }
}
