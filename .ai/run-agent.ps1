# Runs one AI executor (codex or agy) on a task file inside a git worktree.
# - Hard timeout per attempt kills the whole process tree so nothing is left hanging.
# - Stall detector: when the worktree files, the logs and the CPU of the whole process tree all stay still for
#   -IdleMin minutes, the run is killed as 'stalled' and a fresh agent (optionally -FallbackAgent) resumes the task in
#   the same worktree, up to -Retries times. Status (with a heartbeat) is in .ai/logs/<task>-<agent>-<stamp>.status.json.
param(
    [Parameter(Mandatory = $true)][ValidateSet('codex', 'agy')][string]$Agent,
    [Parameter(Mandatory = $true)][string]$Worktree,
    [Parameter(Mandatory = $true)][string]$TaskFile,
    [int]$TimeoutMin = 45,
    [string[]]$Images = @(),
    [string]$Model = '',
    [switch]$Network,
    # Same trust level as agy (owner-approved, worktree only); needed when the sandbox blocks tools such as Python.
    [switch]$NoSandbox,
    # Minutes with no file change, no log output and no CPU in the process tree before the run counts as stalled.
    [int]$IdleMin = 20,
    # How many fresh agents may resume a stalled task.
    [int]$Retries = 1,
    # Agent used for resumed attempts; empty = same agent.
    [ValidateSet('', 'codex', 'agy')][string]$FallbackAgent = '',
    # Testing the runner only: run this PowerShell command instead of an AI agent.
    [string]$SelfTest = ''
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

$basePrompt = "In this run YOU are the hands-on executor: edit files and run commands yourself. " +
    "Ignore any instruction (for example in ~/AGENTS.md or ~/.codex/AGENTS.md) to delegate to opencode or any other agent; opencode is not available here. " +
    "Read the task file '$TaskFile' in the current directory and carry it out exactly. " +
    "Work only inside the current directory. Do not commit, push, or change git config/remotes; leave your changes uncommitted for review. " +
    "End with the report the task file asks for."
$resumePrompt = "RESUME: a previous executor on this task stopped making progress and was stopped. The current directory already " +
    "holds its partial work. Start with 'git status' and 'git diff --stat', keep what is right, fix what is wrong, finish every " +
    "remaining item of the task, then verify as the task says. "

function Get-Launch([string]$who, [string]$prompt, [string]$outLast) {
    if ($SelfTest) {
        return @((Get-Command powershell.exe).Source, ('-NoProfile -Command ' + (Quote $SelfTest)))
    }
    if ($who -eq 'codex') {
        $exe = (Get-Command codex.cmd).Source
        # prompt must come before -i, which is variadic and would swallow it
        $a = @('exec', $prompt, '-C', $Worktree, '--skip-git-repo-check', '-o', $outLast)
        if ($NoSandbox) { $a += '--dangerously-bypass-approvals-and-sandbox' }
        else { $a += @('-s', 'workspace-write', '--add-dir', (Join-Path $env:APPDATA 'Godot')) }
        if ($Model -and $who -eq $Agent) { $a += @('-m', $Model) }
        if ($Network) { $a += @('-c', 'sandbox_workspace_write.network_access=true') }
        foreach ($i in $Images) { $a += @('-i', $i) }
    } else {
        $exe = (Get-Command agy).Source
        $a = @('--print', $prompt, '--dangerously-skip-permissions', '--print-timeout', "$($TimeoutMin)m")
        if ($Model -and $who -eq $Agent) { $a += @('--model', $Model) }
    }
    return @($exe, (($a | ForEach-Object { Quote $_ }) -join ' '))
}

# Total CPU seconds of a process and all its descendants (node, python, godot, ...).
function Get-TreeCpu([int]$rootPid) {
    $all = Get-CimInstance Win32_Process -Property ProcessId, ParentProcessId, KernelModeTime, UserModeTime
    $kids = @{}
    foreach ($p in $all) { $kids[[int]$p.ParentProcessId] += @($p) }
    $total = 0.0; $stack = New-Object System.Collections.Stack; $stack.Push($rootPid); $seen = @{}
    while ($stack.Count -gt 0) {
        $id = [int]$stack.Pop(); if ($seen.ContainsKey($id)) { continue }; $seen[$id] = $true
        $self = $all | Where-Object { $_.ProcessId -eq $id } | Select-Object -First 1
        if ($self) { $total += ([double]$self.KernelModeTime + [double]$self.UserModeTime) / 1e7 }
        foreach ($k in @($kids[$id])) { if ($k) { $stack.Push([int]$k.ProcessId) } }
    }
    return $total
}

function Write-Status([hashtable]$h) { $h | ConvertTo-Json | Set-Content -Encoding utf8 $status }

$started = Get-Date
$attempts = @()
$state = 'not-started'; $code = -1
for ($attempt = 0; $attempt -le $Retries; $attempt++) {
    $who = if ($attempt -gt 0 -and $FallbackAgent) { $FallbackAgent } else { $Agent }
    $prompt = if ($attempt -gt 0) { $resumePrompt + $basePrompt } else { $basePrompt }
    $ab = if ($attempt -gt 0) { "$base-r$attempt" } else { $base }
    $exe, $argLine = Get-Launch $who $prompt "$ab.last.md"

    # Empty stdin: codex exec otherwise blocks forever on "Reading additional input from stdin..."
    Set-Content -Path "$ab.stdin" -Value $null -NoNewline
    $p = Start-Process -FilePath $exe -ArgumentList $argLine -WorkingDirectory $Worktree -NoNewWindow -PassThru `
        -RedirectStandardInput "$ab.stdin" -RedirectStandardOutput "$ab.out.log" -RedirectStandardError "$ab.err.log"
    $null = $p.Handle  # cache the handle, otherwise ExitCode is null after exit
    $aStart = Get-Date

    # Any file change in the worktree (outside .git/.godot) counts as activity.
    $fsw = New-Object IO.FileSystemWatcher $Worktree
    $fsw.IncludeSubdirectories = $true
    $fsw.NotifyFilter = [IO.NotifyFilters]'FileName, DirectoryName, LastWrite, Size'
    $srcId = "agentfs-$stamp-$attempt"
    Register-ObjectEvent -InputObject $fsw -EventName Changed -SourceIdentifier "$srcId-c" | Out-Null
    Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier "$srcId-n" | Out-Null
    Register-ObjectEvent -InputObject $fsw -EventName Deleted -SourceIdentifier "$srcId-d" | Out-Null
    Register-ObjectEvent -InputObject $fsw -EventName Renamed -SourceIdentifier "$srcId-r" | Out-Null
    $fsw.EnableRaisingEvents = $true

    $lastActivity = Get-Date; $lastWhy = 'start'
    $lastCpu = 0.0; $lastLog = -1
    $deadline = $aStart.AddMinutes($TimeoutMin)
    $state = ''
    while ($true) {
        Start-Sleep -Seconds 30
        if ($p.HasExited) { $state = 'finished'; break }
        foreach ($e in @(Get-Event | Where-Object { $_.SourceIdentifier -like "$srcId-*" })) {
            $path = [string]$e.SourceEventArgs.FullPath
            if ($path -notmatch '[\\/]\.(git|godot)([\\/]|$)') { $lastActivity = Get-Date; $lastWhy = 'files' }
            Remove-Event -EventIdentifier $e.EventIdentifier
        }
        $logSize = 0
        foreach ($f in @("$ab.out.log", "$ab.err.log")) { if (Test-Path $f) { $logSize += (Get-Item $f).Length } }
        if ($logSize -ne $lastLog) { if ($lastLog -ge 0) { $lastActivity = Get-Date; $lastWhy = 'log' }; $lastLog = $logSize }
        $cpu = Get-TreeCpu $p.Id
        if ($cpu - $lastCpu -gt 1.0) { $lastActivity = Get-Date; $lastWhy = 'cpu' }
        $lastCpu = $cpu
        $idle = ((Get-Date) - $lastActivity).TotalMinutes
        Write-Status @{ agent = $who; task = $TaskFile; worktree = $Worktree; pid = $p.Id; attempt = $attempt;
            started = $started.ToString('s'); state = 'running'; heartbeat = (Get-Date).ToString('s');
            last_activity = $lastActivity.ToString('s'); last_activity_kind = $lastWhy; idle_minutes = [math]::Round($idle, 1);
            idle_limit = $IdleMin; log = "$ab.out.log" }
        if ((Get-Date) -ge $deadline) { $state = 'timeout-killed'; break }
        if ($idle -ge $IdleMin) { $state = 'stalled'; break }
    }
    $fsw.EnableRaisingEvents = $false
    Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "$srcId-*" } | Unregister-Event
    Get-Event | Where-Object { $_.SourceIdentifier -like "$srcId-*" } | Remove-Event
    $fsw.Dispose()

    if ($state -eq 'finished') { $code = $p.ExitCode }
    else { & taskkill.exe /PID $p.Id /T /F 2>$null | Out-Null; $code = -1 }
    $attempts += @{ agent = $who; state = $state; minutes = [math]::Round(((Get-Date) - $aStart).TotalMinutes, 1); log = "$ab.out.log" }
    if ($state -eq 'stalled') {
        Add-Content -Encoding utf8 (Join-Path $logDir 'stalled.log') "$((Get-Date).ToString('s')) $TaskFile $who attempt $attempt stalled ($IdleMin min idle) -> $(if ($attempt -lt $Retries) { 'resuming' } else { 'giving up' })"
        continue
    }
    # Quota errors (e.g. agy 429) end the run within seconds with a non-zero exit: hand the task to the fallback agent.
    if ($state -eq 'finished' -and $code -ne 0 -and $FallbackAgent -and $who -ne $FallbackAgent -and $attempt -lt $Retries -and
        $attempts[-1].minutes -lt 5) {
        Add-Content -Encoding utf8 (Join-Path $logDir 'stalled.log') "$((Get-Date).ToString('s')) $TaskFile $who attempt $attempt failed fast (exit $code) -> $FallbackAgent"
        continue
    }
    break
}

Write-Status @{ agent = $Agent; task = $TaskFile; worktree = $Worktree; started = $started.ToString('s');
    ended = (Get-Date).ToString('s'); minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1);
    state = $state; exit = $code; attempts = $attempts }
Write-Output "[$Agent] $TaskFile -> $state (exit $code, attempts $($attempts.Count)) log: $($attempts[-1].log)"
