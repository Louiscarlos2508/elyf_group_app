# Isar Database

Guide sur l'utilisation d'Isar comme base de données locale dans ELYF Group App.

## Vue d'ensemble

Isar est utilisé pour le stockage local offline-first. Toutes les données critiques sont stockées dans Isar pour un accès rapide et un fonctionnement hors ligne.

## Configuration

### Initialisation

```dart
// lib/core/offline/isar_service.dart
class IsarService {
  static Isar? _isar;
  
  static Future<Isar> getInstance() async {
    if (_isar != null) return _isar!;
    
    _isar = await Isar.open(
      [
        ProductSchema,
        SaleSchema,
        StockMovementSchema,
        // ... autres schémas
      ],
      directory: (await getApplicationDocumentsDirectory()).path,
    );
    
    return _isar!;
  }
}
```

### Schémas

Définir les schémas Isar pour chaque entité :

```dart
@collection
class ProductIsar {
  @Id()
  int? id;
  
  @Index()
  String enterpriseId;
  
  String productId; // ID Firestore
  String name;
  double price;
  DateTime updatedAt;
  String syncStatus; // 'synced', 'pending', 'error'
  
  Product toDomain() {
    return Product(
      id: productId,
      name: name,
      price: price,
      updatedAt: updatedAt,
    );
  }
  
  factory ProductIsar.fromDomain(Product product, String enterpriseId) {
    return ProductIsar()
      ..productId = product.id
      ..enterpriseId = enterpriseId
      ..name = product.name
      ..price = product.price
      ..updatedAt = product.updatedAt
      ..syncStatus = 'pending';
  }
}
```

## Opérations CRUD

### Create

```dart
Future<void> createProduct(Product product) async {
  final isar = await IsarService.getInstance();
  
  await isar.writeTxn(() async {
    await isar.productIsars.put(
      ProductIsar.fromDomain(product, enterpriseId),
    );
  });
}
```

### Read

```dart
Future<List<Product>> getAllProducts(String enterpriseId) async {
  final isar = await IsarService.getInstance();
  
  final products = await isar.productIsars
    .filter()
    .enterpriseIdEqualTo(enterpriseId)
    .findAll();
  
  return products.map((p) => p.toDomain()).toList();
}

Future<Product?> getProductById(String productId) async {
  final isar = await IsarService.getInstance();
  
  final product = await isar.productIsars
    .filter()
    .productIdEqualTo(productId)
    .findFirst();
  
  return product?.toDomain();
}
```

### Update

```dart
Future<void> updateProduct(Product product) async {
  final isar = await IsarService.getInstance();
  
  await isar.writeTxn(() async {
    final existing = await isar.productIsars
      .filter()
      .productIdEqualTo(product.id)
      .findFirst();
    
    if (existing != null) {
      existing.name = product.name;
      existing.price = product.price;
      existing.updatedAt = product.updatedAt;
      existing.syncStatus = 'pending';
      
      await isar.productIsars.put(existing);
    }
  });
}
```

### Delete

```dart
Future<void> deleteProduct(String productId) async {
  final isar = await IsarService.getInstance();
  
  await isar.writeTxn(() async {
    final product = await isar.productIsars
      .filter()
      .productIdEqualTo(productId)
      .findFirst();
    
    if (product != null) {
      await isar.productIsars.delete(product.id!);
    }
  });
}
```

## Requêtes avancées

### Filtres

```dart
// Produits avec stock faible
final lowStock = await isar.productIsars
  .filter()
  .enterpriseIdEqualTo(enterpriseId)
  .quantityLessThan(10)
  .findAll();

// Produits récemment mis à jour
final recent = await isar.productIsars
  .filter()
  .enterpriseIdEqualTo(enterpriseId)
  .updatedAtGreaterThan(DateTime.now().subtract(Duration(days: 7)))
  .findAll();
```

### Tri

```dart
// Trier par nom
final sorted = await isar.productIsars
  .filter()
  .enterpriseIdEqualTo(enterpriseId)
  .sortByName()
  .findAll();

// Trier par prix décroissant
final byPrice = await isar.productIsars
  .filter()
  .enterpriseIdEqualTo(enterpriseId)
  .sortByPriceDesc()
  .findAll();
```

### Limite et offset

```dart
// Pagination
final page = await isar.productIsars
  .filter()
  .enterpriseIdEqualTo(enterpriseId)
  .offset(20) // Skip 20
  .limit(10)  // Take 10
  .findAll();
```

## Index

Créer des index pour améliorer les performances :

```dart
@collection
class ProductIsar {
  @Id()
  int? id;
  
  @Index()
  String enterpriseId;
  
  @Index(composite: [CompositeIndex('enterpriseId', 'updatedAt')])
  String productId;
  
  // ...
}
```

## Migrations

Gérer les migrations de schéma :

```dart
final isar = await Isar.open(
  schemas,
  schemaVersion: 2,
  migrationStrategy: MigrationStrategy(
    onUpgrade: (migration, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // Migration de la version 1 à 2
        migration.renameProperty('ProductIsar', 'oldField', 'newField');
      }
    },
  ),
);
```

## Bonnes pratiques

1. **Toujours filtrer par enterpriseId** – Isolation des données
2. **Utiliser des transactions** – Pour les opérations multiples
3. **Indexer les champs fréquemment recherchés** – Performance
4. **Gérer les migrations** – Évolution du schéma
5. **Nettoyer les données obsolètes** – Maintenance

## Prochaines étapes

- [Synchronisation](./synchronization.md)
- [Gestion des conflits](./conflict-resolution.md)
