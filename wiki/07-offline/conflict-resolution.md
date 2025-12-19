# Gestion des conflits

Guide sur la résolution des conflits lors de la synchronisation dans ELYF Group App.

## Vue d'ensemble

Les conflits surviennent quand :
- Une donnée est modifiée localement et sur le serveur
- La synchronisation détecte des versions différentes
- Il faut décider quelle version garder

## Stratégies de résolution

### 1. Last Write Wins (LWW)

La version la plus récente gagne, basée sur `updatedAt` :

```dart
Future<void> resolveConflict(Product local, Product remote) async {
  if (local.updatedAt.isAfter(remote.updatedAt)) {
    // Local est plus récent
    await firestore.update(local.toMap());
  } else {
    // Remote est plus récent
    await isar.products.put(remote.toIsar());
  }
}
```

### 2. Logique métier

Pour les cas complexes, appliquer la logique métier :

```dart
Future<void> resolveSaleConflict(Sale local, Sale remote) async {
  // Si la vente locale est validée, elle a priorité
  if (local.status == SaleStatus.validated && 
      remote.status != SaleStatus.validated) {
    await firestore.update(local.toMap());
    return;
  }
  
  // Sinon, utiliser la version la plus récente
  if (local.updatedAt.isAfter(remote.updatedAt)) {
    await firestore.update(local.toMap());
  } else {
    await isar.sales.put(remote.toIsar());
  }
}
```

### 3. Merge intelligent

Fusionner les changements quand possible :

```dart
Future<Product> mergeProduct(Product local, Product remote) async {
  // Fusionner les champs modifiés
  return Product(
    id: local.id,
    name: local.updatedAt.isAfter(remote.updatedAt) 
      ? local.name 
      : remote.name,
    price: local.updatedAt.isAfter(remote.updatedAt) 
      ? local.price 
      : remote.price,
    // Garder les autres champs de la version la plus récente
    updatedAt: DateTime.now(),
  );
}
```

### 4. Intervention utilisateur

Pour les conflits critiques, demander à l'utilisateur :

```dart
Future<void> resolveConflictWithUser(
  Product local,
  Product remote,
  BuildContext context,
) async {
  final choice = await showDialog<ConflictResolution>(
    context: context,
    builder: (context) => ConflictResolutionDialog(
      local: local,
      remote: remote,
    ),
  );
  
  switch (choice) {
    case ConflictResolution.keepLocal:
      await firestore.update(local.toMap());
      break;
    case ConflictResolution.keepRemote:
      await isar.products.put(remote.toIsar());
      break;
    case ConflictResolution.merge:
      final merged = await mergeProduct(local, remote);
      await firestore.update(merged.toMap());
      await isar.products.put(merged.toIsar());
      break;
  }
}
```

## Détection des conflits

### Pendant la synchronisation

```dart
Future<void> syncProduct(Product local) async {
  try {
    final remoteDoc = await firestore
      .collection('enterprises')
      .doc(local.enterpriseId)
      .collection('products')
      .doc(local.id)
      .get();
    
    if (remoteDoc.exists) {
      final remote = Product.fromFirestore(remoteDoc);
      
      // Détecter le conflit
      if (local.updatedAt != remote.updatedAt) {
        await resolveConflict(local, remote);
      } else {
        // Pas de conflit, synchroniser normalement
        await firestore.update(local.toMap());
      }
    } else {
      // Nouveau produit, créer dans Firestore
      await firestore.set(local.toMap());
    }
  } catch (e) {
    // Gérer l'erreur
    await _markAsError(local.id, e);
  }
}
```

## Gestion des erreurs

### Marquer comme erreur

```dart
Future<void> _markAsError(String productId, Exception error) async {
  final isar = await IsarService.getInstance();
  
  await isar.writeTxn(() async {
    final product = await isar.productIsars
      .filter()
      .productIdEqualTo(productId)
      .findFirst();
    
    if (product != null) {
      product.syncStatus = 'error';
      product.syncError = error.toString();
      await isar.productIsars.put(product);
    }
  });
}
```

### Retry automatique

```dart
Future<void> retryFailedSyncs() async {
  final isar = await IsarService.getInstance();
  
  final failed = await isar.productIsars
    .filter()
    .syncStatusEqualTo('error')
    .findAll();
  
  for (final product in failed) {
    try {
      await syncProduct(product.toDomain());
    } catch (e) {
      // Log l'erreur mais continue
      developer.log('Retry failed', error: e);
    }
  }
}
```

## Bonnes pratiques

1. **Stratégie claire** – Définir la stratégie de résolution par type d'entité
2. **Timestamp précis** – Utiliser `updatedAt` pour détecter les conflits
3. **Logique métier** – Appliquer la logique métier quand nécessaire
4. **Intervention utilisateur** – Pour les conflits critiques
5. **Retry automatique** – Réessayer les synchronisations échouées

## Prochaines étapes

- [Synchronisation](./synchronization.md)
- [Isar Database](./isar-database.md)
