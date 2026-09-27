function which ($Command) {
    (Get-Command $Command -ErrorAction SilentlyContinue).Path
}
