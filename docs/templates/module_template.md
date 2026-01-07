# Template de Module Feature

Ce document décrit la structure standard que chaque module (feature) doit suivre.

## Structure de Dossiers

```
features/{module_name}/
├── presentation/          # Couche UI
│   ├── screens/          # Écrans principaux
│   │   └── sections/     # Sections d'écrans (optionnel)
│   └── widgets/          # Widgets spécifiques au module
│       └── {feature}/    # Groupement par fonctionnalité (optionnel)
├── application/          # State management (Riverpod)
│   ├── controllers/      # Controllers métier
│   └── providers.dart    # Providers Riverpod
├── domain/              # Logique métier
│   ├── entities/        # Entités métier
│   ├── repositories/    # Interfaces de repositories
│   ├── services/        # Services métier
│   └── adapters/        # Adapters (optionnel)
└── data/                # Implémentations
    └── repositories/     # Repositories (Mock ou Offline)
```

## Fichiers Obligatoires

### 1. README.md

Chaque module doit avoir un `README.md` à la racine avec :
- Vue d'ensemble du module
- Structure du domaine (entités principales)
- Écrans principaux
- Navigation
- Routes

### 2. shared.dart et core.dart

Fichiers barrel pour réduire les imports :
- `shared.dart` : Réexporte les composants partagés
- `core.dart` : Réexporte les services core

### 3. providers.dart

Fichier centralisant tous les providers Riverpod du module.

## Conventions de Nommage

### Fichiers
- **Screens** : `{name}_screen.dart` (ex: `dashboard_screen.dart`)
- **Widgets** : `{name}_widget.dart` ou `{name}.dart` (ex: `expense_card.dart`)
- **Controllers** : `{name}_controller.dart` (ex: `sale_controller.dart`)
- **Entities** : `{name}.dart` (ex: `sale.dart`, `product.dart`)
- **Repositories** : `{name}_repository.dart` (ex: `sale_repository.dart`)
- **Services** : `{name}_service.dart` (ex: `dashboard_calculation_service.dart`)

### Classes
- **Screens** : `{Name}Screen` (ex: `DashboardScreen`)
- **Widgets** : `{Name}Widget` ou `{Name}` (ex: `ExpenseCard`)
- **Controllers** : `{Name}Controller` (ex: `SaleController`)
- **Entities** : `{Name}` (ex: `Sale`, `Product`)
- **Repositories** : `{Name}Repository` (ex: `SaleRepository`)
- **Services** : `{Name}Service` (ex: `DashboardCalculationService`)

## Règles de Structure

### 1. Taille des Fichiers
- **Objectif** : < 200 lignes par fichier
- **Maximum** : 500 lignes (à éviter)
- **Critique** : > 1000 lignes (à découper immédiatement)

### 2. Organisation des Providers

Tous les providers doivent être dans `application/providers.dart` :

```dart
// Repository providers
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  // ...
});

// Service providers
final dashboardCalculationServiceProvider = Provider<DashboardCalculationService>((ref) {
  return DashboardCalculationService();
});

// Controller providers
final saleControllerProvider = StateNotifierProvider<SaleController, SaleState>((ref) {
  // ...
});
```

### 3. Organisation des Controllers

Les controllers doivent être dans `application/controllers/` :

```dart
class SaleController extends StateNotifier<SaleState> {
  final SaleRepository _repository;
  
  SaleController(this._repository) : super(SaleState.initial());
  
  // Méthodes métier
}
```

### 4. Organisation des Services

Les services doivent être dans `domain/services/` :

```dart
class DashboardCalculationService {
  int calculateTotalRevenue(List<Sale> sales) {
    // Logique métier
  }
}
```

## Exemple de Module Complet

Voir `features/boutique/` ou `features/gaz/` pour des exemples de modules bien structurés.

## Checklist de Création d'un Nouveau Module

- [ ] Créer la structure de dossiers (presentation, application, domain, data)
- [ ] Créer `README.md` avec documentation
- [ ] Créer `shared.dart` et `core.dart` (fichiers barrel)
- [ ] Créer `application/providers.dart`
- [ ] Créer les entités dans `domain/entities/`
- [ ] Créer les interfaces de repository dans `domain/repositories/`
- [ ] Créer les services dans `domain/services/`
- [ ] Créer les implémentations de repository dans `data/repositories/`
- [ ] Créer les controllers dans `application/controllers/`
- [ ] Créer les écrans dans `presentation/screens/`
- [ ] Créer les widgets dans `presentation/widgets/`
- [ ] Vérifier que tous les fichiers font < 200 lignes
- [ ] Vérifier l'architecture avec `dart run dependency_validator`

