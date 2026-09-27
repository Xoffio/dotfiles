# Bootstrap installer for Xoffio/dotfiles (Windows).
#
# Usage:
#   iex "& {$(irm https://raw.githubusercontent.com/Xoffio/dotfiles/refs/heads/master/install.ps1)}"
#   iex "& {$(irm https://raw.githubusercontent.com/Xoffio/dotfiles/refs/heads/master/install.ps1)} init --apply Xoffio"
#
# Installs chezmoi into %USERPROFILE%\.local\bin (matches the ~/.local/bin
# convention used on Linux/macOS in this repo) with checksum verification.
# Any args passed after the script are forwarded to chezmoi, same as the
# sh version's `"$@"` behavior.

$ErrorActionPreference = "Stop"

# Older Windows (Server 2012/2016, some fresh installs) defaults to
# TLS 1.0/1.1, which GitHub rejects. Force TLS 1.2 defensively.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "Xoffio/dotfiles"
$ChezmoiVersion = "2.72.2"
$InstallDir = Join-Path $HOME ".local\bin"

# --- detect architecture ---
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
    "arm64"
} else {
    "amd64"
}

if ($arch -ne "amd64") {
    Write-Error "This script only supports Windows amd64 right now (detected: $arch). chezmoi doesn't publish a bare arm64 binary, only a zip - see https://github.com/twpayne/chezmoi/releases."
    exit 1
}

$filename = "chezmoi-windows-amd64.exe"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$tmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

try {
    $binaryPath = Join-Path $tmpDir $filename
    $checksumsPath = Join-Path $tmpDir "chezmoi_${ChezmoiVersion}_checksums.txt"

    Write-Host "Downloading chezmoi v${ChezmoiVersion} ($filename)..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/twpayne/chezmoi/releases/download/v${ChezmoiVersion}/${filename}" -OutFile $binaryPath
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/twpayne/chezmoi/releases/download/v${ChezmoiVersion}/chezmoi_${ChezmoiVersion}_checksums.txt" -OutFile $checksumsPath

    Write-Host "Verifying checksum..."
    $checksumLine = Select-String -Path $checksumsPath -Pattern ([regex]::Escape($filename))
    if (-not $checksumLine) {
        throw "Could not find a checksum entry for $filename"
    }
    $expectedHash = ($checksumLine.Line -split '\s+')[0]
    $actualHash = (Get-FileHash -Algorithm SHA256 -Path $binaryPath).Hash

    if ($actualHash.ToLower() -ne $expectedHash.ToLower()) {
        throw "Checksum mismatch for ${filename}: expected $expectedHash, got $actualHash"
    }

    $destPath = Join-Path $InstallDir "chezmoi.exe"
    Move-Item -Force -Path $binaryPath -Destination $destPath

    Write-Host "chezmoi installed to $destPath"
}
finally {
    Remove-Item -Recurse -Force -Path $tmpDir -ErrorAction SilentlyContinue
}

# make it usable in this same session
$env:Path = "$InstallDir;$env:Path"

# persist it in the permanent User PATH so every new shell (or app)
# picks it up automatically from now on - no manual step needed
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
 
if (-not ($userPath -split ";" | Where-Object { $_ -eq $InstallDir })) {
    [Environment]::SetEnvironmentVariable("Path", "$InstallDir;$userPath", "User")
    Write-Host "Added $InstallDir to your permanent User PATH."
} else {
    Write-Host "$InstallDir is already on your User PATH."
}

if ($args.Count -gt 0) {
    Write-Host "Running: chezmoi $($args -join ' ')"
    & "$InstallDir\chezmoi.exe" @args
}

Write-Host "Done."
Write-Host "Note: $InstallDir was added to PATH for this session only."
Write-Host "To persist it, run:"
Write-Host "  [Environment]::SetEnvironmentVariable('Path', '$InstallDir;' + [Environment]::GetEnvironmentVariable('Path', 'User'), 'User')"
