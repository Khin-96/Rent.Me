$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot 'tenant_app')
try {
  flutter run -d chrome --no-web-resources-cdn --web-port 8081
} finally {
  Pop-Location
}
