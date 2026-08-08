param(
    [string]$Version = "latest",
    [string]$Project = "",
    [string]$InstallDirectory = "$env:LOCALAPPDATA\wch-cmake"
)

$ErrorActionPreference = "Stop"
$repository = "guajun/wch-cmake"
$asset = "wch-cmake.zip"
$base = if ($Version -eq "latest") {
    "https://github.com/$repository/releases/latest/download"
} else {
    "https://github.com/$repository/releases/download/$Version"
}

$temporary = Join-Path ([System.IO.Path]::GetTempPath()) ("wch-cmake-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    $archive = Join-Path $temporary $asset
    $checksums = Join-Path $temporary "checksums.txt"
    Invoke-WebRequest "$base/$asset" -OutFile $archive
    Invoke-WebRequest "$base/checksums.txt" -OutFile $checksums
    $checksumLine = Get-Content $checksums |
        Where-Object { $_ -match [regex]::Escape($asset) } |
        Select-Object -First 1
    if (-not $checksumLine) {
        throw "Release checksum does not contain $asset"
    }
    $expected = $checksumLine.Split()[0]
    $actual = (Get-FileHash -Algorithm SHA256 $archive).Hash
    if ($actual -ne $expected) {
        throw "Release checksum verification failed"
    }

    Expand-Archive -LiteralPath $archive -DestinationPath $temporary -Force
    $source = Join-Path $temporary "wch-cmake"
    New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
    Copy-Item -Path (Join-Path $source "*") -Destination $InstallDirectory -Recurse -Force
    $entry = Join-Path $InstallDirectory "wch-cmake.ps1"
    Write-Host "Installed wch-cmake scripts at $InstallDirectory"
    if ($Project) {
        & $entry import -Project $Project
    }
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue
}
