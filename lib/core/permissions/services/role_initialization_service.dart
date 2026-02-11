import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logging/app_logger.dart';
import '../../../../features/administration/application/providers.dart';
import '../data/predefined_roles.dart';

/// Service d'initialisation des rôles prédéfinis
class RoleInitializationService {
  const RoleInitializationService(this._ref);

  final Ref _ref;

  /// Initialise tous les rôles prédéfinis dans le système
  /// Cette méthode doit être appelée au premier démarrage de l'application
  /// ou lorsque de nouveaux rôles sont ajoutés
  Future<void> initializePredefinedRoles() async {
    final adminController = _ref.read(adminControllerProvider);

    AppLogger.info('Initialisation des roles predefinis...', name: 'roles');

    int created = 0;
    int skipped = 0;
    int errors = 0;

    for (final role in PredefinedRoles.allRoles) {
      try {
        // Vérifier si le rôle existe déjà
        final existingRoles = await _ref.read(rolesProvider.future);
        final exists = existingRoles.any((r) => r.id == role.id);

        if (exists) {
          AppLogger.debug('Role "${role.name}" existe deja, ignore', name: 'roles');
          skipped++;
          continue;
        }

        // Créer le rôle
        await adminController.createRole(role);
        AppLogger.info('Role "${role.name}" cree avec succes', name: 'roles');
        created++;
      } catch (e) {
        AppLogger.error('Erreur lors de la creation du role "${role.name}": $e', name: 'roles', error: e);
        errors++;
      }
    }

    AppLogger.info('\nResume de l\'initialisation:', name: 'roles');
    AppLogger.info('  Crees: $created', name: 'roles');
    AppLogger.info('  Ignores: $skipped', name: 'roles');
    AppLogger.info('  Erreurs: $errors', name: 'roles');
    AppLogger.info('  Total: ${PredefinedRoles.allRoles.length}', name: 'roles');
  }

  /// Initialise uniquement les rôles pour un module spécifique
  Future<void> initializeRolesForModule(String moduleId) async {
    final adminController = _ref.read(adminControllerProvider);
    final roles = PredefinedRoles.getRolesForModule(moduleId);

    AppLogger.info('Initialisation des roles pour le module "$moduleId"...', name: 'roles');

    for (final role in roles) {
      try {
        final existingRoles = await _ref.read(rolesProvider.future);
        final exists = existingRoles.any((r) => r.id == role.id);

        if (!exists) {
          await adminController.createRole(role);
          AppLogger.info('Role "${role.name}" cree', name: 'roles');
        }
      } catch (e) {
        AppLogger.error('Erreur: $e', name: 'roles', error: e);
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
