# Module Administration

Module centralisé pour gérer les utilisateurs, rôles et permissions dans tous les modules de l'application.

## Fonctionnalités

### 1. Gestion des Modules
- Liste de tous les modules disponibles
- Navigation vers la gestion des utilisateurs par module

### 2. Gestion des Utilisateurs
- Ajouter des utilisateurs à un module
- Attribuer des rôles aux utilisateurs
- Gérer les permissions personnalisées
- Activer/désactiver l'accès d'un utilisateur

### 3. Gestion des Rôles
- Créer de nouveaux rôles
- Modifier les permissions d'un rôle
- Supprimer des rôles (sauf les rôles système)
- Visualiser les permissions associées

## Structure

```
administration/
├── domain/
│   ├── entities/
│   │   └── admin_module.dart      # Entités pour les modules
│   └── repositories/
│       └── admin_repository.dart   # Interface du repository
├── data/
│   └── repositories/
│       └── mock_admin_repository.dart  # Implémentation mock
├── application/
│   └── providers.dart              # Providers Riverpod
└── presentation/
    └── screens/
        ├── admin_home_screen.dart   # Écran principal avec onglets
        └── sections/
            ├── admin_modules_list.dart
            ├── admin_users_section.dart
            └── admin_roles_section.dart
```

## Intégration

### 1. Ajouter le module au router

```dart
GoRoute(
  path: '/admin',
  name: AppRoute.admin.name,
  builder: (context, state) => const AdminHomeScreen(),
),
```

### 2. Enregistrer les permissions d'un module

Dans le module (ex: eau_minerale), lors de l'initialisation :

```dart
final permissions = [
  ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'eau_minerale',
    description: 'Permet de voir le tableau de bord',
  ),
  // ... autres permissions
];

PermissionRegistry.instance.registerModulePermissions(
  'eau_minerale',
  permissions,
);
```

### 3. Utiliser les permissions dans un module

```dart
final permissionService = ref.watch(permissionServiceProvider);
final hasPermission = await permissionService.hasPermission(
  userId,
  'eau_minerale',
  'create_production',
);
```

## TODO

- [ ] Implémenter le dialogue d'ajout d'utilisateur
- [ ] Implémenter le dialogue de création/modification de rôle
- [ ] Implémenter la liste des utilisateurs par module
- [ ] Implémenter la gestion des permissions personnalisées
- [ ] Intégrer avec Firebase Auth et Firestore
- [ ] Ajouter la validation des permissions
- [ ] Ajouter l'audit trail des changements

