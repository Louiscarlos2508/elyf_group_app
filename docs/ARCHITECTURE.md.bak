# Architecture du Projet ELYF Group App

## Vue d'Ensemble

```mermaid
graph TB
    subgraph AppLayer["App Layer"]
        Bootstrap[bootstrap.dart]
        Router[app/router]
    end
    
    subgraph FeaturesLayer["Features Layer"]
        Gaz[features/gaz]
        Boutique[features/boutique]
        EauMinerale[features/eau_minerale]
        Immobilier[features/immobilier]
        OrangeMoney[features/orange_money]
        Administration[features/administration]
    end
    
    subgraph SharedLayer["Shared Layer"]
        SharedWidgets[shared/presentation]
        SharedUtils[shared/utils]
    end
    
    subgraph CoreLayer["Core Layer"]
        Auth[core/auth]
        Offline[core/offline]
        Permissions[core/permissions]
        Tenant[core/tenant]
    end
    
    Bootstrap --> Router
    Router --> FeaturesLayer
    FeaturesLayer --> SharedLayer
    FeaturesLayer --> CoreLayer
    FeaturesLayer --> AppLayer
    
    style AppLayer fill:#f3e5f5
    style FeaturesLayer fill:#e1f5ff
    style SharedLayer fill:#fff4e1
    style CoreLayer fill:#e8f5e9
```

## Structure du Projet

### Organisation par Features

Le projet utilise une organisation par **features** (fonctionnalités) plutôt que par modules techniques. Cette approche améliore la maintenabilité et la scalabilité.

```
lib/
├── features/          # Modules organisés par fonctionnalité
│   ├── boutique/      # Module boutique
│   ├── eau_minerale/  # Module eau minérale
│   ├── gaz/           # Module gaz
│   ├── orange_money/  # Module Orange Money
│   ├── immobilier/    # Module immobilier
│   └── administration/# Module administration
├── shared/            # Composants partagés
│   ├── presentation/  # Widgets UI partagés
│   └── utils/         # Utilitaires partagés
├── core/              # Services transverses
│   ├── auth/          # Authentification
│   ├── offline/       # Infrastructure offline-first
│   ├── permissions/   # Gestion des permissions
│   └── tenant/        # Gestion multi-tenant
└── app/               # Configuration application
    ├── router/        # Configuration routing
    └── bootstrap.dart # Initialisation
```

### Note sur "features" vs "modules"

**Règle originale** : Le projet devait utiliser `lib/modules/`  
**Réalité** : Le projet utilise `lib/features/`

**Justification** : `features/` est une meilleure pratique moderne qui :
- Organise le code par fonctionnalité métier
- Facilite la navigation et la maintenance
- Améliore la scalabilité
- Suit les recommandations Flutter/Dart modernes

Cette différence est documentée ici pour éviter toute confusion.

## Architecture par Couches

Chaque feature suit une architecture en couches (Clean Architecture) :

```
feature/
├── presentation/      # UI (widgets, screens)
│   ├── screens/      # Écrans principaux
│   └── widgets/       # Widgets spécifiques au module
├── application/       # State management (Riverpod)
│   ├── controllers/   # Controllers métier
│   └── providers.dart # Providers Riverpod
├── domain/           # Logique métier
│   ├── entities/     # Entités métier
│   ├── repositories/ # Interfaces de repositories
│   └── services/     # Services métier
└── data/             # Implémentations
    └── repositories/ # Repositories (Mock ou Offline)
```

### Diagramme des Couches

```mermaid
graph TB
    subgraph Presentation["Presentation Layer"]
        Screens[Screens]
        Widgets[Widgets]
    end
    
    subgraph Application["Application Layer"]
        Controllers[Controllers]
        Providers[Providers]
    end
    
    subgraph Domain["Domain Layer"]
        Entities[Entities]
        Repositories[Repository Interfaces]
        Services[Services]
    end
    
    subgraph Data["Data Layer"]
        RepoImpl[Repository Implementations]
        OfflineRepo[OfflineRepositories]
    end
    
    Presentation --> Application
    Application --> Domain
    Data --> Domain
    
    style Presentation fill:#e3f2fd
    style Application fill:#f3e5f5
    style Domain fill:#e8f5e9
    style Data fill:#fff3e0
```

### Règles de Dépendances entre Couches

1. **Presentation** → **Application** : Les widgets utilisent les providers/controllers
2. **Application** → **Domain** : Les controllers utilisent les services et interfaces de repository
3. **Data** → **Domain** : Les implémentations de repository implémentent les interfaces du domain
4. **Domain** est indépendant : Ne dépend ni de Presentation ni de Data
5. **Interdictions** :
   - ❌ Presentation → Data (doit passer par Application et Domain)
   - ❌ Domain → Presentation ou Data
   - ❌ Data → Presentation ou Application

## Offline-First Architecture

### Principe

L'application fonctionne en mode **offline-first** :
1. **Écriture locale d'abord** : Toutes les opérations sont d'abord persistées localement
2. **Synchronisation en arrière-plan** : Les opérations sont synchronisées avec Firestore quand en ligne
3. **Résolution de conflits** : Utilise `updated_at` pour résoudre les conflits (last write wins)

### Diagramme de Flux de Données Offline-First

```mermaid
sequenceDiagram
    participant UI as Presentation Layer
    participant Repo as OfflineRepository
    participant Drift as Drift (SQLite)
    participant Sync as SyncManager
    participant Firestore as Firebase Firestore
    
    UI->>Repo: save(entity)
    Repo->>Drift: saveToLocal(entity)
    Drift-->>Repo: saved
    Repo->>Sync: queueSyncOperation(operation)
    Repo-->>UI: success (immediate)
    
    Note over Sync,Firestore: Background Sync
    Sync->>Firestore: sync(operation)
    alt Online
        Firestore-->>Sync: success
        Sync->>Drift: updateSyncStatus(synced)
    else Offline
        Sync->>Sync: retry later (exponential backoff)
    end
    
    Note over Sync,Firestore: Conflict Resolution
    Sync->>Firestore: fetchRemote(entity)
    Firestore-->>Sync: remoteEntity
    Sync->>Sync: compare updated_at
    alt Local is newer
        Sync->>Firestore: push local
    else Remote is newer
        Sync->>Drift: updateLocal(remoteEntity)
    end
```

### Composants

- **DriftService** : Base de données locale Drift (SQLite)
- **AppDatabase / OfflineRecordDao** : Stockage générique `OfflineRecords` (JSON) + CRUD
- **SyncManager** : Gestionnaire de synchronisation
- **ConnectivityService** : Surveillance de la connectivité
- **OfflineRepository<T>** : Classe de base pour repositories offline-first
- **FirebaseSyncHandler** : Handler de synchronisation Firestore

### Stockage local (Drift)

Les entités sont stockées dans une table SQLite unique `OfflineRecords` :
- `collectionName` (ex: `products`, `sales`)
- `enterpriseId`, `moduleType` (multi-tenant)
- `localId`, `remoteId` (liaison Firestore)
- `dataJson` (payload JSON complet)
- `localUpdatedAt` (tri & conflits)

## Multi-Tenant Architecture

### Principe

L'application supporte plusieurs entreprises (multi-tenant) :
- Chaque entreprise a ses propres données
- Isolation des données par `enterpriseId`
- Support de plusieurs modules par entreprise

### Diagramme Multi-Tenant

```mermaid
graph TB
    subgraph Tenant1["Entreprise 1"]
        E1Gaz[Module Gaz]
        E1Boutique[Module Boutique]
        E1Data1[Données E1 - Gaz]
        E1Data2[Données E1 - Boutique]
    end
    
    subgraph Tenant2["Entreprise 2"]
        E2Gaz[Module Gaz]
        E2Immobilier[Module Immobilier]
        E2Data1[Données E2 - Gaz]
        E2Data2[Données E2 - Immobilier]
    end
    
    subgraph CoreServices["Services Core"]
        TenantProvider[TenantProvider]
        AuthService[AuthService]
        PermissionService[PermissionService]
    end
    
    TenantProvider --> E1Gaz
    TenantProvider --> E1Boutique
    TenantProvider --> E2Gaz
    TenantProvider --> E2Immobilier
    
    E1Gaz --> E1Data1
    E1Boutique --> E1Data2
    E2Gaz --> E2Data1
    E2Immobilier --> E2Data2
    
    AuthService --> TenantProvider
    PermissionService --> TenantProvider
    
    style Tenant1 fill:#e1f5ff
    style Tenant2 fill:#fff4e1
    style CoreServices fill:#e8f5e9
```

### Implémentation

- **Enterprise** : Entité représentant une entreprise
- **ActiveEnterpriseProvider** : Provider pour l'entreprise active
- **Filtrage** : Tous les repositories filtrent par `enterpriseId`
- **ModuleId** : Identifie le module actif (boutique, gaz, etc.)

## State Management

### Riverpod

Le projet utilise **Riverpod** pour la gestion d'état :
- **Providers** : Définis dans `application/providers.dart`
- **Controllers** : Logique métier orchestrée par des controllers
- **AsyncValue** : Gestion des états asynchrones (loading, data, error)

### Diagramme de Flux State Management

```mermaid
graph LR
    subgraph UI["UI Layer"]
        Widget[Widget]
    end
    
    subgraph Riverpod["Riverpod"]
        Provider[Provider]
        Controller[Controller/StateNotifier]
    end
    
    subgraph Domain["Domain Layer"]
        Service[Service]
        Repository[Repository Interface]
    end
    
    subgraph Data["Data Layer"]
        RepoImpl[Repository Implementation]
    Drift[Drift (SQLite)]
    end
    
    Widget -->|watch| Provider
    Provider -->|uses| Controller
    Controller -->|calls| Service
    Service -->|uses| Repository
    Repository -->|implemented by| RepoImpl
RepoImpl -->|reads/writes| Drift
    
    style UI fill:#e3f2fd
    style Riverpod fill:#f3e5f5
    style Domain fill:#e8f5e9
    style Data fill:#fff3e0
```

### Patterns

1. **Repository Pattern** : Abstraction des sources de données
2. **Service Pattern** : Logique métier dans des services
3. **Controller Pattern** : Orchestration des opérations métier

## Séparation des Responsabilités

### Règle : Pas de Logique Métier dans l'UI

**❌ Mauvais** :
```dart
Widget build(BuildContext context) {
  final total = sales.fold(0, (sum, s) => sum + s.totalPrice);
  // ...
}
```

**✅ Bon** :
```dart
// Dans un service
class DashboardCalculationService {
  int calculateTotalRevenue(List<Sale> sales) {
    return sales.fold(0, (sum, s) => sum + s.totalPrice);
  }
}

// Dans le widget
Widget build(BuildContext context) {
  final total = ref.watch(dashboardCalculationServiceProvider)
      .calculateTotalRevenue(sales);
  // ...
}
```

### Services de Calcul

Services créés pour extraire la logique métier :
- `DashboardCalculationService` : Calculs de dashboard
- `ReportCalculationService` : Calculs de rapports
- `SaleService` : Logique de vente
- `ProductionService` : Logique de production
- `ProductCalculationService` : Calculs de produits

## Gestion d'Erreurs

### ErrorHandler

Système centralisé de gestion d'erreurs :
- `ErrorHandler` : Gestionnaire centralisé
- `AppException` : Exceptions de base
- Types d'erreurs : `NetworkException`, `ValidationException`, etc.

### Utilisation

```dart
try {
  // ...
} catch (error, stackTrace) {
  final appException = ErrorHandler.instance.handleError(error, stackTrace);
  // Afficher l'erreur à l'utilisateur
}
```

## Sécurité

### Authentification

- `AuthService` : Service d'authentification
- `AuthGuard` : Protection des routes
- `SecureStorageService` : Stockage sécurisé des données sensibles

### Permissions

- `PermissionService` : Gestion centralisée des permissions
- Permissions par module et par rôle
- Isolation multi-tenant

## Composants Réutilisables

### Widgets Partagés

- `FormDialog` : Dialog générique pour formulaires
- `ExpenseFormDialog` : Dialog générique pour dépenses
- `BaseModuleShellScreen` : Écran shell de base pour modules
- `AdaptiveNavigationScaffold` : Scaffold adaptatif
- `AuthGuard` : Protection des routes
- `EnterpriseSelectorWidget` : Sélecteur d'entreprise
- `SyncStatusIndicator` : Indicateur de statut de synchronisation

### Champs de Formulaire

- `CustomerFormFields` : Champs de formulaire client
- `AmountInputField` : Champ de saisie de montant
- `DatePickerField` : Champ de sélection de date
- `CategorySelectorField` : Sélecteur de catégorie

### Validators

- `required` : Validation requise
- `phone` : Validation téléphone
- `amount` : Validation montant
- `email` : Validation email

## 7. Synchronisation Avancée & Performance

### Stratégie de Synchronisation (SyncManager)
L'application utilise un système de synchronisation sophistiqué pour garantir l'intégrité des données multi-tenant :
- **Queue Persistante** : Les opérations sont stockées localement dans Drift et synchronisées avec un mécanisme de retry (exponential backoff).
- **Batch Operations** : Jusqu'à 500 opérations sont regroupées en une seule transaction Firestore pour optimiser les coûts et le réseau.
- **Delta Sync** : Utilisation de `lastSyncAt` pour ne récupérer que les modifications récentes au démarrage.
- **Priorisation** : Les ventes et paiements sont synchronisés avant les logs ou métriques.

### Résolution de Conflits
Le système suit une approche **Last-Write-Wins** basée sur le champ `updated_at`. En cas de conflit :
1. Le document avec le timestamp le plus récent est conservé.
2. Les données locales en attente de synchronisation sont prioritaires sur les données distantes plus anciennes.

---

## 8. Intégrité des Stocks

Le module `StockIntegrityService` assure la cohérence entre les quantités affichées et l'historique des opérations.

### Diagnostic & Réparation
- **Vérification** : Compare la quantité stockée avec `Somme(entrées) - Somme(sorties)`.
- **Réparation** : Recalcule automatiquement la quantité stockée à partir des mouvements (source de vérité absolue).
- **Architecture des Mouvements** : Utilisation d'un document Firestore par mouvement (pas de tableau géant) pour garantir la scalabilité et éviter les limites de taille de document (1MB).

---

## 📊 9. Métriques et Monitoring
- **AppLogger** : Système de logging centralisé pour le debug et l'audit.
- **SyncMetrics** : Collecte des statistiques de succès/échec de synchronisation.
- **Performance** : Temps de chargement moyen < 500ms pour les données locales.

---

## 💡 10. Bonnes Pratiques de Développement
1.  **Fichiers < 200 lignes** : Séparez les widgets et la logique métier.
2.  **Const Constructors** : Optimisez le rebuild des widgets Flutter.
3.  **Audit Trail** : Enregistrez systématiquement les actions critiques.

---

## 🔗 Ressources
- [Guide d'Installation (SETUP.md)](./SETUP.md)
- [Guide Technique Portfolio](../Project_Portfolio/eau_minerale/docs/guide_technique.md)

## Dépendances entre Modules

### Règles d'Isolation

Les modules (features) sont conçus pour être **complètement indépendants** :

1. **Aucune dépendance directe entre features** :
   - ❌ `features/gaz/` ne peut pas importer depuis `features/boutique/`
   - ❌ `features/eau_minerale/` ne peut pas importer depuis `features/immobilier/`
   - ✅ Chaque feature est isolée et peut être développée/testée indépendamment

2. **Dépendances autorisées** :
   - ✅ `features/*` → `shared/` (composants UI partagés, utilitaires)
   - ✅ `features/*` → `core/` (services transverses : auth, offline, permissions, tenant)
   - ✅ `features/*` → `app/` (configuration, routing)

3. **Communication entre modules** :
   - Via `shared/` : Composants UI réutilisables (FormDialog, ExpenseFormDialog, etc.)
   - Via `core/` : Services partagés (AuthService, PermissionService, DriftService, etc.)
   - Via `app/router/` : Navigation entre modules

### Diagramme de Dépendances

```mermaid
graph TD
    subgraph Features["Features (Modules Indépendants)"]
        Gaz[features/gaz]
        Boutique[features/boutique]
        EauMinerale[features/eau_minerale]
        Immobilier[features/immobilier]
        OrangeMoney[features/orange_money]
        Administration[features/administration]
    end
    
    subgraph Shared["Shared (Composants Partagés)"]
        SharedWidgets[shared/presentation/widgets]
        SharedUtils[shared/utils]
    end
    
    subgraph Core["Core (Services Transverses)"]
        Auth[core/auth]
        Offline[core/offline]
        Permissions[core/permissions]
        Tenant[core/tenant]
    end
    
    subgraph App["App (Configuration)"]
        Router[app/router]
        Bootstrap[app/bootstrap]
    end
    
    Gaz --> SharedWidgets
    Gaz --> SharedUtils
    Gaz --> Auth
    Gaz --> Offline
    Gaz --> Permissions
    Gaz --> Tenant
    Gaz --> Router
    
    Boutique --> SharedWidgets
    Boutique --> SharedUtils
    Boutique --> Auth
    Boutique --> Offline
    Boutique --> Permissions
    Boutique --> Tenant
    Boutique --> Router
    
    EauMinerale --> SharedWidgets
    EauMinerale --> SharedUtils
    EauMinerale --> Auth
    EauMinerale --> Offline
    EauMinerale --> Permissions
    EauMinerale --> Tenant
    EauMinerale --> Router
    
    Immobilier --> SharedWidgets
    Immobilier --> SharedUtils
    Immobilier --> Auth
    Immobilier --> Offline
    Immobilier --> Permissions
    Immobilier --> Tenant
    Immobilier --> Router
    
    OrangeMoney --> SharedWidgets
    OrangeMoney --> SharedUtils
    OrangeMoney --> Auth
    OrangeMoney --> Offline
    OrangeMoney --> Permissions
    OrangeMoney --> Tenant
    OrangeMoney --> Router
    
    Administration --> SharedWidgets
    Administration --> SharedUtils
    Administration --> Auth
    Administration --> Offline
    Administration --> Permissions
    Administration --> Tenant
    Administration --> Router
    
    style Features fill:#e1f5ff
    style Shared fill:#fff4e1
    style Core fill:#e8f5e9
    style App fill:#f3e5f5
```

### Services Partagés

Services partagés dans `core/` utilisés par tous les modules :

- **`AuthService`** : Authentification et gestion de session
- **`PermissionService`** : Gestion centralisée des permissions par module
- **`DriftService`** : Base de données locale Drift (SQLite)
- **`SyncManager`** : Synchronisation avec Firestore
- **`ConnectivityService`** : Surveillance de la connectivité réseau
- **`TenantProvider`** : Gestion multi-tenant (entreprise active)

### Vérification des Dépendances

Pour vérifier qu'aucune dépendance croisée n'existe entre features :

```bash
# Rechercher les imports interdits
grep -r "import.*features/" lib/features/*/ --exclude-dir=node_modules
```

**Résultat attendu** : Aucun import direct entre features (seulement via `shared/` ou `core/`)

## Vérification de l'Architecture

### Tests d'Architecture avec dependency_validator

Le projet utilise `dependency_validator` pour vérifier automatiquement que les règles d'architecture sont respectées.

#### Configuration

Le fichier `dependency_validator.yaml` définit :
- **Dépendances interdites** : Features ne peuvent pas s'importer entre elles, règles de couches
- **Dépendances autorisées** : Features → shared/core/app, Application → Domain, etc.

#### Utilisation

```bash
# Vérifier l'architecture
dart run dependency_validator

# Ou utiliser le script
dart scripts/check_architecture.dart
```

#### Règles Vérifiées

1. **Isolation des Features** : Aucune dépendance directe entre features
2. **Séparation des Couches** :
   - Presentation ne peut pas importer Data
   - Domain ne peut pas importer Presentation ou Data
   - Data ne peut pas importer Presentation ou Application
3. **Dépendances Autorisées** :
   - Features → shared/core/app ✅
   - Application → Domain ✅
   - Presentation → Application ✅
   - Data → Domain ✅

## Évolution Future

### Améliorations Planifiées

1. **Migration complète vers OfflineRepositories** : Remplacer tous les MockRepositories
2. **Tests** : Ajouter des tests unitaires et d'intégration
3. **Documentation** : Améliorer la documentation des APIs
4. **Performance** : Optimiser les requêtes locales (Drift/SQLite)
5. **Sécurité** : Migration vers Firebase Auth
