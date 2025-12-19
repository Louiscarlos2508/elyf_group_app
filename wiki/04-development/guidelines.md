# Guidelines de développement

Règles et bonnes pratiques pour développer dans ELYF Group App.

## Règles générales

### Taille des fichiers

- **Aucun fichier > 200 lignes**
- Découper les fichiers trop longs en widgets/services plus petits
- Un fichier = une responsabilité

### Structure des modules

Chaque module doit suivre cette structure :

```
module_name/
├── presentation/
│   ├── screens/          # Écrans principaux
│   └── widgets/          # Widgets spécifiques
├── application/
│   ├── controllers/      # Contrôleurs Riverpod
│   └── providers.dart    # Export des providers
├── domain/
│   ├── entities/         # Modèles de données
│   └── repositories/     # Interfaces
└── data/
    └── repositories/     # Implémentations
```

## Code Style

### Formatage

```bash
# Formater automatiquement
dart format lib/

# Vérifier le formatage
dart format --set-exit-if-changed lib/
```

### Conventions de nommage

- **Classes** : `PascalCase` (ex: `ProductListScreen`)
- **Variables/Fonctions** : `camelCase` (ex: `getProducts`)
- **Fichiers** : `snake_case.dart` (ex: `product_list_screen.dart`)
- **Constantes** : `lowerCamelCase` avec `const` (ex: `const maxItems = 10`)

### Documentation

```dart
/// Classe représentant un produit dans le module boutique.
/// 
/// Un produit contient les informations de base nécessaires
/// pour la gestion des stocks et des ventes.
class Product {
  /// Identifiant unique du produit.
  final String id;
  
  /// Nom du produit affiché à l'utilisateur.
  final String name;
  
  /// Prix de vente unitaire en FCFA.
  final double price;
}
```

## Widgets

### Découpage

Découper les écrans complexes en widgets enfants :

```dart
// ❌ Mauvais : Écran trop long
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 300 lignes de code...
    );
  }
}

// ✅ Bon : Découpage en widgets
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ProductsAppBar(),
      body: _ProductsBody(),
      floatingActionButton: _AddProductButton(),
    );
  }
}

class _ProductsAppBar extends StatelessWidget { /* ... */ }
class _ProductsBody extends StatelessWidget { /* ... */ }
class _AddProductButton extends StatelessWidget { /* ... */ }
```

### Const constructors

Utiliser `const` autant que possible :

```dart
// ✅ Bon
const Text('Hello');

// ❌ Mauvais
Text('Hello');
```

### Performance

- Utiliser `ListView.builder` pour les longues listes
- Éviter les opérations coûteuses dans `build()`
- Utiliser `compute()` pour les calculs lourds

## State Management

### Providers

- Un provider par responsabilité
- Utiliser `AsyncNotifier` pour état complexe
- Éviter les dépendances circulaires

### Exemple

```dart
// ✅ Bon : Provider simple et clair
final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  () => ProductsNotifier(),
);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repository = ref.read(productRepositoryProvider);
    final enterpriseId = ref.read(currentEnterpriseIdProvider)!;
    return repository.getAll(enterpriseId);
  }
}
```

## Gestion des erreurs

### Try-catch

Toujours gérer les erreurs :

```dart
Future<void> saveProduct(Product product) async {
  try {
    await repository.create(product);
    showSuccessMessage('Produit créé avec succès');
  } on NetworkException catch (e) {
    showErrorMessage('Erreur de connexion: ${e.message}');
  } on ValidationException catch (e) {
    showErrorMessage('Données invalides: ${e.message}');
  } catch (e, stackTrace) {
    developer.log(
      'Erreur inattendue',
      error: e,
      stackTrace: stackTrace,
    );
    showErrorMessage('Une erreur est survenue');
  }
}
```

### Logging

Utiliser `developer.log` au lieu de `print` :

```dart
import 'dart:developer' as developer;

developer.log(
  'Product created',
  name: 'boutique.products',
  error: error,
  stackTrace: stackTrace,
);
```

## Tests

### Structure

```
test/
├── unit/              # Tests unitaires
├── widget/             # Tests de widgets
└── integration/        # Tests d'intégration
```

### Exemple de test

```dart
void main() {
  group('ProductsNotifier', () {
    test('loads products successfully', () async {
      final container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(MockRepository()),
        ],
      );
      
      final notifier = container.read(productsProvider.notifier);
      await notifier.future;
      
      expect(container.read(productsProvider).value, isNotEmpty);
    });
  });
}
```

## Multi-tenant

### Toujours filtrer par enterpriseId

```dart
// ✅ Bon
final products = await repository.getAll(enterpriseId);

// ❌ Mauvais
final products = await repository.getAll();
```

### Vérifier l'accès

```dart
final hasAccess = ref.watch(hasModuleAccessProvider('boutique'));
if (!hasAccess) {
  return const ModuleNotAvailableScreen();
}
```

## Offline

### Sauvegarder localement d'abord

```dart
// ✅ Bon : Sauvegarde locale immédiate
await isar.products.put(product);
// Puis synchronisation async
await syncToFirestore(product);
```

### Gérer les conflits

```dart
if (local.updatedAt.isAfter(remote.updatedAt)) {
  // Local est plus récent, utiliser local
  await firestore.update(local.toMap());
} else {
  // Remote est plus récent, utiliser remote
  await isar.products.put(remote);
}
```

## UI/UX

### Cohérence visuelle

- Utiliser les composants du thème
- Respecter la palette de couleurs
- Utiliser les styles de boutons définis

### Formulaires

- Validation claire
- Messages d'erreur explicites
- Support offline

### Navigation

- Navigation adaptative (Rail/Bar)
- Breadcrumbs pour navigation profonde
- Retour intuitif

## Checklist avant commit

- [ ] Code formaté (`dart format`)
- [ ] Analyse statique passée (`flutter analyze`)
- [ ] Tests passent (`flutter test`)
- [ ] Aucun fichier > 200 lignes
- [ ] Documentation à jour
- [ ] Gestion des erreurs
- [ ] Support offline (si applicable)
- [ ] Filtrage par enterpriseId (si applicable)

## Prochaines étapes

- [Structure des modules](./module-structure.md)
- [Widgets réutilisables](./reusable-widgets.md)
- [Tests](./testing.md)
