$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot

Write-Host "Đang khởi động ngrok để lấy link HTTPS..." -ForegroundColor Cyan
$TunnelJob = Start-Job {
    ngrok http 8080
}

$url = $null
$timeout = 20
$sw = [Diagnostics.Stopwatch]::StartNew()

while ($sw.Elapsed.TotalSeconds -lt $timeout) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        if ($response.tunnels -and $response.tunnels.Count -gt 0) {
            $url = ($response.tunnels | Where-Object { $_.proto -eq 'https' })[0].public_url
            break
        }
    } catch {
        # Đợi ngrok khởi động
    }
    Start-Sleep -Milliseconds 500
}

if (-not $url) {
    Stop-Job -Job $TunnelJob
    Remove-Job -Job $TunnelJob
    Write-Host "Không thể lấy được link HTTPS từ LocalTunnel. Vui lòng kiểm tra lại mạng hoặc Node.js." -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "LINK NGROK/TUNNEL CỦA BẠN LÀ: " -NoNewline
Write-Host $url -ForegroundColor Yellow
Write-Host "Hãy COPY link này và dán vào ô 'Địa chỉ backend' trong App!" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Green

try {
    $oauth = Get-Content -Raw -LiteralPath 'google-oauth.local.json' | ConvertFrom-Json
    if (-not $oauth.GOOGLE_DESKTOP_CLIENT_ID) {
        throw 'Missing Desktop OAuth Client ID.'
    }
    $env:GOOGLE_CLIENT_ID = $oauth.GOOGLE_DESKTOP_CLIENT_ID
    if ($oauth.GOOGLE_WEB_CLIENT_ID) {
        $env:GOOGLE_WEB_CLIENT_ID = $oauth.GOOGLE_WEB_CLIENT_ID
    }
    $env:ATTENDANCE_PUBLIC_BASE_URL = $url
    $env:JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF-8"
    
    Write-Host "Đang khởi động Backend Java..." -ForegroundColor Cyan
    & .\mvnw.cmd spring-boot:run
    
    if ($LASTEXITCODE -ne 0) { throw 'Backend failed to start.' }
} finally {
    Write-Host "Đang dọn dẹp Tunnel..." -ForegroundColor Yellow
    Stop-Job -Job $TunnelJob
    Remove-Job -Job $TunnelJob
    Pop-Location
}
