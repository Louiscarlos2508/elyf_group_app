# Architecture - Module Boutique

## Vue d'ensemble

Le module Boutique suit une **architecture Clean Architecture** avec séparation stricte des couches : Domain, Data, Application, et Presentation.

## 🏗️ Structure des Couches

### 1. Domain (Couche Domaine)

#### Entities (Entités)

**Entités principales** :
- `Product` - Produit avec stock et prix
- `Sale` - Vente avec items et paiement
- `Purchase` - Achat de produits
- `Expense` - Dépense opérationnelle
- `CartItem` - Item du panier

#### Repositories (Interfaces)

- `ProductRepository` - Interface pour la gestion des produits
- `SaleRepository` - Interface pour la gestion des ventes
- `PurchaseRepository` - Interface pour la gestion des achats
- `ExpenseRepository` - Interface pour la gestion des dépenses
- `StockRepository` - Interface pour la gestion des stocks
- `ReportRepository` - Interface pour les rapports (calculs)

#### Services (Services Métier)

**Domain Services** :
- `BoutiqueDashboardCalculationService` - Calculs pour le tableau de bord
- `ProductCalculationService` - Calculs liés aux produits
- `CartCalculationService` - Calculs du panier
- `BoutiqueReportCalculationService` - Calculs pour les rapports
- `ProductValidationService` - Validation des produits

### 2. Data (Couche Données)

#### Repositories Offline

**Repositories migrés vers Offline-first** ✅ :
- `ProductOfflineRepository` ✅
- `SaleOfflineRepository` ✅
- `ExpenseOfflineRepository` ✅
- `StockOfflineRepository` ✅ (délègue à ProductRepository)
- `PurchaseOfflineRepository` ✅
- `ReportOfflineRepository` ✅ (Calculs basés sur les données locales)

**Caractéristiques** :
- Stockage local dans Drift/SQLite
- `enterpriseId` utilisé pour isolation multi-tenant
- `moduleType = 'boutique'` pour tous les repositories
- Support offline-first avec synchronisation automatique

### 3. Application (Couche Application)

#### Controllers

**Controllers disponibles** ✅ :
- `StoreController` - Gestion complète du magasin (produits, ventes, stocks)

#### Providers (Riverpod)

Tous les providers utilisent les controllers, jamais les repositories directement.

### 4. Presentation (Couche Présentation)

Interface utilisateur Flutter avec écrans pour :
- Catalogue de produits
- Point de vente (POS)
- Historique des ventes
- Gestion des achats
- Gestion des dépenses
- Rapports

## 🔄 Flux de Données

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

3. **Synchronisation** :
   - SyncManager traite la file d'attente
   - FirebaseSyncHandler envoie vers Firestore

## 🔐 Multi-Tenancy

### Isolation des Données

- **enterpriseId** : Utilisé pour filtrer toutes les données
- **moduleType** : `'boutique'` pour ce module
- **Collections Firestore** : `enterprises/{enterpriseId}/modules/boutique/collections/{collectionName}`

## 📊 Synchronisation

### Collections Synchronisées

- `products` - Produits
- `sales` - Ventes
- `purchases` - Achats
- `expenses` - Dépenses

