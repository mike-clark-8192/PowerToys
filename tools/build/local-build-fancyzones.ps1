<#
.SYNOPSIS
Build FancyZones (Editor + native) locally without a full PowerToys build.

.DESCRIPTION
Builds:
- FancyZonesEditor (WPF) and its managed/native dependencies
- FancyZonesLib, FancyZonesModuleInterface, FancyZones (native)
- FancyZonesCLI (optional)

This script defaults to disabling SourceLink/Git repository queries to avoid failures when the
local repo uses git reftable refs (extensions.refstorage=reftable), which some .NET SDK tasks
do not support yet.

.PARAMETER Platform
Target platform (x64/arm64). If omitted, auto-detects host platform.

.PARAMETER Configuration
Build configuration (Debug/Release). Default: Debug.

.PARAMETER RestoreOnly
If specified, runs restore only (no builds).

.PARAMETER SkipEditor
Skip FancyZonesEditor build.

.PARAMETER SkipNative
Skip native FancyZones builds (Lib/ModuleInterface/FancyZones).

.PARAMETER SkipCLI
Skip FancyZonesCLI build.

.PARAMETER EnableSourceControlManagerQueries
If specified, enables source-control queries (SourceLink / Microsoft.Build.Tasks.Git).
By default these queries are disabled to avoid git reftable compatibility issues.

.PARAMETER ExtraArgs
Extra MSBuild arguments forwarded to all builds.

.EXAMPLE
./tools/build/local-build-fancyzones.ps1

.EXAMPLE
./tools/build/local-build-fancyzones.ps1 -Configuration Release -Platform x64

.EXAMPLE
./tools/build/local-build-fancyzones.ps1 -SkipNative
#>

param (
    [string]$Platform = '',
    [string]$Configuration = 'Debug',
    [switch]$RestoreOnly,
    [switch]$SkipEditor,
    [switch]$SkipNative,
    [switch]$SkipCLI,
    [switch]$EnableSourceControlManagerQueries,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = 'Stop'

# Find repository root starting from the script location.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = $scriptDir
while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot 'PowerToys.slnx'))) {
    $parent = Split-Path -Parent $repoRoot
    if ($parent -eq $repoRoot) {
        Write-Error "Could not find PowerToys repository root (PowerToys.slnx)."
        exit 1
    }

    $repoRoot = $parent
}

# Export script-scope variables used by build-common helpers.
Set-Variable -Name RepoRoot -Value $repoRoot -Scope Script -Force

# Load shared helpers.
. "$PSScriptRoot\build-common.ps1"

# Initialize Visual Studio dev environment.
if (-not (Ensure-VsDevEnvironment)) { exit 1 }

# Auto-detect platform when not provided.
if (-not $Platform -or $Platform -eq '') {
    try {
        $Platform = Get-DefaultPlatform
        Write-Host ("[AUTO-PLATFORM] Detected platform: {0}" -f $Platform)
    } catch {
        Write-Warning "Failed to auto-detect platform; defaulting to x64"
        $Platform = 'x64'
    }
}

$commonExtra = @()
if (-not $EnableSourceControlManagerQueries) {
    $commonExtra += '/p:EnableSourceControlManagerQueries=false'
}

if ($ExtraArgs) {
    $commonExtra += $ExtraArgs
}

$commonExtraString = $commonExtra -join ' '

Write-Host ("[FANCYZONES BUILD] RepoRoot: {0}" -f $repoRoot)
Write-Host ("[FANCYZONES BUILD] Platform: {0}  Configuration: {1}" -f $Platform, $Configuration)
Write-Host ("[FANCYZONES BUILD] RestoreOnly: {0}" -f $RestoreOnly)
Write-Host ("[FANCYZONES BUILD] ExtraArgs: {0}" -f $commonExtraString)

if (-not $SkipEditor) {
    $editorProj = Join-Path $repoRoot 'src\modules\fancyzones\editor\FancyZonesEditor\FancyZonesEditor.csproj'
    Write-Host ("[FANCYZONES BUILD] Building editor: {0}" -f $editorProj)
    RestoreThenBuild $editorProj $commonExtraString $Platform $Configuration $RestoreOnly
}

if (-not $SkipNative) {
    $fzLib = Join-Path $repoRoot 'src\modules\fancyzones\FancyZonesLib\FancyZonesLib.vcxproj'
    $fzIface = Join-Path $repoRoot 'src\modules\fancyzones\FancyZonesModuleInterface\FancyZonesModuleInterface.vcxproj'
    $fzExe = Join-Path $repoRoot 'src\modules\fancyzones\FancyZones\FancyZones.vcxproj'

    # Some native projects expect SolutionDir to be set even when building a single vcxproj.
    $solutionDir = $repoRoot.TrimEnd('\') + '\'
    $nativeExtraString = ($commonExtra + ("/p:SolutionDir=$solutionDir")) -join ' '

    Write-Host ("[FANCYZONES BUILD] Building native lib: {0}" -f $fzLib)
    RestoreThenBuild $fzLib $nativeExtraString $Platform $Configuration $RestoreOnly

    Write-Host ("[FANCYZONES BUILD] Building module interface: {0}" -f $fzIface)
    RestoreThenBuild $fzIface $nativeExtraString $Platform $Configuration $RestoreOnly

    Write-Host ("[FANCYZONES BUILD] Building FancyZones: {0}" -f $fzExe)
    RestoreThenBuild $fzExe $nativeExtraString $Platform $Configuration $RestoreOnly

    if (-not $SkipCLI) {
        $fzCli = Join-Path $repoRoot 'src\modules\fancyzones\FancyZonesCLI\FancyZonesCLI.csproj'
        Write-Host ("[FANCYZONES BUILD] Building CLI: {0}" -f $fzCli)
        RestoreThenBuild $fzCli $commonExtraString $Platform $Configuration $RestoreOnly
    }
}

Write-Host "[FANCYZONES BUILD] Done."
