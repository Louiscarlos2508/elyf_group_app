# Plan de Nettoyage de la Documentation

## 🎯 Objectif
Réduire de 104 à ~70 fichiers .md en supprimant les doublons et réorganisant la documentation.

## ✅ Actions à effectuer

### 1. Supprimer les doublons (35 fichiers)
**Dossier : `elyf_group_app.wiki/`**
- Ce dossier contient des doublons du wiki organisé dans `wiki/`
- **Action : SUPPRIMER tout le dossier `elyf_group_app.wiki/`**

### 2. Déplacer les fichiers de la racine (2 fichiers)
- `FORMULAIRES_AVEC_CHAMPS_DYNAMIQUES.md` → `wiki/04-development/formulaires-dynamiques.md`
- `MODULES_OVERVIEW.md` → Fusionner avec `wiki/05-modules/overview.md` ou créer `wiki/05-modules/detailed-overview.md`

### 3. Déplacer la documentation technique (1 fichier)
- `lib/core/tenant/GESTION_MULTI_ENTREPRISES.md` → Fusionner avec `wiki/03-architecture/multi-tenant.md`

### 4. Conserver (à ne pas toucher)
- ✅ Tous les `README.md` dans `lib/` (documentation locale des modules)
- ✅ Documentation technique dans `lib/core/` et `lib/features/` (guides d'intégration, etc.)
- ✅ `wiki/` (structure organisée)
- ✅ `README.md` à la racine

## 📊 Résultat attendu

**Avant :** 104 fichiers .md
**Après :** ~70 fichiers .md

**Structure finale :**
```
elyf_group_app/
├── README.md (racine)
├── DOCUMENTATION_AUDIT.md (ce rapport)
├── wiki/ (28 fichiers organisés)
│   ├── 01-getting-started/
│   ├── 02-configuration/
│   ├── 03-architecture/
│   ├── 04-development/
│   ├── 05-modules/
│   ├── 06-permissions/
│   ├── 07-offline/
│   └── 08-printing/
└── lib/
    ├── core/*/README.md (documentation locale)
    ├── features/*/README.md (documentation locale)
    └── core/*/*.md (documentation technique spécifique)
```

## ⚠️ Vérifications avant suppression

Avant de supprimer `elyf_group_app.wiki/`, vérifier que :
1. Tout le contenu important est dans `wiki/`
2. Les liens dans le code pointent vers `wiki/` et non `elyf_group_app.wiki/`
3. Aucune référence dans le code vers `elyf_group_app.wiki/`

## 🚀 Commandes pour le nettoyage

```bash
# 1. Vérifier les références
grep -r "elyf_group_app.wiki" lib/ --include="*.dart" --include="*.md"

# 2. Supprimer les doublons (après vérification)
rm -rf elyf_group_app.wiki/

# 3. Déplacer les fichiers
mv FORMULAIRES_AVEC_CHAMPS_DYNAMIQUES.md wiki/04-development/formulaires-dynamiques.md
# Pour MODULES_OVERVIEW.md, décider si fusion ou nouveau fichier
```

## 📝 Notes

- Les fichiers README.md dans `lib/` sont **nécessaires** et conformes aux règles
- La documentation technique (INTEGRATION_GUIDE, etc.) doit être **conservée**
- Le wiki organisé dans `wiki/` est la **source de vérité** principale

