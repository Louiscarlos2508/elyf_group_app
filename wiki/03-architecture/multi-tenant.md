# Architecture Multi-tenant

Guide sur l'architecture multi-entreprises de ELYF Group App.

## Vue d'ensemble

L'application supporte plusieurs entreprises (tenants) avec :
- Isolation des données par entreprise
- Modules activables par entreprise
- Utilisateurs et permissions par entreprise
- Switch rapide entre entreprises

## Structure des données

### Firestore

```
enterprises/
  {enterpriseId}/
    modules/          # Modules activés
    users/            # Utilisateurs de l'entreprise
    settings/         # Configuration
    
    # Données métier par module
    eau_minerale/
      products/
      sales/
      ...
    gaz/
      ...
```

### Isar (local)

Chaque entreprise a ses collections locales avec `enterpriseId` comme filtre.

## Gestion du tenant actif

### Provider de tenant

```dart
final currentEnterpriseProvider = StateProvider<Enterprise?>((ref) => null);

final currentEnterpriseIdProvider = Provider<String?>((ref) {
  return ref.watch(currentEnterpriseProvider)?.id;
});
```

### Sélection de tenant

```dart
class TenantSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterprises = ref.watch(userEnterprisesProvider);
    final current = ref.watch(currentEnterpriseProvider);
    
    return DropdownButton<Enterprise>(
      value: current,
      items: enterprises.map((e) => 
        DropdownMenuItem(value: e, child: Text(e.name))
      ).toList(),
      onChanged: (enterprise) {
        ref.read(currentEnterpriseProvider.notifier).state = enterprise;
        // Recharger les données pour la nouvelle entreprise
        ref.invalidate(allDataProviders);
      },
    );
  }
}
```

## Filtrage des données

### Repository pattern

Tous les repositories acceptent `enterpriseId` :

```dart
abstract class ProductRepository {
  Future<List<Product>> getAll(String enterpriseId);
  Future<Product?> getById(String enterpriseId, String productId);
  Future<void> create(String enterpriseId, Product product);
}
```

### Utilisation dans les providers

```dart
final productsProvider = FutureProvider.family<List<Product>, String>(
  (ref, enterpriseId) async {
    final repository = ref.read(productRepositoryProvider);
    return repository.getAll(enterpriseId);
  },
);

// Dans un widget
final enterpriseId = ref.watch(currentEnterpriseIdProvider)!;
final products = ref.watch(productsProvider(enterpriseId));
```

## Modules par entreprise

### Activation des modules

Chaque entreprise peut activer/désactiver des modules :

```dart
class Enterprise {
  final String id;
  final String name;
  final List<String> enabledModules; // ['eau_minerale', 'gaz', ...]
}
```

### Vérification d'accès

```dart
final hasModuleAccessProvider = Provider.family<bool, String>(
  (ref, moduleId) {
    final enterprise = ref.watch(currentEnterpriseProvider);
    return enterprise?.enabledModules.contains(moduleId) ?? false;
  },
);

// Utilisation
final hasAccess = ref.watch(hasModuleAccessProvider('eau_minerale'));
if (!hasAccess) {
  return const ModuleNotAvailableScreen();
}
```

## Synchronisation

### Isar avec enterpriseId

Toutes les entités locales incluent `enterpriseId` :

```dart
@collection
class Product {
  @Id()
  int? id;
  
  String enterpriseId; // Filtre par entreprise
  String name;
  // ...
}
```

### Synchronisation Firestore

```dart
Future<void> syncEnterprise(String enterpriseId) async {
  // Synchroniser uniquement les données de cette entreprise
  final products = await firestore
    .collection('enterprises')
    .doc(enterpriseId)
    .collection('products')
    .get();
  
  // Sauvegarder localement
  await isar.writeTxn(() async {
    for (final doc in products.docs) {
      await isar.products.put(Product.fromFirestore(doc));
    }
  });
}
```

## Permissions par entreprise

### Structure

```dart
class UserEnterprise {
  final String userId;
  final String enterpriseId;
  final String role;
  final List<String> permissions;
}
```

### Vérification

```dart
final userEnterprisePermissionsProvider = Provider.family<List<String>, String>(
  (ref, enterpriseId) {
    final userId = ref.watch(currentUserIdProvider);
    final userEnterprise = ref.watch(userEnterpriseProvider(userId, enterpriseId));
    return userEnterprise?.permissions ?? [];
  },
);
```

## Switch d'entreprise

### Flux

1. Utilisateur sélectionne une nouvelle entreprise
2. Mettre à jour `currentEnterpriseProvider`
3. Invalider tous les providers de données
4. Recharger les données pour la nouvelle entreprise
5. Naviguer vers le menu des modules

```dart
void switchEnterprise(Enterprise enterprise) {
  ref.read(currentEnterpriseProvider.notifier).state = enterprise;
  
  // Invalider tous les providers
  ref.invalidate(productsProvider);
  ref.invalidate(salesProvider);
  // ...
  
  // Naviguer vers le menu
  context.go('/modules');
}
```

## Isolation des données

### Firestore Rules

```javascript
match /enterprises/{enterpriseId}/{document=**} {
  // Vérifier que l'utilisateur a accès à cette entreprise
  allow read, write: if request.auth != null 
    && exists(/databases/$(database)/documents/user_enterprises/$(request.auth.uid + '_' + enterpriseId));
}
```

### Validation côté client

Toujours vérifier `enterpriseId` avant les opérations :

```dart
Future<void> createProduct(Product product) async {
  final enterpriseId = ref.read(currentEnterpriseIdProvider);
  if (enterpriseId == null) {
    throw Exception('No enterprise selected');
  }
  
  // Créer avec le bon enterpriseId
  await repository.create(enterpriseId, product);
}
```

## Bonnes pratiques

1. **Toujours filtrer par enterpriseId** – Ne jamais oublier le filtre
2. **Valider l'accès** – Vérifier les permissions avant les opérations
3. **Isolation stricte** – Une entreprise ne doit jamais voir les données d'une autre
4. **Switch propre** – Invalider les providers lors du switch
5. **Cache séparé** – Cache Isar séparé par entreprise

## Prochaines étapes

- [Guidelines de développement](../04-development/guidelines.md)
- [Synchronisation offline](../07-offline/synchronization.md)
