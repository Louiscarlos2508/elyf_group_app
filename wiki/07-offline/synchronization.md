# Synchronisation offline

Guide sur le mode offline-first et la synchronisation dans ELYF Group App.

## Vue d'ensemble

L'application fonctionne en mode **offline-first** :
- Données stockées localement (Isar)
- Synchronisation automatique avec Firestore
- Fonctionnement même sans connexion
- Résolution automatique des conflits

## Architecture

### Stockage local (Isar)

Toutes les données critiques sont stockées localement dans Isar :

```dart
@collection
class Product {
  @Id()
  int? id;
  
  String enterpriseId;
  String name;
  double price;
  DateTime updatedAt; // Pour la résolution de conflits
}
```

### Synchronisation

```
┌─────────────┐
│   Isar DB   │ ← Stockage local (toujours disponible)
└──────┬──────┘
       │
       │ Sync Manager
       │
┌──────▼──────┐
│  Firestore  │ ← Cloud (quand connexion disponible)
└─────────────┘
```

## Flux de données

### Lecture

1. **Essayer Isar d'abord** – Récupérer depuis la base locale
2. **Si vide, Firestore** – Récupérer depuis Firestore
3. **Sauvegarder localement** – Mettre en cache dans Isar

```dart
Future<List<Product>> getAll(String enterpriseId) async {
  // 1. Essayer Isar
  final local = await isar.products
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
    .collection('products')
    .get();
  
  final products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  
  // 3. Sauvegarder localement
  await isar.writeTxn(() async {
    for (final product in products) {
      await isar.products.put(product.toIsar());
    }
  });
  
  return products;
}
```

### Écriture

1. **Sauvegarder localement immédiatement** – Isar
2. **Synchroniser avec Firestore** – En arrière-plan
3. **Mettre à jour le statut** – Indicateur de synchronisation

```dart
Future<void> create(Product product) async {
  // 1. Sauvegarder localement
  await isar.writeTxn(() async {
    await isar.products.put(product.toIsar());
  });
  
  // 2. Synchroniser avec Firestore (async)
  _syncToFirestore(product);
}

Future<void> _syncToFirestore(Product product) async {
  try {
    await firestore
      .collection('enterprises')
      .doc(product.enterpriseId)
      .collection('products')
      .doc(product.id)
      .set(product.toMap());
    
    // Mettre à jour le statut de sync
    await _updateSyncStatus(product.id, SyncStatus.synced);
  } catch (e) {
    // Marquer comme non synchronisé
    await _updateSyncStatus(product.id, SyncStatus.pending);
  }
}
```

## Résolution des conflits

### Stratégie basée sur `updatedAt`

Quand une synchronisation détecte un conflit :

```dart
Future<void> syncProduct(Product local, Product remote) async {
  if (local.updatedAt.isAfter(remote.updatedAt)) {
    // Local est plus récent, utiliser local
    await firestore.update(local.toMap());
  } else if (remote.updatedAt.isAfter(local.updatedAt)) {
    // Remote est plus récent, utiliser remote
    await isar.products.put(remote.toIsar());
  } else {
    // Même timestamp, appliquer la logique métier
    await _resolveConflict(local, remote);
  }
}
```

### Logique métier

Pour les conflits complexes, appliquer la logique métier :

```dart
Future<void> _resolveConflict(Product local, Product remote) async {
  // Exemple : Priorité au prix le plus élevé
  if (local.price > remote.price) {
    await firestore.update(local.toMap());
  } else {
    await isar.products.put(remote.toIsar());
  }
}
```

## Sync Manager

Le Sync Manager gère la synchronisation automatique :

```dart
class SyncManager {
  Future<void> syncAll() async {
    // Synchroniser tous les modules
    await syncProducts();
    await syncSales();
    await syncStock();
    // ...
  }
  
  Future<void> syncProducts() async {
    final pending = await isar.products
      .filter()
      .syncStatusEqualTo(SyncStatus.pending)
      .findAll();
    
    for (final product in pending) {
      await _syncToFirestore(product);
    }
  }
}
```

## Indicateurs de synchronisation

### Dans l'UI

Afficher le statut de synchronisation :

```dart
class SyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    
    return syncStatus.when(
      data: (status) {
        if (status == SyncStatus.syncing) {
          return const CircularProgressIndicator();
        } else if (status == SyncStatus.pending) {
          return const Icon(Icons.cloud_off);
        } else {
          return const Icon(Icons.cloud_done);
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.error),
    );
  }
}
```

## Bonnes pratiques

1. **Toujours sauvegarder localement d'abord** – Disponibilité immédiate
2. **Synchroniser en arrière-plan** – Ne pas bloquer l'UI
3. **Gérer les erreurs** – Retry automatique en cas d'échec
4. **Résoudre les conflits** – Stratégie claire de résolution
5. **Indicateurs visuels** – Informer l'utilisateur du statut

## Prochaines étapes

- [Isar Database](./isar-database.md)
- [Gestion des conflits](./conflict-resolution.md)
