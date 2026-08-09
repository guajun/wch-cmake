param(
    [string]$Version = "latest",
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [switch]$WithVSCode
)

$ErrorActionPreference = "Stop"
$repository = "guajun/wch-cmake"
$asset = "wch-cmake.zip"
$base = if ($Version -eq "latest") {
    "https://github.com/$repository/releases/latest/download"
} else {
    "https://github.com/$repository/releases/download/$Version"
}

$resolvedProject = (Resolve-Path -LiteralPath $Project).Path
$staging = Join-Path $resolvedProject (".wch-cmake-install-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    $archive = Join-Path $staging $asset
    $checksums = Join-Path $staging "checksums.txt"
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

    Expand-Archive -LiteralPath $archive -DestinationPath $staging -Force
    $entry = Join-Path $staging "wch-cmake\wch-cmake.ps1"
    $arguments = @("import", "-Project", $resolvedProject)
    if ($WithVSCode) {
        $arguments += "-WithVSCode"
    }
    & $entry @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "wch-cmake import failed with exit code $LASTEXITCODE"
    }
    Write-Host "Imported wch-cmake $Version into $resolvedProject"
} finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}
