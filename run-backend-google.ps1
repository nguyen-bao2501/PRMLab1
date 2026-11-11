param([string]$PublicBaseUrl, [string]$WebClientId)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $oauth = Get-Content -Raw -LiteralPath 'google-oauth.local.json' | ConvertFrom-Json
    if (-not $oauth.GOOGLE_DESKTOP_CLIENT_ID) {
        throw 'Missing Desktop OAuth Client ID.'
    }
    $env:GOOGLE_CLIENT_ID = $oauth.GOOGLE_DESKTOP_CLIENT_ID
    if ($PublicBaseUrl) { $env:ATTENDANCE_PUBLIC_BASE_URL = $PublicBaseUrl.TrimEnd('/') }
    if ($WebClientId) { 
        $env:GOOGLE_WEB_CLIENT_ID = $WebClientId 
    } elseif ($oauth.GOOGLE_WEB_CLIENT_ID) {
        $env:GOOGLE_WEB_CLIENT_ID = $oauth.GOOGLE_WEB_CLIENT_ID
    }
    & .\mvnw.cmd spring-boot:run
    if ($LASTEXITCODE -ne 0) { throw 'Backend failed to start.' }
} finally {
    Pop-Location
}
