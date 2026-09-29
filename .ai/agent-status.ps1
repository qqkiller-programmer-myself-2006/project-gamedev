# Lists executor runs that are still marked running and flags problems:
#   OK       heartbeat fresh, recent activity
#   IDLE     no activity for over half the idle limit (the runner kills it at the limit and resumes)
#   DEAD     process gone but never marked finished (runner itself was killed) -> marked 'died'
#   NOBEAT   old-style run without heartbeat (started by a previous runner version)
# Usage: powershell -File .ai/agent-status.ps1 [-All]
param([switch]$All)
$logDir = Join-Path $PSScriptRoot 'logs'
$rows = foreach ($f in Get-ChildItem $logDir -Filter *.status.json | Sort-Object LastWriteTime -Descending) {
    $s = Get-Content $f.FullName -Raw | ConvertFrom-Json
    if (-not $All -and $s.state -ne 'running') { continue }
    $alive = $false
    if ($s.pid) { $alive = $null -ne (Get-Process -Id $s.pid -ErrorAction SilentlyContinue) }
    $flag = 'OK'
    if ($s.state -eq 'running' -and -not $alive) {
        $flag = 'DEAD'
        $h = @{}; $s.PSObject.Properties | ForEach-Object { $h[$_.Name] = $_.Value }
        $h.state = 'died'; $h.ended = (Get-Date).ToString('s')
        $h | ConvertTo-Json | Set-Content -Encoding utf8 $f.FullName
    } elseif ($s.state -eq 'running' -and -not $s.heartbeat) {
        $flag = 'NOBEAT'
    } elseif ($s.state -eq 'running' -and $s.idle_minutes -ge ($s.idle_limit / 2)) {
        $flag = 'IDLE'
    } elseif ($s.state -ne 'running') { $flag = $s.state }
    [pscustomobject]@{
        Flag = $flag; Task = [IO.Path]::GetFileNameWithoutExtension($s.task); Agent = $s.agent; Attempt = $s.attempt
        Started = $s.started; LastActivity = $s.last_activity; Kind = $s.last_activity_kind; IdleMin = $s.idle_minutes
    }
}
if ($rows) { $rows | Format-Table -AutoSize | Out-String -Width 200 } else { 'no running executor' }
