# Module Boutique

Module de vente physique avec gestion de stocks et caisse.

## Vue d'ensemble

Le module Boutique permet de gérer :
- Catalogue de produits
- Gestion des stocks
- Point de vente (POS)
- Ventes
- Rapports de vente
- Impression de reçus

## Fonctionnalités

### Catalogue

- Liste des produits
- Ajout/Modification de produits
- Catégorisation
- Gestion des prix
- Images de produits

### Stocks

- Suivi des stocks
- Alertes de stock faible
- Ajustements de stock
- Historique des mouvements
- Rapports de stock

### Point de vente

- Interface de vente rapide
- Panier
- Calcul automatique des totaux
- Gestion de la caisse
- Impression de reçus

### Ventes

- Historique des ventes
- Détails d'une vente
- Recherche de ventes
- Filtres par date
- Export des ventes

### Rapports

- Rapports de vente
- Rapports de stock
- Statistiques
- Graphiques de tendances

## Entités principales

### Product

Produits du catalogue

### Sale

Ventes

### StockMovement

Mouvements de stock

### Expense

Dépenses

## Structure

```
boutique/
├── presentation/
│   ├── screens/
│   │   ├── boutique_shell_screen.dart
│   │   ├── catalog_screen.dart
│   │   └── pos_screen.dart
│   └── widgets/
│       ├── product_tile.dart
│       └── cart_summary.dart
├── application/
│   ├── controllers/
│   │   └── store_controller.dart
│   └── providers.dart
├── domain/
│   ├── entities/
│   │   ├── product.dart
│   │   └── cart_item.dart
│   └── repositories/
│       └── store_repository.dart
└── data/
    └── repositories/
        └── store_repository.dart
```

## Guide d'utilisation

### Ajouter un produit

1. Aller dans **Catalogue**
2. Cliquer sur **Nouveau produit**
3. Remplir les informations
4. Ajouter une image (optionnel)
5. Enregistrer

### Effectuer une vente

1. Aller dans **Point de vente**
2. Scanner ou rechercher un produit
3. Ajouter au panier
4. Répéter pour tous les produits
5. Valider la vente
6. Imprimer le reçu (optionnel)

### Gérer le stock

1. Aller dans **Stocks**
2. Voir le résumé des stocks
3. Ajuster le stock si nécessaire
4. Voir l'historique des mouvements

### Voir les rapports

1. Aller dans **Rapports**
2. Sélectionner le type de rapport
3. Choisir la période
4. Voir ou exporter le rapport

## Impression

Le module supporte l'impression de reçus via l'imprimante Sunmi V3.

Voir [Intégration Sunmi](../08-printing/sunmi-integration.md) pour plus de détails.

## Prochaines étapes

- [Vue d'ensemble des modules](./overview.md)
- [Impression thermique](../08-printing/sunmi-integration.md)
