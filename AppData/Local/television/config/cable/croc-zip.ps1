param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [switch]$Qr
)

# tv's substitution plus Windows argv parsing can leave any of ' " \ stuck
# to the ends of the path. Strip all of them.
$dir = $Path.Trim("'", '"', "\")
$name = Split-Path $dir -Leaf
if (-not $name) { $name = "croc-send" }
$archive = Join-Path $env:TEMP "$name.tar.gz"
$full = (Join-Path $PWD $dir).TrimEnd("\")

$parent = Split-Path $full -Parent
$leaf = Split-Path $full -Leaf

Clear-Host
Write-Host "Archiving $leaf -> $archive"

try {
    Push-Location $parent
    try {
        tar.exe -czf $archive $leaf
        if ($LASTEXITCODE -ne 0) { throw "tar exited with $LASTEXITCODE" }
    } finally {
        Pop-Location
    }

    if ($Qr) {
        croc send --qr $archive
    } else {
        croc send $archive
    }
} catch {
    Write-Host "ERROR: $_"
} finally {
    # Always clean up the temp archive, even on failure or Ctrl+C
    Remove-Item $archive -ErrorAction SilentlyContinue
}

Write-Host ""
cmd /c pause
