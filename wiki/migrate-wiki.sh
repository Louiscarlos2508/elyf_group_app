#!/bin/bash

# Script pour migrer le wiki local vers GitHub Wiki
# URL du wiki: https://github.com/Louiscarlos2508/elyf_group_app.wiki.git

set -e

GITHUB_USER="Louiscarlos2508"
REPO_NAME="elyf_group_app"
WIKI_REPO="${REPO_NAME}.wiki"
WIKI_URL="https://github.com/${GITHUB_USER}/${WIKI_REPO}.git"
CURRENT_DIR=$(pwd)

# Détecter si on est dans le dossier wiki ou à la racine
if [ -d "wiki" ]; then
    # On est à la racine du projet
    WIKI_DIR="${CURRENT_DIR}/wiki"
    OUTPUT_DIR="${CURRENT_DIR}"
elif [ -f "README.md" ] && [ -d "01-getting-started" ]; then
    # On est dans le dossier wiki
    WIKI_DIR="${CURRENT_DIR}"
    OUTPUT_DIR="$(dirname "$CURRENT_DIR")"
else
    echo "❌ Erreur: Impossible de détecter la structure du projet"
    echo "   Exécutez ce script depuis:"
    echo "   - La racine du projet, OU"
    echo "   - Le dossier wiki/"
    exit 1
fi

echo "🚀 Migration du wiki vers GitHub Wiki"
echo "Repository: ${WIKI_URL}"
echo "Dossier wiki: ${WIKI_DIR}"
echo ""

# Vérifier que le dossier wiki existe et contient les fichiers
if [ ! -d "$WIKI_DIR" ] || [ ! -d "${WIKI_DIR}/01-getting-started" ]; then
    echo "❌ Erreur: Le dossier wiki/ ou sa structure n'existe pas"
    echo "   Dossier attendu: ${WIKI_DIR}"
    exit 1
fi

# Cloner ou mettre à jour le wiki
if [ -d "${OUTPUT_DIR}/${WIKI_REPO}" ]; then
    echo "📂 Mise à jour du repository wiki existant..."
    cd "${OUTPUT_DIR}/${WIKI_REPO}"
    git pull origin master || git pull origin main
    cd "$OUTPUT_DIR"
else
    echo "📥 Clonage du repository wiki..."
    cd "$OUTPUT_DIR"
    git clone "$WIKI_URL" "$WIKI_REPO"
fi

# Vérifier que le clone a réussi
if [ ! -d "${OUTPUT_DIR}/${WIKI_REPO}" ]; then
    echo "❌ Erreur: Impossible de cloner le repository wiki"
    echo "   Vérifiez que le wiki est activé sur GitHub:"
    echo "   https://github.com/${GITHUB_USER}/${REPO_NAME}/settings"
    exit 1
fi

WIKI_REPO_PATH="${OUTPUT_DIR}/${WIKI_REPO}"

# Créer la page d'accueil
echo "📝 Création de la page d'accueil..."
cp "${WIKI_DIR}/README.md" "${WIKI_REPO_PATH}/Home.md"

# Créer les pages principales en combinant le contenu
echo "📄 Création des pages principales..."

# Getting Started
echo "  → Getting-Started.md"
cat > "${WIKI_REPO_PATH}/Getting-Started.md" << 'EOF'
# Getting Started

EOF
echo "## Installation" >> "${WIKI_REPO_PATH}/Getting-Started.md"
echo "" >> "${WIKI_REPO_PATH}/Getting-Started.md"
cat "${WIKI_DIR}/01-getting-started/installation.md" >> "${WIKI_REPO_PATH}/Getting-Started.md"
echo "" >> "${WIKI_REPO_PATH}/Getting-Started.md"
echo "---" >> "${WIKI_REPO_PATH}/Getting-Started.md"
echo "" >> "${WIKI_REPO_PATH}/Getting-Started.md"
echo "## Premiers pas" >> "${WIKI_REPO_PATH}/Getting-Started.md"
echo "" >> "${WIKI_REPO_PATH}/Getting-Started.md"
cat "${WIKI_DIR}/01-getting-started/first-steps.md" >> "${WIKI_REPO_PATH}/Getting-Started.md"

# Configuration
echo "  → Configuration.md"
cat > "${WIKI_REPO_PATH}/Configuration.md" << 'EOF'
# Configuration

EOF
echo "## Firebase" >> "${WIKI_REPO_PATH}/Configuration.md"
echo "" >> "${WIKI_REPO_PATH}/Configuration.md"
cat "${WIKI_DIR}/02-configuration/firebase.md" >> "${WIKI_REPO_PATH}/Configuration.md"
echo "" >> "${WIKI_REPO_PATH}/Configuration.md"
echo "---" >> "${WIKI_REPO_PATH}/Configuration.md"
echo "" >> "${WIKI_REPO_PATH}/Configuration.md"
echo "## Environnement de développement" >> "${WIKI_REPO_PATH}/Configuration.md"
echo "" >> "${WIKI_REPO_PATH}/Configuration.md"
cat "${WIKI_DIR}/02-configuration/dev-environment.md" >> "${WIKI_REPO_PATH}/Configuration.md"

# Architecture
echo "  → Architecture.md"
cat > "${WIKI_REPO_PATH}/Architecture.md" << 'EOF'
# Architecture

EOF
cat "${WIKI_DIR}/03-architecture/overview.md" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "---" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "## State Management" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
cat "${WIKI_DIR}/03-architecture/state-management.md" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "---" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "## Navigation" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
cat "${WIKI_DIR}/03-architecture/navigation.md" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "---" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "## Multi-tenant" >> "${WIKI_REPO_PATH}/Architecture.md"
echo "" >> "${WIKI_REPO_PATH}/Architecture.md"
cat "${WIKI_DIR}/03-architecture/multi-tenant.md" >> "${WIKI_REPO_PATH}/Architecture.md"

# Development
echo "  → Development.md"
cat > "${WIKI_REPO_PATH}/Development.md" << 'EOF'
# Development

EOF
cat "${WIKI_DIR}/04-development/guidelines.md" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
echo "---" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
echo "## Structure des modules" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
cat "${WIKI_DIR}/04-development/module-structure.md" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
echo "---" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
echo "## Widgets réutilisables" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
cat "${WIKI_DIR}/04-development/reusable-widgets.md" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
echo "---" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
echo "## Tests" >> "${WIKI_REPO_PATH}/Development.md"
echo "" >> "${WIKI_REPO_PATH}/Development.md"
cat "${WIKI_DIR}/04-development/testing.md" >> "${WIKI_REPO_PATH}/Development.md"

# Modules
echo "  → Modules.md"
cat > "${WIKI_REPO_PATH}/Modules.md" << 'EOF'
# Modules

EOF
cat "${WIKI_DIR}/05-modules/overview.md" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "---" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "## Administration" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
cat "${WIKI_DIR}/05-modules/administration.md" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "---" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "## Eau Minérale" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
cat "${WIKI_DIR}/05-modules/eau-minerale.md" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "---" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "## Gaz" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
cat "${WIKI_DIR}/05-modules/gaz.md" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "---" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "## Orange Money" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
cat "${WIKI_DIR}/05-modules/orange-money.md" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "---" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "## Immobilier" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
cat "${WIKI_DIR}/05-modules/immobilier.md" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "---" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
echo "## Boutique" >> "${WIKI_REPO_PATH}/Modules.md"
echo "" >> "${WIKI_REPO_PATH}/Modules.md"
cat "${WIKI_DIR}/05-modules/boutique.md" >> "${WIKI_REPO_PATH}/Modules.md"

# Permissions
echo "  → Permissions.md"
cat > "${WIKI_REPO_PATH}/Permissions.md" << 'EOF'
# Permissions

EOF
cat "${WIKI_DIR}/06-permissions/overview.md" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "---" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "## Rôles par défaut" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "" >> "${WIKI_REPO_PATH}/Permissions.md"
cat "${WIKI_DIR}/06-permissions/default-roles.md" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "---" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "## Intégration" >> "${WIKI_REPO_PATH}/Permissions.md"
echo "" >> "${WIKI_REPO_PATH}/Permissions.md"
cat "${WIKI_DIR}/06-permissions/integration.md" >> "${WIKI_REPO_PATH}/Permissions.md"

# Offline
echo "  → Offline.md"
cat > "${WIKI_REPO_PATH}/Offline.md" << 'EOF'
# Offline

EOF
cat "${WIKI_DIR}/07-offline/synchronization.md" >> "${WIKI_REPO_PATH}/Offline.md"
echo "" >> "${WIKI_REPO_PATH}/Offline.md"
echo "---" >> "${WIKI_REPO_PATH}/Offline.md"
echo "" >> "${WIKI_REPO_PATH}/Offline.md"
echo "## Isar Database" >> "${WIKI_REPO_PATH}/Offline.md"
echo "" >> "${WIKI_REPO_PATH}/Offline.md"
cat "${WIKI_DIR}/07-offline/isar-database.md" >> "${WIKI_REPO_PATH}/Offline.md"
echo "" >> "${WIKI_REPO_PATH}/Offline.md"
echo "---" >> "${WIKI_REPO_PATH}/Offline.md"
echo "" >> "${WIKI_REPO_PATH}/Offline.md"
echo "## Gestion des conflits" >> "${WIKI_REPO_PATH}/Offline.md"
echo "" >> "${WIKI_REPO_PATH}/Offline.md"
cat "${WIKI_DIR}/07-offline/conflict-resolution.md" >> "${WIKI_REPO_PATH}/Offline.md"

# Printing
echo "  → Printing.md"
cat > "${WIKI_REPO_PATH}/Printing.md" << 'EOF'
# Printing

EOF
cat "${WIKI_DIR}/08-printing/sunmi-integration.md" >> "${WIKI_REPO_PATH}/Printing.md"
echo "" >> "${WIKI_REPO_PATH}/Printing.md"
echo "---" >> "${WIKI_REPO_PATH}/Printing.md"
echo "" >> "${WIKI_REPO_PATH}/Printing.md"
echo "## Templates" >> "${WIKI_REPO_PATH}/Printing.md"
echo "" >> "${WIKI_REPO_PATH}/Printing.md"
cat "${WIKI_DIR}/08-printing/templates.md" >> "${WIKI_REPO_PATH}/Printing.md"
echo "" >> "${WIKI_REPO_PATH}/Printing.md"
echo "---" >> "${WIKI_REPO_PATH}/Printing.md"
echo "" >> "${WIKI_REPO_PATH}/Printing.md"
echo "## Dépannage" >> "${WIKI_REPO_PATH}/Printing.md"
echo "" >> "${WIKI_REPO_PATH}/Printing.md"
cat "${WIKI_DIR}/08-printing/troubleshooting.md" >> "${WIKI_REPO_PATH}/Printing.md"

# Créer le sidebar
echo "📋 Création du menu latéral..."
cat > "${WIKI_REPO_PATH}/_Sidebar.md" << 'EOF'
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
echo "🔗 Adaptation des liens dans Home.md..."
sed -i 's|\./01-getting-started/installation\.md|Getting-Started#installation|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./02-configuration/firebase\.md|Configuration#firebase|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./03-architecture/overview\.md|Architecture|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./04-development/guidelines\.md|Development|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./05-modules/overview\.md|Modules|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./06-permissions/overview\.md|Permissions|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./07-offline/synchronization\.md|Offline|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\./08-printing/sunmi-integration\.md|Printing|g' "${WIKI_REPO_PATH}/Home.md"
sed -i 's|\[Wiki\]\(\./wiki/\)|Wiki|g' "${WIKI_REPO_PATH}/Home.md"

# Commiter et pousser
cd "$WIKI_REPO_PATH"
echo ""
echo "💾 Fichiers préparés dans: ${WIKI_REPO_PATH}/"
echo ""
echo "📤 Voulez-vous commiter et pousser maintenant? (y/n)"
read -r response
if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    echo "📝 Ajout des fichiers..."
    git add .
    
    echo "💬 Création du commit..."
    git commit -m "Add complete wiki documentation" || echo "⚠️  Aucun changement à commiter (peut-être déjà à jour)"
    
    echo "🚀 Push vers GitHub..."
    git push origin master || git push origin main
    
    echo ""
    echo "✅ Wiki migré avec succès!"
    echo "🌐 Accédez au wiki sur: https://github.com/${GITHUB_USER}/${REPO_NAME}/wiki"
else
    echo ""
    echo "📝 Fichiers préparés. Vous pouvez les commiter manuellement:"
    echo ""
    echo "   cd ${WIKI_REPO_PATH}"
    echo "   git add ."
    echo "   git commit -m 'Add wiki documentation'"
    echo "   git push origin master"
    echo ""
    echo "🌐 Ensuite, accédez au wiki sur: https://github.com/${GITHUB_USER}/${REPO_NAME}/wiki"
fi

cd "$CURRENT_DIR"
echo ""
echo "✨ Terminé!"
