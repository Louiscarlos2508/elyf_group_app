# Architecture des Mouvements de Stock : Un Document vs Plusieurs Documents

## Question
Vaut-il mieux avoir **un seul document** contenant tous les mouvements ou **un document par mouvement** dans la collection ?

## Réponse : **Un Document par Mouvement** ✅ (Architecture Actuelle)

L'architecture actuelle utilise **un document par mouvement**, ce qui est la **meilleure pratique** pour Firestore et les applications offline-first.

---

## Comparaison Détaillée

### ✅ Option 1 : Un Document par Mouvement (ACTUELLE)

**Structure :**
```
Collection: bobine_stock_movements
├── Document: movement-1234567890
│   ├── id: "movement-1234567890"
│   ├── bobineId: "bobine-standard"
│   ├── type: "entree"
│   ├── quantite: 100
│   ├── date: "2026-01-26T10:00:00Z"
│   └── ...
├── Document: movement-1234567891
│   └── ...
└── Document: movement-1234567892
    └── ...
```

**Avantages :**
1. ✅ **Scalabilité illimitée** : Pas de limite sur le nombre de mouvements
2. ✅ **Performance optimale** : 
   - Requêtes rapides avec indexation Firestore
   - Filtrage par date/type sans charger tous les mouvements
   - Pagination facile
3. ✅ **Synchronisation incrémentale** :
   - Seuls les nouveaux/changés sont synchronisés
   - Moins de données transférées
   - Plus rapide
4. ✅ **Pas de conflits d'écriture** :
   - Chaque mouvement est indépendant
   - Plusieurs utilisateurs peuvent créer des mouvements simultanément
   - Pas de "last write wins" problématique
5. ✅ **Offline-first optimal** :
   - Chaque mouvement peut être créé localement
   - Synchronisation granulaire
   - Moins de risque de corruption
6. ✅ **Respecte la limite Firestore** :
   - Chaque document < 1 MB (limite Firestore)
   - Pas de risque de dépassement

**Inconvénients :**
- ❌ Plus de documents dans la collection (mais c'est normal et géré efficacement)

---

### ❌ Option 2 : Un Seul Document avec Tableau

**Structure :**
```
Collection: bobine_stock_movements
└── Document: all_movements
    ├── movements: [
    │   { id: "movement-1", type: "entree", quantite: 100, ... },
    │   { id: "movement-2", type: "sortie", quantite: 50, ... },
    │   { id: "movement-3", type: "entree", quantite: 200, ... },
    │   ... (potentiellement des milliers)
    │ ]
    └── updatedAt: "2026-01-26T10:00:00Z"
```

**Problèmes Majeurs :**
1. ❌ **Limite de taille Firestore** :
   - Limite : 1 MB par document
   - Avec ~1000 mouvements (chacun ~500 bytes) = 500 KB
   - Risque de dépassement avec l'historique
2. ❌ **Conflits d'écriture fréquents** :
   - Tous les utilisateurs modifient le même document
   - "Last write wins" peut écraser des mouvements
   - Perte de données en cas de synchronisation simultanée
3. ❌ **Performance dégradée** :
   - Doit charger TOUS les mouvements pour un seul nouveau
   - Pas de filtrage efficace
   - Synchronisation complète à chaque changement
4. ❌ **Offline-first problématique** :
   - Conflits lors de la réconciliation
   - Risque de perte de données
   - Synchronisation lourde
5. ❌ **Pas de requêtes efficaces** :
   - Impossible de filtrer par date/type sans charger tout
   - Pas d'indexation Firestore sur les éléments du tableau
   - Pagination impossible

---

## Recommandation : Garder l'Architecture Actuelle ✅

### Pourquoi c'est la meilleure approche :

1. **Conforme aux Best Practices Firestore** :
   - Google recommande des documents individuels pour les entités
   - Collections avec plusieurs documents = architecture standard

2. **Performance** :
   - Requêtes indexées rapides
   - Filtrage efficace (date, type, stockId)
   - Pagination native

3. **Scalabilité** :
   - Supporte des milliers/millions de mouvements
   - Pas de limite pratique

4. **Synchronisation** :
   - Incrémentale (seulement les changements)
   - Pas de conflits entre utilisateurs
   - Offline-first optimal

5. **Intégrité des données** :
   - Chaque mouvement est atomique
   - Pas de risque de corruption du document entier
   - Vérification d'intégrité possible

---

## Exemple de Calcul de Taille

**Un mouvement typique :**
```json
{
  "id": "movement-1234567890",
  "bobineId": "bobine-standard",
  "bobineReference": "Bobine",
  "type": "entree",
  "quantite": 100,
  "date": "2026-01-26T10:00:00Z",
  "raison": "Livraison",
  "notes": "Fournisseur ABC",
  "createdAt": "2026-01-26T10:00:00Z"
}
```
**Taille estimée : ~200-300 bytes**

**Avec un document par mouvement :**
- 10 000 mouvements = 10 000 documents × 300 bytes = 3 MB (répartis)
- ✅ Pas de problème, chaque document < 1 MB

**Avec un seul document :**
- 10 000 mouvements = 1 document × 3 MB = **3 MB**
- ❌ **DÉPASSE la limite Firestore de 1 MB !**

---

## Conclusion

**L'architecture actuelle (un document par mouvement) est la meilleure solution** pour :
- ✅ Performance
- ✅ Scalabilité
- ✅ Synchronisation
- ✅ Intégrité des données
- ✅ Conformité avec les best practices Firestore

**Ne pas changer** vers un seul document avec tableau, cela créerait plus de problèmes qu'il n'en résoudrait.
