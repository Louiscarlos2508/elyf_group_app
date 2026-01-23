#!/bin/bash

# Script pour vérifier le seuil de couverture de tests
# Usage: ./scripts/check_test_coverage.sh [seuil_minimum]
# Par défaut, le seuil est de 15%

set -e

MIN_COVERAGE=${1:-15}

echo "📊 Vérification de la couverture de tests (seuil minimum: ${MIN_COVERAGE}%)..."

# Exécuter les tests avec couverture
flutter test --coverage

# Vérifier si lcov.info existe
if [ ! -f "coverage/lcov.info" ]; then
  echo "❌ Erreur: coverage/lcov.info non trouvé"
  exit 1
fi

# Extraire le pourcentage de couverture depuis lcov.info
# Note: Cette méthode est basique, pour une analyse plus précise,
# utilisez des outils comme lcov ou genhtml
COVERAGE=$(grep -oP '^LF:\K\d+' coverage/lcov.info | head -1 || echo "0")
TOTAL=$(grep -oP '^LH:\K\d+' coverage/lcov.info | head -1 || echo "0")

if [ "$TOTAL" -eq 0 ]; then
  echo "⚠️  Aucune ligne de code couverte trouvée"
  exit 1
fi

PERCENTAGE=$((COVERAGE * 100 / TOTAL))

echo "📈 Couverture actuelle: ${PERCENTAGE}% (${COVERAGE}/${TOTAL} lignes)"

if [ "$PERCENTAGE" -lt "$MIN_COVERAGE" ]; then
  echo "❌ La couverture (${PERCENTAGE}%) est inférieure au seuil minimum (${MIN_COVERAGE}%)"
  exit 1
else
  echo "✅ La couverture (${PERCENTAGE}%) dépasse le seuil minimum (${MIN_COVERAGE}%)"
fi