# Système de Permissions - Module Eau Minérale

## Vue d'ensemble

Le module eau minérale implémente un système de contrôle d'accès basé sur les rôles (RBAC). Chaque utilisateur a un rôle qui détermine les permissions qu'il possède.

## Rôles disponibles

### 1. Responsable
- **Accès complet** à toutes les fonctionnalités
- Peut gérer les paramètres, produits, et configurations

### 2. Gestionnaire
- Accès à la plupart des modules sauf les paramètres
- Peut créer/modifier production, ventes, dépenses
- Peut voir les rapports et salaires

### 3. Vendeur
- Accès uniquement aux ventes et crédits
- Peut créer des ventes et encaisser des paiements
- Peut voir le stock (lecture seule)

### 4. Producteur
- Accès uniquement à la production
- Peut créer des productions
- Peut voir le stock (lecture seule)

### 5. Comptable
- Accès aux finances, salaires et rapports
- Peut créer/modifier des dépenses
- Peut voir les rapports

### 6. Lecteur
- Accès en lecture seule
- Peut voir le dashboard, production, ventes, stock, crédits, finances et rapports
- Ne peut pas créer ou modifier

## Permissions disponibles

Les permissions sont définies dans `domain/entities/module_permission.dart` :

- `viewDashboard` - Voir le tableau de bord
- `viewProduction`, `createProduction`, `editProduction`, `deleteProduction`
- `viewSales`, `createSale`, `editSale`, `deleteSale`
- `viewStock`, `editStock`
- `viewCredits`, `collectPayment`, `viewCreditHistory`
- `viewFinances`, `createExpense`, `editExpense`, `deleteExpense`
- `viewSalaries`, `createSalary`, `editSalary`, `deleteSalary`
- `viewReports`, `downloadReports`
- `viewSettings`, `editSettings`, `manageProducts`, `configureProduction`
- `viewProfile`, `editProfile`, `changePassword`

## Utilisation dans le code

### 1. Masquer un widget selon les permissions

```dart
PermissionGuard(
  permission: ModulePermission.createProduction,
  child: FilledButton(
    onPressed: () => _showForm(),
    child: Text('Nouvelle Production'),
  ),
)
```

### 2. Masquer une section entière

```dart
PermissionGuard(
  permission: ModulePermission.viewSettings,
  child: SettingsScreen(),
  fallback: AccessDeniedPlaceholder(
    message: 'Vous n\'avez pas accès aux paramètres',
  ),
)
```

### 3. Vérifier plusieurs permissions

```dart
PermissionGuardAny(
  permissions: {
    ModulePermission.editProduction,
    ModulePermission.deleteProduction,
  },
  child: ActionButtons(),
)
```

### 4. Bouton avec permission

```dart
PermissionButton(
  permission: ModulePermission.createSale,
  onPressed: () => _showForm(),
  child: Text('Nouvelle Vente'),
)
```

## Configuration du rôle utilisateur

Actuellement, le rôle est défini dans `application/providers.dart` :

```dart
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => MockPermissionService(
    role: EauMineraleRole.responsable, // Changer ici pour tester
  ),
);
```

### Pour tester différents rôles :

1. Ouvrir `lib/features/eau_minerale/application/providers.dart`
2. Modifier le rôle dans `permissionServiceProvider` :
   - `EauMineraleRole.responsable` - Accès complet
   - `EauMineraleRole.vendeur` - Ventes uniquement
   - `EauMineraleRole.producteur` - Production uniquement
   - `EauMineraleRole.comptable` - Finances uniquement
   - `EauMineraleRole.lecteur` - Lecture seule
   - `EauMineraleRole.gestionnaire` - Presque tout sauf paramètres

## Intégration avec l'authentification

**TODO** : Quand l'application principale sera implémentée, le rôle devra être récupéré depuis :
- Le profil utilisateur dans Firestore
- Les permissions assignées par l'administration
- Le contexte multi-tenant (entreprise)

Le service `PermissionService` devra être remplacé par une implémentation qui :
1. Récupère le rôle depuis le profil utilisateur
2. Vérifie les permissions dans Firestore
3. Prend en compte les permissions spécifiques à l'entreprise/module

## Navigation automatique

Le système filtre automatiquement les sections de navigation selon les permissions de l'utilisateur. Les sections non accessibles n'apparaissent pas dans la barre de navigation.

## Exemples d'utilisation

### Production Screen
- Le bouton "Nouvelle Production" est masqué si l'utilisateur n'a pas `createProduction`

### Sales Screen
- Le bouton "Nouvelle Vente" est masqué si l'utilisateur n'a pas `createSale`

### Settings Screen
- La configuration de production est masquée si l'utilisateur n'a pas `configureProduction`
- Le catalogue de produits est masqué si l'utilisateur n'a pas `manageProducts`

### Credits Screen
- Le bouton "Encaisser" est masqué si l'utilisateur n'a pas `collectPayment`
- Le bouton "Historique" est masqué si l'utilisateur n'a pas `viewCreditHistory`

