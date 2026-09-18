[CmdletBinding()]
param(
    [string]$OutputDirectory = "_site"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$docsRoot = Join-Path $repoRoot "docs"
$outputRoot = Join-Path $repoRoot $OutputDirectory
$requiredFiles = @("index.html", "styles.css", "site.js", "search-index.json", ".nojekyll")

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $outputRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Generated documentation site is missing $relativePath"
    }
}

$documents = @(Get-ChildItem -LiteralPath $docsRoot -Recurse -File -Filter "*.md")
foreach ($document in $documents) {
    $relativeSource = [System.IO.Path]::GetRelativePath($docsRoot, $document.FullName).Replace('\', '/')
    $relativeOutput = ([System.IO.Path]::ChangeExtension($relativeSource, ".html")).ToLowerInvariant()
    $outputPath = Join-Path $outputRoot (Join-Path "docs" ($relativeOutput -replace '/', '\'))
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
        throw "Generated documentation page is missing for $relativeSource"
    }
}

$index = Get-Content -LiteralPath (Join-Path $outputRoot "index.html") -Raw
if ($index -notmatch '<title>[^<]+Cloud Migration Demo</title>') { throw "Generated index.html has an unexpected title" }
if ($index -notmatch 'data-search-card') { throw "Generated index.html has no documentation cards" }
if ($index -match '\{\{[A-Z_]+\}\}') { throw "Generated index.html contains an unresolved template token" }

$sourceAssets = @(Get-ChildItem -LiteralPath $docsRoot -Recurse -File | Where-Object { $_.Extension -notmatch '^\.md$' })
foreach ($asset in $sourceAssets) {
    $relativeAsset = [System.IO.Path]::GetRelativePath($docsRoot, $asset.FullName)
    $outputAsset = Join-Path $outputRoot (Join-Path "docs" ($relativeAsset -replace '/', '\'))
    if (-not (Test-Path -LiteralPath $outputAsset -PathType Leaf)) {
        throw "Generated documentation site is missing asset $relativeAsset"
    }
}

Write-Host "Documentation site validation passed for $($documents.Count) Markdown documents."
