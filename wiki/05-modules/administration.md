# Module Administration

Module centralisé pour gérer les utilisateurs, rôles et permissions dans tous les modules de l'application.

## Fonctionnalités

### Gestion des modules

- Liste de tous les modules disponibles
- Navigation vers la gestion des utilisateurs par module
- Vue d'ensemble des modules activés par entreprise

### Gestion des utilisateurs

- Ajouter des utilisateurs à un module
- Attribuer des rôles aux utilisateurs
- Gérer les permissions personnalisées
- Activer/désactiver l'accès d'un utilisateur
- Voir l'historique des actions d'un utilisateur

### Gestion des rôles

- Créer de nouveaux rôles
- Modifier les permissions d'un rôle
- Supprimer des rôles (sauf les rôles système)
- Visualiser les permissions associées
- Dupliquer un rôle existant

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

## Utilisation

### Accès

1. Se connecter en tant qu'administrateur
2. Aller dans **Administration** depuis le menu principal
3. Naviguer entre les onglets : Modules, Utilisateurs, Rôles

### Ajouter un utilisateur

1. Aller dans l'onglet **Utilisateurs**
2. Sélectionner un module
3. Cliquer sur **Ajouter un utilisateur**
4. Remplir les informations
5. Attribuer un rôle
6. Sauvegarder

### Créer un rôle

1. Aller dans l'onglet **Rôles**
2. Cliquer sur **Nouveau rôle**
3. Définir le nom et la description
4. Sélectionner les permissions
5. Sauvegarder

## Intégration

### Enregistrer les permissions d'un module

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

### Vérifier les permissions

```dart
final hasPermission = ref.watch(
  hasPermissionProvider('eau_minerale', 'view_dashboard'),
);

if (!hasPermission) {
  return const AccessDeniedScreen();
}
```

## Rôles système

Les rôles système ne peuvent pas être supprimés :

- **Super Admin** – Accès complet à tout
- **Admin** – Administration d'une entreprise
- **User** – Utilisateur standard

## Prochaines étapes

- [Système de permissions](../06-permissions/overview.md)
- [Vue d'ensemble des modules](./overview.md)
