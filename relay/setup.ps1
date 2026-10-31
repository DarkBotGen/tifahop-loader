param([switch]$Background)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$install = Join-Path $env:LOCALAPPDATA 'TifaHopRelay'
New-Item -ItemType Directory -Force -Path $install | Out-Null
foreach ($name in @('relay.py','manager.py','setup.ps1','START.cmd','ENABLE-AUTOSTART.cmd','DISABLE-AUTOSTART.cmd','autostart.ps1','README.txt')) {
    $source = Join-Path $PSScriptRoot $name
    $target = Join-Path $install $name
    if ([IO.Path]::GetFullPath($source) -ne [IO.Path]::GetFullPath($target)) { Copy-Item -LiteralPath $source -Destination $target -Force }
}
function Download-Verified($url, $path, $hash) {
    if ((Test-Path -LiteralPath $path) -and ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $hash)) { return }
    Write-Host "Downloading $([IO.Path]::GetFileName($path))..."
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile "$path.partial"
    if ((Get-FileHash -LiteralPath "$path.partial" -Algorithm SHA256).Hash -ne $hash) { throw "Download checksum mismatch: $path" }
    Move-Item -LiteralPath "$path.partial" -Destination $path -Force
}
$pythonDir = Join-Path $install 'python'
$python = Join-Path $pythonDir 'python.exe'
if (-not (Test-Path -LiteralPath $python)) {
    $zip = Join-Path $install 'python.zip'
    Download-Verified 'https://www.python.org/ftp/python/3.13.9/python-3.13.9-embed-amd64.zip' $zip '91d828c2da3a029b41699e918674a0cb379c02cf20dab9c501306885f837402a'
    Expand-Archive -LiteralPath $zip -DestinationPath $pythonDir -Force
}
Download-Verified 'https://github.com/cloudflare/cloudflared/releases/download/2026.10.7/cloudflared-windows-amd64.exe' (Join-Path $install 'cloudflared.exe') '2493dbc168923bb3e59e5e7716f71deced92992eea9acd6e9d74f84ac7751343'
$settings = Join-Path $install 'settings.json'
if (-not (Test-Path -LiteralPath $settings)) { '{"Port":8787,"TunnelToken":"","PublicURL":""}' | Set-Content -LiteralPath $settings -Encoding UTF8 }
Write-Host "Installed in $install"
Write-Host 'Starting relay. Keep this window open. Ctrl+C stops it.'
if ($Background) {
    & $python (Join-Path $install 'manager.py') --background *> (Join-Path $install 'manager.log')
} else { & $python (Join-Path $install 'manager.py') }
if ($LASTEXITCODE -ne 0) { throw "Relay stopped with exit code $LASTEXITCODE" }
