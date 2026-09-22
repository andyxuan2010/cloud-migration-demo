[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$documents = git -C $repoRoot ls-files --cached --others --exclude-standard |
    Where-Object { Test-Path -LiteralPath (Join-Path $repoRoot $_) } |
    Where-Object { $_ -match '\.md$' } |
    Sort-Object |
    ForEach-Object { $_ -replace '\\', '/' }

$documentHashes = $documents | ForEach-Object {
    $path = Join-Path $repoRoot $_
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    "$_`:$hash"
}
$hashInput = $documentHashes -join "`n"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $contentHash = [BitConverter]::ToString(
        $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($hashInput))
    ).Replace('-', '').ToLowerInvariant()
} finally {
    $sha256.Dispose()
}

$existingManifestPath = Join-Path $repoRoot "docs-manifest.json"
$existingManifest = if (Test-Path -LiteralPath $existingManifestPath -PathType Leaf) {
    try { Get-Content -LiteralPath $existingManifestPath -Raw | ConvertFrom-Json } catch { $null }
} else { $null }
$generatedAt = if ($existingManifest -and $existingManifest.contentHash -eq $contentHash) {
    if ($existingManifest.generatedAt -is [datetime]) {
        $existingManifest.generatedAt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } else {
        [string]$existingManifest.generatedAt
    }
} else {
    (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$manifest = [ordered]@{
    documents   = @($documents)
    generatedAt = $generatedAt
    contentHash = $contentHash
}

$json = ($manifest | ConvertTo-Json -Depth 3) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText(
    (Join-Path $repoRoot "docs-manifest.json"),
    $json + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Wrote docs-manifest.json with $($documents.Count) documentation files."
