#!/bin/bash

# Script pour exécuter tous les tests Flutter
# Usage: ./scripts/run_all_tests.sh

set -e

echo "🧪 Exécution de tous les tests Flutter..."

# Exécuter tous les tests
flutter test

echo "✅ Tous les tests sont terminés"