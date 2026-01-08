# Premiers pas

Guide pour démarrer avec ELYF Group App après l'installation.

## Configuration initiale

### 1. Premier lancement

Lors du premier lancement, l'application affiche :
- **Splash Screen** – Chargement initial
- **Onboarding** – Présentation des fonctionnalités (première fois uniquement)
- **Login Screen** – Connexion Firebase

### 2. Créer un compte administrateur

Pour la première utilisation, vous devez créer un compte administrateur :

1. Aller sur la console Firebase
2. Authentication > Users > Add user
3. Créer un utilisateur avec email/mot de passe
4. Se connecter dans l'application

### 3. Configuration multi-tenant

L'application supporte plusieurs entreprises. Pour ajouter une entreprise :

1. Se connecter en tant qu'administrateur
2. Aller dans **Administration** > **Entreprises**
3. Créer une nouvelle entreprise
4. Configurer les modules disponibles

### 4. Configuration des modules

Chaque entreprise peut activer/désactiver des modules :

- Eau Minérale
- Gaz
- Orange Money
- Immobilier
- Boutique

## Navigation de base

### Menu principal

L'écran principal affiche le menu des modules disponibles. Chaque module a :
- Une icône distinctive
- Une description
- Un accès direct via le routing

### Navigation adaptative

L'application s'adapte à la taille de l'écran :
- **Petits écrans** : NavigationBar en bas
- **Grands écrans** : NavigationRail sur le côté

### Modules disponibles

1. **Administration** – Gestion utilisateurs, rôles, permissions
2. **Trésorerie** – Gestion financière centralisée
3. **Eau Minérale** – Production et ventes
4. **Gaz** – Distribution de bouteilles
5. **Orange Money** – Opérations cash-in/cash-out
6. **Immobilier** – Gestion de locations
7. **Boutique** – Vente physique

## Utilisation de base

### Créer une entrée

1. Naviguer vers le module souhaité
2. Cliquer sur le bouton "+" ou "Ajouter"
3. Remplir le formulaire
4. Sauvegarder

### Recherche et filtres

La plupart des listes supportent :
- **Recherche textuelle** – Barre de recherche en haut
- **Filtres** – Bouton de filtre pour affiner les résultats
- **Tri** – Options de tri par colonnes

### Mode offline

L'application fonctionne en mode offline :
- Les données sont stockées localement (Drift / SQLite)
- La synchronisation se fait automatiquement quand la connexion revient
- Un indicateur de synchronisation est visible dans l'UI

### Impression

Pour les modules supportant l'impression (Boutique, Eau Minérale, etc.) :
1. Ouvrir un document (vente, reçu, etc.)
2. Cliquer sur le bouton d'impression
3. L'impression se fait via l'imprimante Sunmi V3 si disponible

## Prochaines étapes

Maintenant que vous connaissez les bases :

1. Explorer les modules : [Vue d'ensemble des modules](../05-modules/overview.md)
2. Comprendre les permissions : [Système de permissions](../06-permissions/overview.md)
3. Apprendre le développement : [Guidelines de développement](../04-development/guidelines.md)

## Astuces

- Utilisez la recherche pour trouver rapidement des éléments
- Les raccourcis clavier sont disponibles sur desktop
- Le mode sombre peut être activé dans les paramètres
- Les notifications push nécessitent une autorisation explicite
