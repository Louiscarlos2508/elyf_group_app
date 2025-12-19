# Module Orange Money

Module pour les opérations cash-in/cash-out des agents agréés.

## Vue d'ensemble

Le module Orange Money permet de gérer :
- Transactions cash-in (dépôts)
- Transactions cash-out (retraits)
- Gestion des clients
- Suivi des commissions
- Rapports de transactions

## Fonctionnalités

### Transactions

- Enregistrement des transactions cash-in
- Enregistrement des transactions cash-out
- Historique des transactions
- Recherche et filtres
- Export des transactions

### Clients

- Gestion de la base de clients
- Recherche de clients
- Historique des transactions par client
- Statistiques par client

### Commissions

- Calcul automatique des commissions
- Suivi des commissions
- Rapports de commissions
- Paiement des commissions

### Rapports

- Rapports journaliers
- Rapports mensuels
- Statistiques de transactions
- Graphiques de tendances

## Entités principales

### Transaction

Transaction cash-in ou cash-out

### Customer

Client Orange Money

## Structure

```
orange_money/
├── application/
│   ├── controllers/
│   │   └── orange_money_controller.dart
│   └── providers.dart
├── data/
│   └── repositories/
│       └── mock_transaction_repository.dart
├── domain/
│   ├── entities/
│   │   └── customer.dart
│   └── repositories/
│       └── transaction_repository.dart
└── presentation/
    └── screens/
        └── sections/
            └── transactions_screen.dart
```

## Guide d'utilisation

### Enregistrer une transaction cash-in

1. Aller dans **Transactions**
2. Cliquer sur **Cash-in**
3. Sélectionner ou créer un client
4. Entrer le montant
5. Enregistrer la transaction

### Enregistrer une transaction cash-out

1. Aller dans **Transactions**
2. Cliquer sur **Cash-out**
3. Sélectionner ou créer un client
4. Entrer le montant
5. Enregistrer la transaction

### Rechercher un client

1. Aller dans **Clients**
2. Utiliser la barre de recherche
3. Filtrer par critères
4. Voir l'historique du client

## Prochaines étapes

- [Vue d'ensemble des modules](./overview.md)
- [Synchronisation offline](../07-offline/synchronization.md)
