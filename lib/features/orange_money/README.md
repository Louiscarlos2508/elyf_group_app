# Feature › Orange Money

Structure actuelle :

## Écrans
- `presentation/screens/sections/transactions_v2_screen.dart` - Écran principal avec tabs (Nouvelle transaction / Historique)
- `presentation/screens/sections/transactions_history_screen.dart` - Écran d'historique avec recherche et filtres
- `presentation/screens/sections/dashboard_screen.dart` - Tableau de bord
- `presentation/screens/sections/agents_screen.dart` - Gestion des agents
- `presentation/screens/sections/commissions_screen.dart` - Gestion des commissions
- `presentation/screens/sections/liquidity_screen.dart` - Gestion de la liquidité
- `presentation/screens/sections/reports_screen.dart` - Rapports
- `presentation/screens/sections/settings_screen.dart` - Paramètres

## Widgets
- `widgets/transaction_type_selector.dart` - Sélecteur de type de transaction (Dépôt/Retrait)
- `widgets/form_field_with_label.dart` - Champ de formulaire réutilisable

## Application
- `application/controllers/orange_money_controller.dart` - Controller principal
- `application/providers.dart` - Providers Riverpod

## Domain
- `domain/entities/transaction.dart` - Entité Transaction
- `domain/repositories/transaction_repository.dart` - Interface du repository

## Data
- `data/repositories/mock_transaction_repository.dart` - Implémentation mock du repository

