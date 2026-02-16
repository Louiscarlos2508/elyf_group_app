# Module Gaz

Module de gestion de vente de gaz (détail et gros).

## Vue d'ensemble

Le module Gaz permet de gérer :
- Distribution de bouteilles de gaz
- Ventes au détail
- Ventes en gros
- Gestion des stocks
- Suivi des dépenses

## Fonctionnalités

### Tableau de bord

- KPIs (ventes, stock, dépenses)
- Vue d'ensemble des ventes
- Résumé des stocks
- Graphiques de tendances

### Ventes au détail

- Vente rapide de bouteilles
- Historique des ventes
- Recherche de ventes
- Filtres par date

### Ventes en gros

- Gestion des clients gros
- Historique des commandes

### Stock

- Gestion des types de bouteilles
- Suivi des stocks par type
- Ajustement de stock
- Alertes de stock faible

### Dépenses

- Suivi des charges par catégorie
- Enregistrement des dépenses
- Rapports de dépenses
- Balance des dépenses

## Entités principales

### Cylinder

Types de bouteilles de gaz

### GasSale

Ventes de gaz

### Expense

Dépenses opérationnelles

## Structure

```
gaz/
├── application/
│   ├── providers.dart
│   └── controllers/
│       ├── gas_controller.dart
│       └── expense_controller.dart
├── data/
│   └── repositories/
│       ├── mock_gas_repository.dart
│       └── mock_expense_repository.dart
├── domain/
│   ├── entities/
│   │   ├── cylinder.dart
│   │   ├── gas_sale.dart
│   │   └── expense.dart
│   └── repositories/
│       ├── gas_repository.dart
│       └── expense_repository.dart
└── presentation/
    ├── screens/
    │   ├── gaz_shell_screen.dart
    │   └── sections/
    │       ├── dashboard_screen.dart
    │       ├── retail_screen.dart
    │       ├── wholesale_screen.dart
    │       ├── stock_screen.dart
    │       └── expenses_screen.dart
    └── widgets/
        ├── enhanced_kpi_card.dart
        ├── dashboard_kpi_grid.dart
        ├── stock_summary_card.dart
        ├── cylinder_card.dart
        ├── expense_card.dart
        ├── expense_form_dialog.dart
        └── monthly_expense_summary.dart
```

## Guide d'utilisation

### Vendre au détail

1. Aller dans **Ventes au détail**
2. Cliquer sur **Nouvelle vente**
3. Sélectionner le type de bouteille
4. Entrer la quantité
5. Enregistrer la vente

### Vendre en gros

1. Aller dans **Ventes en gros**
2. Sélectionner ou créer un client
3. Créer une commande
4. Ajouter les bouteilles
5. Valider la commande

### Gérer le stock

1. Aller dans **Stock**
2. Voir le résumé des stocks
3. Ajuster le stock si nécessaire
4. Voir l'historique des mouvements

### Enregistrer une dépense

1. Aller dans **Dépenses**
2. Cliquer sur **Nouvelle dépense**
3. Remplir les informations
4. Sélectionner la catégorie
5. Enregistrer

## TODO

- [ ] Formulaires de vente (détail & gros)
- [ ] Ajustement de stock
- [ ] Rapports et statistiques avancés
- [ ] Impression de reçus
- [ ] Gestion des clients fidèles

- [Vue d'ensemble des modules](./overview.md)
- [Impression thermique](../08-printing/sunmi-integration.md)
