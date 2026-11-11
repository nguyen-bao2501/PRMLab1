$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if (-not (Test-Path -LiteralPath 'google-oauth.local.json')) {
        throw 'Missing google-oauth.local.json. Configure the Desktop OAuth client first.'
    }
    & flutter run -d windows --dart-define-from-file=google-oauth.local.json
    if ($LASTEXITCODE -ne 0) { throw 'Flutter failed to start.' }
} finally {
    Pop-Location
}
