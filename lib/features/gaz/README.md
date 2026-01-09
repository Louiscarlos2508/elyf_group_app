# Module Gaz

## 📋 Vue d'ensemble

Ce module implémente un système complet de gestion de distribution de bouteilles de gaz avec :
- Gestion des bouteilles (cylinders)
- Gestion des ventes (détail et gros)
- Gestion des stocks
- Gestion des tours d'approvisionnement
- Gestion des points de vente
- Gestion des fuites de bouteilles
- Gestion des dépenses
- Rapports financiers

## 🏗️ Architecture

Le module suit une **architecture Clean Architecture** avec :
- **Offline-first** : Toutes les données sont stockées localement (Drift/SQLite) en premier
- **Synchronisation** : Sync automatique avec Firestore quand en ligne
- **Multi-tenant** : Isolation des données par entreprise
- **Controllers** : Logique métier dans les controllers, jamais dans l'UI

Voir [ARCHITECTURE.md](ARCHITECTURE.md) pour plus de détails.

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture détaillée du module
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Guide d'implémentation et patterns

## 🎮 Controllers Disponibles

- `GasController` - Gestion des bouteilles et ventes
- `CylinderController` - Gestion des bouteilles
- `CylinderStockController` - Gestion des stocks de bouteilles
- `CylinderLeakController` - Gestion des fuites
- `TourController` - Gestion des tours
- `PointOfSaleController` - Gestion des points de vente
- `ExpenseController` - Gestion des dépenses
- `FinancialReportController` - Rapports financiers
- `GazSettingsController` - Paramètres du module

## 🔄 Offline-First & Synchronisation

### Repositories Offline ✅

- `GasOfflineRepository` - Bouteilles et ventes
- `ExpenseOfflineRepository` - Dépenses
- `CylinderStockOfflineRepository` - Stocks de bouteilles
- `TourOfflineRepository` - Tours d'approvisionnement
- `CylinderLeakOfflineRepository` - Fuites de bouteilles
- `PointOfSaleOfflineRepository` - Points de vente
- `GazSettingsOfflineRepository` - Paramètres du module

### Repositories encore Mock ⚠️

- `FinancialReportRepository` → MockFinancialReportRepository (repository de calcul, pas de stockage direct)

### Synchronisation

Toutes les opérations CRUD sont automatiquement synchronisées avec Firestore via `SyncManager`.

## 📁 Structure

```
lib/features/gaz/
├── domain/
│   ├── entities/          # Entités métier
│   ├── repositories/      # Interfaces de repositories
│   └── services/          # Services métier
├── data/
│   └── repositories/      # OfflineRepositories (Drift) + MockRepositories
├── application/
│   ├── controllers/       # Contrôleurs Riverpod
│   └── providers.dart     # Providers Riverpod
└── presentation/
    ├── screens/          # Écrans principaux
    └── widgets/         # Widgets réutilisables
```

## 🎯 Fonctionnalités

### Bouteilles
- Gestion des types de bouteilles (poids, prix)
- Suivi du stock par type
- Historique des mouvements

### Ventes
- Ventes au détail
- Ventes en gros (tours)
- Suivi des clients
- Calcul automatique des montants

### Tours d'Approvisionnement
- Planification des tours
- Gestion des grossistes
- Suivi des livraisons

### Points de Vente
- Gestion des points de vente
- Suivi des ventes par point
- Statistiques

### Fuites
- Enregistrement des fuites
- Suivi des bouteilles défectueuses
- Remplacement

### Dépenses
- Enregistrement des dépenses
- Catégorisation
- Rapports financiers
