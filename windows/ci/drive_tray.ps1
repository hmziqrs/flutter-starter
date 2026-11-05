# Drives the real runner's tray on a Windows machine with nobody at it, for
# Desktop smoke. Never run this on a desktop someone is using: it moves the mouse.
#
#   drive_tray.ps1 -Executable <path to surface probe build> -OutDir <evidence dir>
#
# It fails on anything the contract promises, and writes report.txt and PNGs.

param(
  [Parameter(Mandatory = $true)][string]$Executable,
  [Parameter(Mandatory = $true)][string]$OutDir
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class Win {
  public delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc proc, IntPtr lParam);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr GetProp(IntPtr hwnd, string name);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hwnd);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wparam, IntPtr lparam);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wparam, IntPtr lparam);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
  [DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr menu);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetMenuString(IntPtr menu, uint id, StringBuilder text, int max, uint flags);
  [DllImport("user32.dll")] public static extern uint GetMenuState(IntPtr menu, uint id, uint flags);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint x, uint y, uint data, UIntPtr extra);

  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct NOTIFYICONIDENTIFIER {
    public uint cbSize; public IntPtr hWnd; public uint uID; public Guid guidItem;
  }
  [DllImport("shell32.dll")] public static extern int Shell_NotifyIconGetRect(ref NOTIFYICONIDENTIFIER id, out RECT rect);

  public static IntPtr FindInstance() {
    IntPtr found = IntPtr.Zero;
    EnumWindows((hwnd, _) => {
      if (GetProp(hwnd, "com.example.starter.instance") == IntPtr.Zero) return true;
      found = hwnd;
      return false;
    }, IntPtr.Zero);
    return found;
  }

  public static bool TrayRect(IntPtr hwnd, out RECT rect) {
    var id = new NOTIFYICONIDENTIFIER();
    id.cbSize = (uint)Marshal.SizeOf(id);
    id.hWnd = hwnd;
    id.uID = 1;
    return Shell_NotifyIconGetRect(ref id, out rect) == 0;
  }

  public static string[] ReadMenu(IntPtr menu) {
    int count = GetMenuItemCount(menu);
    var items = new string[count];
    for (uint i = 0; i < count; i++) {
      var text = new StringBuilder(256);
      GetMenuString(menu, i, text, text.Capacity, 0x400);
      uint state = GetMenuState(menu, i, 0x400);
      if ((state & 0x800) != 0) items[i] = "---";
      else items[i] = text.ToString() + (((state & 0x3) != 0) ? " [disabled]" : "");
    }
    return items;
  }
}
'@

$WM_CLOSE = 0x0010
$WM_CANCELMODE = 0x001F
$WM_COMMAND = 0x0111
$WM_KEYDOWN = 0x0100
$WM_CONTEXTMENU = 0x007B
$MN_GETHMENU = 0x01E1
$TRAY_MESSAGE = 0x8001  # WM_APP + 1
$NIN_SELECT = 0x0400
$COMMAND_OPEN = 1
$COMMAND_QUIT = 2
$COMMAND_ACTIONS = 100

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$probeDir = Join-Path $OutDir 'probe'
New-Item -ItemType Directory -Force -Path $probeDir | Out-Null
$results = Join-Path $probeDir 'results.jsonl'
$env:SURFACE_PROBE_DIR = $probeDir
$snapshotFile = Join-Path $env:LOCALAPPDATA 'com.example.starter\native_surfaces.json'
$report = Join-Path $OutDir 'report.txt'
$failures = New-Object System.Collections.ArrayList

function Log($text) {
  Write-Host $text
  Add-Content -Path $report -Value $text -Encoding UTF8
}

function Check([bool]$ok, [string]$name, [string]$detail = '') {
  $word = if ($ok) { 'ok  ' } else { 'FAIL' }
  Log "$word $name $detail"
  if (-not $ok) { [void]$failures.Add($name) }
}

function Shot([string]$name) {
  try {
    $bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
  } catch {
    Add-Type -AssemblyName System.Windows.Forms
    $bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
  }
  try {
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bitmap.Save((Join-Path $OutDir "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
    Log "shot $name.png $($bounds.Width)x$($bounds.Height)"
  } catch {
    Log "shot $name FAILED: $_"
  }
}

function WaitFor([scriptblock]$condition, [int]$seconds = 20) {
  $deadline = (Get-Date).AddSeconds($seconds)
  while ((Get-Date) -lt $deadline) {
    if (& $condition) { return $true }
    Start-Sleep -Milliseconds 200
  }
  return $false
}

function Events([string]$event) {
  if (-not (Test-Path $results)) { return @() }
  $lines = Get-Content -Path $results -Encoding UTF8
  return @($lines | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.event -eq $event })
}

function HasEvent([string]$event, $value) {
  return @(Events $event | Where-Object { $_.value -eq $value }).Count -gt 0
}

function MenuWindow {
  $menu = [Win]::FindWindow('#32768', $null)
  if ($menu -ne [IntPtr]::Zero -and [Win]::IsWindowVisible($menu)) { return $menu }
  return [IntPtr]::Zero
}

function OpenMenuThroughMessage($hwnd) {
  $anchor = (800 -bor (600 -shl 16))
  [void][Win]::PostMessage($hwnd, $TRAY_MESSAGE, [IntPtr]$anchor, [IntPtr]($WM_CONTEXTMENU -bor (1 -shl 16)))
  return (WaitFor { (MenuWindow) -ne [IntPtr]::Zero } 5)
}

function CloseMenu($hwnd) {
  $menu = MenuWindow
  if ($menu -ne [IntPtr]::Zero) {
    [void][Win]::PostMessage($menu, $WM_KEYDOWN, [IntPtr]0x1B, [IntPtr]0)
    if (-not (WaitFor { (MenuWindow) -eq [IntPtr]::Zero } 3)) {
      [void][Win]::PostMessage($hwnd, $WM_CANCELMODE, [IntPtr]0, [IntPtr]0)
      [void](WaitFor { (MenuWindow) -eq [IntPtr]::Zero } 3)
    }
  }
}

function TooltipFromShell {
  # Best effort: the taskbar's buttons are named after their tooltips.
  try {
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $condition = [System.Windows.Automation.Condition]::TrueCondition
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $condition)
    foreach ($window in $all) {
      $class = $window.Current.ClassName
      if ($class -ne 'Shell_TrayWnd' -and $class -ne 'NotifyIconOverflowWindow') { continue }
      $buttons = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition)
      foreach ($button in $buttons) {
        $name = $button.Current.Name
        if ($name -and $name -like '*Surface sample*') { return $name }
        if ($name -and $name -like '*Open the app to get started*') { return $name }
      }
    }
  } catch {
    Log "tooltip lookup failed: $_"
  }
  return $null
}

# Start from a machine where nothing has been published.
if (Test-Path $snapshotFile) { Remove-Item $snapshotFile }
Set-Content -Path $report -Value "Windows tray drive, $(Get-Date -Format o)" -Encoding UTF8

# Show every tray icon rather than folding new ones away, then restart Explorer
# so that the setting takes hold. Best effort, for the screenshots.
try {
  Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' -Name EnableAutoTray -Value 0 -Type DWord
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 5
  if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
  Start-Sleep -Seconds 5
} catch {
  Log "explorer restart skipped: $_"
}
Log "taskbar: $([Win]::FindWindow('Shell_TrayWnd', $null))"

Log '--- launch with a surface URL'
$process = Start-Process -FilePath $Executable -ArgumentList 'starter-surface://open?route=%2Fpricing' -PassThru
Check (WaitFor { (Events 'liveCallsReturned').Count -gt 0 } 90) 'Dart reached the channel'
Check (HasEvent 'launchRoute' '/pricing') 'takeLaunchRoute returns the launch route'
$again = Events 'launchRouteAgain'
Check ($again.Count -eq 1 -and $null -eq $again[0].value) 'takeLaunchRoute is null the second time'
$live = Events 'startLive'
Check ($live.Count -eq 1 -and $live[0].value -eq $false) 'startLive returns false'

Check (WaitFor { [Win]::FindInstance() -ne [IntPtr]::Zero } 20) 'top-level window found'
$hwnd = [Win]::FindInstance()
Check (WaitFor { [Win]::IsWindowVisible($hwnd) } 30) 'window visible after the first frame'
Start-Sleep -Seconds 2

$rect = New-Object Win+RECT
$hasRect = [Win]::TrayRect($hwnd, [ref]$rect)
Check $hasRect 'the shell knows the tray icon' "rect=$($rect.Left),$($rect.Top),$($rect.Right),$($rect.Bottom)"
Shot '01-window-and-tray'

Log '--- fallback, before anything is published'
Log "tooltip from shell: $(TooltipFromShell)"
Check (OpenMenuThroughMessage $hwnd) 'menu opens'
$menu = [Win]::SendMessage((MenuWindow), $MN_GETHMENU, [IntPtr]0, [IntPtr]0)
$items = [Win]::ReadMenu($menu)
Log "menu: $($items -join ' | ')"
Check ($items[0] -eq 'Starter [disabled]') 'fallback title'
Check ($items[1] -eq 'Open the app to get started [disabled]') 'fallback subtitle'
Check ($items[-2] -eq 'Open' -and $items[-1] -eq 'Quit') 'Open and Quit are last'
Shot '02-menu-fallback'
CloseMenu $hwnd

Log '--- publish'
$sample = [ordered]@{
  schema = 1
  title = 'Surface sample & co'
  subtitle = "Build running $([char]0x00E9)"
  value = '72%'
  valueLabel = 'Complete'
  progress = 0.72
  status = 'active'
  updatedAt = '2026-11-05T01:00:00.000Z'
  route = '/'
  actions = @(
    [ordered]@{ label = 'Pricing'; route = '/pricing' },
    [ordered]@{ label = 'Settings'; route = '/settings' }
  )
} | ConvertTo-Json -Compress -Depth 4
[System.IO.File]::WriteAllText((Join-Path $probeDir 'publish.tmp'), $sample, (New-Object System.Text.UTF8Encoding($false)))
Move-Item (Join-Path $probeDir 'publish.tmp') (Join-Path $probeDir 'publish.json')
Check (WaitFor { (Events 'published').Count -gt 0 } 10) 'publish returned'
Check (Test-Path $snapshotFile) 'native_surfaces.json exists in local app data' $snapshotFile
$stored = [System.IO.File]::ReadAllText($snapshotFile, [System.Text.Encoding]::UTF8)
Check ($stored -ceq $sample) 'native_surfaces.json holds the published JSON'
Start-Sleep -Milliseconds 500
$tooltip = TooltipFromShell
Log "tooltip from shell: $tooltip"

# A real right-click on the icon, when the shell shows it, and the same message
# the shell would send when it does not.
$opened = $false
if ([Win]::TrayRect($hwnd, [ref]$rect) -and $rect.Right -gt $rect.Left) {
  [void][Win]::SetCursorPos([int](($rect.Left + $rect.Right) / 2), [int](($rect.Top + $rect.Bottom) / 2))
  Start-Sleep -Milliseconds 300
  [Win]::mouse_event(0x0008, 0, 0, 0, [UIntPtr]::Zero)
  [Win]::mouse_event(0x0010, 0, 0, 0, [UIntPtr]::Zero)
  $opened = WaitFor { (MenuWindow) -ne [IntPtr]::Zero } 5
  Log "menu opened by a real right-click on the icon: $opened"
}
if (-not $opened) { $opened = OpenMenuThroughMessage $hwnd }
Check $opened 'menu opens with the published snapshot'
$menu = [Win]::SendMessage((MenuWindow), $MN_GETHMENU, [IntPtr]0, [IntPtr]0)
$items = [Win]::ReadMenu($menu)
Log "menu: $($items -join ' | ')"
Check ($items[0] -eq 'Surface sample && co [disabled]') 'title, with its ampersand escaped'
Check ($items[1] -ceq "Build running $([char]0x00E9) [disabled]") 'subtitle, non-ASCII intact'
Check ($items -contains 'Pricing' -and $items -contains 'Settings') 'each action is listed'
Check ($items[-2] -eq 'Open' -and $items[-1] -eq 'Quit') 'Open and Quit are last'
Start-Sleep -Milliseconds 500
Shot '03-menu-published'
CloseMenu $hwnd

Log '--- close keeps the app in the tray'
[void][Win]::PostMessage($hwnd, $WM_CLOSE, [IntPtr]0, [IntPtr]0)
Check (WaitFor { -not [Win]::IsWindowVisible($hwnd) } 5) 'closing hides the window'
Start-Sleep -Seconds 1
Check (-not $process.HasExited) 'the process stays alive'
Check ([Win]::TrayRect($hwnd, [ref]$rect)) 'the icon stays in the tray'
Shot '04-closed-to-tray'

Log '--- an action restores the window and opens its route'
[void][Win]::PostMessage($hwnd, $WM_COMMAND, [IntPtr]($COMMAND_ACTIONS + 1), [IntPtr]0)
Check (WaitFor { HasEvent 'openRoute' '/settings' } 5) 'openRoute carries the action route'
Check (WaitFor { [Win]::IsWindowVisible($hwnd) } 5) 'the window comes back'
Start-Sleep -Seconds 1
Shot '05-restored-by-action'

Log '--- Open and the icon go to the snapshot route'
[void][Win]::PostMessage($hwnd, $WM_CLOSE, [IntPtr]0, [IntPtr]0)
Check (WaitFor { -not [Win]::IsWindowVisible($hwnd) } 5) 'hidden again'
[void][Win]::PostMessage($hwnd, $WM_COMMAND, [IntPtr]$COMMAND_OPEN, [IntPtr]0)
Check (WaitFor { HasEvent 'openRoute' '/' } 5) 'Open sends the snapshot route'
Check (WaitFor { [Win]::IsWindowVisible($hwnd) } 5) 'Open restores the window'
[void][Win]::PostMessage($hwnd, $WM_CLOSE, [IntPtr]0, [IntPtr]0)
Check (WaitFor { -not [Win]::IsWindowVisible($hwnd) } 5) 'hidden again'
[void][Win]::PostMessage($hwnd, $TRAY_MESSAGE, [IntPtr]0, [IntPtr]($NIN_SELECT -bor (1 -shl 16)))
Check (WaitFor { [Win]::IsWindowVisible($hwnd) } 5) 'selecting the icon restores the window'

Log '--- a second launch hands over'
[void][Win]::PostMessage($hwnd, $WM_CLOSE, [IntPtr]0, [IntPtr]0)
Check (WaitFor { -not [Win]::IsWindowVisible($hwnd) } 5) 'hidden again'
$second = Start-Process -FilePath $Executable -ArgumentList 'starter-surface://open?route=%2Fsecond' -PassThru
Check ($second.WaitForExit(15000) -and $second.ExitCode -eq 0) 'second instance exits at once'
Check (WaitFor { HasEvent 'openRoute' '/second' } 5) 'its URL reaches the running app as openRoute'
Check (WaitFor { [Win]::IsWindowVisible($hwnd) } 5) 'its URL restores the window'
[void][Win]::PostMessage($hwnd, $WM_CLOSE, [IntPtr]0, [IntPtr]0)
Check (WaitFor { -not [Win]::IsWindowVisible($hwnd) } 5) 'hidden again'
$third = Start-Process -FilePath $Executable -PassThru
Check ($third.WaitForExit(15000) -and $third.ExitCode -eq 0) 'a plain second launch exits at once'
Check (WaitFor { [Win]::IsWindowVisible($hwnd) } 5) 'a plain second launch restores the window'

Log '--- the URL scheme is registered'
$command = (Get-ItemProperty -Path 'HKCU:\Software\Classes\starter-surface\shell\open\command').'(default)'
Log "scheme command: $command"
Check ($command -like '*"%1"') 'starter-surface opens the executable'
[void][Win]::PostMessage($hwnd, $WM_CLOSE, [IntPtr]0, [IntPtr]0)
Start-Process 'starter-surface://open?route=%2Fshell'
Check (WaitFor { HasEvent 'openRoute' '/shell' } 15) 'the shell routes a starter-surface URL to the app'

Log '--- Explorer restarts'
try {
  Stop-Process -Name explorer -Force
  Start-Sleep -Seconds 8
  if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe; Start-Sleep -Seconds 8 }
  Check (WaitFor { [Win]::TrayRect($hwnd, [ref]$rect) } 20) 'the icon comes back after Explorer restarts'
  Shot '06-after-explorer-restart'
} catch {
  Log "explorer restart check skipped: $_"
}

Log '--- Quit really quits'
[void][Win]::PostMessage($hwnd, $WM_COMMAND, [IntPtr]$COMMAND_QUIT, [IntPtr]0)
Check ($process.WaitForExit(20000)) 'Quit ends the process'
Check (-not ([Win]::TrayRect($hwnd, [ref]$rect))) 'the icon is gone'
Shot '07-after-quit'

Log '--- a newer schema falls back'
[System.IO.File]::WriteAllText($snapshotFile, '{"schema":99,"title":"From the future","actions":[]}', (New-Object System.Text.UTF8Encoding($false)))
Remove-Item $results -ErrorAction SilentlyContinue
$process = Start-Process -FilePath $Executable -PassThru
Check (WaitFor { (Events 'liveCallsReturned').Count -gt 0 } 60) 'Dart reached the channel again'
Check (WaitFor { [Win]::FindInstance() -ne [IntPtr]::Zero } 20) 'window found again'
$hwnd = [Win]::FindInstance()
Check (OpenMenuThroughMessage $hwnd) 'menu opens'
$menu = [Win]::SendMessage((MenuWindow), $MN_GETHMENU, [IntPtr]0, [IntPtr]0)
$items = [Win]::ReadMenu($menu)
Log "menu: $($items -join ' | ')"
Check ($items[0] -eq 'Starter [disabled]') 'a newer schema shows the fallback'
CloseMenu $hwnd
[void][Win]::PostMessage($hwnd, $WM_COMMAND, [IntPtr]$COMMAND_QUIT, [IntPtr]0)
[void]$process.WaitForExit(20000)

if ($failures.Count -gt 0) {
  Log "FAILED: $($failures -join '; ')"
  exit 1
}
Log 'all checks passed'
exit 0
