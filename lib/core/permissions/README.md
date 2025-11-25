# Core › Permissions

Système centralisé de gestion des permissions et rôles pour tous les modules.

## Structure

- `entities/` - Entités de base (ModulePermission, UserRole, ModuleUser)
- `services/` - Services pour la gestion des permissions (PermissionService, PermissionRegistry)
- `widgets/` - Widgets réutilisables pour le contrôle d'accès

## Utilisation

### 1. Enregistrer les permissions d'un module

```dart
// Dans le module eau_minerale
final permissions = [
  ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'eau_minerale',
    description: 'Permet de voir le tableau de bord',
  ),
  ActionPermission(
    id: 'create_production',
    name: 'Créer une production',
    module: 'eau_minerale',
    description: 'Permet de créer une nouvelle production',
  ),
  // ... autres permissions
];

PermissionRegistry.instance.registerModulePermissions(
  'eau_minerale',
  permissions,
);
```

### 2. Vérifier les permissions

```dart
final permissionService = ref.watch(permissionServiceProvider);
final hasPermission = await permissionService.hasPermission(
  userId,
  'eau_minerale',
  'create_production',
);
```

### 3. Obtenir le rôle d'un utilisateur

```dart
final role = await permissionService.getUserRole(userId, 'eau_minerale');
```

## Intégration avec les modules

Chaque module doit :
1. Définir ses permissions
2. Les enregistrer dans PermissionRegistry
3. Utiliser PermissionService pour vérifier les accès

