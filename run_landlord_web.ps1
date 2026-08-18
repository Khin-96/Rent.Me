$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot 'landlord_app')
try {
  flutter run -d chrome --no-web-resources-cdn --web-port 8082
} finally {
  Pop-Location
}
