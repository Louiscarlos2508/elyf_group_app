# Système de permissions

Guide complet sur le système de permissions de ELYF Group App.

## Vue d'ensemble

Le système de permissions est centralisé et permet de gérer les accès aux fonctionnalités de tous les modules de manière granulaire.

## Concepts

### Permissions

Une permission représente une action spécifique qu'un utilisateur peut effectuer dans un module.

```dart
ActionPermission(
  id: 'view_dashboard',
  name: 'Voir le tableau de bord',
  module: 'eau_minerale',
  description: 'Permet de voir le tableau de bord',
)
```

### Rôles

Un rôle est un ensemble de permissions. Les utilisateurs ont un rôle par module.

### Modules

Chaque module définit ses propres permissions et peut avoir ses propres rôles.

## Structure

```
core/permissions/
├── entities/
│   └── module_permission.dart
├── services/
│   ├── permission_service.dart
│   └── permission_registry.dart
└── widgets/
    └── permission_guard.dart
```

## Enregistrement des permissions

### Dans un module

Chaque module doit enregistrer ses permissions lors de l'initialisation :

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

## Vérification des permissions

### Dans un provider

```dart
final permissionService = ref.watch(permissionServiceProvider);
final hasPermission = await permissionService.hasPermission(
  userId,
  'eau_minerale',
  'create_production',
);
```

### Dans un widget

```dart
class ProductionButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(
      hasPermissionProvider('eau_minerale', 'create_production'),
    );
    
    if (!hasPermission) {
      return const SizedBox.shrink();
    }
    
    return ElevatedButton(
      onPressed: () => createProduction(),
      child: const Text('Créer une production'),
    );
  }
}
```

### Avec PermissionGuard

```dart
PermissionGuard(
  module: 'eau_minerale',
  permission: 'create_production',
  child: ElevatedButton(
    onPressed: () => createProduction(),
    child: const Text('Créer une production'),
  ),
)
```

## Rôles

### Rôles système

Les rôles système sont prédéfinis et ne peuvent pas être supprimés :

- **Super Admin** – Accès complet à tout
- **Admin** – Administration d'une entreprise
- **User** – Utilisateur standard

### Rôles personnalisés

Les administrateurs peuvent créer des rôles personnalisés avec des permissions spécifiques.

### Obtenir le rôle d'un utilisateur

```dart
final role = await permissionService.getUserRole(userId, 'eau_minerale');
```

## Intégration avec les modules

Chaque module doit :

1. **Définir ses permissions** – Liste complète des permissions du module
2. **Enregistrer les permissions** – Appeler `PermissionRegistry.instance.registerModulePermissions()`
3. **Vérifier les accès** – Utiliser `PermissionService` pour vérifier les permissions
4. **Protéger l'UI** – Utiliser `PermissionGuard` ou vérifier manuellement

## Bonnes pratiques

1. **Permissions spécifiques** – Une permission par action
2. **Noms clairs** – Noms de permissions explicites
3. **Vérification systématique** – Vérifier les permissions avant les actions
4. **UI adaptative** – Masquer les éléments non autorisés
5. **Documentation** – Documenter les permissions dans le README du module

## Prochaines étapes

- [Rôles par défaut](./default-roles.md)
- [Intégration](./integration.md)
