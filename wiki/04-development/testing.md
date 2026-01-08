# Tests

Guide pour écrire et exécuter des tests dans ELYF Group App.

## Vue d'ensemble

L'application utilise trois types de tests :
- **Unit tests** – Logique métier
- **Widget tests** – Composants UI
- **Integration tests** – Flux complets

## Structure

```
test/
├── unit/              # Tests unitaires
│   ├── domain/
│   ├── application/
│   └── data/
├── widget/            # Tests de widgets
│   └── presentation/
└── integration/       # Tests d'intégration
```

## Unit Tests

### Domain Layer

Tester les entités et la logique métier :

```dart
// test/unit/domain/entities/product_test.dart
void main() {
  group('Product', () {
    test('creates product with required fields', () {
      final product = Product(
        id: '1',
        name: 'Test Product',
        price: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      expect(product.id, '1');
      expect(product.name, 'Test Product');
      expect(product.price, 1000);
    });
    
    test('copyWith creates new instance with updated fields', () {
      final original = Product(/* ... */);
      final updated = original.copyWith(name: 'Updated Name');
      
      expect(updated.name, 'Updated Name');
      expect(updated.id, original.id);
    });
  });
}
```

### Application Layer

Tester les providers et contrôleurs :

```dart
// test/unit/application/products_notifier_test.dart
void main() {
  group('ProductsNotifier', () {
    test('loads products successfully', () async {
      final container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
        ],
      );
      
      final notifier = container.read(productsProvider.notifier);
      await notifier.future;
      
      final products = container.read(productsProvider).value;
      expect(products, isNotEmpty);
    });
    
    test('handles errors gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(shouldFail: true),
          ),
        ],
      );
      
      final notifier = container.read(productsProvider.notifier);
      await notifier.future;
      
      final state = container.read(productsProvider);
      expect(state.hasError, isTrue);
    });
  });
}
```

### Data Layer

Tester les repositories :

```dart
// test/unit/data/repositories/product_repository_test.dart
void main() {
  group('ProductRepositoryImpl', () {
    late FirebaseFirestore firestore;
    late DriftService driftService;
    late ProductRepositoryImpl repository;
    
    setUp(() {
      firestore = FirebaseFirestore.instance;
      driftService = DriftService.instance;
      repository = ProductRepositoryImpl(
        firestore: firestore,
        isar: isar,
      );
    });
    
    test('getAll returns products from Firestore', () async {
      // Setup test data
      // ...
      
      final products = await repository.getAll('enterprise-1');
      
      expect(products, isNotEmpty);
    });
  });
}
```

## Widget Tests

### Test simple

```dart
// test/widget/presentation/product_card_test.dart
void main() {
  testWidgets('ProductCard displays product information', (tester) async {
    final product = Product(
      id: '1',
      name: 'Test Product',
      price: 1000,
      // ...
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(product: product),
      ),
    );
    
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('1000 FCFA'), findsOneWidget);
  });
  
  testWidgets('ProductCard calls onTap when tapped', (tester) async {
    var tapped = false;
    final product = Product(/* ... */);
    
    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(
          product: product,
          onTap: () => tapped = true,
        ),
      ),
    );
    
    await tester.tap(find.byType(ProductCard));
    expect(tapped, isTrue);
  });
}
```

### Test avec Riverpod

```dart
// test/widget/presentation/products_list_test.dart
void main() {
  testWidgets('ProductsList displays products from provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWithValue(
          AsyncValue.data([
            Product(id: '1', name: 'Product 1'),
            Product(id: '2', name: 'Product 2'),
          ]),
        ),
      ],
    );
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ProductsList(),
        ),
      ),
    );
    
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });
}
```

## Integration Tests

### Test de flux complet

```dart
// test/integration/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('complete product creation flow', (tester) async {
    // 1. Naviguer vers l'écran de création
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Ajouter un produit'));
    await tester.pumpAndSettle();
    
    // 2. Remplir le formulaire
    await tester.enterText(find.byKey(Key('name_field')), 'New Product');
    await tester.enterText(find.byKey(Key('price_field')), '2000');
    
    // 3. Soumettre
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    
    // 4. Vérifier que le produit apparaît dans la liste
    expect(find.text('New Product'), findsOneWidget);
  });
}
```

## Mocks

### Mock Repository

```dart
// test/helpers/mock_product_repository.dart
class MockProductRepository implements ProductRepository {
  final List<Product> _products = [];
  bool shouldFail = false;
  
  @override
  Future<List<Product>> getAll(String enterpriseId) async {
    if (shouldFail) {
      throw Exception('Network error');
    }
    return _products;
  }
  
  void addProduct(Product product) {
    _products.add(product);
  }
}
```

## Exécution

### Tous les tests

```bash
flutter test
```

### Tests spécifiques

```bash
flutter test test/unit/domain/
flutter test test/widget/presentation/
```

### Avec couverture

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Bonnes pratiques

1. **Tests isolés** – Chaque test doit être indépendant
2. **Nommage clair** – Noms de tests descriptifs
3. **Arrange-Act-Assert** – Structure claire
4. **Mocks appropriés** – Utiliser des mocks pour les dépendances
5. **Couverture** – Viser > 80% de couverture

## Prochaines étapes

- [Guidelines](./guidelines.md)
- [Structure des modules](./module-structure.md)
