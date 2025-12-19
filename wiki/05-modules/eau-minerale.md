# Module Eau Minérale

Module complet de gestion de production et vente d'eau en sachets.

## Vue d'ensemble

Le module Eau Minérale implémente un système complet avec :
- Gestion des utilisateurs (Responsable/Employé)
- Gestion automatique des stocks
- Système de crédits clients
- Production avec périodes
- Gestion des dépenses et salaires

## Fonctionnalités principales

### Tableau de bord

- KPIs (ventes, production, crédits)
- Statistiques par période
- Graphiques de tendances
- Vue d'ensemble financière

### Production

- Création de productions avec périodes
- Gestion des matières premières
- Impact automatique sur les stocks
- Historique des productions

### Ventes

- Création de ventes (comptant ou crédit)
- Gestion automatique des stocks
- Validation automatique
- Historique des ventes

### Crédits

- Suivi des crédits clients
- Encaissement de paiements
- Historique des paiements
- Alertes de crédits impayés

### Stocks

- Suivi des stocks de produits finis
- Suivi des stocks de matières premières
- Mouvements de stock automatiques
- Ajustements manuels

### Finances

- Gestion des dépenses
- Gestion des salaires (fixe et production)
- Rapports financiers
- Balance des comptes

## Entités principales

### User

Utilisateur avec rôle (manager/employee)

### Product

Produit fini ou matière première

### Sale

Vente complète avec workflow de validation

### CreditPayment

Encaissement d'un crédit

### Production

Production avec périodes et matières premières

### StockMovement

Mouvement de stock (entrée/sortie/ajustement)

### Expense

Dépense opérationnelle

### Salary

Paiement de salaire (fixe ou production)

## Système de permissions

### Rôles disponibles

1. **Responsable** – Accès complet
2. **Gestionnaire** – Accès à la plupart des modules
3. **Vendeur** – Accès uniquement aux ventes et crédits
4. **Producteur** – Accès uniquement à la production
5. **Comptable** – Accès aux finances et rapports
6. **Lecteur** – Accès en lecture seule

### Permissions

- `viewDashboard` – Voir le tableau de bord
- `viewProduction`, `createProduction`, `editProduction`, `deleteProduction`
- `viewSales`, `createSale`, `editSale`, `deleteSale`
- `viewStock`, `editStock`
- `viewCredits`, `collectPayment`, `viewCreditHistory`
- `viewFinances`, `createExpense`, `editExpense`, `deleteExpense`
- `viewSalaries`, `createSalary`, `editSalary`, `deleteSalary`
- `viewReports`, `downloadReports`

## Workflows

### Workflow de vente

1. Création de la vente
2. Vérification du stock disponible
3. Calcul automatique : Prix total, Reste à payer
4. Validation automatique
5. Déduction automatique du stock

### Workflow de production

1. Création de la production
2. Vérification du stock de matières premières
3. Calcul automatique de la période
4. Augmentation du stock de produits finis
5. Diminution du stock de matières premières

### Workflow de crédit

1. Encaissement du paiement
2. Vérification du montant (≤ reste à payer)
3. Enregistrement avec signature
4. Mise à jour automatique du reste à payer
5. Si reste = 0 → Vente complètement payée

## Guide d'utilisation

### Créer une production

1. Aller dans **Production**
2. Cliquer sur **Nouvelle production**
3. Sélectionner la date et la période
4. Renseigner les quantités
5. Ajouter les matières premières (optionnel)
6. Enregistrer

### Créer une vente

1. Aller dans **Ventes**
2. Cliquer sur **Nouvelle vente**
3. Sélectionner le client
4. Ajouter les produits
5. Choisir le mode de paiement (comptant ou crédit)
6. Enregistrer

### Encaisser un crédit

1. Aller dans **Crédits**
2. Sélectionner un client avec crédit en cours
3. Cliquer sur **Encaisser**
4. Entrer le montant
5. Signer le paiement
6. Enregistrer

### Payer un salaire

1. Aller dans **Salaires & Indemnités**
2. Sélectionner l'employé
3. Cliquer sur **Payer**
4. Vérifier la date et la période
5. Signer le paiement
6. Enregistrer

## Structure

```
eau_minerale/
├── domain/
│   ├── entities/          # Entités métier
│   ├── repositories/      # Interfaces
│   ├── services/          # Services métier
│   └── permissions/       # Permissions
├── data/
│   └── repositories/      # Implémentations
├── application/
│   ├── controllers/       # Contrôleurs Riverpod
│   └── providers.dart
└── presentation/
    ├── screens/          # Écrans
    └── widgets/         # Widgets
```

## Points clés

- **Ventes directes** – Pas de workflow de validation, validation automatique
- **Impacts automatiques** – Stock, crédits, statistiques mis à jour automatiquement
- **Gestion des périodes** – Production découpée en 3 périodes configurables
- **Traçabilité complète** – Historique de tous les mouvements
- **Gestion des rôles** – Accès différencié selon le rôle utilisateur
- **Validation robuste** – Prévention des paiements en double, validation des dates et montants

## Prochaines étapes

- [Système de permissions](../06-permissions/overview.md)
- [Vue d'ensemble des modules](./overview.md)
