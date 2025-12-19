#!/bin/bash

# Script pour migrer le wiki local vers GitHub Wiki
# Usage: ./migrate-to-github-wiki.sh GITHUB_USERNAME REPO_NAME

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 GITHUB_USERNAME REPO_NAME"
    echo "Example: $0 myusername elyf_group_app"
    exit 1
fi

GITHUB_USER="$1"
REPO_NAME="$2"
WIKI_REPO="${REPO_NAME}.wiki"
WIKI_URL="https://github.com/${GITHUB_USER}/${WIKI_REPO}.git"
CURRENT_DIR=$(pwd)
WIKI_DIR="${CURRENT_DIR}/wiki"

echo "🚀 Migration du wiki vers GitHub Wiki"
echo "Repository: ${WIKI_URL}"
echo ""

# Vérifier que le dossier wiki existe
if [ ! -d "$WIKI_DIR" ]; then
    echo "❌ Erreur: Le dossier wiki/ n'existe pas"
    exit 1
fi

# Cloner ou mettre à jour le wiki
if [ -d "$WIKI_REPO" ]; then
    echo "📂 Mise à jour du repository wiki existant..."
    cd "$WIKI_REPO"
    git pull origin master
    cd ..
else
    echo "📥 Clonage du repository wiki..."
    git clone "$WIKI_URL" "$WIKI_REPO"
fi

# Créer la page d'accueil
echo "📝 Création de la page d'accueil..."
cp "${WIKI_DIR}/README.md" "${WIKI_REPO}/Home.md"

# Créer les pages principales
echo "📄 Création des pages principales..."

# Getting Started
cat > "${WIKI_REPO}/Getting-Started.md" << 'EOF'
# Getting Started

EOF
cat "${WIKI_DIR}/01-getting-started/installation.md" >> "${WIKI_REPO}/Getting-Started.md"
echo "" >> "${WIKI_REPO}/Getting-Started.md"
echo "---" >> "${WIKI_REPO}/Getting-Started.md"
echo "" >> "${WIKI_REPO}/Getting-Started.md"
cat "${WIKI_DIR}/01-getting-started/first-steps.md" >> "${WIKI_REPO}/Getting-Started.md"

# Configuration
cat > "${WIKI_REPO}/Configuration.md" << 'EOF'
# Configuration

EOF
cat "${WIKI_DIR}/02-configuration/firebase.md" >> "${WIKI_REPO}/Configuration.md"
echo "" >> "${WIKI_REPO}/Configuration.md"
echo "---" >> "${WIKI_REPO}/Configuration.md"
echo "" >> "${WIKI_REPO}/Configuration.md"
cat "${WIKI_DIR}/02-configuration/dev-environment.md" >> "${WIKI_REPO}/Configuration.md"

# Architecture
cat > "${WIKI_REPO}/Architecture.md" << 'EOF'
# Architecture

EOF
cat "${WIKI_DIR}/03-architecture/overview.md" >> "${WIKI_REPO}/Architecture.md"
echo "" >> "${WIKI_REPO}/Architecture.md"
echo "---" >> "${WIKI_REPO}/Architecture.md"
echo "" >> "${WIKI_REPO}/Architecture.md"
cat "${WIKI_DIR}/03-architecture/state-management.md" >> "${WIKI_REPO}/Architecture.md"
echo "" >> "${WIKI_REPO}/Architecture.md"
echo "---" >> "${WIKI_REPO}/Architecture.md"
echo "" >> "${WIKI_REPO}/Architecture.md"
cat "${WIKI_REPO}/03-architecture/navigation.md" >> "${WIKI_REPO}/Architecture.md"
echo "" >> "${WIKI_REPO}/Architecture.md"
echo "---" >> "${WIKI_REPO}/Architecture.md"
echo "" >> "${WIKI_REPO}/Architecture.md"
cat "${WIKI_DIR}/03-architecture/multi-tenant.md" >> "${WIKI_REPO}/Architecture.md"

# Development
cat > "${WIKI_REPO}/Development.md" << 'EOF'
# Development

EOF
cat "${WIKI_DIR}/04-development/guidelines.md" >> "${WIKI_REPO}/Development.md"
echo "" >> "${WIKI_REPO}/Development.md"
echo "---" >> "${WIKI_REPO}/Development.md"
echo "" >> "${WIKI_REPO}/Development.md"
cat "${WIKI_DIR}/04-development/module-structure.md" >> "${WIKI_REPO}/Development.md"

# Modules
cat > "${WIKI_REPO}/Modules.md" << 'EOF'
# Modules

EOF
cat "${WIKI_DIR}/05-modules/overview.md" >> "${WIKI_REPO}/Modules.md"

# Permissions
cat > "${WIKI_REPO}/Permissions.md" << 'EOF'
# Permissions

EOF
cat "${WIKI_DIR}/06-permissions/overview.md" >> "${WIKI_REPO}/Permissions.md"

# Offline
cat > "${WIKI_REPO}/Offline.md" << 'EOF'
# Offline

EOF
cat "${WIKI_DIR}/07-offline/synchronization.md" >> "${WIKI_REPO}/Offline.md"

# Printing
cat > "${WIKI_REPO}/Printing.md" << 'EOF'
# Printing

EOF
cat "${WIKI_DIR}/08-printing/sunmi-integration.md" >> "${WIKI_REPO}/Printing.md"

# Créer le sidebar
echo "📋 Création du menu latéral..."
cat > "${WIKI_REPO}/_Sidebar.md" << 'EOF'
* [Home](Home)
* [Getting Started](Getting-Started)
* [Configuration](Configuration)
* [Architecture](Architecture)
* [Development](Development)
* [Modules](Modules)
* [Permissions](Permissions)
* [Offline](Offline)
* [Printing](Printing)
EOF

# Adapter les liens dans Home.md
echo "🔗 Adaptation des liens..."
sed -i 's|\./01-getting-started/installation\.md|Getting-Started#installation|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./02-configuration/firebase\.md|Configuration#firebase|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./03-architecture/overview\.md|Architecture|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./04-development/guidelines\.md|Development|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./05-modules/overview\.md|Modules|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./06-permissions/overview\.md|Permissions|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./07-offline/synchronization\.md|Offline|g' "${WIKI_REPO}/Home.md"
sed -i 's|\./08-printing/sunmi-integration\.md|Printing|g' "${WIKI_REPO}/Home.md"

# Commiter et pousser
cd "$WIKI_REPO"
echo "💾 Ajout des fichiers..."
git add .

echo "📤 Voulez-vous commiter et pousser maintenant? (y/n)"
read -r response
if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    git commit -m "Add wiki documentation from local wiki folder" || echo "Aucun changement à commiter"
    git push origin master
    echo "✅ Wiki migré avec succès!"
    echo "🌐 Accédez au wiki sur: https://github.com/${GITHUB_USER}/${REPO_NAME}/wiki"
else
    echo "📝 Fichiers préparés. Vous pouvez les commiter manuellement:"
    echo "   cd ${WIKI_REPO}"
    echo "   git add ."
    echo "   git commit -m 'Add wiki documentation'"
    echo "   git push origin master"
fi

cd "$CURRENT_DIR"
echo "✨ Terminé!"
