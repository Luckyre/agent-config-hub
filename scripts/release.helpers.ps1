$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Convert-LinesToMcpServers {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Lines
  )

  $servers = @()
  $currentServer = $null
  $currentCapability = $null
  $inArgs = $false
  $inCapabilities = $false

  foreach ($line in $Lines) {
    if ($line -match '^\s*-\s+name:\s*(.+?)\s*$') {
      if ($currentCapability) {
        $currentServer.capabilities += [pscustomobject]$currentCapability
        $currentCapability = $null
      }
      if ($currentServer) {
        $servers += [pscustomobject]$currentServer
      }
      $currentServer = [ordered]@{
        name = $Matches[1].Trim()
        transport = ''
        command = ''
        args = @()
        capabilities = @()
      }
      $inArgs = $false
      $inCapabilities = $false
      continue
    }

    if (-not $currentServer) {
      continue
    }

    if ($line -match '^\s+transport:\s*(.+?)\s*$') {
      $currentServer.transport = $Matches[1].Trim()
      $inArgs = $false
      continue
    }

    if ($line -match '^\s+command:\s*(.+?)\s*$') {
      $currentServer.command = $Matches[1].Trim()
      $inArgs = $false
      continue
    }

    if ($line -match '^\s+args:\s*$') {
      $inArgs = $true
      $inCapabilities = $false
      continue
    }

    if ($line -match '^\s+capabilities:\s*$') {
      $inArgs = $false
      $inCapabilities = $true
      continue
    }

    if ($inArgs -and $line -match '^\s+-\s+(.+?)\s*$') {
      $currentServer.args += $Matches[1].Trim()
      continue
    }

    if ($inCapabilities -and $line -match '^\s+-\s+id:\s*(.+?)\s*$') {
      if ($currentCapability) {
        $currentServer.capabilities += [pscustomobject]$currentCapability
      }
      $currentCapability = [ordered]@{
        id = $Matches[1].Trim()
        label = ''
        summary = ''
      }
      continue
    }

    if ($currentCapability -and $line -match '^\s+label:\s*(.+?)\s*$') {
      $currentCapability.label = $Matches[1].Trim()
      continue
    }

    if ($currentCapability -and $line -match '^\s+summary:\s*(.+?)\s*$') {
      $currentCapability.summary = $Matches[1].Trim()
      continue
    }
  }

  if ($currentCapability) {
    $currentServer.capabilities += [pscustomobject]$currentCapability
  }

  if ($currentServer) {
    $servers += [pscustomobject]$currentServer
  }

  return @($servers)
}

function Get-McpServersDetailed {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  return @(Convert-LinesToMcpServers -Lines (Get-Content -LiteralPath $Path))
}

function Convert-LinesToPlugins {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Lines
  )

  $plugins = @()
  $currentPlugin = $null
  $currentCapability = $null

  foreach ($line in $Lines) {
    if ($line -match '^\s{2}-\s+id:\s*(.+?)\s*$') {
      if ($currentCapability) {
        $currentPlugin.capabilities += [pscustomobject]$currentCapability
        $currentCapability = $null
      }
      if ($currentPlugin) {
        $plugins += [pscustomobject]$currentPlugin
      }
      $currentPlugin = [ordered]@{
        id = $Matches[1].Trim()
        enabled = ''
        source = ''
        capabilities = @()
      }
      continue
    }

    if ($line -match '^\s{6}-\s+id:\s*(.+?)\s*$') {
      if ($currentCapability) {
        $currentPlugin.capabilities += [pscustomobject]$currentCapability
      }
      $currentCapability = [ordered]@{
        id = $Matches[1].Trim()
        label = ''
        summary = ''
      }
      continue
    }

    if (-not $currentPlugin) {
      continue
    }

    if ($line -match '^\s{4}enabled:\s*(.+?)\s*$') {
      $currentPlugin.enabled = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s{4}source:\s*(.+?)\s*$') {
      $currentPlugin.source = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s{4}capabilities:\s*$') {
      continue
    }

    if ($currentCapability -and $line -match '^\s{8}label:\s*(.+?)\s*$') {
      $currentCapability.label = $Matches[1].Trim()
      continue
    }

    if ($currentCapability -and $line -match '^\s{8}summary:\s*(.+?)\s*$') {
      $currentCapability.summary = $Matches[1].Trim()
      continue
    }
  }

  if ($currentCapability) {
    $currentPlugin.capabilities += [pscustomobject]$currentCapability
  }

  if ($currentPlugin) {
    $plugins += [pscustomobject]$currentPlugin
  }

  return @($plugins)
}

function Get-PluginsDetailed {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  return @(Convert-LinesToPlugins -Lines (Get-Content -LiteralPath $Path))
}

function Convert-LinesToSkillsCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Lines
  )

  $skills = @()
  $currentSkill = $null
  $currentCapability = $null

  foreach ($line in $Lines) {
    if ($line -match '^\s{2}-\s+id:\s*(.+?)\s*$') {
      if ($currentCapability) {
        $currentSkill.capabilities += [pscustomobject]$currentCapability
        $currentCapability = $null
      }
      if ($currentSkill) {
        $skills += [pscustomobject]$currentSkill
      }
      $currentSkill = [ordered]@{
        id = $Matches[1].Trim()
        name = ''
        source = ''
        summary = ''
        capabilities = @()
      }
      continue
    }

    if ($line -match '^\s{6}-\s+id:\s*(.+?)\s*$') {
      if ($currentCapability) {
        $currentSkill.capabilities += [pscustomobject]$currentCapability
      }
      $currentCapability = [ordered]@{
        id = $Matches[1].Trim()
        label = ''
        summary = ''
      }
      continue
    }

    if (-not $currentSkill) {
      continue
    }

    if ($line -match '^\s{4}name:\s*(.+?)\s*$') {
      $currentSkill.name = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s{4}source:\s*(.+?)\s*$') {
      $currentSkill.source = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s{4}summary:\s*(.+?)\s*$') {
      $currentSkill.summary = $Matches[1].Trim()
      continue
    }

    if ($currentCapability -and $line -match '^\s{8}summary:\s*(.+?)\s*$') {
        $currentCapability.summary = $Matches[1].Trim()
      continue
    }

    if ($line -match '^\s{4}capabilities:\s*$') {
      continue
    }

    if ($currentCapability -and $line -match '^\s{8}label:\s*(.+?)\s*$') {
      $currentCapability.label = $Matches[1].Trim()
      continue
    }
  }

  if ($currentCapability) {
    $currentSkill.capabilities += [pscustomobject]$currentCapability
  }

  if ($currentSkill) {
    $skills += [pscustomobject]$currentSkill
  }

  return @($skills)
}

function Get-SkillsCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  return @(Convert-LinesToSkillsCatalog -Lines (Get-Content -LiteralPath $Path))
}

function Compare-CapabilitySets {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$Current,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$Previous
  )

  $previousIds = @{}
  foreach ($item in $Previous) {
    $previousIds[$item.id] = $true
  }

  $newItems = @()
  $existingItems = @()
  foreach ($item in $Current) {
    if ($previousIds.ContainsKey($item.id)) {
      $existingItems += $item
    } else {
      $newItems += $item
    }
  }

  return @{
    New = $newItems
    Existing = $existingItems
  }
}

function Merge-CapabilityHistory {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$Current,
    [Parameter(Mandatory = $true)]
    [hashtable]$History,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string[]]$NewCapabilityIds = @()
  )

  $merged = @{}
  $newIdSet = @{}
  foreach ($id in $NewCapabilityIds) {
    $newIdSet[$id] = $true
  }

  foreach ($key in $History.Keys) {
    $merged[$key] = $History[$key]
  }

  foreach ($item in $Current) {
    if (-not $merged.ContainsKey($item.id)) {
      $merged[$item.id] = [ordered]@{
        id = $item.id
        label = $item.label
        summary = $item.summary
        kind = $item.kind
        owner = $item.owner
        ownerSource = $item.ownerSource
        introducedIn = $Version
      }
      continue
    }

    $existing = $merged[$item.id]
    $existing.label = $item.label
    $existing.summary = $item.summary
    $existing.kind = $item.kind
    $existing.owner = $item.owner
    $existing.ownerSource = $item.ownerSource
    if ($newIdSet.ContainsKey($item.id) -or -not $existing.introducedIn) {
      $existing.introducedIn = $Version
    }
  }

  return $merged
}

function ConvertTo-CapabilityRecords {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$McpServers,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$Plugins,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$SkillsCatalog
  )

  $items = @()

  foreach ($server in $McpServers) {
    foreach ($capability in $server.capabilities) {
      $items += [pscustomobject]@{
        id = $capability.id
        label = $capability.label
        summary = $capability.summary
        kind = 'mcp'
        owner = $server.name
        ownerSource = 'mcp/servers.yaml'
      }
    }
  }

  foreach ($plugin in $Plugins) {
    foreach ($capability in $plugin.capabilities) {
      $items += [pscustomobject]@{
        id = $capability.id
        label = $capability.label
        summary = $capability.summary
        kind = 'plugin'
        owner = $plugin.id
        ownerSource = 'plugins/registry.yaml'
      }
    }
  }

  foreach ($skill in $SkillsCatalog) {
    foreach ($capability in $skill.capabilities) {
      $items += [pscustomobject]@{
        id = $capability.id
        label = $capability.label
        summary = $capability.summary
        kind = 'skill'
        owner = $skill.name
        ownerSource = $skill.source
      }
    }
  }

  return @($items)
}

function Get-CapabilityInventory {
  param(
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
    [hashtable]$History,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$NewCapabilities
  )

  $newIds = @{}
  foreach ($item in $NewCapabilities) {
    $newIds[$item.id] = $true
  }

  $mcpCapabilities = @()
  foreach ($server in $McpServers) {
    foreach ($capability in $server.capabilities) {
      $historyItem = $History[$capability.id]
      $mcpCapabilities += [pscustomobject]@{
        id = $capability.id
        owner = $server.name
        ownerSource = 'mcp/servers.yaml'
        label = $capability.label
        summary = $capability.summary
        kind = 'mcp'
        introducedIn = $historyItem.introducedIn
        isNew = $newIds.ContainsKey($capability.id)
      }
    }
  }

  $pluginCapabilities = @()
  foreach ($plugin in $Plugins) {
    foreach ($capability in $plugin.capabilities) {
      $historyItem = $History[$capability.id]
      $pluginCapabilities += [pscustomobject]@{
        id = $capability.id
        owner = $plugin.id
        ownerSource = 'plugins/registry.yaml'
        label = $capability.label
        summary = $capability.summary
        kind = 'plugin'
        introducedIn = $historyItem.introducedIn
        isNew = $newIds.ContainsKey($capability.id)
      }
    }
  }

  $skillCapabilities = @()
  foreach ($skill in $SkillsCatalog) {
    foreach ($capability in $skill.capabilities) {
      $historyItem = $History[$capability.id]
      $skillCapabilities += [pscustomobject]@{
        id = $capability.id
        owner = $skill.name
        ownerId = $skill.id
        ownerSource = $skill.source
        label = $capability.label
        summary = $capability.summary
        kind = 'skill'
        introducedIn = $historyItem.introducedIn
        isNew = $newIds.ContainsKey($capability.id)
      }
    }
  }

  return @{
    McpCapabilities = @($mcpCapabilities | Sort-Object owner, label)
    PluginCapabilities = @($pluginCapabilities | Sort-Object owner, label)
    SkillCapabilities = @($skillCapabilities | Sort-Object owner, label)
  }
}

function Render-CapabilityBadge {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$IsNew
  )

  if ($IsNew) {
    return '<span style="color:#d9480f;font-weight:600;">NEW</span>'
  }

  return ''
}

function Format-CapabilityLine {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Capability
  )

  $badge = Render-CapabilityBadge -IsNew $Capability.isNew
  $suffix = if ($badge) { " $badge" } else { '' }
  return ('- `[{0}]` {1}{2}: {3} (`introduced: {4}`)' -f $Capability.owner, $Capability.label, $suffix, $Capability.summary, $Capability.introducedIn)
}

function New-VersionMatrixTable {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Manifest,
    [Parameter(Mandatory = $true)]
    [ValidateSet('zh','en')]
    [string]$Language
  )

  if ($Language -eq 'zh') {
    $lines = @(
      '| 组件 | 版本 |',
      '| --- | --- |'
    )
  } else {
    $lines = @(
      '| Component | Version |',
      '| --- | --- |'
    )
  }

  $lines += @(
    "| repo | $($Manifest.repoVersion) |",
    "| rules | $($Manifest.rulesVersion) |",
    "| mcp | $($Manifest.mcpVersion) |",
    "| plugins | $($Manifest.pluginsVersion) |",
    "| skills | $($Manifest.skillsVersion) |"
  )

  return ($lines -join [Environment]::NewLine)
}

function Update-ReadmeReleaseMetadata {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [Parameter(Mandatory = $true)]
    [hashtable]$Manifest,
    [Parameter(Mandatory = $true)]
    [ValidateSet('zh','en')]
    [string]$Language
  )

  $updated = $Text
  $updated = $updated -replace '\\\.\\scripts\\release\.ps1', '.\scripts\release.ps1'
  $updated = $updated -replace '(?<=\.\\scripts\\sync\.ps1 -TargetVersion )v\d{4}\.\d{2}\.\d{2}\.\d+', $Manifest.repoVersion

  if ($Language -eq 'zh') {
    $heading = '## 当前版本映射'
  } else {
    $heading = '## Current Version Matrix'
  }

  $pattern = '(?ms)(' + [regex]::Escape($heading) + '\s*\r?\n\r?\n).*?(?=\r?\n## |\z)'
  $replacement = '$1' + (New-VersionMatrixTable -Manifest $Manifest -Language $Language)
  return [regex]::Replace($updated, $pattern, $replacement, 1)
}

function New-ReadmeCapabilitySection {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$McpCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$PluginCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$SkillCapabilities
  )

  $lines = @(
    '<!-- BEGIN:CAPABILITY-CATALOG -->',
    '',
    '### MCP 能力枚举',
    ''
  )

  if ($McpCapabilities.Count -eq 0) {
    $lines += '- 暂无结构化 MCP 能力项。'
  } else {
    foreach ($item in $McpCapabilities) {
      $lines += Format-CapabilityLine -Capability $item
    }
  }

  $lines += @(
    '',
    '### Plugins 能力枚举',
    ''
  )

  if ($PluginCapabilities.Count -eq 0) {
    $lines += '- 暂无结构化 Plugin 能力项。'
  } else {
    foreach ($item in $PluginCapabilities) {
      $lines += Format-CapabilityLine -Capability $item
    }
  }

  $lines += @(
    '',
    '### Skills 能力枚举',
    ''
  )

  if ($SkillCapabilities.Count -eq 0) {
    $lines += '- 暂无托管 Skills 能力项。'
  } else {
    foreach ($item in $SkillCapabilities) {
      $lines += Format-CapabilityLine -Capability $item
    }
  }

  $lines += @(
    '',
    '> 标记说明：带有 `<span style="color:#d9480f;font-weight:600;">NEW</span>` 的能力表示“相对上一个 release tag 本次刚新增”。',
    '',
    '<!-- END:CAPABILITY-CATALOG -->'
  )

  return ($lines -join [Environment]::NewLine)
}

function New-ReadmeCapabilitySectionEn {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$McpCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$PluginCapabilities,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$SkillCapabilities
  )

  $lines = @(
    '<!-- BEGIN:CAPABILITY-CATALOG -->',
    '',
    '### MCP Capabilities',
    ''
  )

  if ($McpCapabilities.Count -eq 0) {
    $lines += '- No structured MCP capabilities.'
  } else {
    foreach ($item in $McpCapabilities) {
      $lines += Format-CapabilityLine -Capability $item
    }
  }

  $lines += @(
    '',
    '### Plugin Capabilities',
    ''
  )

  if ($PluginCapabilities.Count -eq 0) {
    $lines += '- No structured plugin capabilities.'
  } else {
    foreach ($item in $PluginCapabilities) {
      $lines += Format-CapabilityLine -Capability $item
    }
  }

  $lines += @(
    '',
    '### Skill Capabilities',
    ''
  )

  if ($SkillCapabilities.Count -eq 0) {
    $lines += '- No managed skill capabilities.'
  } else {
    foreach ($item in $SkillCapabilities) {
      $lines += Format-CapabilityLine -Capability $item
    }
  }

  $lines += @(
    '',
    '> Badge rule: items marked with `<span style="color:#d9480f;font-weight:600;">NEW</span>` were introduced in this release compared with the previous release tag.',
    '',
    '<!-- END:CAPABILITY-CATALOG -->'
  )

  return ($lines -join [Environment]::NewLine)
}

function New-CatalogCapabilitySection {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Title,
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$Capabilities
  )

  $lines = @(
    "## $Title",
    ''
  )

  if ($Capabilities.Count -eq 0) {
    $lines += '- none'
    return ($lines -join [Environment]::NewLine)
  }

  foreach ($item in $Capabilities) {
    $badge = Render-CapabilityBadge -IsNew $item.isNew
    $suffix = if ($badge) { " $badge" } else { '' }
    $lines += ('- `[{0}]` **{1}**{2}' -f $item.owner, $item.label, $suffix)
    $lines += ('  - id: `{0}`' -f $item.id)
    $lines += ('  - summary: {0}' -f $item.summary)
    $lines += ('  - introduced: `{0}`' -f $item.introducedIn)
  }

  return ($lines -join [Environment]::NewLine)
}

function New-ReleaseDiffSection {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$NewCapabilities
  )

  $lines = @(
    '## Release Diff Summary',
    ''
  )

  if ($NewCapabilities.Count -eq 0) {
    $lines += '- No newly introduced MCP or Skill capabilities in this release.'
    return ($lines -join [Environment]::NewLine)
  }

  foreach ($item in ($NewCapabilities | Sort-Object kind, owner, label)) {
    $kindLabel = if ($item.kind -eq 'mcp') { 'MCP' } elseif ($item.kind -eq 'plugin') { 'Plugin' } else { 'Skill' }
    $lines += ('- [{0}] `{1}` -> `{2}` {3}' -f $kindLabel, $item.owner, $item.label, (Render-CapabilityBadge -IsNew $true))
  }

  return ($lines -join [Environment]::NewLine)
}

function Update-ManagedBlock {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [Parameter(Mandatory = $true)]
    [string]$BeginMarker,
    [Parameter(Mandatory = $true)]
    [string]$EndMarker,
    [Parameter(Mandatory = $true)]
    [string]$Replacement,
    [string]$InsertBeforeHeading
  )

  $escapedBegin = [regex]::Escape($BeginMarker)
  $escapedEnd = [regex]::Escape($EndMarker)
  $pattern = "$escapedBegin[\s\S]*?$escapedEnd"
  if ([regex]::IsMatch($Text, $pattern)) {
    return [regex]::Replace($Text, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $Replacement }, 1)
  }

  if ($InsertBeforeHeading) {
    $headingPattern = '(?m)^' + [regex]::Escape($InsertBeforeHeading) + '\s*$'
    if ([regex]::IsMatch($Text, $headingPattern)) {
      return [regex]::Replace($Text, $headingPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) "$Replacement`r`n`r`n$($m.Value)" }, 1)
    }
  }

  return ($Text.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $Replacement + [Environment]::NewLine)
}

function Read-CapabilityHistory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return @{}
  }

  $raw = Get-Content -LiteralPath $Path -Raw
  if (-not $raw.Trim()) {
    return @{}
  }

  $data = $raw | ConvertFrom-Json
  $history = @{}
  if ($data.capabilities) {
    foreach ($entry in $data.capabilities.PSObject.Properties) {
      $history[$entry.Name] = [ordered]@{}
      foreach ($property in $entry.Value.PSObject.Properties) {
        $history[$entry.Name][$property.Name] = $property.Value
      }
    }
  }

  return $history
}

function Write-CapabilityHistory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [hashtable]$History
  )

  $orderedCaps = [ordered]@{}
  foreach ($key in ($History.Keys | Sort-Object)) {
    $orderedCaps[$key] = $History[$key]
  }

  $payload = [ordered]@{
    capabilities = $orderedCaps
  }

  $payload | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -Path $Path
}
