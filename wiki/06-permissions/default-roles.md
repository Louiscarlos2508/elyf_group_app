# Rôles par défaut

Liste des rôles système et des rôles par défaut de chaque module.

## Rôles système

Ces rôles sont disponibles dans tous les modules :

### Super Admin

- Accès complet à tous les modules
- Gestion des entreprises
- Gestion des utilisateurs
- Gestion des rôles
- Toutes les permissions

### Admin

- Administration d'une entreprise
- Gestion des utilisateurs de l'entreprise
- Gestion des rôles de l'entreprise
- Accès à tous les modules de l'entreprise

### User

- Utilisateur standard
- Permissions de base selon le module

## Rôles par module

### Module Eau Minérale

#### Responsable
- Accès complet à toutes les fonctionnalités
- Gestion des paramètres et configurations

#### Gestionnaire
- Accès à la plupart des modules sauf les paramètres
- Création/modification de production, ventes, dépenses
- Voir les rapports et salaires

#### Vendeur
- Accès uniquement aux ventes et crédits
- Créer des ventes et encaisser des paiements
- Voir le stock (lecture seule)

#### Producteur
- Accès uniquement à la production
- Créer des productions
- Voir le stock (lecture seule)

#### Comptable
- Accès aux finances, salaires et rapports
- Créer/modifier des dépenses
- Voir les rapports

#### Lecteur
- Accès en lecture seule
- Voir le dashboard, production, ventes, stock, crédits, finances et rapports
- Ne peut pas créer ou modifier

### Module Boutique

#### Gérant
- Accès complet
- Gestion du catalogue
- Gestion des stocks
- Point de vente
- Rapports

#### Vendeur
- Point de vente
- Voir le catalogue
- Voir le stock (lecture seule)

#### Stockiste
- Gestion des stocks
- Ajustements de stock
- Voir le catalogue

### Module Gaz

#### Gérant
- Accès complet
- Gestion des ventes
- Gestion des stocks
- Rapports

#### Vendeur
- Ventes au détail
- Voir le stock (lecture seule)

#### Vendeur Gros
- Ventes en gros
- Gestion des clients gros
- Voir le stock (lecture seule)

### Module Orange Money

#### Agent Principal
- Accès complet
- Toutes les transactions
- Gestion des clients
- Rapports

#### Agent
- Transactions cash-in/cash-out
- Voir l'historique
- Gestion des clients

### Module Immobilier

#### Gérant
- Accès complet
- Gestion des propriétés
- Gestion des contrats
- Rapports

#### Gestionnaire
- Gestion des locataires
- Gestion des contrats
- Enregistrement des paiements

## Attribution des rôles

Les rôles sont attribués aux utilisateurs par module dans le module Administration.

## Prochaines étapes

- [Vue d'ensemble](./overview.md)
- [Intégration](./integration.md)
