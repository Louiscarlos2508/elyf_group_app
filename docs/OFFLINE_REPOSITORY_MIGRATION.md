# Guide de Migration vers OfflineRepository

Ce guide explique comment migrer les MockRepositories vers des OfflineRepositories pour activer le mode offline-first.

## Vue d'ensemble

L'infrastructure offline-first est déjà en place :
- `IsarService` : Base de données locale Isar
- `SyncManager` : Gestionnaire de synchronisation avec Firestore
- `ConnectivityService` : Surveillance de la connectivité
- `OfflineRepository<T>` : Classe de base pour repositories offline-first

## Architecture

### Collections Isar

Les collections Isar stockent les données localement. Collections disponibles :
- `EnterpriseCollection`
- `SaleCollection`
- `ProductCollection`
- `ExpenseCollection`
- `CustomerCollection`
- `AgentCollection`
- `TransactionCollection`
- `PropertyCollection`
- `TenantCollection`
- `ContractCollection`
- `PaymentCollection`
- `MachineCollection`
- `BobineCollection`
- `ProductionSessionCollection`

### OfflineRepository

Classe abstraite de base qui fournit :
- `saveToLocal()` : Sauvegarde locale
- `deleteFromLocal()` : Suppression locale
- `getByLocalId()` : Récupération par ID local
- `getAllForEnterprise()` : Récupération par entreprise
- `save()` : Sauvegarde avec synchronisation
- `delete()` : Suppression avec synchronisation
- `queueCreate()`, `queueUpdate()`, `queueDelete()` : File d'attente de synchronisation

## Étapes de Migration

### 1. Créer l'OfflineRepository

Exemple pour `ProductOfflineRepository` :

```dart
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/product_collection.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductOfflineRepository extends OfflineRepository<Product>
    implements ProductRepository {
  ProductOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'products';

  // Implémenter fromMap, toMap, getLocalId, getRemoteId, getEnterpriseId
  // Implémenter saveToLocal, deleteFromLocal, getByLocalId, getAllForEnterprise
  // Implémenter les méthodes de ProductRepository
}
```

### 2. Mettre à jour les Providers

Dans `lib/features/*/application/providers.dart` :

```dart
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final isarService = IsarService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return ProductOfflineRepository(
      isarService: isarService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
  },
);
```

### 3. Tester le Mode Offline

1. Activer le mode avion
2. Créer/modifier des données
3. Vérifier la persistance locale (redémarrer l'app)
4. Désactiver le mode avion
5. Vérifier la synchronisation avec Firestore

## Collections Manquantes

Si une entité n'a pas de collection Isar, créer `*_collection.dart` dans `lib/core/offline/collections/` :

```dart
import 'package:isar/isar.dart';

part 'my_entity_collection.g.dart';

@collection
class MyEntityCollection {
  Id id = Isar.autoIncrement;
  
  @Index()
  String? remoteId;
  
  @Index(unique: true)
  late String localId;
  
  @Index()
  late String enterpriseId;
  
  @Index()
  late String moduleType;
  
  // Champs de l'entité
  late String name;
  // ...
  
  DateTime? createdAt;
  DateTime? updatedAt;
  @Index()
  late DateTime localUpdatedAt;
  
  factory MyEntityCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    // ...
  }
  
  Map<String, dynamic> toMap() {
    // ...
  }
}
```

Puis ajouter la collection dans `isar_service.dart` :

```dart
_isar = await Isar.open(
  [
    // ... autres collections
    MyEntityCollectionSchema,
  ],
  // ...
);
```

## Synchronisation

Le `SyncManager` synchronise automatiquement les opérations en file d'attente quand :
- L'appareil est en ligne
- Une connexion est détectée
- Un intervalle de synchronisation est atteint

Les opérations sont traitées par `FirebaseSyncHandler` qui est configuré dans `bootstrap.dart`.

## Résolution de Conflits

Les conflits sont résolus avec la stratégie "last write wins" basée sur `updated_at`. Voir `ConflictResolver` dans `sync_manager.dart`.

## Bonnes Pratiques

1. **Toujours utiliser `enterpriseId` et `moduleType`** pour filtrer les données
2. **Générer des `localId` uniques** avec `generateLocalId()` ou `LocalIdGenerator.generate()`
3. **Gérer les erreurs** avec `ErrorHandler`
4. **Tester en mode offline** avant de déployer
5. **Vérifier la synchronisation** après les modifications

## Dépannage

### Les données ne se synchronisent pas
- Vérifier que `syncHandler` est configuré dans `bootstrap.dart`
- Vérifier la connectivité avec `isOnlineProvider`
- Vérifier les opérations en attente avec `pendingSyncCountProvider`

### Les données ne persistent pas localement
- Vérifier que la collection Isar est ajoutée dans `isar_service.dart`
- Vérifier que `saveToLocal()` est appelé
- Vérifier les logs Isar en mode debug

### Erreurs de synchronisation
- Vérifier les logs dans `sync_manager.dart`
- Vérifier la configuration Firestore
- Vérifier les permissions Firestore

