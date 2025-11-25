# Guide : Étendre le système de permissions aux autres modules

Ce guide explique comment adapter les autres modules (Gaz, Orange Money, Immobilier, Boutique) pour utiliser le système de permissions centralisé, comme c'est déjà fait pour le module Eau Minérale.

## Architecture du système

Le système de permissions centralisé est composé de :

1. **Core › Permissions** (`lib/core/permissions/`)
   - Entités : `ModulePermission`, `UserRole`, `ModuleUser`
   - Services : `PermissionService`, `PermissionRegistry`

2. **Module Administration** (`lib/features/administration/`)
   - Gestion centralisée des utilisateurs, rôles et permissions
   - Accessible via `/admin`

3. **Module Eau Minérale** (exemple de référence)
   - Permissions définies dans `domain/permissions/eau_minerale_permissions.dart`
   - Adapter dans `application/adapters/eau_minerale_permission_adapter.dart`
   - Widgets de contrôle d'accès dans `presentation/widgets/centralized_permission_guard.dart`

## Étapes pour chaque module

### 1. Créer le fichier de permissions

Créez `lib/features/[module]/domain/permissions/[module]_permissions.dart` :

```dart
import '../../../../../core/permissions/entities/module_permission.dart';

class GazPermissions {
  // Dashboard
  static const viewDashboard = ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'gaz',
    description: 'Permet de voir le tableau de bord',
  );

  // Sales
  static const viewSales = ActionPermission(
    id: 'view_sales',
    name: 'Voir les ventes',
    module: 'gaz',
    description: 'Permet de voir les ventes',
  );

  static const createSale = ActionPermission(
    id: 'create_sale',
    name: 'Créer une vente',
    module: 'gaz',
    description: 'Permet de créer une nouvelle vente',
  );

  // ... autres permissions selon les besoins du module

  /// Toutes les permissions du module
  static const all = [
    viewDashboard,
    viewSales,
    createSale,
    // ... toutes les permissions
  ];
}
```

### 2. Créer l'adapter

Créez `lib/features/[module]/application/adapters/[module]_permission_adapter.dart` :

```dart
import '../../../../../core/permissions/services/permission_service.dart';
import '../../../../../core/permissions/services/permission_registry.dart';
import '../../domain/permissions/gaz_permissions.dart';

/// Adapter pour utiliser le système de permissions centralisé.
class GazPermissionAdapter {
  GazPermissionAdapter({
    required this.permissionService,
    required this.userId,
  });

  final PermissionService permissionService;
  final String userId;

  static const String moduleId = 'gaz';

  /// Initialiser et enregistrer les permissions
  static void initialize() {
    PermissionRegistry.instance.registerModulePermissions(
      moduleId,
      GazPermissions.all,
    );
  }

  /// Vérifier si l'utilisateur a une permission spécifique
  Future<bool> hasPermission(String permissionId) async {
    return await permissionService.hasPermission(userId, moduleId, permissionId);
  }

  /// Vérifier si l'utilisateur a au moins une des permissions
  Future<bool> hasAnyPermission(Set<String> permissionIds) async {
    return await permissionService.hasAnyPermission(userId, moduleId, permissionIds);
  }

  /// Vérifier si l'utilisateur a toutes les permissions
  Future<bool> hasAllPermissions(Set<String> permissionIds) async {
    return await permissionService.hasAllPermissions(userId, moduleId, permissionIds);
  }
}
```

### 3. Ajouter les providers

Dans `lib/features/[module]/application/providers.dart` :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart'
    show permissionServiceProvider;
import '../../../core/permissions/services/permission_service.dart';
import '../domain/permissions/gaz_permissions.dart';
import '../application/adapters/gaz_permission_adapter.dart';

/// Initialiser les permissions lors du chargement du module
void _initializeGazPermissions() {
  GazPermissionAdapter.initialize();
}

/// Provider pour le service de permissions centralisé
final centralizedPermissionServiceProvider = Provider<PermissionService>(
  (ref) {
    _initializeGazPermissions();
    return ref.watch(permissionServiceProvider);
  },
);

/// Provider pour l'ID utilisateur courant
/// TODO: Remplacer par l'auth réelle
final currentUserIdProvider = Provider<String>(
  (ref) => 'user-1',
);

/// Provider pour l'adapter de permissions du module Gaz
final gazPermissionAdapterProvider = Provider<GazPermissionAdapter>(
  (ref) => GazPermissionAdapter(
    permissionService: ref.watch(centralizedPermissionServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);
```

### 4. Créer les widgets de permissions

Créez `lib/features/[module]/presentation/widgets/centralized_permission_guard.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/permissions/entities/module_permission.dart';
import '../../application/providers.dart';
import '../../domain/permissions/gaz_permissions.dart';

/// Widget qui affiche l'enfant uniquement si l'utilisateur a la permission requise.
class GazPermissionGuard extends ConsumerWidget {
  const GazPermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final ActionPermission permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapter = ref.watch(gazPermissionAdapterProvider);
    
    return FutureBuilder<bool>(
      future: adapter.hasPermission(permission.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
```

### 5. Utiliser dans les écrans

Dans vos écrans, utilisez le widget de permissions :

```dart
import '../../widgets/centralized_permission_guard.dart';
import '../../../domain/permissions/gaz_permissions.dart';

// Dans votre build method
GazPermissionGuard(
  permission: GazPermissions.createSale,
  child: FilledButton(
    onPressed: () => _showForm(),
    child: Text('Nouvelle Vente'),
  ),
)
```

### 6. Filtrer la navigation (si applicable)

Si votre module a une navigation avec plusieurs sections, filtrez-les comme dans `eau_minerale_shell_screen.dart` :

```dart
Future<List<_SectionConfig>> _getAccessibleSections(
  GazPermissionAdapter adapter,
) async {
  final accessible = <_SectionConfig>[];
  for (final section in _sections) {
    if (await adapter.canAccessSection(section.id)) {
      accessible.add(section);
    }
  }
  return accessible;
}
```

## Exemple complet : Module Gaz

### Structure de fichiers à créer

```
lib/features/gaz/
├── domain/
│   └── permissions/
│       └── gaz_permissions.dart          # Définition des permissions
├── application/
│   ├── adapters/
│   │   └── gaz_permission_adapter.dart   # Adapter pour le module
│   └── providers.dart                    # Ajouter les providers
└── presentation/
    └── widgets/
        └── centralized_permission_guard.dart  # Widgets de contrôle d'accès
```

### Permissions typiques par module

**Gaz** :
- `view_dashboard`, `view_sales`, `create_sale`, `view_stock`, `manage_depots`

**Orange Money** :
- `view_dashboard`, `view_transactions`, `create_transaction`, `view_agents`, `manage_agents`

**Immobilier** :
- `view_dashboard`, `view_properties`, `create_property`, `view_rentals`, `manage_rentals`

**Boutique** :
- `view_dashboard`, `view_sales`, `create_sale`, `view_stock`, `manage_products`, `view_cash_register`

## Gestion des rôles dans le module Administration

Une fois les permissions enregistrées pour chaque module :

1. **Créer des rôles spécifiques** pour chaque module dans le module Administration
2. **Attribuer des rôles** aux utilisateurs pour chaque module
3. **Ajouter des permissions personnalisées** au-delà du rôle de base

### Exemple de rôles par module

**Gaz** :
- Responsable : Accès complet
- Vendeur : Voir et créer des ventes
- Gestionnaire dépôt : Gérer les dépôts et le stock

**Orange Money** :
- Responsable : Accès complet
- Agent : Créer des transactions
- Superviseur : Voir toutes les transactions

## Avantages du système centralisé

- ✅ **Cohérence** : Même système pour tous les modules
- ✅ **Maintenabilité** : Gestion centralisée des permissions
- ✅ **Flexibilité** : Permissions granulaires par action
- ✅ **Sécurité** : Contrôle d'accès uniforme
- ✅ **Évolutivité** : Facile d'ajouter de nouveaux modules

## Checklist pour chaque module

- [ ] Créer le fichier de permissions (`[module]_permissions.dart`)
- [ ] Créer l'adapter (`[module]_permission_adapter.dart`)
- [ ] Ajouter les providers dans `providers.dart`
- [ ] Créer les widgets de permissions (`centralized_permission_guard.dart`)
- [ ] Intégrer dans les écrans existants
- [ ] Filtrer la navigation si applicable
- [ ] Tester avec différents rôles via le module Administration

## Prochaines étapes

1. Créer les permissions pour chaque module (Gaz, Orange Money, Immobilier, Boutique)
2. Créer les adapters pour chaque module
3. Intégrer dans les écrans existants
4. Tester avec différents rôles via le module Administration
5. Remplacer `currentUserIdProvider` par l'auth réelle (quand disponible)

