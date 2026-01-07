# Guide des Patterns du Projet

Ce document décrit les patterns et conventions utilisés dans le projet Elyf Group App.

## Architecture

### Structure des Modules

Chaque module (eau_minerale, gaz, orange_money, etc.) suit la structure suivante :

```
lib/features/<module>/
  ├── domain/
  │   ├── entities/          # Entités métier
  │   ├── repositories/       # Interfaces de repositories
  │   └── services/          # Services métier
  ├── application/
  │   ├── controllers/        # Contrôleurs Riverpod
  │   └── providers.dart     # Providers Riverpod
  └── presentation/
      ├── screens/           # Écrans
      └── widgets/          # Widgets réutilisables
```

### State Management

Le projet utilise **Riverpod** pour la gestion d'état.

#### Controllers

Les controllers encapsulent la logique métier et l'état :

```dart
class SalesController {
  final SaleRepository _repository;
  
  SalesController(this._repository);
  
  Future<void> createSale(Sale sale) async {
    // Logique métier
  }
}
```

#### Providers

Les providers exposent les controllers et les données :

```dart
final salesControllerProvider = Provider<SalesController>(
  (ref) => SalesController(ref.watch(saleRepositoryProvider)),
);
```

## Widgets

### Découpage des Widgets

**Règle** : Aucun fichier widget ne doit dépasser 200 lignes.

#### Pattern d'Extraction

1. Identifier les sections logiques
2. Extraire chaque section en widget séparé
3. Créer des helpers pour la logique réutilisable
4. Utiliser des composants réutilisables pour l'UI

#### Exemple

```dart
// Avant (500+ lignes)
class LargeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),      // 50 lignes
        _buildFilters(),     // 100 lignes
        _buildList(),        // 200 lignes
        _buildActions(),     // 150 lignes
      ],
    );
  }
}

// Après (découpé)
class LargeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(),
        ScreenFilters(),
        ScreenList(),
        ScreenActions(),
      ],
    );
  }
}
```

### Helpers

Les helpers contiennent la logique réutilisable :

```dart
class ScreenHelpers {
  static String formatCurrency(int amount) {
    // Logique de formatage
  }
}
```

## Gestion d'Erreurs

### Système Centralisé

Le projet utilise un système centralisé de gestion d'erreurs :

```dart
import 'package:elyf_groupe_app/core/errors/errors.dart';

try {
  // Code qui peut échouer
} catch (e, stackTrace) {
  final appException = ErrorHandler.instance.handleError(e, stackTrace);
  ErrorLogger.instance.logError(e, stackTrace, 'Context');
  // Afficher l'erreur à l'utilisateur
  showDialog(
    context: context,
    builder: (_) => AppErrorWidget(error: appException),
  );
}
```

### Types d'Exceptions

- `NetworkException` : Erreurs de réseau
- `AuthenticationException` : Erreurs d'authentification
- `AuthorizationException` : Erreurs d'autorisation
- `ValidationException` : Erreurs de validation
- `NotFoundException` : Ressources non trouvées
- `StorageException` : Erreurs de stockage
- `SyncException` : Erreurs de synchronisation
- `UnknownException` : Erreurs inconnues

## Stockage Sécurisé

### SecureStorageService

Utilisez `SecureStorageService` pour stocker des données sensibles :

```dart
final storage = SecureStorageService();

// Écrire
await storage.write('user_token', token);

// Lire
final token = await storage.read('user_token');

// Supprimer
await storage.delete('user_token');
```

## Formatage

### Helpers de Formatage

Utilisez les helpers pour le formatage :

```dart
// Formatage de devise
final formatted = InvoicePrintHelpers.formatCurrency(amount);

// Formatage de date
final formatted = InvoicePrintHelpers.formatDate(date);
```

## Multi-tenant

### Filtrage par Entreprise

Tous les widgets et services doivent filtrer par `enterpriseId` :

```dart
class SalesScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider);
    final sales = ref.watch(salesProvider(enterpriseId));
    // ...
  }
}
```

## Tests

### Structure des Tests

Les tests suivent la structure du code source :

```
test/
  └── features/
      └── <module>/
          ├── domain/
          ├── application/
          └── presentation/
```

## Conventions de Nommage

- **Classes** : PascalCase (`SalesController`)
- **Variables** : camelCase (`salesList`)
- **Fichiers** : snake_case (`sales_controller.dart`)
- **Constantes** : camelCase avec `const` (`const maxRetries = 3`)

## Documentation

### Doc Comments

Toutes les classes publiques doivent avoir des doc comments :

```dart
/// Service pour gérer les ventes.
/// 
/// Ce service encapsule la logique métier pour créer, modifier
/// et supprimer des ventes.
class SaleService {
  // ...
}
```

### Paramètres

Documentez les paramètres des méthodes publiques :

```dart
/// Crée une nouvelle vente.
/// 
/// [sale] : L'entité vente à créer
/// Retourne l'ID de la vente créée
Future<String> createSale(Sale sale) async {
  // ...
}
```

