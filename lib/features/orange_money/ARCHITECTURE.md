# Architecture - Module Orange Money

## Vue d'ensemble

Le module Orange Money suit une **architecture Clean Architecture** avec séparation stricte des couches : Domain, Data, Application, et Presentation.

## 🏗️ Structure des Couches

### 1. Domain (Couche Domaine)

#### Entities (Entités)

**Entités principales** :
- `Transaction` - Transaction cash-in/cash-out
- `Agent` - Agent Orange Money
- `Commission` - Commission mensuelle
- `LiquidityCheckpoint` - Pointage de liquidité (matin/soir)
- `OrangeMoneySettings` - Paramètres du module

#### Repositories (Interfaces)

- `TransactionRepository` - Interface pour la gestion des transactions
- `AgentRepository` - Interface pour la gestion des agents
- `CommissionRepository` - Interface pour la gestion des commissions
- `LiquidityRepository` - Interface pour la gestion des pointages
- `SettingsRepository` - Interface pour la gestion des paramètres

### 2. Data (Couche Données)

#### Repositories Offline

**Repositories migrés vers Offline-first** ✅ :
- `TransactionOfflineRepository` ✅
- `AgentOfflineRepository` ✅
- `CommissionOfflineRepository` ✅ (nouveau)
- `LiquidityOfflineRepository` ✅ (nouveau)
- `SettingsOfflineRepository` ✅ (nouveau)

**Caractéristiques** :
- Stockage local dans Drift/SQLite
- `enterpriseId` utilisé pour isolation multi-tenant
- `moduleType = 'orange_money'` pour tous les repositories
- Support offline-first avec synchronisation automatique

### 3. Application (Couche Application)

#### Controllers

**Controllers disponibles** ✅ :
- `OrangeMoneyController` - Gestion des transactions
- `AgentsController` - Gestion des agents
- `CommissionsController` - Gestion des commissions
- `LiquidityController` - Gestion des pointages
- `SettingsController` - Gestion des paramètres

#### Providers (Riverpod)

Tous les providers utilisent les controllers, jamais les repositories directement.

### 4. Presentation (Couche Présentation)

Interface utilisateur Flutter avec écrans pour :
- Transactions (liste, filtres, détails)
- Agents (liste, création, modification)
- Commissions (calcul, paiement)
- Pointages de liquidité (matin/soir)
- Paramètres (notifications, seuils)

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
- **moduleType** : `'orange_money'` pour ce module
- **Collections Firestore** : `enterprises/{enterpriseId}/modules/orange_money/collections/{collectionName}`

## 📊 Synchronisation

### Collections Synchronisées

- `transactions` - Transactions cash-in/cash-out
- `agents` - Agents Orange Money
- `commissions` - Commissions mensuelles
- `liquidity_checkpoints` - Pointages de liquidité
- `orange_money_settings` - Paramètres du module

