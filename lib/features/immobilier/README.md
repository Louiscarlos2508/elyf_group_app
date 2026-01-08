# Feature › Immobilier

Module de gestion immobilière pour la location de maisons.

## Structure

- `presentation/` — écrans et widgets (shell + sous-modules).
- `application/` — providers Riverpod, contrôleurs et navigation interne.
- `domain/` — entités, value objects et interfaces de repository.
- `data/` — implémentations mock (Drift/Firestore seront branchés plus tard).

## Entités

- `Property` — Propriétés immobilières (maisons, appartements, villas, etc.)
- `Tenant` — Locataires
- `Contract` — Contrats de location
- `Payment` — Paiements de loyers
- `PropertyExpense` — Dépenses liées aux propriétés

## Écrans

- `DashboardScreen` — Vue d'ensemble avec KPIs
- `PropertiesScreen` — Liste des propriétés
- `TenantsScreen` — Liste des locataires
- `ContractsScreen` — Liste des contrats
- `PaymentsScreen` — Liste des paiements
- `ExpensesScreen` — Liste des dépenses

## Navigation

Le module utilise une navigation adaptative :
- `NavigationRail` pour les écrans larges (≥600px)
- `NavigationBar` pour les petits écrans

## Routes

- `/modules/immobilier` — Écran d'accueil du module
- `/immobilier` — Shell screen avec navigation complète
