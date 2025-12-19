# State Management avec Riverpod

Guide complet sur la gestion d'état avec Riverpod dans ELYF Group App.

## Vue d'ensemble

Riverpod est utilisé pour toute la gestion d'état de l'application. Il offre :
- Type safety
- Testabilité
- Performance optimisée
- Dépendances explicites

## Types de Providers

### StateNotifier

Pour état mutable simple :

```dart
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
```

### AsyncNotifier

Pour état asynchrone :

```dart
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repository = ref.read(productRepositoryProvider);
    return repository.getAll();
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(productRepositoryProvider);
      return repository.getAll();
    });
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  () => ProductsNotifier(),
);
```

### FutureProvider

Pour données asynchrones simples :

```dart
final userProvider = FutureProvider<User?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getCurrentUser();
});
```

### StreamProvider

Pour flux de données :

```dart
final salesStreamProvider = StreamProvider<List<Sale>>((ref) {
  final repository = ref.read(saleRepositoryProvider);
  final enterpriseId = ref.read(currentEnterpriseProvider);
  return repository.watchAll(enterpriseId);
});
```

## Utilisation dans les widgets

### ConsumerWidget

```dart
class ProductsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    
    return productsAsync.when(
      data: (products) => ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductItem(products[index]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### ConsumerStatefulWidget

Pour état local + Riverpod :

```dart
class ProductForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    final productsNotifier = ref.read(productsProvider.notifier);
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Champs du formulaire
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                productsNotifier.addProduct(product);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
```

## Patterns courants

### Provider avec paramètres

```dart
final productProvider = FutureProvider.family<Product, String>(
  (ref, productId) async {
    final repository = ref.read(productRepositoryProvider);
    return repository.getById(productId);
  },
);

// Utilisation
final product = ref.watch(productProvider('product-123'));
```

### Provider dépendant d'un autre

```dart
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider).value ?? [];
  final filter = ref.watch(productFilterProvider);
  
  return products.where((p) => p.category == filter).toList();
});
```

### Provider auto-refresh

```dart
final autoRefreshProvider = StreamProvider<List<Sale>>((ref) {
  final repository = ref.read(saleRepositoryProvider);
  final enterpriseId = ref.watch(currentEnterpriseProvider);
  
  // Refresh toutes les 30 secondes
  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => repository.getAll(enterpriseId),
  ).asyncMap((_) => repository.getAll(enterpriseId));
});
```

## Gestion des erreurs

### AsyncValue

```dart
final productsAsync = ref.watch(productsProvider);

productsAsync.when(
  data: (products) => ProductsList(products),
  loading: () => const LoadingIndicator(),
  error: (error, stackTrace) {
    // Logger l'erreur
    developer.log(
      'Error loading products',
      error: error,
      stackTrace: stackTrace,
    );
    return ErrorMessage(error.toString());
  },
);
```

### Retry

```dart
final productsNotifier = ref.read(productsProvider.notifier);

// Retry manuel
productsAsync.when(
  error: (error, stack) => RetryButton(
    onRetry: () => productsNotifier.refresh(),
  ),
  // ...
);
```

## Tests

### Mock providers

```dart
testWidgets('ProductsList displays products', (tester) async {
  final container = ProviderContainer(
    overrides: [
      productsProvider.overrideWithValue(
        AsyncValue.data([Product(id: '1', name: 'Test')]),
      ),
    ],
  );
  
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ProductsList(),
    ),
  );
  
  expect(find.text('Test'), findsOneWidget);
});
```

## Bonnes pratiques

1. **Un provider par responsabilité** – Éviter les providers trop gros
2. **Utiliser AsyncNotifier pour état complexe** – Plus de contrôle
3. **Éviter les dépendances circulaires** – Architecture claire
4. **Tester les providers** – Unit tests pour la logique
5. **Documenter les providers** – Commentaires pour usage

## Prochaines étapes

- [Navigation](./navigation.md)
- [Guidelines de développement](../04-development/guidelines.md)
