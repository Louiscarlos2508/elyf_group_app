# Feature › Gaz

Module de gestion de vente de gaz (détail et gros).

## Structure

```
lib/features/gaz/
├── application/
│   ├── providers.dart          # Providers Riverpod
│   └── controllers/
│       ├── gas_controller.dart
│       └── expense_controller.dart
├── data/
│   └── repositories/
│       ├── mock_gas_repository.dart
│       └── mock_expense_repository.dart
├── domain/
│   ├── entities/
│   │   ├── cylinder.dart       # Types de bouteilles
│   │   ├── delivery.dart       # Livraisons/approvisionnements
│   │   ├── gas_sale.dart       # Ventes
│   │   └── expense.dart        # Dépenses
│   └── repositories/
│       ├── gas_repository.dart
│       └── expense_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── gaz_shell_screen.dart
│   │   └── sections/
│   │       ├── dashboard_screen.dart
│   │       ├── retail_screen.dart
│   │       ├── wholesale_screen.dart
│   │       ├── stock_screen.dart
│   │       └── expenses_screen.dart
│   └── widgets/
│       ├── enhanced_kpi_card.dart
│       ├── dashboard_kpi_grid.dart
│       ├── stock_summary_card.dart
│       ├── cylinder_card.dart
│       ├── expense_card.dart
│       ├── expense_form_dialog.dart
│       └── monthly_expense_summary.dart
└── README.md
```

## Fonctionnalités

- **Tableau de bord** : KPIs, stock, ventes, dépenses
- **Ventes au détail** : Vente rapide, historique
- **Ventes en gros** : Gestion clients gros, commandes
- **Stock** : Gestion des types de bouteilles, ajustement stock
- **Dépenses** : Suivi des charges par catégorie

## TODO

- [ ] Formulaires de vente (détail & gros)
- [ ] Ajustement de stock
- [ ] Rapports et statistiques avancés
- [ ] Impression de reçus
- [ ] Gestion des clients fidèles
