function which ($Command) {
    (Get-Command $Command -ErrorAction SilentlyContinue).Path
}

# uutils coreutils (winget: uutils.coreutils) ships one multicall binary with
# shim exes per utility. PowerShell's built-in aliases (ls->Get-ChildItem,
# cat->Get-Content, sort->Sort-Object, ...) shadow those shims, so when
# coreutils is installed, drop the aliases whose names coreutils provides
# (the list below is coreutils --list). Without coreutils, nothing changes.
if (Get-Command coreutils -ErrorAction SilentlyContinue) {
    $coreutilsNames = @(
        'arch','b2sum','base32','base64','basename','basenc','cat','cksum',
        'comm','cp','csplit','cut','date','dd','df','dir','dircolors','dirname',
        'du','echo','env','expand','expr','factor','false','fmt','fold','head',
        'hostid','hostname','join','kill','link','ln','ls','md5sum','mkdir',
        'mktemp','more','mv','nice','nl','nohup','nproc','numfmt','od','paste',
        'pathchk','pr','printenv','printf','ptx','pwd','readlink','realpath',
        'rm','rmdir','seq','sha1sum','sha224sum','sha256sum','sha384sum',
        'sha512sum','shred','shuf','sleep','sort','split','stdbuf','sum','sync',
        'tac','tail','tee','test','timeout','touch','tr','true','truncate',
        'tsort','tty','uname','unexpand','uniq','unlink','uptime','vdir','wc',
        'whoami','yes'
    )
    foreach ($name in $coreutilsNames) {
        Remove-Item "Alias:$name" -Force -ErrorAction SilentlyContinue
    }
}

# Atuin shell plugin
# This has to be at the end of the file
atuin init powershell | Out-String | Invoke-Expression

Get-ChildItem "$PSScriptRoot\Completions\*.ps1" -ErrorAction SilentlyContinue |
    ForEach-Object { . $_.FullName }
