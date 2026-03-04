# Architecture - Module Gaz

## Vue d'ensemble

Le module Gaz suit une **architecture Clean Architecture** optimisée pour une gestion multi-tenant à deux niveaux : **Entreprise Parent** (Supervision/Logistique) et **Point de Vente** (Opérations/Ventes).

## 🏗️ Structure des Couches

### 1. Domain (Couche Domaine)

#### Entities (Entités)

- `Cylinder` - Types de bouteilles (3kg, 6kg, etc.)
- `GasSale` - Ventes (Détail/Gros) avec support de prix forcé.
- `CylinderStock` - Stock physique isolé par `siteId` (ID du POS).
- `CylinderLeak` - Tracé des bouteilles défectueuses (reconverties en vides).
- `Tour` - Tournée **administrative** (Logistique, dépenses, collectes).
- `GazSettings` - Paramètres locaux (Prix de vente pour POS, Prix d'achat pour Parent).
- `Payroll` - Nouveau : Gestion des salaires (Parent uniquement).

#### Services (Services Métier)

- `StockService` - Gestion des stocks avec isolation par `siteId`.
- `TourService` - Gestion logistique administrative (sans impact automatique sur stock Parent).
- `TransactionService` - Exécution atomique (Ventes -> Trésorerie POS, Tours -> Trésorerie Parent).
- `PayrollService` - Gestion des paiements de salaires.
- `RealtimeSyncService` - Synchronisation bidirectionnelle Firestore/Drift.

### 2. Data (Couche Données)

#### Multi-Tenancy & Isolation
- **Isolation Physique** : Les stocks sont enregistrés sous l'ID de l'entreprise Parent mais isolés par le champ **`siteId`** correspondant à l'ID du point de vente.
- **Trésorerie** : Les opérations financières sont liées à l'ID de l'entité active (POS pour les ventes, Parent pour les tournées/salaires).

### 3. Application (Couche Application)

#### Providers (Riverpod)
- `gazSharedScopedEnterpriseIdsProvider` : Gère l'accès aux données partagées (cylindres, grossistes) depuis le Parent vers les POS.

## 🔄 Flux de Données

### 1. Vente POS
- UI (Manual Price Override) -> `GasSaleController` -> `TransactionService` (Debit Stock `siteId`, Credit Treasury POS).

### 2. Tournée Administrative
- UI -> `TourController` -> `TourService` (Record Expenses, Record Wholesaler collection, Record POS bottle exchanges).

### 3. Mouvements de Stock POS
- UI -> `StockController` -> `StockService` (Entry Full/Empty, Exit Empty, Signal Leak).


