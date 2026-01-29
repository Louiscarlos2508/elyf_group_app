# Service de Vérification d'Intégrité des Stocks

## 🎯 À quoi ça sert ?

Le service de vérification d'intégrité des stocks (`StockIntegrityService`) est un outil de **diagnostic et de réparation** qui garantit la cohérence des données de stock dans votre application.

### Fonctions principales :

1. **Vérification** : Compare les quantités stockées avec la somme calculée à partir de tous les mouvements
2. **Détection** : Identifie les incohérences (corruptions de données, erreurs de calcul)
3. **Réparation** : Recalcule automatiquement les quantités à partir des mouvements (source de vérité)

## 🔍 Comment ça fonctionne ?

### Principe de base

```
Quantité stockée = Quantité calculée à partir des mouvements
```

Le service :
1. Récupère tous les mouvements (entrées, sorties, ajustements) pour chaque stock
2. Calcule la quantité théorique : `Somme(entrées) - Somme(sorties) - Somme(ajustements)`
3. Compare avec la quantité stockée actuellement
4. Signale toute différence comme une incohérence

### Exemple

**Stock de bobines "Type A"** :
- Quantité stockée : 150
- Mouvements :
  - Entrée : +200
  - Sortie : -30
  - Ajustement : -20
- Quantité calculée : 200 - 30 - 20 = **150** ✅
- **Résultat** : Stock valide

**Stock d'emballages "Sachet 500ml"** :
- Quantité stockée : 1000
- Mouvements :
  - Entrée : +1500
  - Sortie : -400
  - Ajustement : -50
- Quantité calculée : 1500 - 400 - 50 = **1050** ❌
- **Résultat** : Incohérence détectée (différence de 50)

## 🔒 Sécurité

### ✅ **C'est sécurisé** pour plusieurs raisons :

#### 1. **Lecture seule pour la vérification**
- La vérification ne modifie **aucune donnée**
- Elle lit uniquement les stocks et mouvements
- Aucun risque de corruption lors de la vérification

#### 2. **Source de vérité : Les mouvements**
- Les **mouvements ne sont jamais modifiés ou supprimés**
- Les mouvements sont la source de vérité absolue
- La réparation recalcule uniquement les quantités stockées à partir des mouvements

#### 3. **Réparation contrôlée**
- La réparation modifie **uniquement** la quantité stockée
- Elle utilise la formule : `Quantité stockée = Somme calculée des mouvements`
- Les mouvements restent intacts

#### 4. **Traçabilité complète**
- Toutes les actions sont loggées (`AppLogger`)
- Les erreurs sont capturées et signalées
- Impossible de perdre des données sans trace

#### 5. **Gestion d'erreurs robuste**
- Si une réparation échoue, les autres continuent
- Les erreurs sont signalées sans bloquer le processus
- Aucune donnée n'est perdue en cas d'erreur

### ⚠️ **Ce qui est modifié lors de la réparation**

**AVANT réparation** :
```dart
Stock {
  id: "packaging-sachet-500ml",
  quantity: 1000,  // ❌ Incohérent
  updatedAt: "2025-01-20"
}
```

**APRÈS réparation** :
```dart
Stock {
  id: "packaging-sachet-500ml",
  quantity: 1050,  // ✅ Corrigé (recalculé depuis les mouvements)
  updatedAt: "2025-01-26"  // Mis à jour
}
```

**Les mouvements ne changent JAMAIS** :
```dart
// Mouvements restent identiques (source de vérité)
[
  { type: "entree", quantite: 1500, date: "2025-01-15" },
  { type: "sortie", quantite: 400, date: "2025-01-18" },
  { type: "ajustement", quantite: 50, date: "2025-01-20" }
]
```

## 🛡️ Protection des données

### Ce qui est protégé :
- ✅ **Mouvements** : Jamais modifiés (source de vérité)
- ✅ **Historique** : Tous les mouvements restent intacts
- ✅ **Audit** : Traçabilité complète via les logs
- ✅ **Synchronisation** : Les mouvements sont synchronisés avec Firestore

### Ce qui peut être corrigé :
- ⚠️ **Quantités stockées** : Recalculées si incohérentes
- ⚠️ **Date de mise à jour** : Mise à jour lors de la réparation

## 📊 Cas d'utilisation

### Quand utiliser la vérification d'intégrité ?

1. **Après une synchronisation** : Vérifier que les données sont cohérentes
2. **Après une erreur** : Détecter les corruptions potentielles
3. **Maintenance périodique** : Vérification préventive
4. **Avant un rapport important** : S'assurer de la cohérence des données

### Quand utiliser la réparation ?

- ✅ **Uniquement si des incohérences sont détectées**
- ✅ **Après avoir vérifié que les mouvements sont corrects**
- ✅ **Pour corriger des erreurs de calcul automatiques**

## 🔄 Processus de réparation

```
1. Vérification → Détection des incohérences
2. Affichage des résultats → Utilisateur voit les problèmes
3. Réparation (optionnelle) → Utilisateur décide de réparer
4. Recalcul → Quantités recalculées depuis les mouvements
5. Sauvegarde → Nouvelles quantités sauvegardées
6. Re-vérification → Confirmation que tout est corrigé
```

## ⚡ Avantages

1. **Détection précoce** : Identifie les problèmes avant qu'ils ne s'aggravent
2. **Correction automatique** : Répare les incohérences sans intervention manuelle
3. **Confiance** : Garantit la cohérence des données
4. **Traçabilité** : Logs complets pour audit
5. **Non-destructif** : Ne supprime jamais de données, seulement recalcule

## 🚫 Limitations

- Ne peut pas corriger les mouvements incorrects (ils sont la source de vérité)
- Ne peut pas récupérer des mouvements supprimés
- Nécessite que les mouvements soient corrects pour fonctionner

## 📝 Conclusion

Le service de vérification d'intégrité est **sécurisé et recommandé** car :
- ✅ Il ne modifie jamais les mouvements (source de vérité)
- ✅ Il ne supprime aucune donnée
- ✅ Il corrige uniquement les quantités stockées incohérentes
- ✅ Il fournit une traçabilité complète
- ✅ Il protège contre les corruptions de données

**Recommandation** : Utilisez-le régulièrement pour maintenir la cohérence de vos données de stock.
