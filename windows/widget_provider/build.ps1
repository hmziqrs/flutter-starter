# Builds the Widgets Board provider and packs it into an MSIX, separately from
# `flutter build windows`. Needs the .NET 8 SDK and the Windows SDK.
#
#   windows/widget_provider/build.ps1 -OutDir build/widget_provider
#
# The MSIX is unsigned unless you pass -Sign, which makes a throwaway certificate
# so that a test machine can install it. A real release needs your own certificate,
# and its subject in -Publisher.

param(
  [Parameter(Mandatory = $true)][string]$OutDir,
  [string]$Publisher = 'CN=Starter Test',
  [switch]$Sign
)

$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
$publish = Join-Path $OutDir 'publish'
$layout = Join-Path $OutDir 'layout'
$msix = Join-Path $OutDir 'StarterWidgets.msix'
Remove-Item -Recurse -Force $OutDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

dotnet publish (Join-Path $project 'StarterWidgetProvider.csproj') -c Release -o $publish `
  -p:Platform=x64 --nologo
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed: $LASTEXITCODE" }

# The manifest depends on the runtime this NuGet version ships, so read its identity
# from the framework MSIX in the restored package rather than repeating it here.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$nuget = if ($env:NUGET_PACKAGES) { $env:NUGET_PACKAGES } else { Join-Path $env:USERPROFILE '.nuget\packages' }
$runtimeMsix = Get-ChildItem -Recurse -Path (Join-Path $nuget 'microsoft.windowsappsdk.runtime') -Filter '*x64*.msix' |
  Where-Object { $_.Name -match '^Microsoft\.WindowsAppRuntime\.\d' -and $_.FullName -match 'win10-x64' } |
  Select-Object -First 1
if (-not $runtimeMsix) { throw "No Windows App Runtime framework MSIX found under $nuget" }
Write-Host "Runtime framework: $($runtimeMsix.FullName)"
$zip = [System.IO.Compression.ZipFile]::OpenRead($runtimeMsix.FullName)
try {
  $reader = New-Object System.IO.StreamReader($zip.GetEntry('AppxManifest.xml').Open())
  [xml]$runtimeManifest = $reader.ReadToEnd()
  $reader.Dispose()
} finally {
  $zip.Dispose()
}
$identity = $runtimeManifest.Package.Identity
Write-Host "Runtime identity: $($identity.Name) $($identity.Version) $($identity.Publisher)"

New-Item -ItemType Directory -Force -Path $layout | Out-Null
Copy-Item -Recurse -Path (Join-Path $publish '*') -Destination $layout
Copy-Item -Recurse -Path (Join-Path $project 'Package\Assets') -Destination $layout
New-Item -ItemType Directory -Force -Path (Join-Path $layout 'Public') | Out-Null
Set-Content -Path (Join-Path $layout 'Public\.keep') -Value '' -Encoding ASCII

$manifest = Get-Content -Raw -Path (Join-Path $project 'Package\AppxManifest.xml')
$manifest = $manifest.Replace('__PUBLISHER__', $Publisher).
  Replace('__RUNTIME_NAME__', $identity.Name).
  Replace('__RUNTIME_VERSION__', $identity.Version).
  Replace('__RUNTIME_PUBLISHER__', $identity.Publisher)
[System.IO.File]::WriteAllText((Join-Path $layout 'AppxManifest.xml'), $manifest, (New-Object System.Text.UTF8Encoding($false)))

$kits = 'C:\Program Files (x86)\Windows Kits\10\bin'
$tools = Get-ChildItem -Path $kits -Directory -Filter '10.*' | Sort-Object Name -Descending |
  ForEach-Object { Join-Path $_.FullName 'x64' } |
  Where-Object { Test-Path (Join-Path $_ 'makeappx.exe') } | Select-Object -First 1
if (-not $tools) { throw "makeappx.exe not found under $kits" }

& (Join-Path $tools 'makeappx.exe') pack /o /d $layout /p $msix
if ($LASTEXITCODE -ne 0) { throw "makeappx failed: $LASTEXITCODE" }

if ($Sign) {
  $certificate = New-SelfSignedCertificate -Type Custom -Subject $Publisher `
    -KeyUsage DigitalSignature -CertStoreLocation 'Cert:\CurrentUser\My' `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
  & (Join-Path $tools 'signtool.exe') sign /fd SHA256 /sha1 $certificate.Thumbprint $msix
  if ($LASTEXITCODE -ne 0) { throw "signtool failed: $LASTEXITCODE" }
  Export-Certificate -Cert $certificate -FilePath (Join-Path $OutDir 'StarterWidgetsTest.cer') | Out-Null
}

Write-Host "Packed $msix"
