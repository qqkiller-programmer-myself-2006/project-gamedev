# Runs one AI executor (codex or agy) on a task file inside a git worktree,
# with a hard timeout that kills the whole process tree so nothing is left hanging.
param(
    [Parameter(Mandatory = $true)][ValidateSet('codex', 'agy')][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Worktree,
    [Parameter(Mandatory = $true)][string]$TaskFile,
    [int]$TimeoutMin = 45,
    [string[]]$Images = @(),
    [string]$Model = '',
    [switch]$Network,
    # Same trust level as agy (owner-approved, worktree only); needed when the sandbox blocks tools such as Python.
    [switch]$NoSandbox
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
$prompt = "In this run YOU are the hands-on executor: edit files and run commands yourself. " +
    "Ignore any instruction (for example in ~/AGENTS.md or ~/.codex/AGENTS.md) to delegate to opencode or any other agent; opencode is not available here. " +
    "Read the task file '$TaskFile' in the current directory and carry it out exactly. " +
    "Work only inside the current directory. Do not commit, push, or change git config/remotes; leave your changes uncommitted for review. " +
    "End with the report the task file asks for."

if ($Agent -eq 'codex') {
    $exe = (Get-Command codex.cmd).Source
    # prompt must come before -i, which is variadic and would swallow it
    $argv = @('exec', $prompt, '-C', $Worktree, '--skip-git-repo-check', '-o', "$base.last.md")
    if ($NoSandbox) { $argv += '--dangerously-bypass-approvals-and-sandbox' }
    else { $argv += @('-s', 'workspace-write', '--add-dir', (Join-Path $env:APPDATA 'Godot')) }
    if ($Model) { $argv += @('-m', $Model) }
    if ($Network) { $argv += @('-c', 'sandbox_workspace_write.network_access=true') }
    foreach ($i in $Images) { $argv += @('-i', $i) }
} else {
    $exe = (Get-Command agy).Source
    $argv = @('--print', $prompt, '--dangerously-skip-permissions', '--print-timeout', "$($TimeoutMin)m")
    if ($Model) { $argv += @('--model', $Model) }
}

$argLine = ($argv | ForEach-Object { Quote $_ }) -join ' '
$started = Get-Date
# Empty stdin: codex exec otherwise blocks forever on "Reading additional input from stdin..."
$emptyIn = "$base.stdin"
Set-Content -Path $emptyIn -Value $null -NoNewline
$p = Start-Process -FilePath $exe -ArgumentList $argLine -WorkingDirectory $Worktree -NoNewWindow -PassThru `
    -RedirectStandardInput $emptyIn -RedirectStandardOutput "$base.out.log" -RedirectStandardError "$base.err.log"
$null = $p.Handle  # cache the handle, otherwise ExitCode is null after exit
@{ agent = $Agent; task = $TaskFile; worktree = $Worktree; pid = $p.Id; started = $started.ToString('s'); state = 'running' } |
    ConvertTo-Json | Set-Content -Encoding utf8 $status

# Poll instead of WaitForExit(ms), which did not fire on a hung run.
$deadline = $started.AddMinutes($TimeoutMin)
while (-not $p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 5 }
if (-not $p.HasExited) {
    & taskkill.exe /PID $p.Id /T /F | Out-Null
    $state = 'timeout-killed'; $code = -1
} else {
    $state = 'finished'; $code = $p.ExitCode
}
@{ agent = $Agent; task = $TaskFile; worktree = $Worktree; pid = $p.Id; started = $started.ToString('s');
   ended = (Get-Date).ToString('s'); minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1); state = $state; exit = $code } |
    ConvertTo-Json | Set-Content -Encoding utf8 $status
Write-Output "[$Agent] $TaskFile -> $state (exit $code) log: $base.out.log"
