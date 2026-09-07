param(
    [Parameter(Mandatory=$true)][string]$BaseZip,
    [Parameter(Mandatory=$true)][string]$FlutterRoot,
    [Parameter(Mandatory=$true)][string]$Destination,
    [string]$Assets = "$PSScriptRoot\..\build\upgraded-assets"
)
$ErrorActionPreference = 'Stop'
# The supplied runner registers geolocator_windows, the only native Windows plugin.
# Dart-only additions need no new runner registration. Rebuild the runner if that changes.
if (Test-Path -LiteralPath $Destination) { throw 'Choose a new output directory.' }
$engine = Join-Path $FlutterRoot 'bin\cache\artifacts\engine\windows-x64-release\flutter_windows.dll'
$icu = Join-Path $PSScriptRoot '..\windows\flutter\ephemeral\icudtl.dat'
foreach ($inputFile in @($BaseZip, $engine, $icu, "$Assets\windows\app.so")) {
    if (!(Test-Path -LiteralPath $inputFile)) { throw "Missing input: $inputFile" }
}
New-Item -ItemType Directory -Path "$Destination\data" -Force | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $BaseZip))
try {
    foreach ($name in @('wingstar.exe', 'geolocator_windows_plugin.dll')) {
        $entry = $archive.GetEntry($name)
        if ($null -eq $entry) { throw "Missing runner component: $name" }
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $Destination $name))
    }
} finally { $archive.Dispose() }
Copy-Item -LiteralPath $engine -Destination $Destination
Copy-Item -LiteralPath $icu -Destination "$Destination\data"
Copy-Item -LiteralPath "$Assets\windows\app.so" -Destination "$Destination\data"
Copy-Item -LiteralPath "$Assets\flutter_assets" -Destination "$Destination\data" -Recurse
Copy-Item -LiteralPath "$PSScriptRoot\..\docs\UPGRADE.md" -Destination "$Destination\읽어주세요.md"
Copy-Item -LiteralPath "$PSScriptRoot\..\assets\fonts\OFL.txt" -Destination "$Destination\FONT-LICENSE.txt"
Compress-Archive -Path "$Destination\*" -DestinationPath "$Destination.zip"
Get-FileHash -LiteralPath "$Destination\data\app.so", "$Destination.zip"
