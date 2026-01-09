# Guide d'Implémentation - Module Eau Minérale

## Vue d'ensemble

Ce guide explique comment implémenter de nouvelles fonctionnalités dans le module Eau Minérale en suivant l'architecture Clean Architecture et les patterns établis.

## 🏗️ Patterns d'Implémentation

### 1. Créer un OfflineRepository

**Template** :

```dart
import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/x.dart';
import '../../domain/repositories/x_repository.dart';

/// Offline-first repository for X entities (eau_minerale module).
class XOfflineRepository extends OfflineRepository<X>
    implements XRepository {
  XOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'x_collection';

  @override
  X fromMap(Map<String, dynamic> map) {
    return X(
      id: map['id'] as String? ?? map['localId'] as String,
      // ... autres champs
    );
  }

  @override
  Map<String, dynamic> toMap(X entity) {
    return {
      'id': entity.id,
      // ... autres champs
    };
  }

  @override
  String getLocalId(X entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(X entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(X entity) => enterpriseId;

  @override
  Future<void> saveToLocal(X entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(X entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
  }

  @override
  Future<X?> getByLocalId(String localId) async {
    // Implémentation standard
  }

  @override
  Future<List<X>> getAllForEnterprise(String enterpriseId) async {
    // Implémentation standard
  }

  // Implémenter les méthodes de XRepository
  @override
  Future<List<X>> fetchAll() async {
    return await getAllForEnterprise(enterpriseId);
  }

  @override
  Future<String> create(X entity) async {
    final entityWithId = entity.id.isEmpty
        ? entity.copyWith(id: LocalIdGenerator.generate())
        : entity;
    await save(entityWithId);
    return entityWithId.id;
  }
}
```

### 2. Créer un Controller

**Template** :

```dart
import '../../domain/entities/x.dart';
import '../../domain/repositories/x_repository.dart';

class XController {
  XController(this._repository);

  final XRepository _repository;

  Future<List<X>> fetchAll() async {
    return await _repository.fetchAll();
  }

  Future<X?> getById(String id) async {
    return await _repository.getById(id);
  }

  Future<String> create(X entity) async {
    return await _repository.create(entity);
  }

  Future<void> update(X entity) async {
    return await _repository.update(entity);
  }

  Future<void> delete(String id) async {
    return await _repository.delete(id);
  }
}
```

### 3. Créer un Provider

**Template** :

```dart
// Dans repository_providers.dart
final xRepositoryProvider = Provider<XRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return XOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

// Dans controller_providers.dart
final xControllerProvider = Provider<XController>(
  (ref) => XController(ref.watch(xRepositoryProvider)),
);

// Dans state_providers.dart
final xListProvider = FutureProvider.autoDispose<List<X>>(
  (ref) => ref.watch(xControllerProvider).fetchAll(),
);
```

## 🔄 Migration depuis MockRepository

### Étapes de Migration

1. **Créer l'OfflineRepository**
   - Copier le template ci-dessus
   - Implémenter `fromMap()` et `toMap()`
   - Implémenter toutes les méthodes de l'interface

2. **Mettre à jour le Provider**
   - Remplacer `MockXRepository` par `XOfflineRepository`
   - Ajouter les dépendances nécessaires (driftService, syncManager, etc.)

3. **Tester**
   - Vérifier que les données sont sauvegardées localement
   - Vérifier que la synchronisation fonctionne
   - Tester offline/online

4. **Supprimer le MockRepository**
   - Une fois que tout fonctionne, supprimer le fichier mock

### Exemple de Migration

**Avant** :
```dart
final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => MockStockRepository(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(productRepositoryProvider),
  ),
);
```

**Après** :
```dart
final stockRepositoryProvider = Provider<StockRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return StockOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
      inventoryRepository: ref.watch(inventoryRepositoryProvider),
      productRepository: ref.watch(productRepositoryProvider),
    );
  },
);
```

## 🧪 Tests

### Test d'un OfflineRepository

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/data/repositories/x_offline_repository.dart';

void main() {
  group('XOfflineRepository', () {
    late XOfflineRepository repository;
    
    setUp(() {
      // Setup repository avec mocks
    });

    test('should create entity', () async {
      final entity = X(/* ... */);
      final id = await repository.create(entity);
      expect(id, isNotEmpty);
    });

    test('should fetch all entities', () async {
      final entities = await repository.fetchAll();
      expect(entities, isA<List<X>>());
    });
  });
}
```

## 📝 Best Practices

### 1. Toujours utiliser les Controllers

```dart
// ✅ CORRECT
final controller = ref.watch(xControllerProvider);
final items = await controller.fetchAll();

// ❌ INCORRECT
final repository = ref.watch(xRepositoryProvider);
final items = await repository.fetchAll();
```

### 2. Gérer les Erreurs

```dart
try {
  await controller.create(entity);
} catch (e) {
  ErrorHandler.instance.handleError(e, stackTrace);
  // Afficher message d'erreur à l'utilisateur
}
```

### 3. Utiliser enterpriseId

Toujours récupérer `enterpriseId` depuis `activeEnterpriseProvider` :

```dart
final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
```

### 4. Logging

Utiliser `developer.log` pour les actions importantes :

```dart
developer.log(
  'Created entity: ${entity.id}',
  name: 'XController',
);
```

## 🔍 Debugging

### Vérifier la Synchronisation

1. Ouvrir les DevTools
2. Vérifier les logs de `SyncManager`
3. Vérifier la file d'attente dans Drift

### Vérifier les Données Locales

Les données sont stockées dans Drift (SQLite). Utiliser un outil SQLite pour inspecter :
- Table `sync_operations` : Opérations en attente de sync
- Table `records` : Données locales

### Vérifier Firestore

Vérifier dans la console Firebase que les données sont bien synchronisées :
- Collection : `enterprises/{enterpriseId}/modules/eau_minerale/collections/{collectionName}`

## 🚀 Prochaines Étapes

### Repositories à Migrer

1. `InventoryRepository` → `InventoryOfflineRepository`
2. `BobineStockQuantityRepository` → `BobineStockQuantityOfflineRepository`
3. `PackagingStockRepository` → `PackagingStockOfflineRepository`
4. `CreditRepository` → `CreditOfflineRepository`
5. `ActivityRepository` → `ActivityOfflineRepository`
6. `DailyWorkerRepository` → `DailyWorkerOfflineRepository`
7. `ReportRepository` → `ReportOfflineRepository`

### Améliorations Futures

1. Tests unitaires pour tous les controllers
2. Tests d'intégration pour la synchronisation
3. Optimisation des requêtes
4. Pagination pour les grandes listes

