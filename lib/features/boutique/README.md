# Module Boutique

## 📋 Vue d'ensemble

Ce module implémente un système de gestion de boutique physique pour un utilisateur unique (Propriétaire/Gérant) avec :
- Gestion des produits et stocks
- Point de vente (POS) rapide
- Gestion des ventes et des recettes
- Gestion des achats et dépenses
- Rapports et statistiques journaliers

## 🏗️ Architecture

Le module suit une **architecture Clean Architecture** avec :
- **Offline-first** : Toutes les données sont stockées localement (Drift/SQLite) en premier.
- **Synchronisation** : Synchronisation transparente avec Firestore.
- **Isolation** : Données isolées par entreprise (Multi-tenant global).
- **Controllers** : Logique métier pilotée par Riverpod controllers.

## 🎮 Controllers Disponibles

- `StoreController` - Gestion centrale du magasin (produits, ventes, stocks).

## 🔄 Offline-First & Synchronisation

### Repositories Offline ✅

- `ProductOfflineRepository` - Produits
- `SaleOfflineRepository` - Ventes
- `ExpenseOfflineRepository` - Dépenses
- `StockOfflineRepository` - Stocks
- `PurchaseOfflineRepository` - Achats

## 📁 Structure

```
lib/features/boutique/
├── domain/           # Entités et interfaces
├── data/             # Repositories (Drift)
├── application/      # Controllers Riverpod
└── presentation/     # Écrans POS, Catalog, Stocks
```

## 🎯 Fonctionnalités

### Produits & Stocks
- Catalogue de produits avec photos.
- Alertes de stock faible.
- Historique complet des mouvements.

### Point de Vente (POS)
- Interface de vente optimisée pour la rapidité.
- Paiements Espèces et Mobile Money.
- Impression de reçus thermiques (Sunmi ou imprimante générique Bluetooth/USB).

### Rapports
- Historique des ventes journalières.
- Rapports de fin de journée (Z-Report).
- Statistiques de performance produits.
