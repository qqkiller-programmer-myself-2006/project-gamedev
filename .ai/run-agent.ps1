# Runs one AI executor (codex or agy) on a task file inside a git worktree,
# with a hard timeout that kills the whole process tree so nothing is left hanging.
param(
    [Parameter(Mandatory = $true)][ValidateSet('codex', 'agy')][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Worktree,
    [Parameter(Mandatory = $true)][string]$TaskFile,
    [int]$TimeoutMin = 45,
    [string[]]$Images = @(),
    [string]$Model = ''
)
$ErrorActionPreference = 'Stop'

function Quote([string]$s) { '"' + ($s -replace '"', '\"') + '"' }

$name = [IO.Path]::GetFileNameWithoutExtension($TaskFile)
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Force $logDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$base = Join-Path $logDir "$name-$Agent-$stamp"
$status = "$base.status.json"

$env:GODOT = 'D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
$prompt = "Read the task file '$TaskFile' in the current directory and carry it out exactly. " +
    "Work only inside the current directory. Do not commit, push, or change git config/remotes; leave your changes uncommitted for review. " +
    "End with the report the task file asks for."

if ($Agent -eq 'codex') {
    $exe = (Get-Command codex.cmd).Source
    $argv = @('exec', '-C', $Worktree, '-s', 'workspace-write', '--skip-git-repo-check',
        '--add-dir', (Join-Path $env:APPDATA 'Godot'), '-o', "$base.last.md")
    foreach ($i in $Images) { $argv += @('-i', $i) }
    if ($Model) { $argv += @('-m', $Model) }
    $argv += $prompt
} else {
    $exe = (Get-Command agy).Source
    $argv = @('--print', $prompt, '--dangerously-skip-permissions', '--print-timeout', "$($TimeoutMin)m")
    if ($Model) { $argv += @('--model', $Model) }
}

$argLine = ($argv | ForEach-Object { Quote $_ }) -join ' '
$started = Get-Date
$p = Start-Process -FilePath $exe -ArgumentList $argLine -WorkingDirectory $Worktree -NoNewWindow -PassThru `
    -RedirectStandardOutput "$base.out.log" -RedirectStandardError "$base.err.log"
@{ agent = $Agent; task = $TaskFile; worktree = $Worktree; pid = $p.Id; started = $started.ToString('s'); state = 'running' } |
    ConvertTo-Json | Set-Content -Encoding utf8 $status

$finished = $p.WaitForExit($TimeoutMin * 60 * 1000)
if (-not $finished) {
    & taskkill.exe /PID $p.Id /T /F | Out-Null
    $state = 'timeout-killed'; $code = -1
} else {
    $state = 'finished'; $code = $p.ExitCode
}
@{ agent = $Agent; task = $TaskFile; worktree = $Worktree; pid = $p.Id; started = $started.ToString('s');
   ended = (Get-Date).ToString('s'); minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1); state = $state; exit = $code } |
    ConvertTo-Json | Set-Content -Encoding utf8 $status
Write-Output "[$Agent] $TaskFile -> $state (exit $code) log: $base.out.log"
