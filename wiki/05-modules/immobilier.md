# Module Immobilier

Module de gestion de locations de maisons.

## Vue d'ensemble

Le module Immobilier permet de gérer :
- Propriétés immobilières
- Locataires
- Contrats de location
- Paiements de loyers
- Dépenses liées aux propriétés

## Fonctionnalités

### Tableau de bord

- KPIs (propriétés, locataires, revenus)
- Vue d'ensemble des locations
- Statistiques financières
- Graphiques de tendances

### Propriétés

- Liste des propriétés
- Détails d'une propriété
- Ajout/Modification de propriétés
- Statut des propriétés (disponible/louée)

### Locataires

- Liste des locataires
- Détails d'un locataire
- Ajout/Modification de locataires
- Historique des locations

### Contrats

- Liste des contrats
- Création de contrats
- Modification de contrats
- Renouvellement de contrats
- Résiliation de contrats

### Paiements

- Enregistrement des paiements de loyers
- Historique des paiements
- Suivi des impayés
- Rapports de paiements

### Dépenses

- Dépenses liées aux propriétés
- Catégorisation des dépenses
- Rapports de dépenses
- Balance des dépenses

## Entités principales

### Property

Propriétés immobilières (maisons, appartements, villas, etc.)

### Tenant

Locataires

### Contract

Contrats de location

### Payment

Paiements de loyers

### PropertyExpense

Dépenses liées aux propriétés

## Structure

```
immobilier/
├── presentation/
│   └── screens/
│       └── immobilier_shell_screen.dart
├── application/
│   └── providers.dart
├── domain/
│   └── entities/
└── data/
    └── repositories/
```

## Écrans

- `DashboardScreen` – Vue d'ensemble avec KPIs
- `PropertiesScreen` – Liste des propriétés
- `TenantsScreen` – Liste des locataires
- `ContractsScreen` – Liste des contrats
- `PaymentsScreen` – Liste des paiements
- `ExpensesScreen` – Liste des dépenses

## Navigation

Le module utilise une navigation adaptative :
- `NavigationRail` pour les écrans larges (≥600px)
- `NavigationBar` pour les petits écrans

## Routes

- `/modules/immobilier` – Écran d'accueil du module
- `/immobilier` – Shell screen avec navigation complète

## Guide d'utilisation

### Ajouter une propriété

1. Aller dans **Propriétés**
2. Cliquer sur **Nouvelle propriété**
3. Remplir les informations
4. Enregistrer

### Créer un contrat

1. Aller dans **Contrats**
2. Cliquer sur **Nouveau contrat**
3. Sélectionner la propriété et le locataire
4. Remplir les détails du contrat
5. Enregistrer

### Enregistrer un paiement

1. Aller dans **Paiements**
2. Cliquer sur **Nouveau paiement**
3. Sélectionner le contrat
4. Entrer le montant et la date
5. Enregistrer

## Prochaines étapes

- [Vue d'ensemble des modules](./overview.md)
- [Synchronisation offline](../07-offline/synchronization.md)
