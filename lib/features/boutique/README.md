# Module Boutique

## 📋 Vue d'ensemble

Ce module implémente un système complet de gestion de boutique avec :
- Gestion des produits et stocks
- Point de vente (POS)
- Gestion des ventes
- Gestion des achats
- Gestion des dépenses
- Rapports et statistiques

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

- `StoreController` - Gestion du magasin (produits, ventes, stocks)

## 🔄 Offline-First & Synchronisation

### Repositories Offline ✅

- `ProductOfflineRepository` - Produits
- `SaleOfflineRepository` - Ventes
- `ExpenseOfflineRepository` - Dépenses
- `StockOfflineRepository` - Stocks (délègue à ProductRepository)
- `PurchaseOfflineRepository` - Achats

### Repositories encore Mock ⚠️

- `ReportRepository` → MockReportRepository

### Synchronisation

Toutes les opérations CRUD sont automatiquement synchronisées avec Firestore via `SyncManager`.

## 📁 Structure

```
lib/features/boutique/
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

### Produits
- Catalogue de produits
- Gestion des stocks
- Alertes de stock faible
- Codes-barres

### Point de Vente (POS)
- Interface de vente rapide
- Panier avec calculs automatiques
- Impression de reçus
- Gestion des paiements

### Ventes
- Historique des ventes
- Recherche et filtres
- Détails de vente
- Statistiques

### Achats
- Enregistrement des achats
- Gestion des fournisseurs
- Impact sur les stocks

### Dépenses
- Enregistrement des dépenses
- Catégorisation
- Rapports financiers
