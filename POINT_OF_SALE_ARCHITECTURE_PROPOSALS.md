# Propositions d'Architecture pour Point de Vente comme Entreprise

## Contexte

Un **Point de Vente (PointOfSale)** doit être traité comme une **entreprise à part entière** avec :
- Le module **gaz** activé
- Des **accès/permissions spécifiques** pour les utilisateurs
- Une **isolation des données** (chaque point de vente a ses propres données)

## Problème Actuel

Actuellement, `PointOfSale` est une simple entité qui référence une `enterpriseId` :
```dart
class PointOfSale {
  final String id;
  final String name;
  final String address;
  final String contact;
  final String enterpriseId;  // ← Référence à l'entreprise parente
  final String moduleId;
  final List<String> cylinderIds;
}
```

**Limitations :**
- Pas de création automatique d'Enterprise
- Pas de gestion des permissions spécifiques
- Pas d'isolation complète des données

---

## Proposition 1 : PointOfSale → Enterprise Automatique (Recommandée)

### Concept
Lors de la création d'un PointOfSale, créer automatiquement une Enterprise correspondante avec le module gaz.

### Avantages
✅ Isolation complète des données  
✅ Gestion native des permissions via `EnterpriseModuleUser`  
✅ Réutilisation de l'infrastructure existante  
✅ Cohérence avec l'architecture multi-tenant  

### Implémentation

#### 1. Service de Création
```dart
class PointOfSaleService {
  final EnterpriseRepository enterpriseRepository;
  final PointOfSaleRepository pointOfSaleRepository;
  final AdminController adminController; // Pour créer les accès
  
  /// Crée un point de vente avec Enterprise automatique
  Future<PointOfSale> createPointOfSaleWithEnterprise({
    required String name,
    required String address,
    required String contact,
    required String parentEnterpriseId, // Entreprise principale (gaz_1)
    required String createdByUserId,
    List<String>? cylinderIds,
  }) async {
    // 1. Générer un ID unique pour l'entreprise du point de vente
    final enterpriseId = 'pos_${parentEnterpriseId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // 2. Créer l'Enterprise
    final enterprise = Enterprise(
      id: enterpriseId,
      name: name,
      type: 'gaz', // Module gaz
      address: address,
      phone: contact,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await enterpriseRepository.createEnterprise(enterprise);
    
    // 3. Créer le PointOfSale avec l'enterpriseId
    final pointOfSale = PointOfSale(
      id: enterpriseId, // Même ID que l'Enterprise
      name: name,
      address: address,
      contact: contact,
      enterpriseId: parentEnterpriseId, // Entreprise parente (pour référence)
      moduleId: 'gaz',
      cylinderIds: cylinderIds ?? [],
      createdAt: DateTime.now(),
    );
    await pointOfSaleRepository.addPointOfSale(pointOfSale);
    
    // 4. Créer les accès pour l'utilisateur créateur
    // IMPORTANT: Le rôle doit exister dans la base de données
    // La fonction _getDefaultRoleForGazModule utilise PermissionRegistry
    // pour trouver un rôle qui a au moins une permission du module gaz.
    // Cela fonctionne même si le rôle a des permissions pour plusieurs modules.
    final defaultRoleId = await _getDefaultRoleForGazModule(adminController);
    
    final access = EnterpriseModuleUser(
      userId: createdByUserId,
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
      roleId: defaultRoleId, // Rôle avec permissions gaz (peut être multi-module)
      isActive: true,
      createdAt: DateTime.now(),
    );
    await adminController.assignUserToEnterprise(access, currentUserId: createdByUserId);
    
    return pointOfSale;
  }
}
```

#### 2. Modification de PointOfSale
```dart
class PointOfSale {
  final String id; // Même ID que l'Enterprise
  final String name;
  final String address;
  final String contact;
  final String parentEnterpriseId; // Entreprise principale (gaz_1)
  final String moduleId;
  final List<String> cylinderIds;
  final bool isActive;
  
  // Nouveau : Référence à l'Enterprise
  Enterprise? enterprise; // Optionnel, chargé à la demande
}
```

#### 3. Repository Modifié

**⚠️ IMPORTANT : Gestion de l'enterpriseId pour l'accès depuis l'entreprise mère**

Le repository doit stocker le PointOfSale avec `enterpriseId = parentEnterpriseId` pour qu'il soit accessible depuis les sections du module gaz de l'entreprise mère.

```dart
class PointOfSaleOfflineRepository extends OfflineRepository<PointOfSale> {
  final String enterpriseId; // Entreprise mère (gaz_1)
  final String moduleType;
  
  // Lors de la sauvegarde, s'assurer que l'Enterprise existe
  Future<void> addPointOfSale(PointOfSale pointOfSale) async {
    // Vérifier si l'Enterprise existe déjà
    final enterprise = await enterpriseRepository.getEnterpriseById(pointOfSale.id);
    if (enterprise == null) {
      // Créer l'Enterprise si elle n'existe pas
      await enterpriseRepository.createEnterprise(
        Enterprise(
          id: pointOfSale.id,
          name: pointOfSale.name,
          type: 'gaz',
          address: pointOfSale.address,
          phone: pointOfSale.contact,
          isActive: pointOfSale.isActive,
        ),
      );
    }
    
    // Sauvegarder le PointOfSale avec enterpriseId = parentEnterpriseId
    // pour qu'il soit accessible depuis l'entreprise mère
    await saveToLocal(pointOfSale);
  }
  
  @override
  String? getEnterpriseId(PointOfSale entity) {
    // ⚠️ IMPORTANT : Utiliser parentEnterpriseId pour le stockage dans Drift
    // Cela permet de récupérer les points de vente depuis l'entreprise mère
    // via getAllForEnterprise('gaz_1')
    // 
    // Exemple :
    // - PointOfSale(id: 'pos_gaz_1_123', parentEnterpriseId: 'gaz_1')
    // - Stocké avec enterpriseId = 'gaz_1' dans Drift
    // - Récupérable via getAllForEnterprise('gaz_1')
    return entity.parentEnterpriseId;
  }
  
  @override
  Future<List<PointOfSale>> getAllForEnterprise(String enterpriseId) async {
    // Récupérer tous les PointOfSale avec parentEnterpriseId == enterpriseId
    // Cela permet de voir les points de vente depuis l'entreprise mère
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId, // Entreprise mère (gaz_1)
      moduleType: moduleType,
    );
    // ... reste du code
  }
}
```

**Pourquoi cette approche ?**

1. **Accessibilité depuis l'entreprise mère** : Les sections du module gaz (Stock, Dashboard, Paramètres) utilisent `enterpriseId = 'gaz_1'` pour récupérer les points de vente
2. **Isolation des données** : Chaque point de vente a sa propre Enterprise avec ses propres données (ventes, stocks, etc.)
3. **Double accès possible** :
   - Depuis l'entreprise mère (gaz_1) : Voir/gérer tous les points de vente
   - Depuis le point de vente (pos_gaz_1_...) : Voir uniquement les données de ce point de vente

---

## Proposition 2 : PointOfSale avec Enterprise Intégré

### Concept
PointOfSale contient directement les données Enterprise (composition).

### Avantages
✅ Pas de duplication de données  
✅ Accès direct aux informations Enterprise  
✅ Moins de requêtes  

### Inconvénients
❌ Duplication de logique Enterprise  
❌ Moins flexible pour l'évolution future  

### Implémentation
```dart
class PointOfSale {
  final String id;
  final String name;
  final String address;
  final String contact;
  final String parentEnterpriseId;
  final String moduleId;
  final List<String> cylinderIds;
  
  // Données Enterprise intégrées
  final String? description;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Méthode pour convertir en Enterprise
  Enterprise toEnterprise() {
    return Enterprise(
      id: id,
      name: name,
      type: 'gaz',
      description: description,
      address: address,
      phone: contact,
      email: email,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
```

---

## Proposition 3 : Hiérarchie d'Entreprises

### Concept
PointOfSale est une entreprise "enfant" de l'entreprise principale avec une relation parent-enfant.

### Avantages
✅ Hiérarchie claire  
✅ Gestion des permissions héritées possible  
✅ Support pour plusieurs niveaux  

### Inconvénients
❌ Plus complexe à implémenter  
❌ Nécessite des modifications à Enterprise  

### Implémentation
```dart
class Enterprise {
  final String id;
  final String name;
  final String type;
  final String? parentEnterpriseId; // ← Nouveau : Référence au parent
  final bool isActive;
  // ...
}

// Lors de la création
final pointOfSaleEnterprise = Enterprise(
  id: 'pos_${parentEnterpriseId}_${timestamp}',
  name: name,
  type: 'gaz',
  parentEnterpriseId: parentEnterpriseId, // Entreprise principale
  isActive: true,
);
```

---

## Proposition 4 : PointOfSale avec EnterpriseModuleUser Automatique

### Concept
PointOfSale reste une entité simple, mais lors de sa création, on crée automatiquement les accès EnterpriseModuleUser pour les utilisateurs.

### Avantages
✅ Minimal changes  
✅ Réutilisation de l'infrastructure existante  

### Inconvénients
❌ Pas d'isolation complète des données  
❌ PointOfSale n'est pas vraiment une Enterprise  

### Implémentation
```dart
class PointOfSaleService {
  Future<PointOfSale> createPointOfSale({
    required String name,
    required String address,
    required String contact,
    required String enterpriseId,
    required List<String> userIds, // Utilisateurs à autoriser
    List<String>? cylinderIds,
  }) async {
    // 1. Créer le PointOfSale
    final pointOfSale = PointOfSale(
      id: LocalIdGenerator.generate(),
      name: name,
      address: address,
      contact: contact,
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
      cylinderIds: cylinderIds ?? [],
      createdAt: DateTime.now(),
    );
    await pointOfSaleRepository.addPointOfSale(pointOfSale);
    
    // 2. Créer les accès pour chaque utilisateur
    for (final userId in userIds) {
      final access = EnterpriseModuleUser(
        userId: userId,
        enterpriseId: enterpriseId, // Même entreprise
        moduleId: 'gaz',
        roleId: 'vendeur_gaz', // Rôle spécifique pour point de vente
        customPermissions: {
          'view_point_of_sale',
          'manage_point_of_sale_stock',
          // Permissions spécifiques au point de vente
        },
        isActive: true,
        createdAt: DateTime.now(),
      );
      await adminController.assignUserToEnterprise(access);
    }
    
    return pointOfSale;
  }
}
```

---

## Comparaison des Propositions

| Critère | Prop 1 (Enterprise Auto) | Prop 2 (Intégré) | Prop 3 (Hiérarchie) | Prop 4 (Accès Auto) |
|---------|-------------------------|------------------|---------------------|---------------------|
| **Isolation des données** | ✅ Complète | ⚠️ Partielle | ✅ Complète | ❌ Non |
| **Permissions natives** | ✅ Oui | ⚠️ Partiel | ✅ Oui | ⚠️ Partiel |
| **Complexité** | ⚠️ Moyenne | ✅ Faible | ❌ Élevée | ✅ Faible |
| **Flexibilité** | ✅ Élevée | ⚠️ Moyenne | ✅ Élevée | ❌ Faible |
| **Réutilisation** | ✅ Maximale | ⚠️ Moyenne | ✅ Maximale | ⚠️ Moyenne |
| **Évolutivité** | ✅ Excellente | ⚠️ Limitée | ✅ Excellente | ❌ Limitée |

---

## Recommandation : Proposition 1

**Pourquoi ?**
1. **Isolation complète** : Chaque point de vente a ses propres données
2. **Permissions natives** : Utilise `EnterpriseModuleUser` existant
3. **Cohérence** : S'intègre parfaitement avec l'architecture multi-tenant
4. **Évolutivité** : Facile d'ajouter des fonctionnalités Enterprise au point de vente

### Étapes d'Implémentation

1. **Créer `PointOfSaleService`** avec méthode `createPointOfSaleWithEnterprise`
2. **Modifier `PointOfSale`** pour inclure `parentEnterpriseId`
3. **Modifier `PointOfSaleRepository`** pour créer l'Enterprise si nécessaire
4. **Mettre à jour l'UI** pour utiliser le nouveau service
5. **Migration** : Script pour convertir les PointOfSale existants en Enterprise

### Exemple d'Utilisation

```dart
// Dans le formulaire de création
final pointOfSale = await pointOfSaleService.createPointOfSaleWithEnterprise(
  name: 'Point de Vente Centre-Ville',
  address: '123 Rue Principale',
  contact: '+221 77 123 4567',
  parentEnterpriseId: 'gaz_1', // Entreprise principale
  createdByUserId: currentUserId,
  cylinderIds: ['cylinder_6kg', 'cylinder_12kg'],
);

// L'Enterprise est créée automatiquement avec l'ID du PointOfSale
// Les permissions sont configurées pour l'utilisateur créateur
```

### Attribution d'Utilisateurs depuis l'Administration ✅

**Oui, vous pouvez attribuer des utilisateurs au point de vente depuis l'interface d'administration !**

Une fois qu'une Enterprise est créée pour un PointOfSale, elle apparaît automatiquement dans la liste des entreprises disponibles dans l'interface d'administration (`AssignEnterpriseDialog`).

**Important :** Après la création initiale du PointOfSale (où le créateur reçoit automatiquement un rôle), **tous les autres utilisateurs seront attribués depuis l'interface d'administration**. C'est la méthode standard et recommandée pour gérer les accès.

**Workflow d'attribution :**

1. **Création du PointOfSale** → Le créateur reçoit automatiquement un rôle (Option A)
2. **Attribution supplémentaire** → L'administrateur va dans "Administration" → "Utilisateurs" → "Attribuer une Entreprise"
3. **Sélection** → Module: "gaz", Rôle: (choix), Entreprise: "Point de Vente Centre-Ville"
4. **Résultat** → L'utilisateur a maintenant accès au point de vente avec le rôle sélectionné

**Comment ça fonctionne :**

1. **Création du PointOfSale** → Enterprise créée automatiquement avec `type: 'gaz'`
2. **L'Enterprise apparaît dans la liste** → `enterprisesProvider` récupère toutes les entreprises via `getAllEnterprises()`
3. **Attribution depuis Admin** → L'administrateur peut :
   - Sélectionner le module "gaz"
   - Sélectionner un rôle
   - Sélectionner l'entreprise du point de vente dans la liste
   - Attribuer l'utilisateur avec les permissions appropriées

**Avantages :**
- ✅ **Flexibilité** : Vous pouvez attribuer des utilisateurs à tout moment depuis l'admin
- ✅ **Gestion centralisée** : Tous les accès sont gérés au même endroit
- ✅ **Pas de duplication** : L'Enterprise créée automatiquement est réutilisée
- ✅ **Support multi-utilisateurs** : Vous pouvez attribuer plusieurs utilisateurs avec des rôles différents

**Exemple de workflow :**

```dart
// 1. Création du PointOfSale (automatique)
final pos = await pointOfSaleService.createPointOfSaleWithEnterprise(...);
// → Enterprise créée avec ID: 'pos_gaz_1_1234567890'

// 2. Plus tard, depuis l'interface Admin
// → L'administrateur ouvre "Attribuer une Entreprise"
// → Sélectionne Module: "gaz"
// → Sélectionne Rôle: "vendeur_gaz"
// → Sélectionne Entreprise: "Point de Vente Centre-Ville" (apparaît dans la liste)
// → Attribue l'utilisateur

// 3. L'utilisateur a maintenant accès au point de vente
```

---

## Questions à Considérer

1. **Qui peut créer un PointOfSale ?**
   - Seulement les administrateurs de l'entreprise principale ?
   - Ou les gestionnaires du module gaz ?

2. **Gestion des rôles ⚠️ IMPORTANT**
   - **Quel rôle utiliser pour le créateur du PointOfSale ?**
     - Option A : Utiliser un rôle existant (ex: 'gestionnaire_gaz')
     - Option B : Demander à l'utilisateur de sélectionner un rôle lors de la création
     - Option C : Créer automatiquement un rôle système "Gestionnaire Point de Vente"
   - **Les rôles doivent exister avant d'être utilisés** (créés côté administration)
   - **Recommandation** : Option A avec fallback vers un rôle admin si aucun rôle gaz n'existe
   
   **✅ L'Option A fonctionne même si un rôle contient des permissions pour plusieurs modules !**
   
   Le système utilise `PermissionRegistry` pour vérifier si un rôle a **au moins une permission** du module gaz. Un rôle multi-module (ex: Super Admin avec permissions gaz + eau_minerale) sera correctement détecté car il a au moins une permission gaz.
   
   **Exemple :**
   ```dart
   // Rôle "Super Admin" avec permissions pour plusieurs modules
   final superAdminRole = UserRole(
     id: 'super_admin',
     permissions: {
       'view_dashboard',      // gaz
       'create_sale',         // gaz
       'view_production',     // eau_minerale
     },
   );
   
   // Ce rôle sera détecté pour le module gaz car il a au moins une permission gaz
   // Même s'il a aussi des permissions eau_minerale
   ```
   
   La fonction `_getDefaultRoleForGazModule` utilise la même logique que `_filterRolesForModule` dans `assign_enterprise_dialog_v2`, garantissant la cohérence avec l'UI d'administration.

3. **Permissions par défaut ?**
   - Quelles permissions spécifiques au point de vente ?
   - Faut-il des permissions personnalisées (`customPermissions`) ?

4. **Migration des données existantes ?**
   - Comment convertir les PointOfSale existants ?
   - Faut-il créer des Enterprise pour eux ?
   - Comment gérer les utilisateurs existants qui utilisent ces points de vente ?

5. **Relation avec l'entreprise principale ?**
   - Les données du point de vente sont-elles visibles depuis l'entreprise principale ?
   - Ou complètement isolées ?
   - Faut-il un mécanisme de "vue consolidée" pour l'entreprise principale ?

6. **Accès aux Points de Vente depuis l'Entreprise Mère ⚠️ IMPORTANT**
   
   **Question :** Les points de vente doivent-ils rester accessibles depuis les sections du module gaz de l'entreprise mère (gaz_1) ?
   
   **Réponse : OUI, c'est essentiel et cela fonctionne automatiquement !** 
   
   Les points de vente restent accessibles depuis l'entreprise mère grâce à `parentEnterpriseId`. Les sections du module gaz continuent de fonctionner normalement :
   - ✅ Voir les stocks par point de vente (Stock Screen)
   - ✅ Gérer les points de vente dans les paramètres (Settings Screen)
   - ✅ Consulter les performances par point de vente dans le dashboard
   - ✅ Créer des ventes pour un point de vente spécifique
   - ✅ Voir tous les points de vente dans les listes
   
   **Comment ça fonctionne :**
   
   Le repository stocke les PointOfSale avec `enterpriseId = parentEnterpriseId` dans Drift. Quand les sections du module gaz appellent `getAllForEnterprise('gaz_1')`, elles récupèrent tous les points de vente qui ont `parentEnterpriseId == 'gaz_1'`.
   
   **Aucun changement nécessaire dans les écrans existants !** Ils continuent d'utiliser `enterpriseId` qui correspond maintenant à `parentEnterpriseId`.
   
   **Solution :** Le `PointOfSale` garde une référence à `parentEnterpriseId` :
   ```dart
   class PointOfSale {
     final String id; // Même ID que l'Enterprise
     final String name;
     final String parentEnterpriseId; // ← Entreprise mère (gaz_1)
     final String moduleId;
     // ...
   }
   ```
   
   **Dans les sections du module gaz :**
   - Les providers utilisent `enterpriseId` de l'entreprise active (gaz_1)
   - Les points de vente sont filtrés par `parentEnterpriseId == enterpriseId`
   - Les utilisateurs avec accès à l'entreprise mère peuvent voir/gérer les points de vente
   - Les utilisateurs avec accès uniquement au point de vente voient uniquement leurs données
   
   **Exemple actuel :**
   ```dart
   // Dans stock_screen.dart
   final pointsOfSaleAsync = ref.watch(
     pointsOfSaleProvider((
       enterpriseId: 'gaz_1', // Entreprise mère
       moduleId: 'gaz',
     )),
   );
   // → Récupère tous les PointOfSale avec parentEnterpriseId == 'gaz_1'
   ```
   
   **Cela fonctionne car :**
   - Le repository filtre par `enterpriseId` qui correspond à `parentEnterpriseId` du PointOfSale
   - Les sections du module gaz utilisent l'entreprise active (gaz_1)
   - Les points de vente apparaissent comme des "sous-entités" de l'entreprise mère

6. **Attribution d'utilisateurs depuis l'administration ✅**
   - **Réponse : OUI, c'est automatique !**
   - Une fois l'Enterprise créée pour le PointOfSale, elle apparaît dans la liste des entreprises
   - L'administrateur peut attribuer des utilisateurs via `AssignEnterpriseDialog`
   - Support pour attribution multiple d'utilisateurs avec différents rôles
   - Pas besoin de code supplémentaire, tout fonctionne avec l'infrastructure existante

---

## Prochaines Étapes

1. **Valider la proposition** avec l'équipe
2. **Définir les permissions** spécifiques aux points de vente
3. **Créer le service** `PointOfSaleService`
4. **Implémenter la création** automatique d'Enterprise
5. **Tester** avec un point de vente de test
6. **Migrer** les données existantes si nécessaire
