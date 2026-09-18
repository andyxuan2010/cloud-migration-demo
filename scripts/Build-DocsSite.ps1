[CmdletBinding()]
param(
    [string]$OutputDirectory = "_site"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$docsRoot = Join-Path $repoRoot "docs"
$siteRoot = Join-Path $repoRoot "site"
$outputRoot = Join-Path $repoRoot $OutputDirectory
$templatePath = Join-Path $siteRoot "template.html"
$configPath = Join-Path $siteRoot "site.json"

function Write-Utf8File {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Encode-Html {
    param([AllowEmptyString()] [string]$Value)
    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Convert-InlineMarkdown {
    param(
        [Parameter(Mandatory)] [string]$Text,
        [string]$CurrentRelativePath = ""
    )

    $value = $Text.Trim()
    # The source documentation contains generated anchor and pre tags. Keep their
    # useful text while preventing source HTML from becoming executable markup.
    $value = $value -replace '(?is)<a\b[^>]*>(.*?)</a>', '$1'
    $value = $value -replace '(?is)</?pre\b[^>]*>', ''
    $value = $value -replace '(?is)<br\s*/?>', ' '
    $value = Encode-Html $value

    $value = [regex]::Replace($value, '!\[([^\]]*)\]\(([^)]+)\)', {
        param($match)
        $alt = Encode-Html $match.Groups[1].Value
        $href = $match.Groups[2].Value.Trim()
        $href = $href -replace '\s+"[^"]*"$', ''
        return "<img src=`"$href`" alt=`"$alt`" loading=`"lazy`">"
    })
    $value = [regex]::Replace($value, '\[([^\]]+)\]\(([^)]+)\)', {
        param($match)
        $label = $match.Groups[1].Value
        $href = $match.Groups[2].Value.Trim()
        $href = $href -replace '\s+"[^"]*"$', ''
        if ($href -match '(?i)\.md(?:#.*)?$') {
            if ($href -match '(?i)^(?:\.\./)*README\.md(?:#.*)?$') {
                $href = "../index.html"
            } else {
                $href = $href -replace '(?i)\.md(?=#|$)', '.html'
            }
        }
        return "<a href=`"$href`">$label</a>"
    })
    $value = [regex]::Replace($value, '`([^`]+)`', '<code>$1</code>')
    $value = [regex]::Replace($value, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    $value = [regex]::Replace($value, '(?<!\*)\*([^*]+)\*(?!\*)', '<em>$1</em>')
    return $value
}

function Convert-MarkdownTable {
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [System.Collections.Generic.List[string]]$Rows,
        [string]$CurrentRelativePath = ""
    )

    if ($Rows.Count -lt 2) { return Convert-InlineMarkdown ($Rows -join " ") $CurrentRelativePath }
    $header = $Rows[0].Trim().Trim('|') -split '\s*\|\s*'
    $bodyRows = $Rows | Select-Object -Skip 2
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine('<table><thead><tr>')
    foreach ($cell in $header) {
        [void]$builder.Append("<th>")
        [void]$builder.Append((Convert-InlineMarkdown $cell $CurrentRelativePath))
        [void]$builder.AppendLine('</th>')
    }
    [void]$builder.AppendLine('</tr></thead><tbody>')
    foreach ($row in $bodyRows) {
        [void]$builder.AppendLine('<tr>')
        $cells = $row.Trim().Trim('|') -split '\s*\|\s*'
        foreach ($cell in $cells) {
            [void]$builder.Append("<td>")
            [void]$builder.Append((Convert-InlineMarkdown $cell $CurrentRelativePath))
            [void]$builder.AppendLine('</td>')
        }
        [void]$builder.AppendLine('</tr>')
    }
    [void]$builder.AppendLine('</tbody></table>')
    return $builder.ToString()
}

function Flush-Paragraph {
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory)] [System.Text.StringBuilder]$Builder,
        [string]$CurrentRelativePath = ""
    )
    if ($Lines.Count -eq 0) { return }
    [void]$Builder.Append("<p>")
    [void]$Builder.Append((Convert-InlineMarkdown ($Lines -join " ") $CurrentRelativePath))
    [void]$Builder.AppendLine('</p>')
    $Lines.Clear()
}

function Flush-List {
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [System.Collections.Generic.List[string]]$Items,
        [Parameter(Mandatory)] [System.Text.StringBuilder]$Builder,
        [ref]$ListType,
        [string]$CurrentRelativePath = ""
    )
    if ($Items.Count -eq 0) { return }
    $tag = if ($ListType.Value -eq "ol") { "ol" } else { "ul" }
    [void]$Builder.AppendLine("<$tag>")
    foreach ($item in $Items) {
        [void]$Builder.Append("<li>")
        [void]$Builder.Append((Convert-InlineMarkdown $item $CurrentRelativePath))
        [void]$Builder.AppendLine('</li>')
    }
    [void]$Builder.AppendLine("</$tag>")
    $Items.Clear()
    $ListType.Value = ""
}

function Flush-Table {
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [System.Collections.Generic.List[string]]$Rows,
        [Parameter(Mandatory)] [System.Text.StringBuilder]$Builder,
        [string]$CurrentRelativePath = ""
    )
    if ($Rows.Count -eq 0) { return }
    [void]$Builder.Append((Convert-MarkdownTable $Rows $CurrentRelativePath))
    $Rows.Clear()
}

function Convert-MarkdownToHtml {
    param(
        [Parameter(Mandatory)] [string]$Markdown,
        [string]$CurrentRelativePath = "",
        [switch]$SkipFirstH1
    )

    $lines = $Markdown -split '\r?\n'
    $builder = [System.Text.StringBuilder]::new()
    $paragraph = [System.Collections.Generic.List[string]]::new()
    $items = [System.Collections.Generic.List[string]]::new()
    $tableRows = [System.Collections.Generic.List[string]]::new()
    $listType = ""
    $inCode = $false
    $codeLanguage = ""
    $codeLines = [System.Collections.Generic.List[string]]::new()
    $h1Skipped = $false

    foreach ($line in $lines) {
        if ($inCode) {
            if ($line -match '^\s*```') {
                $languageClass = if ($codeLanguage) { " class=`"language-$([regex]::Replace($codeLanguage.ToLowerInvariant(), '[^a-z0-9-]', ''))`"" } else { "" }
                [void]$builder.Append("<pre><code$languageClass>")
                [void]$builder.Append((Encode-Html ($codeLines -join "`n")))
                [void]$builder.AppendLine('</code></pre>')
                $inCode = $false
                $codeLanguage = ""
                $codeLines.Clear()
            } else {
                $codeLines.Add($line)
            }
            continue
        }

        if ($line -match '^\s*```\s*(.*)$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
            Flush-Table $tableRows $builder $CurrentRelativePath
            $inCode = $true
            $codeLanguage = $Matches[1].Trim()
            continue
        }

        if ($line -match '^\s*$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
            Flush-Table $tableRows $builder $CurrentRelativePath
            continue
        }

        if ($SkipFirstH1 -and -not $h1Skipped -and $line -match '^\s*#\s+(.+?)\s*$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            $h1Skipped = $true
            continue
        }

        if ($line -match '^\s*(#{2,6})\s+(.+?)\s*$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
            Flush-Table $tableRows $builder $CurrentRelativePath
            $level = $Matches[1].Length
            [void]$builder.AppendLine("<h$level>$(Convert-InlineMarkdown $Matches[2] $CurrentRelativePath)</h$level>")
            continue
        }

        if ($line -match '^\s*>\s?(.*)$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
            Flush-Table $tableRows $builder $CurrentRelativePath
            [void]$builder.AppendLine("<blockquote>$(Convert-InlineMarkdown $Matches[1] $CurrentRelativePath)</blockquote>")
            continue
        }

        if ($line.Trim() -match '^(?:\|.*\|)$' -or ($line -split '\|').Count -ge 3) {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
            $tableRows.Add($line)
            continue
        }

        if ($tableRows.Count -gt 0) {
            Flush-Table $tableRows $builder $CurrentRelativePath
        }

        if ($line -match '^\s*([-*+])\s+(.+)$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            if ($listType -and $listType -ne "ul") { Flush-List $items $builder ([ref]$listType) $CurrentRelativePath }
            $listType = "ul"
            $items.Add($Matches[2])
            continue
        }

        if ($line -match '^\s*\d+[.)]\s+(.+)$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            if ($listType -and $listType -ne "ol") { Flush-List $items $builder ([ref]$listType) $CurrentRelativePath }
            $listType = "ol"
            $items.Add($Matches[1])
            continue
        }

        if ($line.Trim() -match '^(---+|\*\*\*+)$') {
            Flush-Paragraph $paragraph $builder $CurrentRelativePath
            Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
            [void]$builder.AppendLine('<hr>')
            continue
        }

        Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
        $paragraph.Add($line.Trim())
    }

    if ($inCode) {
        $languageClass = if ($codeLanguage) { " class=`"language-$([regex]::Replace($codeLanguage.ToLowerInvariant(), '[^a-z0-9-]', ''))`"" } else { "" }
        [void]$builder.Append("<pre><code$languageClass>")
        [void]$builder.Append((Encode-Html ($codeLines -join "`n")))
        [void]$builder.AppendLine('</code></pre>')
    }
    Flush-Paragraph $paragraph $builder $CurrentRelativePath
    Flush-List $items $builder ([ref]$listType) $CurrentRelativePath
    Flush-Table $tableRows $builder $CurrentRelativePath
    return $builder.ToString()
}

function Get-RootPrefix {
    param([string]$RelativeFile)
    $directory = Split-Path -Parent ($RelativeFile -replace '/', '\')
    if (-not $directory) { return "" }
    $segments = @($directory -split '[\\/]+' | Where-Object { $_ })
    return ("../" * $segments.Count)
}

function Get-DocumentTitle {
    param([string]$Markdown, [string]$Fallback)
    $match = [regex]::Match($Markdown, '(?m)^\s*#\s+(.+?)\s*$')
    if ($match.Success) { return ($match.Groups[1].Value.Trim() -replace '[*_`]', '') }
    $formatted = $Fallback -replace '[_-]+', ' '
    return [Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($formatted.ToLowerInvariant())
}

function Get-DocumentSummary {
    param([string]$Markdown, [string]$Title)
    $clean = $Markdown -replace '(?s)<!--.*?-->', ''
    $inCode = $false
    foreach ($line in ($clean -split '\r?\n')) {
        $candidate = $line.Trim()
        if ($candidate -match '^```') { $inCode = -not $inCode; continue }
        if ($inCode -or -not $candidate -or $candidate -match '^#{1,6}\s' -or $candidate -match '^\s*[|>]' -or $candidate -match '^\s*[-*+]\s') { continue }
        $candidate = ($candidate -replace '\[([^]]+)\]\([^)]+\)', '$1' -replace '`', '').Trim()
        if ($candidate.Length -ge 30) {
            if ($candidate.Length -gt 190) { return ($candidate.Substring(0, 187).TrimEnd() + "…") }
            return $candidate
        }
    }
    return "Reference documentation for $Title."
}

function Get-DocumentCategory {
    param([string]$RelativePath, [string]$Title)
    $value = "$RelativePath $Title".ToLowerInvariant()
    if ($value -match 'requirement|readme|overview') {
        return [pscustomobject]@{
            Key = "overview"
            Title = "Start here"
            Description = "Scope, assumptions, requirements, and the recommended small-business migration direction."
            Icon = "◇"
        }
    }
    if ($value -match 'option|decision|comparison') {
        return [pscustomobject]@{
            Key = "options"
            Title = "Options & decisions"
            Description = "Compare identity, endpoint, and hosted-desktop paths with their trade-offs and fit."
            Icon = "▦"
        }
    }
    return [pscustomobject]@{
        Key = "architectures"
        Title = "Target architectures"
        Description = "Review the detailed designs, authentication workflows, controls, and rollout guidance."
        Icon = "⌁"
    }
}

if (-not (Test-Path -LiteralPath $docsRoot)) { throw "Documentation directory not found: $docsRoot" }
if (-not (Test-Path -LiteralPath $templatePath)) { throw "Site template not found: $templatePath" }
if (-not (Test-Path -LiteralPath $configPath)) { throw "Site configuration not found: $configPath" }

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$documents = @(Get-ChildItem -LiteralPath $docsRoot -Recurse -File -Filter "*.md" | Sort-Object FullName)
if ($documents.Count -eq 0) { throw "No Markdown documents found under $docsRoot" }

if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$pages = @(
    foreach ($document in $documents) {
        $relativeSource = [System.IO.Path]::GetRelativePath($docsRoot, $document.FullName).Replace('\', '/')
        $relativeOutput = ([System.IO.Path]::ChangeExtension($relativeSource, ".html")).ToLowerInvariant()
        [pscustomobject]@{
            SourcePath = $document.FullName
            RelativePath = $relativeSource
            OutputPath = $relativeOutput
            Title = Get-DocumentTitle (Get-Content -LiteralPath $document.FullName -Raw) ([System.IO.Path]::GetFileNameWithoutExtension($document.Name))
        }
    }
)
foreach ($page in $pages) {
    $markdown = Get-Content -LiteralPath $page.SourcePath -Raw
    $page | Add-Member -NotePropertyName Summary -NotePropertyValue (Get-DocumentSummary $markdown $page.Title)
    $page | Add-Member -NotePropertyName Html -NotePropertyValue (Convert-MarkdownToHtml $markdown ("docs/" + $page.RelativePath) -SkipFirstH1)
    $category = Get-DocumentCategory $page.RelativePath $page.Title
    $page | Add-Member -NotePropertyName CategoryKey -NotePropertyValue $category.Key
    $page | Add-Member -NotePropertyName CategoryTitle -NotePropertyValue $category.Title
    $page | Add-Member -NotePropertyName CategoryDescription -NotePropertyValue $category.Description
    $page | Add-Member -NotePropertyName CategoryIcon -NotePropertyValue $category.Icon
}
$pages = @($pages | Sort-Object Title)

$navigation = ($pages | ForEach-Object {
    $href = "{{ROOT_PREFIX}}docs/$($_.OutputPath)"
    "<a href=`"$href`">$(Encode-Html $_.Title)</a>"
}) -join "`n        "

$template = Get-Content -LiteralPath $templatePath -Raw
$siteTitle = Encode-Html ([string]$config.title)
$siteDescription = Encode-Html ([string]$config.description)
$eyebrow = Encode-Html ([string]$config.eyebrow)
$repositoryUrl = Encode-Html ([string]$config.repository)
$generatedText = Encode-Html $generatedAt
$assetVersion = [DateTime]::UtcNow.Ticks.ToString()

function Render-Page {
    param(
        [string]$Content,
        [string]$PageTitle,
        [string]$RelativeOutput,
        [bool]$IsHome
    )
    $prefix = Get-RootPrefix $RelativeOutput
    $page = $template.Replace('{{DESCRIPTION}}', $siteDescription)
    $page = $page.Replace('{{PAGE_TITLE}}', (Encode-Html $PageTitle))
    $page = $page.Replace('{{SITE_TITLE}}', $siteTitle)
    $page = $page.Replace('{{EYEBROW}}', $eyebrow)
    $page = $page.Replace('{{GENERATED_AT}}', $generatedText)
    $page = $page.Replace('{{GITHUB_URL}}', $repositoryUrl)
    $page = $page.Replace('{{ASSET_VERSION}}', $assetVersion)
    $page = $page.Replace('{{ROOT_PREFIX}}', $prefix)
    $page = $page.Replace('{{HOME_ACTIVE}}', $(if ($IsHome) { 'active' } else { '' }))
    $page = $page.Replace('{{NAVIGATION}}', ($navigation -replace '\{\{ROOT_PREFIX\}\}', $prefix))
    return $page.Replace('{{CONTENT}}', $Content)
}

$categoryDefinitions = @(
    [pscustomobject]@{ Key = "overview"; Title = "Start here"; Description = "Scope, assumptions, requirements, and the recommended small-business migration direction."; Icon = "◇" },
    [pscustomobject]@{ Key = "options"; Title = "Options & decisions"; Description = "Compare identity, endpoint, and hosted-desktop paths with their trade-offs and fit."; Icon = "▦" },
    [pscustomobject]@{ Key = "architectures"; Title = "Target architectures"; Description = "Review the detailed designs, authentication workflows, controls, and rollout guidance."; Icon = "⌁" }
)
$categoryMarkup = ($categoryDefinitions | ForEach-Object {
    $category = $_
    $categoryPages = @($pages | Where-Object { $_.CategoryKey -eq $category.Key })
    $links = ($categoryPages | ForEach-Object {
        $href = "docs/$($_.OutputPath)"
        "<a class=`"category-card-link`" data-search-card href=`"$href`"><span>$(Encode-Html $_.Title)</span><span aria-hidden=`"true`">↗</span></a>"
    }) -join "`n"
    $countLabel = if ($categoryPages.Count -eq 1) { "1 document →" } else { "$($categoryPages.Count) documents →" }
    "<article class=`"category-card`" data-category=`"$($category.Key)`"><span class=`"category-card-head`"><span class=`"category-icon`" aria-hidden=`"true`">$($category.Icon)</span><strong>$(Encode-Html $category.Title)</strong></span><p>$(Encode-Html $category.Description)</p><span class=`"category-card-links`">$links</span><span class=`"category-meta`" data-count-for=`"$($category.Key)`">$countLabel</span></article>"
}) -join "`n"
$heroLinks = ($pages | Select-Object -First 2 | ForEach-Object {
    "<a class=`"hero-link`" href=`"docs/$($_.OutputPath)`">$(Encode-Html $_.Title) ↗</a>"
}) -join "`n      "
$documentLabel = if ($pages.Count -eq 1) { "1 document" } else { "$($pages.Count) documents" }
$indexContent = @"
<main class="catalog-view">
  <section class="hero">
    <p class="eyebrow">$eyebrow</p>
    <h1>$siteTitle</h1>
    <p class="hero-copy">$siteDescription</p>
    $heroLinks
  </section>
  <div class="catalog-toolbar">
    <form data-search-form role="search">
      <label class="sr-only" for="site-search">Search documentation</label>
      <div class="search-wrap"><input class="search-input" id="site-search" type="search" placeholder="Search documentation" autocomplete="off"></div>
    </form>
    <div class="doc-count">$documentLabel</div>
  </div>
  <section class="category-overview">
    <div class="category-intro">
      <h2 class="catalog-heading">Explore the library</h2>
    <p>Choose a collection to browse requirements, migration options, or detailed target architectures.</p>
    </div>
    <div class="category-grid">
      $categoryMarkup
    </div>
  </section>
  <p class="search-empty" data-search-empty hidden>No documents match your search.</p>
</main>
"@
Write-Utf8File (Join-Path $outputRoot "index.html") (Render-Page $indexContent "Home" "index.html" $true)

foreach ($page in $pages) {
    $prefix = Get-RootPrefix ("docs/" + $page.OutputPath)
    $sourcePath = "docs/$($page.RelativePath)"
    $sourceHref = "$repositoryUrl/blob/main/$sourcePath"
    $content = @"
<main class="reader-view">
  <div class="reader-navigation">
    <a class="back-button" href="${prefix}index.html">← All documents</a>
    <span class="reader-path">$([System.Net.WebUtility]::HtmlEncode($sourcePath))</span>
  </div>
  <article class="reader">
    <div class="reader-tools">
      <span class="file-label">$([System.Net.WebUtility]::HtmlEncode($sourcePath))</span>
      <a class="github-link" href="$sourceHref" target="_blank" rel="noopener">View source on GitHub ↗</a>
    </div>
    <div class="markdown-body">
    $($page.Html)
    </div>
  </article>
</main>
"@
    $destination = Join-Path $outputRoot (Join-Path "docs" ($page.OutputPath -replace '/', '\'))
    Write-Utf8File $destination (Render-Page $content $page.Title ("docs/" + $page.OutputPath) $false)
}

$searchIndex = @($pages | ForEach-Object {
    [ordered]@{
        title = $_.Title
        path = "docs/$($_.OutputPath)"
        summary = $_.Summary
    }
}) | ConvertTo-Json -Depth 4
Write-Utf8File (Join-Path $outputRoot "search-index.json") ($searchIndex + "`n")
Copy-Item -LiteralPath (Join-Path $siteRoot "styles.css") -Destination (Join-Path $outputRoot "styles.css")
Copy-Item -LiteralPath (Join-Path $siteRoot "site.js") -Destination (Join-Path $outputRoot "site.js")
foreach ($asset in Get-ChildItem -LiteralPath $docsRoot -Recurse -File | Where-Object { $_.Extension -notmatch '^\.md$' }) {
    $relativeAsset = [System.IO.Path]::GetRelativePath($docsRoot, $asset.FullName)
    $destinationAsset = Join-Path $outputRoot (Join-Path "docs" ($relativeAsset -replace '/', '\'))
    $destinationDirectory = Split-Path -Parent $destinationAsset
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Copy-Item -LiteralPath $asset.FullName -Destination $destinationAsset -Force
}
Write-Utf8File (Join-Path $outputRoot ".nojekyll") ""

Write-Host "Built documentation site with $($pages.Count) pages at $outputRoot"
