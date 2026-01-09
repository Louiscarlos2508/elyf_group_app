# Module Orange Money

## 📋 Vue d'ensemble

Ce module implémente un système complet de gestion des opérations Orange Money (cash-in/cash-out) avec :
- Gestion des transactions
- Gestion des agents
- Calcul et paiement des commissions
- Pointages de liquidité (matin/soir)
- Paramètres et notifications

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

## 🎮 Controllers Disponibles

- `OrangeMoneyController` - Gestion des transactions
- `AgentsController` - Gestion des agents
- `CommissionsController` - Gestion des commissions
- `LiquidityController` - Gestion des pointages
- `SettingsController` - Gestion des paramètres

## 🔄 Offline-First & Synchronisation

### Repositories Offline ✅

- `TransactionOfflineRepository` - Transactions cash-in/cash-out
- `AgentOfflineRepository` - Agents Orange Money
- `CommissionOfflineRepository` - Commissions mensuelles
- `LiquidityOfflineRepository` - Pointages de liquidité
- `SettingsOfflineRepository` - Paramètres du module

### Synchronisation

Toutes les opérations CRUD sont automatiquement synchronisées avec Firestore via `SyncManager`.

## 📁 Structure

```
lib/features/orange_money/
├── domain/
│   ├── entities/          # Entités métier
│   ├── repositories/      # Interfaces de repositories
│   └── services/          # Services métier
├── data/
│   └── repositories/      # OfflineRepositories (Drift)
├── application/
│   ├── controllers/       # Contrôleurs Riverpod
│   └── providers.dart     # Providers Riverpod
└── presentation/
    ├── screens/          # Écrans principaux
    └── widgets/         # Widgets réutilisables
```

## 🎯 Fonctionnalités

### Transactions
- Création de transactions cash-in/cash-out
- Historique avec recherche et filtres
- Validation et signature

### Agents
- Gestion des agents Orange Money
- Suivi de la liquidité par agent
- Calcul des commissions

### Commissions
- Calcul automatique des commissions mensuelles
- Suivi des paiements
- Alertes d'échéance

### Pointages de Liquidité
- Pointage du matin
- Pointage du soir
- Suivi de la liquidité quotidienne

### Paramètres
- Notifications (alertes liquidité, rappels commissions)
- Seuils (liquidité critique, jours avant échéance)
- Numéro SIM
