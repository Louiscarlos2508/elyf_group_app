import 'package:elyf_groupe_app/core/permissions/data/predefined_roles.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service d'initialisation des rôles prédéfinis
class RoleInitializationService {
  const RoleInitializationService(this._ref);

  final Ref _ref;

  /// Initialise tous les rôles prédéfinis dans le système
  /// Cette méthode doit être appelée au premier démarrage de l'application
  /// ou lorsque de nouveaux rôles sont ajoutés
  Future<void> initializePredefinedRoles() async {
    final adminController = _ref.read(adminControllerProvider);

    // ignore: avoid_print
    print('[ROLES] Initialisation des roles predefinis...');

    int created = 0;
    int skipped = 0;
    int errors = 0;

    for (final role in PredefinedRoles.allRoles) {
      try {
        // Vérifier si le rôle existe déjà
        final existingRoles = await _ref.read(rolesProvider.future);
        final exists = existingRoles.any((r) => r.id == role.id);

        if (exists) {
          // ignore: avoid_print
          print('[ROLES] Role "${role.name}" existe deja, ignore');
          skipped++;
          continue;
        }

        // Créer le rôle
        await adminController.createRole(role);
        // ignore: avoid_print
        print('[ROLES] Role "${role.name}" cree avec succes');
        created++;
      } catch (e) {
        // ignore: avoid_print
        print('[ROLES] Erreur lors de la creation du role "${role.name}": $e');
        errors++;
      }
    }

    // ignore: avoid_print
    print('\n[ROLES] Resume de l\'initialisation:');
    // ignore: avoid_print
    print('[ROLES]   Crees: $created');
    // ignore: avoid_print
    print('[ROLES]   Ignores: $skipped');
    // ignore: avoid_print
    print('[ROLES]   Erreurs: $errors');
    // ignore: avoid_print
    print('[ROLES]   Total: ${PredefinedRoles.allRoles.length}');
  }

  /// Initialise uniquement les rôles pour un module spécifique
  Future<void> initializeRolesForModule(String moduleId) async {
    final adminController = _ref.read(adminControllerProvider);
    final roles = PredefinedRoles.getRolesForModule(moduleId);

    // ignore: avoid_print
    print('[ROLES] Initialisation des roles pour le module "$moduleId"...');

    for (final role in roles) {
      try {
        final existingRoles = await _ref.read(rolesProvider.future);
        final exists = existingRoles.any((r) => r.id == role.id);

        if (!exists) {
          await adminController.createRole(role);
          // ignore: avoid_print
          print('[ROLES] Role "${role.name}" cree');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[ROLES] Erreur: $e');
      }
    }
  }
}

/// Provider pour le service d'initialisation
final roleInitializationServiceProvider = Provider<RoleInitializationService>((
  ref,
) {
  return RoleInitializationService(ref);
});
