# 🚀 Migration rapide vers GitHub Wiki

## URL du wiki GitHub
`https://github.com/Louiscarlos2508/elyf_group_app.wiki.git`

## Étapes rapides

### 1. Activer le wiki sur GitHub

1. Allez sur : https://github.com/Louiscarlos2508/elyf_group_app/settings
2. Dans la section **Features**, cochez **Wikis**
3. Cliquez sur **Save**

### 2. Exécuter le script

Depuis la racine du projet :

```bash
cd wiki
./migrate-wiki.sh
```

Le script va :
- ✅ Cloner le repository wiki GitHub
- ✅ Convertir toutes les pages
- ✅ Créer Home.md et _Sidebar.md
- ✅ Adapter les liens
- ✅ Vous proposer de commiter et pousser

### 3. Vérifier le résultat

Une fois poussé, accédez au wiki :
https://github.com/Louiscarlos2508/elyf_group_app/wiki

## Structure créée

Le script crée ces pages :

- **Home.md** - Page d'accueil
- **Getting-Started.md** - Installation et premiers pas
- **Configuration.md** - Firebase et environnement
- **Architecture.md** - Vue d'ensemble, State Management, Navigation, Multi-tenant
- **Development.md** - Guidelines, structure, widgets, tests
- **Modules.md** - Vue d'ensemble et tous les modules
- **Permissions.md** - Système de permissions
- **Offline.md** - Synchronisation et Isar
- **Printing.md** - Intégration Sunmi
- **_Sidebar.md** - Menu de navigation

## Notes

- Le script combine les sous-sections en pages principales
- Les liens sont automatiquement adaptés
- Si le wiki existe déjà, il sera mis à jour
- Vous pouvez exécuter le script plusieurs fois en toute sécurité

## Problèmes ?

Si le script échoue :

1. Vérifiez que le wiki est activé sur GitHub
2. Vérifiez vos permissions d'accès au repository
3. Vérifiez que vous êtes authentifié avec Git
