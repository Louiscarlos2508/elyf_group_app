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

### Providers implémentés

Le système utilise les providers suivants (dans `lib/core/tenant/tenant_provider.dart`) :

- **`activeEnterpriseIdProvider`** : Stocke l'ID de l'entreprise active (Notifier avec persistance via SharedPreferences)
- **`activeEnterpriseProvider`** : Récupère l'objet Enterprise complet (FutureProvider)
- **`userAccessibleEnterprisesProvider`** : Liste des entreprises accessibles à l'utilisateur (utilise `currentUserIdProvider`)
- **`autoSelectEnterpriseProvider`** : Sélectionne automatiquement l'entreprise si l'utilisateur n'en a qu'une seule
- **`currentUserIdProvider`** : Provider pour l'ID de l'utilisateur connecté (dans `lib/core/auth/providers.dart`)

### Sélection de tenant

Le widget `EnterpriseSelectorWidget` (dans `lib/core/tenant/enterprise_selector_widget.dart`) permet de sélectionner l'entreprise active :

```dart
// Utilisation dans l'AppBar
EnterpriseSelectorWidget(
  compact: true, // Icône seulement
)

// Ou affichage complet
EnterpriseSelectorWidget(
  showLabel: true, // Affiche le nom de l'entreprise
)

// Méthode statique pour afficher depuis n'importe où
EnterpriseSelectorWidget.showSelector(context, ref);
```

**Fonctionnalités :**
- Mode compact : Icône seulement (pour AppBar)
- Mode normal : Affiche le nom de l'entreprise actuelle
- Méthode statique `showSelector()` : Affiche le sélecteur depuis n'importe quel contexte
- Affiche un snackbar de confirmation lors du changement d'entreprise
- Persistance : L'entreprise sélectionnée est sauvegardée localement

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

### Flux utilisateur

1. **Connexion** : L'utilisateur se connecte
2. **Vérification des accès** : Le système récupère toutes les entreprises accessibles via `userAccessibleEnterprisesProvider`
3. **Sélection initiale** :
   - Si une entreprise était sauvegardée → elle est restaurée automatiquement
   - Si l'utilisateur n'a qu'une seule entreprise → elle est sélectionnée automatiquement (via `autoSelectEnterpriseProvider`)
   - Sinon → l'utilisateur doit en sélectionner une via le widget de sélection
4. **Travail** : L'utilisateur travaille avec l'entreprise sélectionnée
5. **Changement** : L'utilisateur peut changer d'entreprise à tout moment via l'icône dans l'AppBar
   - Un snackbar de confirmation s'affiche avec le nom de l'entreprise sélectionnée
   - L'utilisateur est redirigé vers le menu des modules pour recharger avec la nouvelle entreprise

### Implémentation

```dart
// Dans EnterpriseSelectorWidget
if (selected != null && context.mounted) {
  final tenantNotifier = ref.read(activeEnterpriseIdProvider.notifier);
  await tenantNotifier.setActiveEnterpriseId(selected.id);

  // Rafraîchir les providers qui dépendent de l'entreprise active
  ref.invalidate(activeEnterpriseProvider);

  // Afficher un message de confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Entreprise sélectionnée : ${selected.name}'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );

  // Rediriger vers le menu des modules
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

## Intégration dans les routes

Les routes des modules utilisent automatiquement l'entreprise active via des wrappers (dans `lib/app/router/module_route_wrappers.dart`) :

- `/modules/eau_sachet` → `EauMineraleRouteWrapper` utilise `activeEnterpriseProvider`
- `/modules/gaz` → `GazRouteWrapper` utilise `activeEnterpriseProvider`
- `/modules/orange_money` → `OrangeMoneyRouteWrapper` utilise `activeEnterpriseProvider`
- `/modules/immobilier` → `ImmobilierRouteWrapper` utilise `activeEnterpriseProvider`
- `/modules/boutique` → `BoutiqueRouteWrapper` utilise `activeEnterpriseProvider`

**Gestion du cas "aucune entreprise sélectionnée"** :
- Si aucune entreprise n'est sélectionnée, un écran s'affiche avec :
  - Un message explicatif
  - Un bouton pour sélectionner une entreprise (redirige vers `/modules`)
  - Un bouton pour retourner au menu

## Utilisation dans les widgets

Pour utiliser l'entreprise active dans un widget, utilisez `activeEnterpriseProvider` :

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const Text('Aucune entreprise sélectionnée');
        }
        // Utiliser enterprise.id pour filtrer les données
        return MyContent(enterpriseId: enterprise.id);
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }
}
```

**Important** : Ne plus utiliser d'IDs hardcodés ! Tous les widgets doivent utiliser `activeEnterpriseProvider`.

## Améliorations implémentées

✅ **Sélection automatique** : Si l'utilisateur n'a qu'une seule entreprise, elle est sélectionnée automatiquement au démarrage  
✅ **Confirmation visuelle** : Un snackbar s'affiche lors du changement d'entreprise  
✅ **Gestion des erreurs** : Écran dédié si aucune entreprise n'est sélectionnée  
✅ **Provider utilisateur** : `currentUserIdProvider` pour récupérer l'ID de l'utilisateur connecté  
✅ **Wrappers de routes** : Tous les modules utilisent l'entreprise active automatiquement

## Bonnes pratiques

1. **Toujours filtrer par enterpriseId** – Ne jamais oublier le filtre
2. **Valider l'accès** – Vérifier les permissions avant les opérations
3. **Isolation stricte** – Une entreprise ne doit jamais voir les données d'une autre
4. **Switch propre** – Invalider les providers lors du switch
5. **Cache séparé** – Cache Isar séparé par entreprise
6. **Utiliser les providers** – Ne jamais hardcoder les IDs d'entreprise

## Prochaines étapes

- [Guidelines de développement](../04-development/guidelines.md)
- [Synchronisation offline](../07-offline/synchronization.md)
