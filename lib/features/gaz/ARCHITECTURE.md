# Architecture - Module Gaz

## Vue d'ensemble

Le module Gaz suit une **architecture Clean Architecture** avec séparation stricte des couches : Domain, Data, Application, et Presentation.

## 🏗️ Structure des Couches

### 1. Domain (Couche Domaine)

#### Entities (Entités)

**Entités principales** :
- `Cylinder` - Bouteille de gaz avec poids et prix
- `GasSale` - Vente de gaz (détail ou gros)
- `CylinderStock` - Stock de bouteilles
- `CylinderLeak` - Fuite de bouteille
- `Tour` - Tour d'approvisionnement
- `PointOfSale` - Point de vente
- `GazExpense` - Dépense opérationnelle
- `FinancialReport` - Rapport financier
- `GazSettings` - Paramètres du module

#### Repositories (Interfaces)

- `GasRepository` - Interface pour la gestion des bouteilles et ventes
- `CylinderStockRepository` - Interface pour la gestion des stocks
- `CylinderLeakRepository` - Interface pour la gestion des fuites
- `TourRepository` - Interface pour la gestion des tours
- `PointOfSaleRepository` - Interface pour la gestion des points de vente
- `GazExpenseRepository` - Interface pour la gestion des dépenses
- `FinancialReportRepository` - Interface pour les rapports financiers
- `GazSettingsRepository` - Interface pour les paramètres

#### Services (Services Métier)

**Domain Services** :
- `GazDashboardCalculationService` - Calculs pour le tableau de bord
- `GazReportCalculationService` - Calculs pour les rapports
- `GazCalculationService` - Calculs métier
- `FinancialCalculationService` - Calculs financiers
- `StockService` - Gestion des stocks
- `TourService` - Gestion des tours
- `TransactionService` - Gestion des transactions
- `DataConsistencyService` - Vérification de cohérence
- `RealtimeSyncService` - Synchronisation temps réel

### 2. Data (Couche Données)

#### Repositories Offline

**Repositories migrés vers Offline-first** ✅ :
- `GasOfflineRepository` ✅ (bouteilles et ventes)
- `ExpenseOfflineRepository` ✅

**Repositories encore Mock** ⚠️ :
- `CylinderStockRepository` → MockCylinderStockRepository
- `CylinderLeakRepository` → MockCylinderLeakRepository
- `TourRepository` → MockTourRepository
- `PointOfSaleRepository` → MockPointOfSaleRepository
- `FinancialReportRepository` → MockFinancialReportRepository (repository de calcul)
- `GazSettingsRepository` → MockGazSettingsRepository

**Caractéristiques** :
- Stockage local dans Drift/SQLite
- `enterpriseId` utilisé pour isolation multi-tenant
- `moduleType = 'gaz'` pour tous les repositories
- Support offline-first avec synchronisation automatique

### 3. Application (Couche Application)

#### Controllers

**Controllers disponibles** ✅ :
- `GasController` - Gestion des bouteilles et ventes
- `CylinderController` - Gestion des bouteilles
- `CylinderStockController` - Gestion des stocks
- `CylinderLeakController` - Gestion des fuites
- `TourController` - Gestion des tours
- `PointOfSaleController` - Gestion des points de vente
- `ExpenseController` - Gestion des dépenses
- `FinancialReportController` - Rapports financiers
- `GazSettingsController` - Paramètres

#### Providers (Riverpod)

Tous les providers utilisent les controllers, jamais les repositories directement.

### 4. Presentation (Couche Présentation)

Interface utilisateur Flutter avec écrans pour :
- Gestion des bouteilles
- Ventes (détail et gros)
- Stocks
- Tours d'approvisionnement
- Points de vente
- Fuites
- Dépenses
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
- **moduleType** : `'gaz'` pour ce module
- **Collections Firestore** : `enterprises/{enterpriseId}/modules/gaz/collections/{collectionName}`

## 📊 Synchronisation

### Collections Synchronisées

- `cylinders` - Bouteilles
- `gas_sales` - Ventes
- `gaz_expenses` - Dépenses

