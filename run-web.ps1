$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot

$desktopClientId = "1008762251643-8b5aisjte501r1lf32dndefijmntrnmg.apps.googleusercontent.com"
$desktopClientSecret = "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"

if (Test-Path 'google-oauth.local.json') {
    try {
        $oauthCfg = Get-Content -Raw -LiteralPath 'google-oauth.local.json' | ConvertFrom-Json
        if ($oauthCfg.GOOGLE_DESKTOP_CLIENT_ID) { $desktopClientId = $oauthCfg.GOOGLE_DESKTOP_CLIENT_ID }
        if ($oauthCfg.GOOGLE_DESKTOP_CLIENT_SECRET) { $desktopClientSecret = $oauthCfg.GOOGLE_DESKTOP_CLIENT_SECRET }
    } catch {}
}

try {
    & flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080 "--dart-define=GOOGLE_DESKTOP_CLIENT_ID=$desktopClientId" "--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=$desktopClientSecret"
    if ($LASTEXITCODE -ne 0) { throw 'Flutter failed to start.' }
} finally {
    Pop-Location
}
