# Guide d'Intégration - Système de Permissions Centralisé

## Vue d'ensemble

Un système de permissions centralisé a été créé pour gérer les utilisateurs, rôles et permissions dans tous les modules de l'application.

## Architecture

### Core › Permissions
- **entities/** : Entités de base (ModulePermission, UserRole, ModuleUser)
- **services/** : Services pour la gestion (PermissionService, PermissionRegistry)

### Module Administration
- **domain/** : Entités et repositories pour l'administration
- **data/** : Implémentations mock
- **presentation/** : Écrans d'administration

## Étapes d'intégration pour un nouveau module

### 1. Définir les permissions du module

Dans votre module (ex: `eau_minerale`), créez un fichier `permissions.dart` :

```dart
import '../../../core/permissions/entities/module_permission.dart';

class EauMineralePermissions {
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'eau_minerale',
    description: 'Permet de voir le tableau de bord',
  );

  static const createProduction = ActionPermission(
    id: 'create_production',
    name: 'Créer une production',
    module: 'eau_minerale',
    description: 'Permet de créer une nouvelle production',
  );

  // ... autres permissions

  static const all = [
    viewDashboard,
    createProduction,
    // ... toutes les permissions
  ];
}
```

### 2. Enregistrer les permissions

Lors de l'initialisation de l'application ou du module :

```dart
import '../../../core/permissions/services/permission_registry.dart';
import 'permissions.dart';

// Dans votre provider ou service d'initialisation
PermissionRegistry.instance.registerModulePermissions(
  'eau_minerale',
  EauMineralePermissions.all,
);
```

### 3. Utiliser les permissions dans les widgets

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/permissions/services/permission_service.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    
    return FutureBuilder<bool>(
      future: permissionService.hasPermission(
        'current-user-id', // À récupérer depuis l'auth
        'eau_minerale',
        'create_production',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }
        
        return FilledButton(
          onPressed: () => _createProduction(),
          child: Text('Nouvelle Production'),
        );
      },
    );
  }
}
```

### 4. Créer un widget helper pour simplifier

```dart
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    required this.permissionId,
    required this.child,
  });

  final String permissionId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    // ... logique de vérification
  }
}
```

## Module d'Administration

Le module d'administration est accessible via `/admin` et permet de :

1. **Gérer les modules** : Voir tous les modules disponibles
2. **Gérer les utilisateurs** : Ajouter des utilisateurs à un module, attribuer des rôles
3. **Gérer les rôles** : Créer, modifier, supprimer des rôles et leurs permissions

## Migration depuis le système local

Pour migrer le module `eau_minerale` du système local vers le système centralisé :

1. Créer `EauMineralePermissions` avec toutes les permissions
2. Enregistrer les permissions dans `PermissionRegistry`
3. Remplacer `MockPermissionService` local par le service centralisé
4. Adapter les widgets pour utiliser le nouveau système

## Prochaines étapes

- [ ] Intégrer avec Firebase Auth pour récupérer l'utilisateur courant
- [ ] Implémenter les repositories Firestore pour la persistance
- [ ] Créer les dialogues d'ajout/modification d'utilisateurs et rôles
- [ ] Ajouter l'audit trail des changements de permissions
- [ ] Implémenter la validation des permissions côté serveur

