# Guide rapide : Migration vers GitHub Wiki

## 🚀 Méthode rapide (Script automatique)

1. **Activer le wiki sur GitHub** :
   - Allez sur votre repository GitHub
   - Settings → Features → Cocher "Wikis"
   - Sauvegarder

2. **Exécuter le script** :
   ```bash
   cd wiki
   ./migrate-to-github-wiki.sh VOTRE_USERNAME NOM_DU_REPO
   ```
   
   Exemple :
   ```bash
   ./migrate-to-github-wiki.sh myusername elyf_group_app
   ```

3. **Le script va** :
   - Cloner le repository wiki GitHub
   - Convertir la structure de dossiers en pages
   - Créer la page d'accueil (Home.md)
   - Créer le menu latéral (_Sidebar.md)
   - Adapter les liens
   - Vous proposer de commiter et pousser

## 📝 Méthode manuelle

### Étape 1 : Activer le wiki

1. Repository GitHub → **Settings**
2. Section **Features** → Cocher **Wikis**
3. **Save**

### Étape 2 : Cloner le wiki

```bash
git clone https://github.com/VOTRE_USERNAME/NOM_DU_REPO.wiki.git
cd NOM_DU_REPO.wiki
```

### Étape 3 : Créer les pages

Créez les pages principales en combinant le contenu des sous-dossiers :

- `Home.md` ← `wiki/README.md`
- `Getting-Started.md` ← Contenu de `01-getting-started/`
- `Configuration.md` ← Contenu de `02-configuration/`
- `Architecture.md` ← Contenu de `03-architecture/`
- etc.

### Étape 4 : Créer le menu

Créez `_Sidebar.md` :

```markdown
* [Home](Home)
* [Getting Started](Getting-Started)
* [Configuration](Configuration)
* [Architecture](Architecture)
* [Development](Development)
* [Modules](Modules)
* [Permissions](Permissions)
* [Offline](Offline)
* [Printing](Printing)
```

### Étape 5 : Pousser

```bash
git add .
git commit -m "Add wiki documentation"
git push origin master
```

## ⚠️ Différences importantes

### Structure

**Wiki local (dossiers)** :
```
wiki/
├── 01-getting-started/
│   └── installation.md
```

**GitHub Wiki (pages plates)** :
```
REPO.wiki/
├── Getting-Started.md
```

### Liens

**Avant** :
```markdown
[Installation](./01-getting-started/installation.md)
```

**Après** :
```markdown
[Installation](Getting-Started#installation)
```

## 📚 Documentation complète

Voir [GITHUB_WIKI_SETUP.md](./GITHUB_WIKI_SETUP.md) pour le guide complet.
