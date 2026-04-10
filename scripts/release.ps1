[CmdletBinding()]
param(
  [string]$Version,
  [string]$Notes = 'Configuration update',
  [switch]$SkipGit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

. (Join-Path $PSScriptRoot 'release.helpers.ps1')

function Get-Plugins {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return @()
  }

  $plugins = @()
  $current = $null
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*-\s+id:\s*(.+)\s*$') {
      if ($current) {
        $plugins += [pscustomobject]$current
      }
      $current = [ordered]@{
        id = $Matches[1].Trim()
        enabled = ''
        source = ''
      }
      continue
    }

    if (-not $current) {
      continue
    }

    if ($line -match '^\s+enabled:\s*(.+)\s*$') {
      $current.enabled = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s+source:\s*(.+)\s*$') {
      $current.source = $Matches[1].Trim()
      continue
    }
  }

  if ($current) {
    $plugins += [pscustomobject]$current
  }

  return $plugins
}

function Get-SkillItems {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return @()
  }

  $items = @()
  foreach ($entry in Get-ChildItem -LiteralPath $Path | Sort-Object Name) {
    if ($entry.Name -eq 'README.md' -or $entry.Name -eq 'catalog.yaml') {
      continue
    }

    if ($entry.PSIsContainer) {
      $items += "dir:$($entry.Name)"
    } else {
      $items += "file:$($entry.Name)"
    }
  }

  return $items
}

function Get-PreviousReleaseVersion {
  param(
    [string]$CurrentVersion
  )

  $tags = @()
  $remoteHead = (& git rev-parse --verify origin/master 2>$null)
  if ($LASTEXITCODE -eq 0 -and $remoteHead) {
    $tags = @(git tag --merged origin/master --sort=-version:refname)
  }

  if (-not $tags) {
    $tags = @(git tag --sort=-version:refname)
  }

  if (-not $tags) {
    return $null
  }

  foreach ($tag in $tags) {
    if (-not $CurrentVersion -or $tag -ne $CurrentVersion) {
      return $tag
    }
  }

  return $null
}

function Get-TaggedFileLines {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  try {
    $content = & git show "${Tag}:$RelativePath" 2>$null
  } catch {
    return @()
  }

  if ($LASTEXITCODE -ne 0 -or -not $content) {
    return @()
  }

  return @($content -split "`r?`n")
}

function Write-IntegrationCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [hashtable]$Manifest,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$McpServers,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$Plugins,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$SkillsCatalog,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$McpCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$PluginCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$SkillCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$NewCapabilities
  )

  $catalogDir = Split-Path -Path $Path -Parent
  if (-not (Test-Path $catalogDir)) {
    New-Item -ItemType Directory -Path $catalogDir -Force | Out-Null
  }

  $lines = @(
    '# Integration Catalog',
    '',
    "Last Updated (UTC): $($Manifest.generatedAt)",
    "Current Repo Version: $($Manifest.repoVersion)",
    '',
    '## Version Matrix',
    '',
    '| Component | Version | Source |',
    '| --- | --- | --- |',
    "| repo | $($Manifest.repoVersion) | manifests/manifest.lock.json |",
    "| rules | $($Manifest.rulesVersion) | rules/base.md |",
    "| mcp | $($Manifest.mcpVersion) | mcp/servers.yaml |",
    "| plugins | $($Manifest.pluginsVersion) | plugins/registry.yaml |",
    "| skills | $($Manifest.skillsVersion) | skills/catalog.yaml |",
    '',
    '## MCP Servers',
    '',
    '| Name | Transport | Command |',
    '| --- | --- | --- |'
  )

  if ($McpServers.Count -eq 0) {
    $lines += '| - | - | - |'
  } else {
    foreach ($server in $McpServers) {
      $lines += "| $($server.name) | $($server.transport) | $($server.command) |"
    }
  }

  $lines += @(
    '',
    '## Skills Catalog',
    ''
  )

  if ($SkillsCatalog.Count -eq 0) {
    $lines += '- none'
  } else {
    foreach ($skill in $SkillsCatalog) {
      $lines += ('- `{0}` | {1} | {2}' -f $skill.id, $skill.name, $skill.summary)
    }
  }

  $lines += @(
    '',
    '## Plugins',
    '',
    '| ID | Enabled | Source |',
    '| --- | --- | --- |'
  )

  if ($Plugins.Count -eq 0) {
    $lines += '| - | - | - |'
  } else {
    foreach ($plugin in $Plugins) {
      $lines += "| $($plugin.id) | $($plugin.enabled) | $($plugin.source) |"
    }
  }

  $lines += @(
    '',
    (New-CatalogCapabilitySection -Title 'MCP Capabilities' -Capabilities $McpCapabilities),
    '',
    (New-CatalogCapabilitySection -Title 'Plugin Capabilities' -Capabilities $PluginCapabilities),
    '',
    (New-CatalogCapabilitySection -Title 'Skill Capabilities' -Capabilities $SkillCapabilities),
    '',
    (New-ReleaseDiffSection -NewCapabilities $NewCapabilities),
    '',
    '## Release Rule',
    '',
    '- On each release, run `scripts/release.ps1` so this catalog stays aligned with the published version tag.',
    '- NEW badges are computed by comparing the current release against the previous release tag.'
  )

  Set-Content -Encoding UTF8 -Path $Path -Value $lines
}

$scanRoots = @('rules','mcp','plugins','skills','configs')
$files = @()
foreach ($root in $scanRoots) {
  if (Test-Path $root) {
    $files += Get-ChildItem -Path $root -Recurse -File
  }
}
$files = $files | Sort-Object FullName

if (-not $Version) {
  $datePart = Get-Date -Format 'yyyy.MM.dd'
  $prefix = "v$datePart."
  $tags = git tag --list "$prefix*"
  $maxSeq = 0
  foreach ($tag in $tags) {
    $parts = $tag -split '\.'
    if ($parts.Length -ge 4) {
      $candidate = 0
      if ([int]::TryParse($parts[3], [ref]$candidate)) {
        if ($candidate -gt $maxSeq) { $maxSeq = $candidate }
      }
    }
  }
  $Version = "$prefix$($maxSeq + 1)"
}

$manifestEntries = @()
foreach ($file in $files) {
  $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName
  $relative = $file.FullName.Substring($repoRoot.Path.Length + 1).Replace('\\','/')
  $manifestEntries += [ordered]@{
    path = $relative
    sha256 = $hash.Hash.ToLowerInvariant()
  }
}

$manifest = [ordered]@{
  repoVersion = $Version
  generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  rulesVersion = $Version
  mcpVersion = $Version
  pluginsVersion = $Version
  skillsVersion = $Version
  compatibility = [ordered]@{
    tools = @('codex','claudex')
    os = @('windows','macos')
  }
  files = $manifestEntries
}

$manifestPath = Join-Path $repoRoot 'manifests/manifest.lock.json'
$manifest | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $manifestPath

$mcpServers = @(Get-McpServersDetailed -Path (Join-Path $repoRoot 'mcp/servers.yaml'))
$plugins = @(Get-PluginsDetailed -Path (Join-Path $repoRoot 'plugins/registry.yaml'))
$skillsCatalog = @(Get-SkillsCatalog -Path (Join-Path $repoRoot 'skills/catalog.yaml'))
$skillItems = Get-SkillItems -Path (Join-Path $repoRoot 'skills')

$currentCapabilityRecords = @(ConvertTo-CapabilityRecords -McpServers $mcpServers -Plugins $plugins -SkillsCatalog $skillsCatalog)
$previousTag = Get-PreviousReleaseVersion -CurrentVersion $Version
$previousCapabilityRecords = @()
if ($previousTag) {
  $previousMcpLines = @(Get-TaggedFileLines -Tag $previousTag -RelativePath 'mcp/servers.yaml')
  $previousPluginLines = @(Get-TaggedFileLines -Tag $previousTag -RelativePath 'plugins/registry.yaml')
  $previousSkillLines = @(Get-TaggedFileLines -Tag $previousTag -RelativePath 'skills/catalog.yaml')
  $previousMcpServers = @()
  $previousPlugins = @()
  $previousSkillsCatalog = @()
  if ($previousMcpLines.Count -gt 0) {
    $previousMcpServers = @(Convert-LinesToMcpServers -Lines $previousMcpLines)
  }
  if ($previousPluginLines.Count -gt 0) {
    $previousPlugins = @(Convert-LinesToPlugins -Lines $previousPluginLines)
  }
  if ($previousSkillLines.Count -gt 0) {
    $previousSkillsCatalog = @(Convert-LinesToSkillsCatalog -Lines $previousSkillLines)
  }
  $previousCapabilityRecords = @(ConvertTo-CapabilityRecords -McpServers $previousMcpServers -Plugins $previousPlugins -SkillsCatalog $previousSkillsCatalog)
}

$historyPath = Join-Path $repoRoot 'manifests/integration-history.json'
$existingHistory = Read-CapabilityHistory -Path $historyPath
$capabilityDiff = Compare-CapabilitySets -Current $currentCapabilityRecords -Previous $previousCapabilityRecords
$newCapabilities = @($capabilityDiff.New)
$mergedHistory = Merge-CapabilityHistory -Current $currentCapabilityRecords -History $existingHistory -Version $Version -NewCapabilityIds ($newCapabilities | ForEach-Object { $_.id })
Write-CapabilityHistory -Path $historyPath -History $mergedHistory

$inventory = Get-CapabilityInventory -McpServers $mcpServers -Plugins $plugins -SkillsCatalog $skillsCatalog -History $mergedHistory -NewCapabilities $newCapabilities
$mcpCapabilities = @($inventory.McpCapabilities)
$pluginCapabilities = @($inventory.PluginCapabilities)
$skillCapabilities = @($inventory.SkillCapabilities)

$catalogPath = Join-Path $repoRoot 'docs/integration-catalog.md'
Write-IntegrationCatalog -Path $catalogPath -Manifest $manifest -McpServers $mcpServers -Plugins $plugins -SkillsCatalog $skillsCatalog -McpCapabilities $mcpCapabilities -PluginCapabilities $pluginCapabilities -SkillCapabilities $skillCapabilities -NewCapabilities $newCapabilities

$readmePath = Join-Path $repoRoot 'README.md'
$readmeContent = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
$readmeContent = Update-ReadmeReleaseMetadata -Text $readmeContent -Manifest $manifest -Language 'zh'
$readmeCapabilityBlock = New-ReadmeCapabilitySection -McpCapabilities $mcpCapabilities -PluginCapabilities $pluginCapabilities -SkillCapabilities $skillCapabilities
$updatedReadme = Update-ManagedBlock -Text $readmeContent -BeginMarker '<!-- BEGIN:CAPABILITY-CATALOG -->' -EndMarker '<!-- END:CAPABILITY-CATALOG -->' -Replacement $readmeCapabilityBlock -InsertBeforeHeading '## 当前版本映射'
Set-Content -Encoding UTF8 -Path $readmePath -Value $updatedReadme

$readmeEnPath = Join-Path $repoRoot 'README.en.md'
$readmeEnContent = Get-Content -LiteralPath $readmeEnPath -Raw -Encoding UTF8
$readmeEnContent = Update-ReadmeReleaseMetadata -Text $readmeEnContent -Manifest $manifest -Language 'en'
$readmeEnCapabilityBlock = New-ReadmeCapabilitySectionEn -McpCapabilities $mcpCapabilities -PluginCapabilities $pluginCapabilities -SkillCapabilities $skillCapabilities
$updatedReadmeEn = Update-ManagedBlock -Text $readmeEnContent -BeginMarker '<!-- BEGIN:CAPABILITY-CATALOG -->' -EndMarker '<!-- END:CAPABILITY-CATALOG -->' -Replacement $readmeEnCapabilityBlock -InsertBeforeHeading '## Current Version Matrix'
Set-Content -Encoding UTF8 -Path $readmeEnPath -Value $updatedReadmeEn

$mcpSummary = if ($mcpServers.Count -gt 0) { ($mcpServers | ForEach-Object { $_.name }) -join ', ' } else { 'none' }
$pluginSummary = if ($plugins.Count -gt 0) { ($plugins | ForEach-Object { $_.id }) -join ', ' } else { 'none' }
$skillSummary = if ($skillsCatalog.Count -gt 0) { ($skillsCatalog | ForEach-Object { $_.id }) -join ', ' } else { '(skills/catalog.yaml empty)' }
$newCapabilitySummary = if ($newCapabilities.Count -gt 0) { ($newCapabilities | ForEach-Object { $_.id }) -join ', ' } else { 'none' }

$today = Get-Date -Format 'yyyy-MM-dd'
$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogBlock = @"

## [$Version] - $today

- $Notes
- Integration versions: rules=$($manifest.rulesVersion), mcp=$($manifest.mcpVersion), plugins=$($manifest.pluginsVersion), skills=$($manifest.skillsVersion)
- MCP servers: $mcpSummary
- Plugins: $pluginSummary
- Skills: $skillSummary
- New capabilities vs previous release: $newCapabilitySummary
- Integration catalog: docs/integration-catalog.md
"@
Add-Content -Encoding UTF8 -Path $changelogPath -Value $changelogBlock

if (-not $SkipGit) {
  git add manifests/manifest.lock.json manifests/integration-history.json CHANGELOG.md docs/integration-catalog.md README.md README.en.md
  $staged = git diff --cached --name-only
  if ($staged) {
    git commit -m "release: $Version" | Out-Null
  }

  $existingTag = git tag --list $Version
  if ($existingTag) {
    throw "Tag already exists: $Version"
  }
  git tag $Version
}

Write-Output "Release prepared: $Version"
if ($previousTag) {
  Write-Output "Compared against previous tag: $previousTag"
} else {
  Write-Output 'Compared against previous tag: none'
}
if ($SkipGit) {
  Write-Output 'Git commit/tag skipped.'
} else {
  Write-Output 'Next: git push origin HEAD --tags'
}
