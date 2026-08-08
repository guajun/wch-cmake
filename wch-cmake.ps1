[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("import", "verify", "help")]
    [string]$Command = "help",

    [string]$Project = ".",
    [string]$BuildDir = "obj",
    [string]$MrsBuild = "obj",
    [string]$CMakeBuild = "build/release",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if ($Command -eq "help") {
    @"
wch-cmake generates a standalone CMake build from an MRS2-generated makefile.

Usage:
  .\wch-cmake.ps1 import -Project PATH [-BuildDir obj] [-Force]
  .\wch-cmake.ps1 verify -Project PATH [-MrsBuild obj] [-CMakeBuild build/release]

The command is a script. It does not install or execute a wch-cmake binary.
"@ | Write-Output
    exit 0
}

$resolvedProject = (Resolve-Path -LiteralPath $Project).Path
$cmakeArguments = @("-DWCH_PROJECT=$resolvedProject")
switch ($Command) {
    "import" {
        $cmakeArguments += "-DWCH_BUILD_DIR=$BuildDir"
        $cmakeArguments += "-DWCH_FORCE=$($Force.IsPresent)"
        $cmakeArguments += @("-P", (Join-Path $PSScriptRoot "scripts\import.cmake"))
    }
    "verify" {
        $cmakeArguments += "-DWCH_MRS_BUILD=$MrsBuild"
        $cmakeArguments += "-DWCH_CMAKE_BUILD=$CMakeBuild"
        $cmakeArguments += @("-P", (Join-Path $PSScriptRoot "scripts\verify.cmake"))
    }
}

& cmake @cmakeArguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
