# Checks the built provider as far as a machine with no Widgets Board can, for
# Desktop smoke. Installs the test MSIX, so run it only on a throwaway machine.
#
#   windows/widget_provider/verify.ps1 -BuildDir build/widget_provider -OutDir <evidence>
#
# Every result is written to provider-report.txt. Steps past packing are best effort:
# what they cannot prove stays unproven, and the report says so.

param(
  [Parameter(Mandatory = $true)][string]$BuildDir,
  [Parameter(Mandatory = $true)][string]$OutDir
)

$ErrorActionPreference = 'Continue'
$BuildDir = [System.IO.Path]::GetFullPath($BuildDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
$report = Join-Path $OutDir 'provider-report.txt'
$classId = 'F55748D8-A04C-4675-BB30-3C8128234385'
$exe = Join-Path $BuildDir 'publish\StarterWidgetProvider.exe'
$failed = $false

function Log($text) {
  Write-Host $text
  Add-Content -Path $report -Value $text -Encoding UTF8
}

Set-Content -Path $report -Value "Widget provider check, $(Get-Date -Format o)" -Encoding UTF8
Log "OS: $((Get-CimInstance Win32_OperatingSystem).Caption) $([Environment]::OSVersion.Version)"
$msix = Join-Path $BuildDir 'StarterWidgets.msix'
Log "msix: $msix $((Get-Item $msix).Length) bytes"

Log '--- files in the package'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($msix)
$names = $zip.Entries | ForEach-Object { $_.FullName }
$zip.Dispose()
$names | Set-Content -Path (Join-Path $OutDir 'msix-files.txt') -Encoding UTF8
Log "$($names.Count) files"
foreach ($expected in 'AppxManifest.xml', 'StarterWidgetProvider.exe', 'Templates/surface.json', 'Assets/ScreenshotDark.png') {
  $present = $names -contains $expected
  Log "$(if ($present) { 'ok  ' } else { 'FAIL' }) contains $expected"
  if (-not $present) { $failed = $true }
}

Log '--- card data, from the same code the widgets use'
$samples = @{
  'published' = '{"schema":1,"title":"Starter","subtitle":"Build running","value":"72%","valueLabel":"Complete","progress":0.72,"status":"active","updatedAt":"2026-11-05T01:00:00.000Z","route":"/","actions":[{"label":"Pricing","route":"/pricing"}]}'
  'no-value' = '{"schema":1,"title":"Starter","subtitle":"All quiet","value":null,"valueLabel":null,"progress":null,"status":"idle","updatedAt":"2026-11-05T01:00:00.000Z","route":"/","actions":[]}'
  'newer-schema' = '{"schema":99,"title":"From the future"}'
  'malformed' = 'not json'
}
foreach ($name in $samples.Keys) {
  $input = Join-Path $OutDir "card-$name-input.json"
  $output = Join-Path $OutDir "card-$name.json"
  [System.IO.File]::WriteAllText($input, $samples[$name])
  $process = Start-Process -FilePath $exe -ArgumentList '--print-card-data', "`"$input`"", "`"$output`"" -PassThru -Wait
  if ($process.ExitCode -eq 0 -and (Test-Path $output)) {
    Log "ok   $name -> $(Get-Content -Raw $output)"
  } else {
    Log "FAIL $name exit=$($process.ExitCode)"
    $failed = $true
  }
}

Log '--- install, best effort: the host of this check has no Widgets Board'
$installed = $false
try {
  Import-Certificate -FilePath (Join-Path $BuildDir 'StarterWidgetsTest.cer') -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null
  $nuget = if ($env:NUGET_PACKAGES) { $env:NUGET_PACKAGES } else { Join-Path $env:USERPROFILE '.nuget\packages' }
  $runtime = Get-ChildItem -Recurse -Path (Join-Path $nuget 'microsoft.windowsappsdk.runtime') -Filter '*x64*.msix' |
    Where-Object { $_.Name -match '^Microsoft\.WindowsAppRuntime\.\d' -and $_.FullName -match 'win10-x64' } | Select-Object -First 1
  Log "runtime framework: $($runtime.Name)"
  Add-AppxPackage -Path $runtime.FullName -ForceApplicationShutdown -ErrorAction Stop
  Add-AppxPackage -Path $msix -ErrorAction Stop
  $package = Get-AppxPackage -Name 'com.example.starter.widgets'
  Log "ok   installed: $($package.PackageFullName)"
  $installed = $true
} catch {
  Log "NOT PROVEN install: $_"
}

if ($installed) {
  Log '--- COM activation, best effort'
  try {
    $object = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]$classId))
    Log "ok   COM activation returned $($object.GetType().FullName)"
    $server = Get-Process -Name 'StarterWidgetProvider' -ErrorAction SilentlyContinue
    Log "provider process: $(if ($server) { "running, pid $($server.Id)" } else { 'not found' })"
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($object)
  } catch {
    Log "NOT PROVEN COM activation: $_"
  }
  Get-Process -Name 'StarterWidgetProvider' -ErrorAction SilentlyContinue | Stop-Process -Force
  Get-AppxPackage -Name 'com.example.starter.widgets' | Remove-AppxPackage -ErrorAction SilentlyContinue
}

Log 'NOT PROVEN by design: pinning a widget, rendering in the Widgets Board, resizing, theme, tapping.'
if ($failed) { exit 1 }
exit 0
