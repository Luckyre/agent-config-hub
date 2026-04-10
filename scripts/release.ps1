[CmdletBinding()]
param(
  [string]$Version,
  [string]$Notes = 'Configuration update'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

function Get-McpServers {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    return @()
  }

  $servers = @()
  $current = $null
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*-\s+name:\s*(.+)\s*$') {
      if ($current) {
        $servers += [pscustomobject]$current
      }
      $current = [ordered]@{
        name = $Matches[1].Trim()
        transport = ''
        command = ''
      }
      continue
    }

    if (-not $current) {
      continue
    }

    if ($line -match '^\s+transport:\s*(.+)\s*$') {
      $current.transport = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s+command:\s*(.+)\s*$') {
      $current.command = $Matches[1].Trim()
      continue
    }
  }

  if ($current) {
    $servers += [pscustomobject]$current
  }

  return $servers
}

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
    if ($entry.Name -eq 'README.md') {
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

function Write-IntegrationCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [hashtable]$Manifest,
    [Parameter(Mandatory = $true)]
    [object[]]$McpServers,
    [Parameter(Mandatory = $true)]
    [object[]]$Plugins,
    [Parameter(Mandatory = $true)]
    [string[]]$SkillItems
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
    "| skills | $($Manifest.skillsVersion) | skills/README.md |",
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
    '## Skills',
    ''
  )

  if ($SkillItems.Count -eq 0) {
    $lines += '- (skills/README.md only)'
  } else {
    foreach ($skill in $SkillItems) {
      $lines += "- $skill"
    }
  }

  $lines += @(
    '',
    '## Release Rule',
    '',
    '- On each release, run scripts/release.ps1 so this catalog stays aligned with the published version tag.'
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

$mcpServers = Get-McpServers -Path (Join-Path $repoRoot 'mcp/servers.yaml')
$plugins = Get-Plugins -Path (Join-Path $repoRoot 'plugins/registry.yaml')
$skillItems = Get-SkillItems -Path (Join-Path $repoRoot 'skills')

$catalogPath = Join-Path $repoRoot 'docs/integration-catalog.md'
Write-IntegrationCatalog -Path $catalogPath -Manifest $manifest -McpServers $mcpServers -Plugins $plugins -SkillItems $skillItems

$mcpSummary = if ($mcpServers.Count -gt 0) { ($mcpServers | ForEach-Object { $_.name }) -join ', ' } else { 'none' }
$pluginSummary = if ($plugins.Count -gt 0) { ($plugins | ForEach-Object { $_.id }) -join ', ' } else { 'none' }
$skillSummary = if ($skillItems.Count -gt 0) { $skillItems -join ', ' } else { '(skills/README.md only)' }

$today = Get-Date -Format 'yyyy-MM-dd'
$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogBlock = @"

## [$Version] - $today

- $Notes
- Integration versions: rules=$($manifest.rulesVersion), mcp=$($manifest.mcpVersion), plugins=$($manifest.pluginsVersion), skills=$($manifest.skillsVersion)
- MCP servers: $mcpSummary
- Plugins: $pluginSummary
- Skills: $skillSummary
- Integration catalog: docs/integration-catalog.md
"@
Add-Content -Encoding UTF8 -Path $changelogPath -Value $changelogBlock

git add manifests/manifest.lock.json CHANGELOG.md docs/integration-catalog.md
$staged = git diff --cached --name-only
if ($staged) {
  git commit -m "release: $Version" | Out-Null
}

$existingTag = git tag --list $Version
if ($existingTag) {
  throw "Tag already exists: $Version"
}
git tag $Version

Write-Output "Release prepared: $Version"
Write-Output "Next: git push origin HEAD --tags"
