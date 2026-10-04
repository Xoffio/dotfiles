function which ($Command) {
    (Get-Command $Command -ErrorAction SilentlyContinue).Path
}

# Atuin shell plugin
# This has to be at the end of the file
atuin init powershell | Out-String | Invoke-Expression

Get-ChildItem "$PSScriptRoot\Completions\*.ps1" -ErrorAction SilentlyContinue |
    ForEach-Object { . $_.FullName }
