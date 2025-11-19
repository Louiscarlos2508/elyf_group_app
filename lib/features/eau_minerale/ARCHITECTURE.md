# Architecture du Module Eau Minérale

## 📋 Vue d'ensemble

Ce module implémente un système complet de gestion de production et vente d'eau en sachets avec :
- Gestion des utilisateurs (Responsable/Employé)
- Workflow de validation des ventes
- Gestion automatique des stocks
- Système de crédits clients
- Production avec périodes
- Gestion des dépenses et salaires

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
- `AuthRepository` : Authentification et gestion utilisateurs
- `ProductRepository` : Gestion des produits
- `SaleRepository` : Gestion des ventes avec validation
- `CreditRepository` : Gestion des crédits et paiements
- `ProductionRepository` : Gestion de la production
- `StockRepository` : Gestion des stocks
- `ExpenseRepository` : Gestion des dépenses
- `SalaryRepository` : Gestion des salaires
- `DashboardRepository` : Statistiques du dashboard
- `CustomerRepository` : Gestion des clients

### Services métier (`domain/services/`)

Logique métier centralisée :
- **SaleService** : Création/validation de ventes avec impacts automatiques sur stock
- **ProductionService** : Création de production avec mise à jour automatique des stocks
- **CreditService** : Enregistrement de paiements avec mise à jour des crédits

## 🔄 Workflows implémentés

### Workflow de vente

1. **Création** (Employé ou Responsable)
   - Vérification du stock disponible
   - Calcul automatique : Prix total, Reste à payer
   - Statut initial : `pending` (employé) ou `validated` (responsable)

2. **Validation** (Responsable uniquement)
   - Vérification du stock
   - Déduction automatique du stock de produits finis
   - Mise à jour du statut à `validated`

3. **Rejet** (Responsable uniquement)
   - Annulation de la vente
   - Pas de déduction de stock

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
   - Enregistrement du paiement
   - Mise à jour automatique du reste à payer

2. **Paiement complet**
   - Si reste à payer = 0 → Vente complètement payée

## 📝 Prochaines étapes

### 1. Implémentations mock (`data/repositories/`)

Créer les implémentations mock de tous les repositories avec données de test.

### 2. Contrôleurs Riverpod (`application/controllers/`)

Créer les contrôleurs pour :
- Dashboard
- Ventes (avec validation)
- Crédits
- Production
- Stocks
- Dépenses
- Salaires
- Paramètres

### 3. Écrans (`presentation/screens/`)

Développer les écrans avec workflows complets :
- **Dashboard** : Statistiques et alertes (Responsable uniquement)
- **Ventes** : Liste, création, validation, filtres
- **Crédits** : Liste clients, encaissements
- **Production** : Liste par période, création avec matières
- **Stocks** : Vue par type, mouvements, ajustements
- **Dépenses** : Liste, création, statistiques
- **Salaires** : Employés fixes, paiements production
- **Paramètres** : Produits, périodes, profil

### 4. Formulaires (`presentation/widgets/forms/`)

Créer les formulaires complets pour :
- Nouvelle vente (avec auto-complétion client)
- Validation/Rejet de vente
- Nouvelle production (avec sélection matières)
- Encaissement crédit
- Entrée/Sortie/Ajustement stock
- Nouvelle dépense
- Paiement salaire (fixe ou production)
- Gestion produit
- Configuration périodes

## 🎯 Points clés

- **Validation à deux niveaux** : Employé crée → Responsable valide
- **Impacts automatiques** : Stock, crédits, statistiques mis à jour automatiquement
- **Gestion des périodes** : Production découpée en 3 périodes configurables
- **Traçabilité complète** : Historique de tous les mouvements
- **Gestion des rôles** : Accès différencié selon le rôle utilisateur

