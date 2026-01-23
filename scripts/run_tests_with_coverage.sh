#!/bin/bash

# Script pour exécuter les tests avec génération de rapport de couverture
# Usage: ./scripts/run_tests_with_coverage.sh

set -e

echo "🧪 Exécution des tests avec couverture..."

# Créer le dossier coverage s'il n'existe pas
mkdir -p coverage

# Exécuter les tests avec couverture
flutter test --coverage

# Le rapport de couverture sera généré dans coverage/lcov.info
if [ -f "coverage/lcov.info" ]; then
  echo "✅ Rapport de couverture généré: coverage/lcov.info"
  echo "📊 Pour visualiser: genhtml coverage/lcov.info -o coverage/html"
else
  echo "⚠️  Aucun rapport de couverture généré"
fi