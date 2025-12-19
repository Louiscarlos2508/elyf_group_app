# Guide : Ajouter le wiki au wiki GitHub

Ce guide explique comment migrer le wiki local vers le wiki GitHub.

## 📋 Prérequis

1. Un repository GitHub pour le projet
2. Accès en écriture au repository
3. Git installé sur votre machine

## 🔧 Méthode 1 : Via l'interface GitHub (Recommandé)

### Étape 1 : Activer le wiki GitHub

1. Allez sur votre repository GitHub
2. Cliquez sur **Settings** (Paramètres)
3. Dans la section **Features**, cochez **Wikis**
4. Cliquez sur **Save**

### Étape 2 : Cloner le wiki

Le wiki GitHub est un repository Git séparé. Clonez-le :

```bash
# Remplacez USERNAME et REPO par vos valeurs
git clone https://github.com/USERNAME/REPO.wiki.git
cd REPO.wiki
```

### Étape 3 : Copier les fichiers

Copiez tous les fichiers markdown du dossier `wiki/` vers le repository wiki :

```bash
# Depuis la racine du projet
cp -r wiki/* ../REPO.wiki/
cd ../REPO.wiki
```

### Étape 4 : Créer la page d'accueil

Le wiki GitHub nécessite une page `Home.md` comme page d'accueil :

```bash
# Créer Home.md à partir de wiki/README.md
cp wiki/README.md Home.md
```

### Étape 5 : Adapter les liens

Les liens internes doivent être adaptés pour GitHub. Utilisez le script fourni (voir ci-dessous).

### Étape 6 : Commiter et pousser

```bash
git add .
git commit -m "Add wiki documentation"
git push origin master
```

## 🔧 Méthode 2 : Script automatique

Un script est fourni pour automatiser la migration (voir `migrate-to-github-wiki.sh`).

## 📝 Structure GitHub Wiki

GitHub Wiki attend une structure spécifique :

```
REPO.wiki/
├── Home.md                    # Page d'accueil (obligatoire)
├── Getting-Started.md          # Pages principales
├── Configuration.md
├── Architecture.md
├── Development.md
├── Modules.md
└── _Sidebar.md                # Menu latéral (optionnel)
```

## 🔗 Adaptation des liens

### Liens internes

Les liens doivent être adaptés :

**Avant (wiki local) :**
```markdown
[Installation](./01-getting-started/installation.md)
```

**Après (GitHub Wiki) :**
```markdown
[Installation](Getting-Started#installation)
```

### Structure recommandée

Pour GitHub Wiki, il est recommandé de :
1. Créer une page par section principale
2. Utiliser des ancres pour les sous-sections
3. Créer un fichier `_Sidebar.md` pour la navigation

## 📄 Fichier _Sidebar.md

Créez un fichier `_Sidebar.md` pour le menu latéral :

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

## ⚠️ Notes importantes

1. **Page d'accueil** : Doit s'appeler `Home.md`
2. **Noms de fichiers** : Utilisez des noms simples sans espaces (GitHub les convertit automatiquement)
3. **Liens** : Utilisez des noms de pages, pas des chemins de fichiers
4. **Images** : Placez-les dans le repository principal et référencez-les avec le chemin complet

## 🚀 Alternative : GitHub Pages

Si vous préférez garder la structure actuelle, vous pouvez utiliser GitHub Pages :

1. Créez une branche `gh-pages`
2. Placez le dossier `wiki/` dans `docs/`
3. Activez GitHub Pages dans les settings
4. Sélectionnez la source `docs/`

L'avantage : vous gardez la structure de dossiers actuelle.

## 📚 Ressources

- [Documentation GitHub Wiki](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [GitHub Pages](https://docs.github.com/en/pages)
