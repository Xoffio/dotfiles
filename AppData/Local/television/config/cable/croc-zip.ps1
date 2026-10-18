param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [switch]$Qr
)

# tv passes the path single-quoted with a possible trailing backslash,
# e.g. 'config\'
$dir = $Path.Trim("'").TrimEnd("\")
$name = Split-Path $dir -Leaf
if (-not $name) { $name = "croc-send" }
$archive = Join-Path $env:TEMP "$name.tar.gz"
$full = (Join-Path $PWD $dir).TrimEnd("\")

$parent = Split-Path $full -Parent
$leaf = Split-Path $full -Leaf

Clear-Host
Write-Host "Archiving $leaf -> $archive"
Push-Location $parent
try {
    tar.exe -czf $archive $leaf
} finally {
    Pop-Location
}

if (Test-Path $archive) {
    if ($Qr) {
        croc send --qr $archive
    } else {
        croc send $archive
    }
    Remove-Item $archive -ErrorAction SilentlyContinue
} else {
    Write-Host "ERROR: archive was not created"
}

Write-Host ""
cmd /c pause
