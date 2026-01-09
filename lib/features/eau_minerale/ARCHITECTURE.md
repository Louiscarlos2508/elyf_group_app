# Architecture - Module Eau Minérale

## Vue d'ensemble

Le module Eau Minérale suit une **architecture Clean Architecture** avec séparation stricte des couches : Domain, Data, Application, et Presentation.

## 🏗️ Structure des Couches

### 1. Domain (Couche Domaine)

Couche métier pure, indépendante des frameworks et technologies.

#### Entities (Entités)

**Entités principales** :
- `Product` - Produit fini ou matière première
- `Sale` - Vente complète avec workflow de validation
- `Customer` - Client avec historique de crédits
- `ProductionSession` - Session de production avec périodes
- `StockMovement` - Mouvement de stock (entrée/sortie/ajustement)
- `ExpenseRecord` - Dépense opérationnelle
- `Employee` - Employé permanent (fixe)
- `SalaryPayment` - Paiement de salaire mensuel
- `ProductionPayment` - Paiement de production hebdomadaire
- `Machine` - Machine de production
- `BobineStock` - Stock de bobines
- `PackagingStock` - Stock d'emballages

#### Repositories (Interfaces)

- `ProductRepository` - Interface pour la gestion des produits
- `SaleRepository` - Interface pour la gestion des ventes
- `CustomerRepository` - Interface pour la gestion des clients
- `StockRepository` - Interface pour la gestion des stocks
- `ProductionSessionRepository` - Interface pour la gestion de la production
- `FinanceRepository` - Interface pour la gestion des dépenses
- `SalaryRepository` - Interface pour la gestion des salaires
- `MachineRepository` - Interface pour la gestion des machines
- `InventoryRepository` - Interface pour la gestion de l'inventaire
- `BobineStockQuantityRepository` - Interface pour la gestion des bobines
- `PackagingStockRepository` - Interface pour la gestion des emballages

#### Services (Services Métier)

**Domain Services** :
- `SaleService` - Logique métier pour les ventes
- `ProductionService` - Logique métier pour la production
- `DashboardCalculationService` - Calculs pour le tableau de bord
- `ReportCalculationService` - Calculs pour les rapports
- `ProductCalculationService` - Calculs liés aux produits

### 2. Data (Couche Données)

Implémentations concrètes des repositories et services de données.

#### Repositories Offline

**Repositories migrés vers Offline-first** ✅ :
- `ProductOfflineRepository` ✅
- `SaleOfflineRepository` ✅
- `CustomerOfflineRepository` ✅
- `ProductionSessionOfflineRepository` ✅
- `MachineOfflineRepository` ✅
- `StockOfflineRepository` ✅ (nouveau)
- `SalaryOfflineRepository` ✅ (nouveau)
- `FinanceOfflineRepository` ✅ (nouveau)

**Repositories encore Mock** ⚠️ :
- `InventoryRepository` → MockInventoryRepository
- `BobineStockQuantityRepository` → MockBobineStockQuantityRepository
- `PackagingStockRepository` → MockPackagingStockRepository
- `ActivityRepository` → MockActivityRepository
- `CreditRepository` → MockCreditRepository
- `DailyWorkerRepository` → MockDailyWorkerRepository
- `ReportRepository` → MockReportRepository

**Caractéristiques** :
- Stockage local dans Drift/SQLite
- `enterpriseId` utilisé pour isolation multi-tenant
- `moduleType = 'eau_minerale'` pour tous les repositories
- Support offline-first avec synchronisation automatique

### 3. Application (Couche Application)

Couche de logique métier orchestrée par les controllers.

#### Controllers

**Controllers disponibles** ✅ :
- `ProductController` - Gestion des produits
- `SalesController` - Gestion des ventes
- `ClientsController` - Gestion des clients
- `StockController` - Gestion des stocks
- `ProductionSessionController` - Gestion de la production
- `FinancesController` - Gestion des dépenses
- `SalaryController` - Gestion des salaires
- `MachineController` - Gestion des machines
- `InventoryController` - Gestion de l'inventaire
- `BobineStockQuantityController` - Gestion des bobines
- `PackagingStockController` - Gestion des emballages
- `ActivityController` - Gestion des activités
- `ReportController` - Gestion des rapports

**Pattern Controller** :
```dart
class XController {
  XController(this._repository);

  final XRepository _repository;

  Future<X> create(X entity) async {
    return await _repository.create(entity);
    // Sync automatique via OfflineRepository
  }
}
```

#### Providers (Riverpod)

Tous les providers utilisent les controllers, jamais les repositories directement.

```dart
// ✅ CORRECT
final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productControllerProvider).fetchProducts(),
);

// ❌ INCORRECT
final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).fetchProducts(), // ❌
);
```

### 4. Presentation (Couche Présentation)

Interface utilisateur Flutter.

#### Écrans Principaux

- `EauMineraleShellScreen` - Écran principal avec navigation adaptative

#### Sections

- `DashboardScreen` - Tableau de bord avec KPIs
- `ProductionScreen` - Gestion de la production
- `SalesScreen` - Gestion des ventes
- `StockScreen` - Gestion des stocks
- `ClientsScreen` - Gestion des clients
- `FinancesScreen` - Gestion des finances
- `SalariesScreen` - Gestion des salaires
- `ReportsScreen` - Rapports

## 🔄 Flux de Données

### Flux Général

```
UI (Presentation)
    ↓
Controller (Application)
    ↓
Repository (Data) → OfflineRepository → Drift (SQLite)
    ↓
SyncManager → FirebaseSyncHandler → Firestore
```

### Flux Offline-First

1. **Écriture** :
   - UI appelle Controller
   - Controller appelle Repository
   - Repository écrit dans Drift (local)
   - SyncManager enqueue l'opération pour sync

2. **Lecture** :
   - UI appelle Controller via Provider
   - Controller lit depuis Repository
   - Repository lit depuis Drift (local)
   - Si online, sync en arrière-plan

3. **Synchronisation** :
   - SyncManager traite la file d'attente
   - FirebaseSyncHandler envoie vers Firestore
   - Résolution de conflits si nécessaire

### Flux Multi-Tenant

Toutes les opérations utilisent `enterpriseId` :
- Filtrage des données par entreprise
- Isolation complète des données
- Collections Firestore organisées par entreprise

## 🔐 Multi-Tenancy

### Isolation des Données

- **enterpriseId** : Utilisé pour filtrer toutes les données
- **moduleType** : `'eau_minerale'` pour ce module
- **Collections Firestore** : `enterprises/{enterpriseId}/modules/eau_minerale/collections/{collectionName}`

### Exemple

```dart
final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';

final repository = ProductOfflineRepository(
  driftService: driftService,
  syncManager: syncManager,
  connectivityService: connectivityService,
  enterpriseId: enterpriseId,
  moduleType: 'eau_minerale',
);
```

## 📊 Synchronisation

### SyncManager

- File d'attente pour opérations en attente
- Retry automatique en cas d'échec
- Résolution de conflits (last-write-wins avec updatedAt)

### Collections Synchronisées

- `products` - Produits
- `sales` - Ventes
- `customers` - Clients
- `production_sessions` - Sessions de production
- `stock_movements` - Mouvements de stock
- `employees` - Employés
- `production_payments` - Paiements de production
- `salary_payments` - Paiements de salaires
- `expenses` - Dépenses

## 🧪 Tests

### Tests Unitaires

- `product_offline_repository_test.dart` ✅
- `sale_service_test.dart` ✅
- `production_service_test.dart` ✅
- `dashboard_calculation_service_test.dart` ✅
- `report_calculation_service_test.dart` ✅

### Tests à Créer

- Tests pour tous les controllers
- Tests pour tous les OfflineRepositories
- Tests d'intégration pour la synchronisation

## 📝 Notes Techniques

### IDs Locaux vs Distants

- **IDs locaux** : Préfixe `local_` (ex: `local_1234567890_abc`)
- **IDs distants** : IDs Firestore (ex: `abc123def456`)
- Conversion automatique lors de la synchronisation

### Gestion des Conflits

- Utilisation de `updatedAt` pour résoudre les conflits
- Last-write-wins strategy
- Logs des conflits pour audit

### Performance

- Pagination pour les listes longues
- Lazy loading des données
- Cache local avec Drift

