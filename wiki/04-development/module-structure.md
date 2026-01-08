# Structure des modules

Guide pour créer et structurer un nouveau module dans ELYF Group App.

## Vue d'ensemble

Chaque module suit une architecture en couches :

```
module_name/
├── presentation/      # Couche présentation
├── application/        # Couche application
├── domain/            # Couche domaine
└── data/              # Couche données
```

## Création d'un module

### 1. Structure de base

Créer la structure de dossiers :

```bash
mkdir -p lib/features/mon_module/{presentation/{screens,widgets},application/{controllers},domain/{entities,repositories},data/repositories}
```

### 2. Domain Layer

#### Entities

Définir les entités métier :

```dart
// lib/features/mon_module/domain/entities/mon_entity.dart
class MonEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const MonEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  
  MonEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

#### Repository Interface

Définir l'interface du repository :

```dart
// lib/features/mon_module/domain/repositories/mon_repository.dart
abstract class MonRepository {
  Future<List<MonEntity>> getAll(String enterpriseId);
  Future<MonEntity?> getById(String enterpriseId, String id);
  Future<void> create(String enterpriseId, MonEntity entity);
  Future<void> update(String enterpriseId, MonEntity entity);
  Future<void> delete(String enterpriseId, String id);
  Stream<List<MonEntity>> watchAll(String enterpriseId);
}
```

### 3. Data Layer

#### Repository Implementation

Implémenter le repository :

```dart
// lib/features/mon_module/data/repositories/mon_repository_impl.dart
class MonRepositoryImpl implements MonRepository {
  final FirebaseFirestore firestore;
  final DriftService driftService;
  
  MonRepositoryImpl({
    required this.firestore,
    required this.isar,
  });
  
  @override
  Future<List<MonEntity>> getAll(String enterpriseId) async {
    // 1. Essayer de récupérer depuis Drift (offline)
    final local = await isar.monEntities
      .filter()
      .enterpriseIdEqualTo(enterpriseId)
      .findAll();
    
    if (local.isNotEmpty) {
      return local.map((e) => e.toDomain()).toList();
    }
    
    // 2. Récupérer depuis Firestore
    final snapshot = await firestore
      .collection('enterprises')
      .doc(enterpriseId)
      .collection('mon_module')
      .get();
    
    final entities = snapshot.docs
      .map((doc) => MonEntity.fromFirestore(doc))
      .toList();
    
    // 3. Sauvegarder localement
    await isar.writeTxn(() async {
      for (final entity in entities) {
        await isar.monEntities.put(entity.toIsar());
      }
    });
    
    return entities;
  }
  
  // Autres méthodes...
}
```

### 4. Application Layer

#### Providers

Créer les providers Riverpod :

```dart
// lib/features/mon_module/application/providers.dart
final monRepositoryProvider = Provider<MonRepository>((ref) {
  return MonRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    isar: ref.read(isarProvider),
  );
});

final monEntitiesProvider = FutureProvider.family<List<MonEntity>, String>(
  (ref, enterpriseId) async {
    final repository = ref.read(monRepositoryProvider);
    return repository.getAll(enterpriseId);
  },
);

final monEntityProvider = FutureProvider.family<MonEntity?, String>(
  (ref, entityId) async {
    final enterpriseId = ref.read(currentEnterpriseIdProvider)!;
    final repository = ref.read(monRepositoryProvider);
    return repository.getById(enterpriseId, entityId);
  },
);
```

#### Controllers

Créer les contrôleurs pour les actions :

```dart
// lib/features/mon_module/application/controllers/mon_controller.dart
class MonController extends StateNotifier<AsyncValue<void>> {
  MonController(this.ref) : super(const AsyncValue.data(null));
  
  final Ref ref;
  
  Future<void> create(MonEntity entity) async {
    state = const AsyncValue.loading();
    
    try {
      final enterpriseId = ref.read(currentEnterpriseIdProvider)!;
      final repository = ref.read(monRepositoryProvider);
      
      await repository.create(enterpriseId, entity);
      
      // Invalider le provider pour recharger la liste
      ref.invalidate(monEntitiesProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final monControllerProvider = StateNotifierProvider<MonController, AsyncValue<void>>(
  (ref) => MonController(ref),
);
```

### 5. Presentation Layer

#### Screens

Créer les écrans :

```dart
// lib/features/mon_module/presentation/screens/mon_list_screen.dart
class MonListScreen extends ConsumerWidget {
  const MonListScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseId = ref.watch(currentEnterpriseIdProvider)!;
    final entitiesAsync = ref.watch(monEntitiesProvider(enterpriseId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Module')),
      body: entitiesAsync.when(
        data: (entities) => _MonList(entities: entities),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/mon_module/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonList extends StatelessWidget {
  final List<MonEntity> entities;
  
  const _MonList({required this.entities});
  
  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return const Center(child: Text('Aucun élément'));
    }
    
    return ListView.builder(
      itemCount: entities.length,
      itemBuilder: (context, index) => _MonListItem(entities[index]),
    );
  }
}

class _MonListItem extends StatelessWidget {
  final MonEntity entity;
  
  const _MonListItem(this.entity);
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(entity.name),
      onTap: () => context.push('/mon_module/${entity.id}'),
    );
  }
}
```

#### Shell Screen

Créer l'écran shell avec navigation :

```dart
// lib/features/mon_module/presentation/screens/mon_module_shell_screen.dart
class MonModuleShellScreen extends StatelessWidget {
  const MonModuleShellScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.list),
          label: 'Liste',
          route: '/mon_module',
        ),
        NavigationDestination(
          icon: const Icon(Icons.dashboard),
          label: 'Tableau de bord',
          route: '/mon_module/dashboard',
        ),
      ],
      child: const Outlet(), // GoRouter Outlet
    );
  }
}
```

### 6. Routes

Ajouter les routes dans `app_router.dart` :

```dart
GoRoute(
  path: '/modules/mon_module',
  name: 'monModule',
  builder: (context, state) => const MonModuleShellScreen(),
  routes: [
    GoRoute(
      path: '',
      builder: (context, state) => const MonListScreen(),
    ),
    GoRoute(
      path: 'create',
      builder: (context, state) => const MonCreateScreen(),
    ),
    GoRoute(
      path: ':id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MonDetailScreen(id: id);
      },
    ),
  ],
),
```

### 7. Permissions

Enregistrer les permissions du module :

```dart
// Dans l'initialisation du module
final permissions = [
  ActionPermission(
    id: 'view_mon_module',
    name: 'Voir le module',
    module: 'mon_module',
    description: 'Permet d\'accéder au module',
  ),
  ActionPermission(
    id: 'create_mon_entity',
    name: 'Créer',
    module: 'mon_module',
    description: 'Permet de créer des entités',
  ),
];

PermissionRegistry.instance.registerModulePermissions(
  'mon_module',
  permissions,
);
```

## Checklist

- [ ] Structure de dossiers créée
- [ ] Entities définies
- [ ] Repository interface créée
- [ ] Repository implémenté (Firestore + Drift)
- [ ] Providers créés
- [ ] Controllers créés
- [ ] Screens créés
- [ ] Shell screen avec navigation
- [ ] Routes ajoutées
- [ ] Permissions enregistrées
- [ ] Tests écrits
- [ ] README.md du module créé

## Prochaines étapes

- [Widgets réutilisables](./reusable-widgets.md)
- [Tests](./testing.md)
