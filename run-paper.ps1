param(
    [switch]$Stop,
    [int]$Minutes = 0,
    [string]$Until = '',         # e.g. -Until 05:00 -> detached overnight manager (auto-restart on crash)
    [int]$StopAfterSeconds = 0   # internal: used by the hidden auto-stop helper
)
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $dir 'bot.pid'
$stopTimeFile = Join-Path $dir 'bot-stop-time.txt'
$ahk = Join-Path $dir 'ahk-v1\AutoHotkeyU64.exe'
$script = Join-Path $dir 'kalshi-v5-paper.ahk'

function Stop-Bot {
    if (Test-Path $pidFile) {
        $id = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($id) {
            $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($proc) {
                Stop-Process -Id $id -Force
                Add-Content -Path (Join-Path $dir 'kalshi-paper.log') -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] RUN LIMIT REACHED - bot stopped by launcher."
                "Bot stopped (PID $id)."
            } else { "Bot was not running." }
        }
        Remove-Item $pidFile -ErrorAction SilentlyContinue
    } else {
        Get-Process AutoHotkeyU64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$dir*" } | Stop-Process -Force
        "Bot stopped."
    }
    Remove-Item $stopTimeFile -ErrorAction SilentlyContinue
    # also end the overnight manager so it does not auto-restart the bot
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
        Where-Object { $_.CommandLine -match '[R]UN-TILL\.ps1' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

if ($StopAfterSeconds -gt 0) {
    Start-Sleep -Seconds $StopAfterSeconds
    Stop-Bot
    return
}

if ($Stop) { Stop-Bot; return }

if (Test-Path $pidFile) {
    $old = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($old -and (Get-Process -Id $old -ErrorAction SilentlyContinue)) {
        "Already running (PID $old). Use:  .\run-paper.ps1 -Stop"
        Start-Sleep 4
        return
    }
}

Remove-Item $stopTimeFile -ErrorAction SilentlyContinue
$proc = Start-Process -FilePath $ahk -ArgumentList "`"$script`"" -WorkingDirectory $dir -PassThru
Set-Content $pidFile $proc.Id
""
"Kalshi PAPER bot started (PID $($proc.Id)). No window - it lives in the tray."
if ($Until -ne '') {
    Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dir\RUN-TILL.ps1`" -Until `"$Until`""
    "Overnight manager started - runs until $Until, auto-restarts the bot if it crashes."
}
if ($Minutes -gt 0) {
    $stopAt = (Get-Date).AddMinutes($Minutes)
    Set-Content $stopTimeFile $stopAt.ToString('o')
    Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dir\run-paper.ps1`" -StopAfterSeconds $($Minutes * 60)"
    "Auto-stop at $($stopAt.ToString('HH:mm:ss'))  ($Minutes min run)."
}
""
"View live:  double-click 'Kalshi Paper View' desktop shortcut"
"Stop bot:   .\run-paper.ps1 -Stop"
Start-Sleep 5
