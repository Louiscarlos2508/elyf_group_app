# Modules - Vue d'ensemble

Présentation des modules disponibles dans ELYF Group App.

## Modules disponibles

### Administration

Gestion centralisée des utilisateurs, rôles et permissions pour tous les modules.

- Gestion des modules
- Gestion des utilisateurs
- Gestion des rôles
- Attribution de permissions

Voir [Module Administration](./administration.md) pour plus de détails.

### Trésorerie

Gestion centralisée de la trésorerie pour tous les modules.

- Vue d'ensemble financière
- Flux de trésorerie
- Rapports financiers
- Balance des comptes

### Eau Minérale

Module de gestion de production et de vente de sachets d'eau.

- Production de sachets
- Gestion des stocks
- Ventes
- Rapports de production

Voir [Module Eau Minérale](./eau-minerale.md) pour plus de détails.

### Gaz

Module de distribution de bouteilles de gaz.

- Gestion des dépôts
- Distribution
- Suivi des stocks
- Rapports de vente

Voir [Module Gaz](./gaz.md) pour plus de détails.

### Orange Money

Module pour les opérations cash-in/cash-out des agents agréés.

- Transactions cash-in
- Transactions cash-out
- Gestion des clients
- Rapports de transactions

Voir [Module Orange Money](./orange-money.md) pour plus de détails.

### Immobilier

Module de gestion de locations de maisons.

- Gestion des propriétés
- Gestion des locataires
- Contrats de location
- Paiements de loyers

Voir [Module Immobilier](./immobilier.md) pour plus de détails.

### Boutique

Module de vente physique avec gestion de stocks et caisse.

- Gestion des produits
- Gestion des stocks
- Ventes
- Rapports de vente
- Impression de reçus

Voir [Module Boutique](./boutique.md) pour plus de détails.

## Architecture commune

Tous les modules suivent la même architecture :

```
module/
├── presentation/      # UI
├── application/       # State management
├── domain/           # Logique métier
└── data/             # Accès aux données
```

## Fonctionnalités communes

### Navigation adaptative

Tous les modules utilisent une navigation adaptative :
- **Petits écrans** : NavigationBar en bas
- **Grands écrans** : NavigationRail sur le côté

### Support offline

Tous les modules fonctionnent en mode offline :
- Données stockées localement (Isar)
- Synchronisation automatique
- Indicateurs de synchronisation

### Permissions

Tous les modules intègrent le système de permissions :
- Vérification d'accès
- Rôles et permissions
- Audit trail

### Multi-tenant

Tous les modules supportent le multi-tenant :
- Filtrage par entreprise
- Isolation des données
- Switch d'entreprise

## Création d'un nouveau module

Voir [Structure des modules](../04-development/module-structure.md) pour créer un nouveau module.

## Prochaines étapes

- [Module Administration](./administration.md)
- [Module Eau Minérale](./eau-minerale.md)
- [Module Gaz](./gaz.md)
- [Module Orange Money](./orange-money.md)
- [Module Immobilier](./immobilier.md)
- [Module Boutique](./boutique.md)
