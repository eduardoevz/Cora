# Compilación local de paquetes de lanzamiento para Cora Mobile
param(
    [switch]$BuildApk = $true,
    [switch]$BuildAab = $true
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando compilación de lanzamiento de Cora Mobile..." -ForegroundColor Cyan

Set-Location $PSScriptRoot\..

Write-Host "📦 1. Resolviendo dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host "🔍 2. Verificando análisis estático..." -ForegroundColor Yellow
flutter analyze --fatal-infos

Write-Host "🧪 3. Ejecutando suite de pruebas..." -ForegroundColor Yellow
flutter test

if ($BuildAab) {
    Write-Host "📱 4. Compilando Android App Bundle (.aab) para Google Play..." -ForegroundColor Green
    flutter build appbundle --release --no-tree-shake-icons
    Write-Host "✅ AAB generado en: mobile/build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
}

if ($BuildApk) {
    Write-Host "📱 5. Compilando APK universal release..." -ForegroundColor Green
    flutter build apk --release --no-tree-shake-icons
    Write-Host "✅ APK generado en: mobile/build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
}

Write-Host "🎉 Compilación de paquetes de lanzamiento finalizada con éxito!" -ForegroundColor Cyan
