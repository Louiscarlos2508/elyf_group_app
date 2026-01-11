import '../modules/eau_minerale_permissions.dart';
import '../modules/gaz_permissions.dart';
import '../modules/orange_money_permissions.dart';
import '../modules/immobilier_permissions.dart';
import '../modules/boutique_permissions.dart';
import '../modules/administration_permissions.dart';
import 'permission_registry.dart';

/// Service pour initialiser toutes les permissions au démarrage de l'application.
/// 
/// Cette classe centralise l'enregistrement de toutes les permissions
/// de tous les modules dans le PermissionRegistry.
class PermissionInitializer {
  PermissionInitializer._();

  /// Initialise toutes les permissions de tous les modules.
  /// 
  /// Cette méthode doit être appelée au démarrage de l'application
  /// (dans bootstrap.dart) pour que toutes les permissions soient disponibles.
  static void initializeAllPermissions() {
    final registry = PermissionRegistry.instance;

    // Enregistrer les permissions du module Eau Minérale
    registry.registerModulePermissions(
      'eau_minerale',
      EauMineralePermissions.all,
    );

    // Enregistrer les permissions du module Gaz
    registry.registerModulePermissions(
      'gaz',
      GazPermissions.all,
    );

    // Enregistrer les permissions du module Orange Money
    registry.registerModulePermissions(
      'orange_money',
      OrangeMoneyPermissions.all,
    );

    // Enregistrer les permissions du module Immobilier
    registry.registerModulePermissions(
      'immobilier',
      ImmobilierPermissions.all,
    );

    // Enregistrer les permissions du module Boutique
    registry.registerModulePermissions(
      'boutique',
      BoutiquePermissions.all,
    );

    // Enregistrer les permissions du module Administration
    registry.registerModulePermissions(
      'administration',
      AdministrationPermissions.all,
    );
  }

  /// Retourne toutes les permissions enregistrées dans le registry.
  /// 
  /// Utile pour le debug et l'affichage dans les interfaces d'administration.
  static Map<String, Map<String, String>> getAllRegisteredPermissions() {
    final registry = PermissionRegistry.instance;
    final result = <String, Map<String, String>>{};

    for (final moduleId in registry.registeredModules) {
      final modulePermissions = registry.getModulePermissions(moduleId);
      if (modulePermissions != null) {
        result[moduleId] = {
          for (final perm in modulePermissions.values)
            perm.id: perm.name,
        };
      }
    }

    return result;
  }
}
