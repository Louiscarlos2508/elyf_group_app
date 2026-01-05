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

## Détails des sections par module

### 📦 Eau Minérale (`eau_minerale`)

**Sections disponibles :**

1. **Tableau (Activity/Dashboard)** - `activity_screen.dart`
   - Vue d'ensemble avec résumé de la journée

2. **Production** - `production_sessions_screen.dart`
   - Gestion des sessions de production
   - Détails des sessions : `production_session_detail_screen.dart`
   - Formulaire de création : `production_session_form_screen.dart`
   - Suivi de production : `production_tracking_screen.dart`

3. **Ventes** - `sales_screen.dart`
   - Gestion des ventes de sachets d'eau

4. **Stock** - `stock_screen.dart`
   - Gestion des stocks (bobines, emballages, produits finis)

5. **Crédits (Clients)** - `clients_screen.dart`
   - Gestion des clients et crédits

6. **Dépenses (Finances)** - `finances_screen.dart`
   - Gestion des dépenses

7. **Salaires** - `salaries_screen.dart`
   - Gestion des salaires

8. **Rapports** - `reports_screen.dart`
   - Rapports de production, ventes, dépenses, etc.

9. **Profil** - `profile_screen.dart`
   - Profil utilisateur

10. **Paramètres** - `settings_screen.dart`
    - Configuration du module

**Permissions :**
- Géré via `EauMineralePermissions` et `EauMineralePermissionAdapter`
- Sections filtrées selon les permissions de l'utilisateur

### 🏪 Boutique (`boutique`)

**Sections disponibles :**

1. **Tableau** - `dashboard_screen.dart`
   - Vue d'ensemble avec KPIs

2. **Caisse (POS)** - `pos_screen.dart`
   - Point de vente pour les ventes physiques

3. **Produits (Catalogue)** - `catalog_screen.dart`
   - Gestion du catalogue de produits

4. **Dépenses** - `expenses_screen.dart`
   - Gestion des dépenses de la boutique

5. **Rapports** - `reports_screen.dart`
   - Rapports de ventes, achats, dépenses, profits

6. **Profil** - `profile_screen.dart` (partagé)
   - Profil utilisateur

### 🏠 Immobilier (`immobilier`)

**Sections disponibles :**

1. **Tableau** - `dashboard_screen.dart`
   - Vue d'ensemble avec KPIs

2. **Propriétés** - `properties_screen.dart`
   - Liste et gestion des propriétés immobilières

3. **Locataires** - `tenants_screen.dart`
   - Gestion des locataires

4. **Contrats** - `contracts_screen.dart`
   - Gestion des contrats de location

5. **Paiements** - `payments_screen.dart`
   - Gestion des paiements de loyers

6. **Dépenses** - `expenses_screen.dart`
   - Gestion des dépenses liées aux propriétés

7. **Rapports** - `reports_screen.dart`
   - Rapports immobiliers

8. **Profil** - `profile_screen.dart` (partagé)
   - Profil utilisateur

### 💰 Orange Money (`orange_money`)

**Sections disponibles :**

1. **Transactions** - `transactions_v2_screen.dart`
   - Nouvelle transaction / Historique
   - Historique détaillé : `transactions_history_screen.dart`

2. **Agents Affiliés** - `agents_screen.dart`
   - Gestion des agents Orange Money

3. **Liquidité** - `liquidity_screen.dart`
   - Gestion de la liquidité

4. **Commissions** - `commissions_screen.dart`
   - Gestion des commissions

5. **Rapports** - `reports_screen.dart`
   - Rapports des transactions et commissions

6. **Paramètres** - `settings_screen.dart`
   - Configuration du module

7. **Profil** - `profile_screen.dart` (partagé)
   - Profil utilisateur

### 🔥 Gaz (`gaz`)

**Sections disponibles :**

1. **Tableau** - `dashboard_screen.dart`
   - Vue d'ensemble avec KPIs
   - Performance POS
   - Sections : `dashboard_kpi_section.dart`, `dashboard_performance_section.dart`, `dashboard_pos_performance_section.dart`

2. **Vente Détail (Retail)** - `retail_screen.dart`
   - Vente au détail de bouteilles de gaz
   - Liste des bouteilles : `retail_cylinder_list.dart`
   - Nouvelle vente : `retail_new_sale_tab.dart`
   - Statistiques : `retail_statistics_tab.dart`

3. **Vente Gros (Wholesale)** - `wholesale_screen.dart`
   - Vente en gros

4. **Approvisionnement** - `approvisionnement_screen.dart`
   - Gestion des tours d'approvisionnement
   - Liste des tours : `tours_list_tab.dart`

5. **Détail de Tour** - `tour_detail_screen.dart`
   - Détails d'un tour d'approvisionnement

6. **Stock** - `stock_screen.dart`
   - Gestion des stocks de bouteilles
   - Liste POS : `stock_pos_list.dart`

7. **Pertes/Fuites (Cylinder Leak)** - `cylinder_leak_screen.dart`
   - Gestion des bouteilles avec fuites/perdus

8. **Dépenses** - `expenses_screen.dart`
   - Gestion des dépenses
   - Par catégorie : `expenses_category_tab.dart`
   - Historique : `expenses_history_tab.dart`

9. **Rapports** - `reports_screen.dart`
   - Rapports du module gaz

10. **Paramètres** - `settings_screen.dart`
    - Configuration du module

11. **Profil** - `profile_screen.dart`
    - Profil utilisateur

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

## Comparaison des modules

### Modules avec système de permissions dynamique :
- ✅ **Eau Minérale** : Utilise `EauMineralePermissions` et `accessibleSectionsProvider` pour filtrer les sections selon les permissions

### Modules avec navigation statique :
- ⚠️ **Boutique** : Sections hardcodées
- ⚠️ **Immobilier** : Sections hardcodées
- ⚠️ **Orange Money** : Sections hardcodées
- ⚠️ **Gaz** : Sections hardcodées

## Recommandations

Pour une cohérence dans toute l'application, il serait recommandé :

1. **Implémenter un système de permissions pour tous les modules** (similaire à Eau Minérale)
2. **Créer des enums de sections pour chaque module** (comme `EauMineraleSection`)
3. **Utiliser des providers pour gérer les sections accessibles** (comme `accessibleSectionsProvider`)
4. **Centraliser la gestion des permissions** via le module Administration

## Notes de développement

- **Eau Minérale** est le module le plus avancé avec un système complet de permissions
- Tous les modules utilisent `AdaptiveNavigationScaffold` pour la navigation
- Les écrans de profil sont partagés entre les modules (dans `shared/presentation/widgets/profile/`)
- La structure des modules suit le pattern Feature-First avec séparation domain/application/presentation

## Création d'un nouveau module

Voir [Structure des modules](../04-development/module-structure.md) pour créer un nouveau module.

## Prochaines étapes

- [Module Administration](./administration.md)
- [Module Eau Minérale](./eau-minerale.md)
- [Module Gaz](./gaz.md)
- [Module Orange Money](./orange-money.md)
- [Module Immobilier](./immobilier.md)
- [Module Boutique](./boutique.md)
