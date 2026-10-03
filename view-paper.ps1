$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$streams = Join-Path $dir 'kalshi-streams.txt'
$log = Join-Path $dir 'kalshi-paper.log'
$pidFile = Join-Path $dir 'bot.pid'
$stopTimeFile = Join-Path $dir 'bot-stop-time.txt'
$Host.UI.RawUI.WindowTitle = 'Kalshi Paper Bot - LIVE'

# ---- big, readable console (Consolas 12x24 cells, 100x30 window) ----
try {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public struct CCOORD { public short X; public short Y; }
public struct CRECT { public short Left; public short Top; public short Right; public short Bottom; }
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct CFONT {
    public uint cbSize;
    public uint nFont;
    public CCOORD dwFontSize;
    public uint FontFamily;
    public uint FontWeight;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string FaceName;
}
public static class ConBig {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int h);
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool SetCurrentConsoleFontEx(IntPtr h, bool max, ref CFONT f);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleScreenBufferSize(IntPtr h, CCOORD s);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleWindowInfo(IntPtr h, bool abs, ref CRECT r);
}
'@
    $h = [ConBig]::GetStdHandle(-11)
    $f = New-Object CFONT
    $f.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf([type][CFONT])
    $f.FaceName = 'Consolas'
    $f.dwFontSize.X = 12
    $f.dwFontSize.Y = 24
    [ConBig]::SetCurrentConsoleFontEx($h, $false, [ref]$f) | Out-Null
    $b = New-Object CCOORD; $b.X = 100; $b.Y = 300
    [ConBig]::SetConsoleScreenBufferSize($h, $b) | Out-Null
    $r = New-Object CRECT; $r.Left = 0; $r.Top = 0; $r.Right = 99; $r.Bottom = 29
    [ConBig]::SetConsoleWindowInfo($h, $true, [ref]$r) | Out-Null
} catch { }
# ---------------------------------------------------------------------

while ($true) {
    $alive = $false
    if (Test-Path $pidFile) {
        $id = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($id) { $alive = [bool](Get-Process -Id $id -ErrorAction SilentlyContinue) }
    }
    $left = ''
    if (Test-Path $stopTimeFile) {
        $t = Get-Content $stopTimeFile -ErrorAction SilentlyContinue
        if ($t) {
            $ts = [datetime]$t - (Get-Date)
            if ($ts.TotalSeconds -lt 0) { $ts = [timespan]::Zero }
            if ($ts.TotalHours -ge 1) { $left = 'auto-stop in {0:hh\:mm\:ss}' -f $ts }
            else { $left = 'auto-stop in {0:mm\:ss}' -f $ts }
        }
    }

    Clear-Host
    Write-Host ''
    Write-Host '   =================  KALSHI v5 PAPER BOT  =================' -ForegroundColor Cyan
    Write-Host ("   Status: {0}    {1}    clock {2}" -f $(if ($alive) { 'RUNNING' } else { 'STOPPED' }), $left, (Get-Date -Format 'HH:mm:ss')) -ForegroundColor $(if ($alive) { 'Green' } else { 'Red' })
    Write-Host '   -----------------  live numbers  ------------------------' -ForegroundColor DarkCyan
    if (Test-Path $streams) {
        Get-Content $streams | ForEach-Object {
            $color = 'White'
            if ($_ -match ':') {
                $v = ($_ -split ':', 2)[1].Trim()
                if ($v -match '^-') { $color = 'Red' }
                elseif ($v -match '^\+') { $color = 'Green' }
            }
            Write-Host ("   " + $_) -ForegroundColor $color
        }
    }
    Write-Host '   -----------------  recent events  ----------------------' -ForegroundColor DarkCyan
    if (Test-Path $log) { Get-Content $log -Tail 8 | ForEach-Object { Write-Host ("   " + $_) -ForegroundColor Gray } }
    Write-Host ''
    Write-Host '   (close this window any time; bot keeps running in tray)' -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
}
