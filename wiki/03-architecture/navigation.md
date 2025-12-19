# Navigation avec GoRouter

Guide sur le système de navigation avec GoRouter dans ELYF Group App.

## Vue d'ensemble

GoRouter offre :
- Navigation déclarative
- Routes nommées
- Paramètres de route
- Redirections conditionnelles
- Deep linking
- Support web

## Configuration

### Router principal

Le router est défini dans `lib/app/router/app_router.dart` :

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isOnLogin = state.matchedLocation == '/login';
      
      if (!isAuthenticated && !isOnLogin) {
        return '/login';
      }
      
      if (isAuthenticated && isOnLogin) {
        return '/modules';
      }
      
      return null;
    },
    routes: [
      // Routes définies ici
    ],
  });
});
```

## Définition des routes

### Route simple

```dart
GoRoute(
  path: '/modules',
  name: AppRoute.moduleMenu.name,
  builder: (context, state) => const ModuleMenuScreen(),
),
```

### Route avec paramètres

```dart
GoRoute(
  path: '/products/:id',
  name: AppRoute.productDetail.name,
  builder: (context, state) {
    final productId = state.pathParameters['id']!;
    return ProductDetailScreen(productId: productId);
  },
),
```

### Route avec query parameters

```dart
GoRoute(
  path: '/products',
  name: AppRoute.products.name,
  builder: (context, state) {
    final filter = state.uri.queryParameters['filter'];
    return ProductsScreen(filter: filter);
  },
),
```

### Routes imbriquées

```dart
GoRoute(
  path: '/modules/boutique',
  name: AppRoute.homeBoutique.name,
  builder: (context, state) => const BoutiqueShellScreen(),
  routes: [
    GoRoute(
      path: 'sales',
      builder: (context, state) => const SalesScreen(),
    ),
    GoRoute(
      path: 'sales/:id',
      builder: (context, state) {
        final saleId = state.pathParameters['id']!;
        return SaleDetailScreen(saleId: saleId);
      },
    ),
  ],
),
```

## Navigation

### Navigation simple

```dart
// Dans un widget
context.go('/modules/boutique');
context.push('/products/123');
context.pop();
```

### Navigation avec nom de route

```dart
context.goNamed(
  AppRoute.productDetail.name,
  pathParameters: {'id': '123'},
);
```

### Navigation avec query parameters

```dart
context.go(
  Uri(
    path: '/products',
    queryParameters: {'filter': 'active'},
  ).toString(),
);
```

### Navigation avec données

```dart
context.push(
  '/products/123',
  extra: {'from': 'dashboard'},
);
```

## Redirections

### Redirection conditionnelle

```dart
GoRouter(
  redirect: (context, state) {
    final authState = ref.read(authStateProvider);
    
    // Rediriger vers login si non authentifié
    if (authState.value == null && state.matchedLocation != '/login') {
      return '/login';
    }
    
    // Rediriger vers modules si authentifié et sur login
    if (authState.value != null && state.matchedLocation == '/login') {
      return '/modules';
    }
    
    return null; // Pas de redirection
  },
  routes: [...],
);
```

### Redirection par route

```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    final hasPermission = checkAdminPermission();
    if (!hasPermission) {
      return '/modules';
    }
    return null;
  },
  builder: (context, state) => const AdminScreen(),
),
```

## Deep linking

### Configuration

GoRouter supporte automatiquement les deep links :

```dart
// URL: myapp://products/123
context.go('/products/123');

// URL: https://myapp.com/products/123?filter=active
context.go('/products/123?filter=active');
```

### Web

Pour le web, configurer dans `web/index.html` :

```html
<base href="/">
```

## Navigation adaptative

### NavigationRail vs NavigationBar

L'application utilise une navigation adaptative selon la taille d'écran :

```dart
class AdaptiveNavigationScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    
    return Scaffold(
      body: Row(
        children: [
          if (isWide) NavigationRail(...),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWide ? null : NavigationBar(...),
    );
  }
}
```

## Gestion des erreurs

### Page 404

```dart
GoRouter(
  errorBuilder: (context, state) => ErrorScreen(
    error: state.error,
  ),
  routes: [...],
);
```

## Bonnes pratiques

1. **Routes nommées** – Utiliser des enums pour les noms de routes
2. **Paramètres typés** – Valider les paramètres de route
3. **Redirections claires** – Logique de redirection simple
4. **Deep linking** – Tester les deep links
5. **Navigation conditionnelle** – Vérifier les permissions avant navigation

## Exemple complet

```dart
enum AppRoute {
  splash,
  login,
  modules,
  boutique,
  productDetail,
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/modules',
        name: AppRoute.modules.name,
        builder: (context, state) => const ModuleMenuScreen(),
      ),
      GoRoute(
        path: '/modules/boutique',
        name: AppRoute.boutique.name,
        builder: (context, state) => const BoutiqueShellScreen(),
        routes: [
          GoRoute(
            path: 'products/:id',
            name: AppRoute.productDetail.name,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductDetailScreen(productId: id);
            },
          ),
        ],
      ),
    ],
  );
});
```

## Prochaines étapes

- [Multi-tenant](./multi-tenant.md)
- [Guidelines de développement](../04-development/guidelines.md)
