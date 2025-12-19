# Intégration des permissions

Guide pour intégrer le système de permissions dans un module.

## Étapes d'intégration

### 1. Définir les permissions

Créer un fichier `permissions.dart` dans le module :

```dart
// lib/features/mon_module/domain/permissions/module_permissions.dart
final modulePermissions = [
  ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'mon_module',
    description: 'Permet de voir le tableau de bord',
  ),
  ActionPermission(
    id: 'create_item',
    name: 'Créer un élément',
    module: 'mon_module',
    description: 'Permet de créer un nouvel élément',
  ),
  ActionPermission(
    id: 'edit_item',
    name: 'Modifier un élément',
    module: 'mon_module',
    description: 'Permet de modifier un élément existant',
  ),
  ActionPermission(
    id: 'delete_item',
    name: 'Supprimer un élément',
    module: 'mon_module',
    description: 'Permet de supprimer un élément',
  ),
];
```

### 2. Enregistrer les permissions

Dans l'initialisation du module (par exemple dans `bootstrap.dart` ou lors du chargement) :

```dart
// Enregistrer les permissions
PermissionRegistry.instance.registerModulePermissions(
  'mon_module',
  modulePermissions,
);
```

### 3. Créer un adapter (optionnel)

Pour simplifier l'utilisation dans le module :

```dart
// lib/features/mon_module/application/adapters/permission_adapter.dart
class MonModulePermissionAdapter {
  static Future<bool> hasViewDashboard(Ref ref, String userId) {
    final service = ref.read(permissionServiceProvider);
    return service.hasPermission(userId, 'mon_module', 'view_dashboard');
  }
  
  static Future<bool> hasCreateItem(Ref ref, String userId) {
    final service = ref.read(permissionServiceProvider);
    return service.hasPermission(userId, 'mon_module', 'create_item');
  }
  
  // ... autres méthodes
}
```

### 4. Créer des providers

```dart
// lib/features/mon_module/application/providers.dart
final hasViewDashboardProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final service = ref.read(permissionServiceProvider);
    return service.hasPermission(userId, 'mon_module', 'view_dashboard');
  },
);

final hasCreateItemProvider = FutureProvider.family<bool, String>(
  (ref, userId) async {
    final service = ref.read(permissionServiceProvider);
    return service.hasPermission(userId, 'mon_module', 'create_item');
  },
);
```

### 5. Utiliser dans les widgets

#### Vérification simple

```dart
class MonModuleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider)!;
    final hasPermission = ref.watch(hasViewDashboardProvider(userId));
    
    return hasPermission.when(
      data: (hasAccess) {
        if (!hasAccess) {
          return const AccessDeniedScreen();
        }
        return const DashboardContent();
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

#### Avec PermissionGuard

```dart
class MonModuleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashboardContent(),
      floatingActionButton: PermissionGuard(
        module: 'mon_module',
        permission: 'create_item',
        child: FloatingActionButton(
          onPressed: () => createItem(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

### 6. Protéger les actions

Dans les contrôleurs :

```dart
class MonModuleController extends StateNotifier<AsyncValue<void>> {
  MonModuleController(this.ref) : super(const AsyncValue.data(null));
  
  final Ref ref;
  
  Future<void> createItem(Item item) async {
    final userId = ref.read(currentUserIdProvider)!;
    final hasPermission = await ref.read(
      hasCreateItemProvider(userId).future,
    );
    
    if (!hasPermission) {
      throw PermissionDeniedException('Cannot create item');
    }
    
    // Créer l'élément
    // ...
  }
}
```

## Exemple complet

Voir le module Eau Minérale pour un exemple complet d'intégration :

- `lib/features/eau_minerale/domain/permissions/eau_minerale_permissions.dart`
- `lib/features/eau_minerale/application/adapters/permission_adapter.dart`
- `lib/features/eau_minerale/presentation/widgets/permission_guard.dart`

## Bonnes pratiques

1. **Enregistrer tôt** – Enregistrer les permissions lors de l'initialisation
2. **Vérifier systématiquement** – Toujours vérifier les permissions avant les actions
3. **UI adaptative** – Masquer les éléments non autorisés
4. **Messages clairs** – Afficher des messages d'erreur clairs en cas de refus
5. **Tests** – Tester les permissions dans les tests

## Prochaines étapes

- [Vue d'ensemble](./overview.md)
- [Rôles par défaut](./default-roles.md)
