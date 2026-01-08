# Architecture - Vue d'ensemble

Architecture générale de ELYF Group App.

## Principes architecturaux

### Clean Architecture

L'application suit les principes de Clean Architecture avec séparation en couches :

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (UI, Widgets, Screens)             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Application Layer              │
│  (State Management, Controllers)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Domain Layer                   │
│  (Entities, Use Cases, Interfaces)  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Data Layer                     │
│  (Repositories, Data Sources)       │
└─────────────────────────────────────┘
```

### Séparation des responsabilités

- **Presentation** : Affichage et interaction utilisateur
- **Application** : Logique métier et gestion d'état
- **Domain** : Entités et règles métier pures
- **Data** : Accès aux données (Firestore, Drift)

## Structure des modules

Chaque module suit la même structure :

```
features/
└── module_name/
    ├── presentation/      # UI
    │   ├── screens/      # Écrans principaux
    │   └── widgets/      # Widgets spécifiques au module
    ├── application/       # State management
    │   ├── controllers/  # Contrôleurs Riverpod
    │   └── providers.dart
    ├── domain/           # Logique métier
    │   ├── entities/     # Modèles de données
    │   └── repositories/ # Interfaces
    └── data/             # Implémentations
        └── repositories/ # Repositories concrets
```

## Couches transverses

### Core

Services partagés par tous les modules :

- `auth/` – Authentification Firebase
- `firebase/` – Wrappers Firestore, Functions, FCM
- `offline/` – Drift (SQLite) et synchronisation
- `printing/` – Intégration Sunmi V3
- `permissions/` – Système de permissions
- `tenant/` – Gestion multi-tenant
- `pdf/` – Génération de PDFs

### Shared

Composants réutilisables :

- `presentation/` – Widgets et écrans partagés
- `providers/` – Providers Riverpod globaux
- `utils/` – Utilitaires (formatters, helpers)

## State Management

### Riverpod

L'application utilise **Riverpod** pour la gestion d'état :

- **StateNotifier** – État mutable simple
- **AsyncNotifier** – État asynchrone
- **FutureProvider** – Données asynchrones
- **StreamProvider** – Flux de données

Voir [State Management](./state-management.md) pour plus de détails.

## Navigation

### GoRouter

Navigation déclarative avec **GoRouter** :

- Routes nommées
- Paramètres de route
- Redirections conditionnelles
- Deep linking

Voir [Navigation](./navigation.md) pour plus de détails.

## Multi-tenant

### Architecture

Chaque entreprise (tenant) a :
- Ses propres données dans Firestore
- Ses modules activés
- Ses utilisateurs et permissions

Voir [Multi-tenant](./multi-tenant.md) pour plus de détails.

## Offline-first

### Stratégie

1. **Stockage local** – Drift (SQLite) pour données critiques
2. **Synchronisation** – Automatique quand connexion disponible
3. **Résolution de conflits** – Basée sur `updated_at` et logique métier

Voir [Synchronisation](../07-offline/synchronization.md) pour plus de détails.

## Flux de données

### Lecture

```
UI → Provider → Repository → Firestore/Drift
                ↓
            Cache (Drift)
```

### Écriture

```
UI → Provider → Repository → Drift (immédiat)
                ↓
            Firestore (async)
                ↓
            Sync Status
```

## Sécurité

### Authentification

- Firebase Auth pour l'authentification
- JWT tokens pour les sessions
- Refresh tokens automatiques

### Autorisation

- Système de rôles et permissions
- Vérification côté client et serveur
- Audit trail pour actions critiques

## Performance

### Optimisations

- **Lazy loading** – Listes avec `ListView.builder`
- **Const constructors** – Réduction des rebuilds
- **Memoization** – Cache des calculs coûteux
- **Isolates** – Calculs lourds hors UI thread

### Monitoring

- DevTools pour profiling
- Logs structurés pour debugging
- Analytics pour usage

## Tests

### Stratégie

- **Unit tests** – Domain et Application layers
- **Widget tests** – Presentation layer
- **Integration tests** – Flux complets

Voir [Tests](../04-development/testing.md) pour plus de détails.

## Prochaines étapes

- [State Management](./state-management.md)
- [Navigation](./navigation.md)
- [Multi-tenant](./multi-tenant.md)
