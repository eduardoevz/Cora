#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Iniciando compilación de lanzamiento de Cora Mobile..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "📦 1. Resolviendo dependencias..."
flutter pub get

echo "🔍 2. Verificando análisis estático..."
flutter analyze --fatal-infos

echo "🧪 3. Ejecutando suite de pruebas..."
flutter test

echo "📱 4. Compilando Android App Bundle (.aab) para Google Play..."
flutter build appbundle --release --no-tree-shake-icons
echo "✅ AAB generado en: mobile/build/app/outputs/bundle/release/app-release.aab"

echo "📱 5. Compilando APK universal release..."
flutter build apk --release --no-tree-shake-icons
echo "✅ APK generado en: mobile/build/app/outputs/flutter-apk/app-release.apk"

echo "🎉 Compilación de paquetes de lanzamiento finalizada con éxito!"
