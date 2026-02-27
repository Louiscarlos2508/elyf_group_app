import '../../../../core/permissions/entities/module_permission.dart';
import '../entities/module_sections_info.dart';

/// Structure pour organiser les permissions par module et section.
class PermissionsBySection {
  const PermissionsBySection({required this.moduleId, required this.sections});

  final String moduleId;
  final Map<String, List<ModulePermission>> sections;
}

/// Service pour mapper les permissions aux sections d'un module.
class PermissionSectionMapper {
  PermissionSectionMapper._();

  /// Mappe les permissions d'un module vers leurs sections respectives.
  ///
  /// Retourne une map sectionId -> liste de permissions pour ce module.
  static Map<String, List<ModulePermission>> mapPermissionsToSections({
    required String moduleId,
    required List<ModulePermission> permissions,
  }) {
    final sections = ModuleSectionsRegistry.getSectionsForModule(moduleId);
    final result = <String, List<ModulePermission>>{};

    // Initialiser toutes les sections avec des listes vides
    for (final section in sections) {
      result[section.id] = [];
    }

    // Mapper chaque permission à sa section
    for (final permission in permissions) {
      final sectionId = _getSectionIdForPermission(moduleId, permission.id);
      if (sectionId != null) {
        result[sectionId] ??= [];
        result[sectionId]!.add(permission);
      } else {
        // Si aucune section trouvée, mettre dans "autres" ou la première section
        final firstSection = sections.isNotEmpty ? sections.first.id : 'other';
        result[firstSection] ??= [];
        result[firstSection]!.add(permission);
      }
    }

    // Retirer les sections vides
    result.removeWhere((key, value) => value.isEmpty);

    return result;
  }

  /// Détermine la section d'une permission basée sur son ID.
  ///
  /// Analyse l'ID de la permission pour trouver la section correspondante.
  static String? _getSectionIdForPermission(
    String moduleId,
    String permissionId,
  ) {
    // Patterns généraux
    if (permissionId.startsWith('view_') ||
        permissionId.startsWith('edit_') ||
        permissionId.startsWith('create_') ||
        permissionId.startsWith('delete_') ||
        permissionId.startsWith('use_') ||
        permissionId.startsWith('download_') ||
        permissionId.startsWith('restore_') ||
        permissionId.startsWith('change_') ||
        permissionId.startsWith('assign_') ||
        permissionId.startsWith('manage_') ||
        permissionId.startsWith('validate_') ||
        permissionId.startsWith('declare_') ||
        permissionId.startsWith('export_')) {
      final prefix = permissionId.split('_').first;
      final suffix = permissionId.substring(prefix.length + 1);

      // Mapping spécifique par module et suffixe
      switch (moduleId) {
        case 'boutique':
          if (suffix == 'dashboard' || suffix.startsWith('dashboard')) {
            return 'dashboard';
          } else if (suffix == 'sales' || suffix == 'sale' || suffix == 'pos') {
            return 'pos';
          } else if (suffix == 'products' ||
              suffix == 'product' ||
              suffix == 'catalog') {
            return 'catalog';
          } else if (suffix == 'purchases' || suffix == 'purchase') {
            return 'catalog'; // Les achats sont dans le catalogue
          } else if (suffix == 'stock') {
            return 'catalog'; // Le stock est dans le catalogue
          } else if (suffix == 'expenses' || suffix == 'expense') {
            return 'expenses';
          } else if (suffix == 'reports' || suffix == 'report') {
            return 'reports';
          } else if (suffix == 'profile' || suffix == 'password') {
            return 'profile';
          } else if (suffix == 'trash') {
            return 'catalog'; // La corbeille est dans le catalogue
          }
          break;

        case 'eau_minerale':
          if (suffix == 'dashboard' || suffix.startsWith('dashboard')) {
            return 'activity';
          } else if (permissionId.contains('configure_production')) {
            // configure_production va dans settings
            return 'settings';
          } else if (permissionId.contains('manage_products')) {
            // manage_products va dans settings
            return 'settings';
          } else if (suffix == 'production') {
            return 'production';
          } else if (suffix == 'sales' || suffix == 'sale') {
            return 'sales';
          } else if (suffix == 'stock') {
            return 'stock';
          } else if (suffix == 'clients' ||
              suffix == 'client' ||
              suffix == 'credit' ||
              suffix == 'credits') {
            return 'clients';
          } else if (suffix == 'finances' ||
              suffix == 'finance' ||
              suffix == 'expense' ||
              suffix == 'expenses') {
            return 'finances';
          } else if (suffix == 'salaries' || suffix == 'salary') {
            return 'salaries';
          } else if (suffix == 'reports' || suffix == 'report') {
            return 'reports';
          } else if (suffix == 'settings' || suffix == 'setting') {
            return 'settings';
          } else if (suffix == 'profile' || suffix == 'password') {
            return 'profile';
          }
          break;

        case 'gaz':
          if (suffix == 'dashboard' || suffix.startsWith('dashboard')) {
            return 'dashboard';
          } else if (suffix == 'retail' ||
              (suffix == 'sales' && !permissionId.contains('wholesale'))) {
            return 'retail';
          } else if (suffix == 'wholesale') {
            return 'wholesale';
          } else if (suffix == 'stock') {
            return 'stock';
          } else if (suffix == 'approvisionnement' ||
              suffix == 'approvision' ||
              suffix == 'tours' ||
              suffix == 'tour') {
            return 'approvisionnement';
          } else if (suffix == 'cylinder' ||
              suffix == 'cylinders' ||
              suffix == 'leak' ||
              suffix == 'leaks') {
            return 'cylinder_leak';
          } else if (suffix == 'expenses' || suffix == 'expense') {
            return 'expenses';
          } else if (suffix == 'reports' || suffix == 'report') {
            return 'reports';
          } else if (suffix == 'settings' || suffix == 'setting') {
            return 'settings';
          } else if (suffix == 'profile' || suffix == 'password') {
            return 'profile';
          }
          break;

        case 'orange_money':
          if (suffix == 'dashboard' || suffix.startsWith('dashboard')) {
            return 'transactions'; // Par défaut dans transactions si section dashboard non présente
          } else if (permissionId.contains('network_dashboard') || 
                     permissionId.contains('child_transactions')) {
            return 'hierarchy'; // Nouvelle section pour la hiérarchie
          } else if (suffix == 'transaction' || suffix == 'transactions') {
            return 'transactions';
          } else if (suffix == 'agent' || suffix == 'agents') {
            return 'agents';
          } else if (suffix == 'liquidity' ||
              suffix == 'checkpoint' ||
              suffix == 'checkpoints') {
            return 'liquidity';
          } else if (suffix == 'commission' || suffix == 'commissions') {
            return 'commissions';
          } else if (suffix == 'reports' || suffix == 'report') {
            return 'reports';
          } else if (suffix == 'settings' || suffix == 'setting') {
            return 'settings';
          } else if (suffix == 'profile' || suffix == 'password') {
            return 'profile';
          }
          break;

        case 'immobilier':
          if (suffix == 'dashboard' || suffix.startsWith('dashboard')) {
            return 'dashboard';
          } else if (suffix == 'property' || suffix == 'properties') {
            return 'properties';
          } else if (suffix == 'tenant' || suffix == 'tenants') {
            return 'tenants';
          } else if (suffix == 'contract' ||
              suffix == 'contracts' ||
              suffix == 'terminate') {
            // terminate_contract va dans contracts
            return 'contracts';
          } else if (suffix == 'payment' || suffix == 'payments') {
            return 'payments';
          } else if (suffix == 'expenses' || suffix == 'expense') {
            return 'expenses';
          } else if (suffix == 'reports' || suffix == 'report') {
            return 'reports';
          } else if (suffix == 'settings' || suffix == 'setting') {
            return 'settings';
          } else if (suffix == 'profile' || suffix == 'password') {
            return 'profile';
          }
          break;

        case 'administration':
          if (suffix == 'dashboard') {
            return 'enterprises'; // On met le dashboard admin avec les entreprises
          } else if (suffix == 'enterprise' ||
              suffix == 'enterprises' ||
              suffix == 'hierarchy') {
            return 'enterprises';
          } else if (suffix == 'user' ||
              suffix == 'users' ||
              suffix == 'assign_user_to_enterprise') {
            return 'users';
          } else if (suffix == 'role' ||
              suffix == 'roles' ||
              suffix == 'permission' ||
              suffix == 'permissions') {
            return 'roles';
          } else if (suffix == 'module' || suffix == 'modules') {
            return 'modules';
          } else if (suffix == 'audit' || suffix == 'audit_trail') {
            return 'audit';
          } else if (suffix == 'profile' || suffix == 'password') {
            return 'profile';
          }
          break;
      }
    }

    // Si aucune correspondance, retourner null
    return null;
  }

  /// Organise les permissions de tous les modules par module et section.
  ///
  /// Retourne une liste de PermissionsBySection.
  static List<PermissionsBySection> organizeAllPermissions({
    required Map<String, List<ModulePermission>> permissionsByModule,
  }) {
    final result = <PermissionsBySection>[];

    for (final entry in permissionsByModule.entries) {
      final moduleId = entry.key;
      final permissions = entry.value;

      final sectionsMap = mapPermissionsToSections(
        moduleId: moduleId,
        permissions: permissions,
      );

      if (sectionsMap.isNotEmpty) {
        result.add(
          PermissionsBySection(moduleId: moduleId, sections: sectionsMap),
        );
      }
    }

    return result;
  }
}
