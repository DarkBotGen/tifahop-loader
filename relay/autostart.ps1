param([switch]$Disable)
$ErrorActionPreference='Stop'
$startup=[Environment]::GetFolderPath('Startup')
$link=Join-Path $startup 'TifaHop Relay.lnk'
if ($Disable) {
    if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link }
    Write-Host 'Automatic startup disabled. A running relay stays running.'
    exit
}
$install=Join-Path $env:LOCALAPPDATA 'TifaHopRelay'
if (-not (Test-Path -LiteralPath (Join-Path $install 'python/python.exe'))) { throw 'Run START.cmd once before enabling automatic startup.' }
$shell=New-Object -ComObject WScript.Shell
$shortcut=$shell.CreateShortcut($link)
$shortcut.TargetPath=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$shortcut.Arguments='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+(Join-Path $install 'setup.ps1')+'" -Background'
$shortcut.WorkingDirectory=$install
$shortcut.Save()
Write-Host 'Relay will start when this Windows user signs in. URL file: '
Write-Host (Join-Path $install 'YOUR-RELAY-URL.txt')
