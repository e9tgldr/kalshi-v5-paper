# Detached overnight manager for the Kalshi paper bot.
# Keeps the bot running until -Until time (default 05:00), auto-restarts it if it dies, then stops it.
param([string]$Until = '05:00')
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $dir 'bot.pid'
$stopTimeFile = Join-Path $dir 'bot-stop-time.txt'
$ahk = Join-Path $dir 'ahk-v1\AutoHotkeyU64.exe'
$script = Join-Path $dir 'kalshi-v5-paper.ahk'
$managerLog = Join-Path $dir 'kalshi-paper.log'

function Log-Manager($msg) {
    Add-Content -Path $managerLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] (manager) $msg"
}

$target = [datetime]::ParseExact($Until, 'HH:mm', $null)
$target = (Get-Date -Hour $target.Hour -Minute $target.Minute -Second 0)
if ($target -le (Get-Date)) { $target = $target.AddDays(1) }
Set-Content $stopTimeFile $target.ToString('o')
Log-Manager "overnight run started - will stop at $($target.ToString('yyyy-MM-dd HH:mm'))"

$lastStart = Get-Date
while ($true) {
    Start-Sleep -Seconds 30
    if ((Get-Date) -ge $target) { break }

    $alive = $false
    $id = $null
    if (Test-Path $pidFile) {
        $id = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($id) { $alive = [bool](Get-Process -Id $id -ErrorAction SilentlyContinue) }
    }
    if (-not $alive) {
        # guard against instant-crash restart loops
        if (((Get-Date) - $lastStart).TotalSeconds -lt 90) { continue }
        $proc = Start-Process -FilePath $ahk -ArgumentList "`"$script`"" -WorkingDirectory $dir -PassThru
        Set-Content $pidFile $proc.Id
        $lastStart = Get-Date
        Log-Manager "bot was not running - auto-restarted (PID $($proc.Id))"
    }
}

# time reached - stop the bot
if (Test-Path $pidFile) {
    $id = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($id -and (Get-Process -Id $id -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $id -Force
        Log-Manager "05:00 REACHED (or target time) - bot stopped. Overnight run complete."
    }
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
Remove-Item $stopTimeFile -ErrorAction SilentlyContinue
Log-Manager "overnight manager exiting."
