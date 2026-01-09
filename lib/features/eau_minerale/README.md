# Module Eau Minérale

## 📋 Vue d'ensemble

Ce module implémente un système complet de gestion de production et vente d'eau en sachets avec :
- Gestion des utilisateurs (Responsable/Employé)
- Gestion automatique des stocks
- Système de crédits clients
- Production avec périodes
- Gestion des dépenses et salaires

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

## 🏗️ Structure du domaine

### Entités (`domain/entities/`)

- **User** : Utilisateur avec rôle (manager/employee)
- **Product** : Produit fini ou matière première
- **Sale** : Vente complète avec workflow de validation
- **CreditPayment** : Encaissement d'un crédit
- **Production** : Production avec périodes et matières premières
- **StockMovement** : Mouvement de stock (entrée/sortie/ajustement)
- **Expense** : Dépense opérationnelle
- **Salary** : Paiement de salaire (fixe ou production)
- **Employee** : Employé avec contrat
- **ProductionPeriodConfig** : Configuration des périodes
- **DashboardStats** : Statistiques du tableau de bord
- **CustomerSummary** : Résumé client avec historique

### Repositories (`domain/repositories/`)

Interfaces abstraites pour :
- `ProductRepository` : Gestion des produits ✅ Offline
- `SaleRepository` : Gestion des ventes ✅ Offline
- `CreditRepository` : Gestion des crédits et paiements ⚠️ Mock
- `ProductionSessionRepository` : Gestion de la production ✅ Offline
- `StockRepository` : Gestion des stocks ✅ Offline
- `FinanceRepository` : Gestion des dépenses ✅ Offline
- `SalaryRepository` : Gestion des salaires ✅ Offline
- `CustomerRepository` : Gestion des clients ✅ Offline
- `MachineRepository` : Gestion des machines ✅ Offline
- `InventoryRepository` : Gestion de l'inventaire ⚠️ Mock
- `BobineStockQuantityRepository` : Gestion des bobines ⚠️ Mock
- `PackagingStockRepository` : Gestion des emballages ⚠️ Mock

### Services métier (`domain/services/`)

Logique métier centralisée :
- **SaleService** : Création de ventes avec impacts automatiques sur stock
- **ProductionService** : Création de production avec mise à jour automatique des stocks
- **CreditService** : Enregistrement de paiements avec mise à jour des crédits

## 🔐 Système de Permissions

Le module implémente un système de contrôle d'accès basé sur les rôles (RBAC). Chaque utilisateur a un rôle qui détermine les permissions qu'il possède.

### Rôles disponibles

#### 1. Responsable
- **Accès complet** à toutes les fonctionnalités
- Peut gérer les paramètres, produits, et configurations

#### 2. Gestionnaire
- Accès à la plupart des modules sauf les paramètres
- Peut créer/modifier production, ventes, dépenses
- Peut voir les rapports et salaires

#### 3. Vendeur
- Accès uniquement aux ventes et crédits
- Peut créer des ventes et encaisser des paiements
- Peut voir le stock (lecture seule)

#### 4. Producteur
- Accès uniquement à la production
- Peut créer des productions
- Peut voir le stock (lecture seule)

#### 5. Comptable
- Accès aux finances, salaires et rapports
- Peut créer/modifier des dépenses
- Peut voir les rapports

#### 6. Lecteur
- Accès en lecture seule
- Peut voir le dashboard, production, ventes, stock, crédits, finances et rapports
- Ne peut pas créer ou modifier

### Permissions disponibles

Les permissions sont définies dans `domain/permissions/eau_minerale_permissions.dart` :

- `viewDashboard` - Voir le tableau de bord
- `viewProduction`, `createProduction`, `editProduction`, `deleteProduction`
- `viewSales`, `createSale`, `editSale`, `deleteSale`
- `viewStock`, `editStock`
- `viewCredits`, `collectPayment`, `viewCreditHistory`
- `viewFinances`, `createExpense`, `editExpense`, `deleteExpense`
- `viewSalaries`, `createSalary`, `editSalary`, `deleteSalary`
- `viewReports`, `downloadReports`
- `viewSettings`, `editSettings`, `manageProducts`, `configureProduction`
- `viewProfile`, `editProfile`, `changePassword`

### Utilisation dans le code

Le système utilise `EauMineralePermissionAdapter` pour vérifier les permissions via le système centralisé de permissions.

Les widgets `CentralizedPermissionGuard` et `EauMineralePermissionGuard` permettent de masquer des éléments UI selon les permissions.

## 🔄 Workflows implémentés

### Workflow de vente

1. **Création**
   - Vérification du stock disponible
   - Calcul automatique : Prix total, Reste à payer
   - Statut initial : `validated` (vente directe) ou `fullyPaid` (paiement complet)

2. **Impacts automatiques**
   - Déduction automatique du stock de produits finis
   - Enregistrement d'un mouvement de stock

### Workflow de production

1. **Création**
   - Vérification du stock de matières premières (si renseignées)
   - Calcul automatique de la période selon la date
   - Enregistrement de la production

2. **Impacts automatiques**
   - ➕ Augmentation du stock de produits finis
   - ➖ Diminution du stock de matières premières (si renseignées)

### Workflow de crédit

1. **Encaissement**
   - Vérification du montant (≤ reste à payer)
   - Enregistrement du paiement avec signature
   - Mise à jour automatique du reste à payer

2. **Paiement complet**
   - Si reste à payer = 0 → Vente complètement payée

### Workflow de paiement salaire fixe

1. **Création d'employé**
   - Enregistrement des informations (nom, poste, salaire mensuel)

2. **Paiement mensuel**
   - Sélection de la date de paiement
   - Validation pour éviter les doublons (même mois/année)
   - Signature du bénéficiaire
   - Enregistrement du paiement

## 🎮 Controllers Disponibles

Tous les controllers utilisent les OfflineRepositories et gèrent la synchronisation automatique :

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

## 📁 Structure des fichiers

```
lib/features/eau_minerale/
├── domain/
│   ├── entities/          # Entités métier
│   ├── repositories/      # Interfaces de repositories
│   ├── services/          # Services métier
│   ├── permissions/       # Définition des permissions
│   └── exceptions/       # Exceptions métier
├── data/
│   └── repositories/      # OfflineRepositories (Drift) + MockRepositories (en migration)
├── application/
│   ├── controllers/       # Contrôleurs Riverpod
│   ├── providers/         # Providers organisés par catégorie
│   └── adapters/         # Adaptateurs de permissions
└── presentation/
    ├── screens/          # Écrans principaux
    └── widgets/         # Widgets réutilisables
```

## 🔄 Offline-First & Synchronisation

### Repositories Offline ✅

- `ProductOfflineRepository` - Produits
- `SaleOfflineRepository` - Ventes
- `CustomerOfflineRepository` - Clients
- `ProductionSessionOfflineRepository` - Sessions de production
- `MachineOfflineRepository` - Machines
- `StockOfflineRepository` - Mouvements de stock
- `SalaryOfflineRepository` - Employés et salaires
- `FinanceOfflineRepository` - Dépenses

### Synchronisation

Toutes les opérations CRUD sont automatiquement synchronisées avec Firestore via `SyncManager` :
- Écriture locale immédiate (offline-first)
- File d'attente pour sync
- Retry automatique en cas d'échec
- Résolution de conflits (last-write-wins)

## 🎯 Points clés

- **Ventes directes** : Pas de workflow de validation, les ventes sont directement validées
- **Impacts automatiques** : Stock, crédits, statistiques mis à jour automatiquement
- **Gestion des périodes** : Production découpée en 3 périodes configurables
- **Traçabilité complète** : Historique de tous les mouvements
- **Gestion des rôles** : Accès différencié selon le rôle utilisateur
- **Validation robuste** : Prévention des paiements en double, validation des dates et montants

## 📝 Guide d'utilisation

### Créer un employé fixe

1. Aller dans "Salaires & Indemnités" → Onglet "Employés Fixes"
2. Cliquer sur "Nouvel Employé"
3. Remplir les informations (nom, poste, salaire mensuel)
4. Enregistrer

### Payer un salaire mensuel

1. Dans la carte de l'employé, cliquer sur "Payer"
2. Vérifier la date de paiement et la période
3. Ajouter des notes optionnelles
4. Signer le paiement
5. Enregistrer

Le système empêche automatiquement les paiements en double pour le même mois/année.

### Gérer les ventes

1. Aller dans "Ventes"
2. Cliquer sur "Nouvelle Vente"
3. Sélectionner le client et les produits
4. Choisir le mode de paiement (comptant ou crédit)
5. Enregistrer

La vente est automatiquement validée et le stock est mis à jour.

### Gérer les crédits

1. Aller dans "Crédits"
2. Sélectionner un client avec crédit en cours
3. Cliquer sur "Encaisser"
4. Entrer le montant à encaisser
5. Enregistrer le paiement

Le reste à payer est automatiquement mis à jour.
