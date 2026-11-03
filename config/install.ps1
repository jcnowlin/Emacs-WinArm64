# install.ps1 — put the jProX Emacs core config in place.
# Copies init.el, cheatsheet.org, guide.org and bookmarks from this
# folder into %APPDATA%\.emacs.d (where the MSYS2 Emacs looks).
# Safe to re-run: an existing init.el is backed up once, the first
# time, to init.el.pre-jprox-port.
$ErrorActionPreference = 'Stop'

$src = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:APPDATA '.emacs.d'

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
    Write-Host "Created $dest"
}

$files = 'init.el', 'cheatsheet.org', 'guide.org', 'bookmarks'
foreach ($f in $files) {
    $from = Join-Path $src $f
    $to = Join-Path $dest $f
    if ($f -eq 'init.el' -and (Test-Path $to) -and -not (Test-Path "$to.pre-jprox-port")) {
        Copy-Item $to "$to.pre-jprox-port"
        Write-Host "Backed up existing init.el to init.el.pre-jprox-port"
    }
    Copy-Item $from $to -Force
    Write-Host "Installed $f"
}

# Vendored packages (ef-themes, embark-consult, modus-themes) ship
# with the port; the init loads them from .emacs.d\vendor, off the
# package archives.
$vendorFrom = Join-Path $src 'vendor'
if (Test-Path $vendorFrom) {
    $vendorTo = Join-Path $dest 'vendor'
    if (-not (Test-Path $vendorTo)) {
        New-Item -ItemType Directory -Path $vendorTo | Out-Null
    }
    # Copy the CONTENTS of vendor, never the folder itself: Copy-Item
    # of a folder onto an already-existing folder nests the source
    # inside it (vendor\vendor) instead of merging -- that doubling
    # is what broke the 2026-11-01 install rerun.
    Copy-Item (Join-Path $vendorFrom '*') $vendorTo -Recurse -Force
    Write-Host "Installed vendor packages (ef-themes, embark-consult, modus-themes)"
}

Write-Host ""
Write-Host "Config is in $dest"
Write-Host "Launch Emacs from the GitHub bundle (bin\runemacs.exe where you unzipped it),"
Write-Host "or with C:\msys64\clangarm64\bin\runemacs.exe for the MSYS2 install."
Write-Host "First launch downloads the remaining packages from ELPA/MELPA; give it a few minutes."
if ($env:HOME) {
    Write-Host ""
    Write-Host "NOTE: a HOME environment variable is set ($env:HOME)."
    Write-Host "If Emacs does not pick up this config, it is looking in"
    Write-Host "$env:HOME\.emacs.d instead. Tell Bill and he will adjust."
}
