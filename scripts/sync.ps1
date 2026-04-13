[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('codex','claudex')]
  [string]$Tool,

  [Parameter(Mandatory = $true)]
  [ValidateSet('company','home')]
  [string]$Profile,

  [string]$TargetVersion
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot
$installToolingScript = Join-Path $PSScriptRoot 'install-tooling.ps1'
. (Join-Path $PSScriptRoot 'release.helpers.ps1')

function Convert-YamlScalar {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  $trimmed = $Value.Trim()
  if (
    (($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) -or
     ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'"))) -and
    $trimmed.Length -ge 2
  ) {
    return $trimmed.Substring(1, $trimmed.Length - 2)
  }

  if ($trimmed -match '^(true|false)$') {
    return [bool]::Parse($trimmed)
  }

  $intValue = 0
  if ([int]::TryParse($trimmed, [ref]$intValue)) {
    return $intValue
  }

  return $trimmed
}

function Get-NextYamlEntry {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Lines,
    [Parameter(Mandatory = $true)]
    [int]$StartIndex
  )

  for ($i = $StartIndex; $i -lt $Lines.Count; $i++) {
    $candidate = $Lines[$i]
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }

    $trimmed = $candidate.Trim()
    if ($trimmed.StartsWith('#')) {
      continue
    }

    return [pscustomobject]@{
      indent = ($candidate.Length - $candidate.TrimStart().Length)
      trimmed = $trimmed
    }
  }

  return $null
}

function Convert-LinesToSimpleYamlObject {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Lines
  )

  $root = [ordered]@{}
  $stack = New-Object System.Collections.ArrayList
  [void]$stack.Add([pscustomobject]@{
    indent = -1
    type = 'map'
    container = $root
  })

  for ($i = 0; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }

    $trimmed = $line.Trim()
    if ($trimmed.StartsWith('#')) {
      continue
    }

    $indent = $line.Length - $line.TrimStart().Length
    while ($stack.Count -gt 1 -and $indent -le $stack[$stack.Count - 1].indent) {
      $stack.RemoveAt($stack.Count - 1)
    }

    $frame = $stack[$stack.Count - 1]

    if ($trimmed.StartsWith('- ')) {
      if ($frame.type -ne 'list') {
        throw "Unsupported YAML list position: $trimmed"
      }

      $frame.container.Add((Convert-YamlScalar -Value $trimmed.Substring(2))) | Out-Null
      continue
    }

    if ($trimmed -notmatch '^([^:]+):\s*(.*)$') {
      throw "Unsupported YAML line: $trimmed"
    }

    $key = $Matches[1].Trim()
    $rest = $Matches[2]
    if ([string]::IsNullOrWhiteSpace($rest)) {
      $nextEntry = Get-NextYamlEntry -Lines $Lines -StartIndex ($i + 1)
      $newContainer = if ($nextEntry -and $nextEntry.indent -gt $indent -and $nextEntry.trimmed.StartsWith('- ')) {
        New-Object System.Collections.ArrayList
      } else {
        [ordered]@{}
      }

      $frame.container[$key] = $newContainer
      $containerType = if ($newContainer -is [System.Collections.ArrayList]) { 'list' } else { 'map' }
      [void]$stack.Add([pscustomobject]@{
        indent = $indent
        type = $containerType
        container = $newContainer
      })
      continue
    }

    $frame.container[$key] = Convert-YamlScalar -Value $rest
  }

  return $root
}

function Get-SimpleYamlObject {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return [ordered]@{}
  }

  return Convert-LinesToSimpleYamlObject -Lines (Get-Content -LiteralPath $Path)
}

function ConvertTo-PlainData {
  param(
    [Parameter(ValueFromPipeline = $true)]
    $Value
  )

  if ($null -eq $Value) {
    return $null
  }

  if ($Value -is [System.Collections.IDictionary]) {
    $result = [ordered]@{}
    foreach ($key in $Value.Keys) {
      $result[$key] = ConvertTo-PlainData -Value $Value[$key]
    }
    return $result
  }

  if ($Value -is [pscustomobject]) {
    $result = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-PlainData -Value $property.Value
    }
    return $result
  }

  if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
    $items = @()
    foreach ($item in $Value) {
      $items += ,(ConvertTo-PlainData -Value $item)
    }
    return ,$items
  }

  return $Value
}

function Copy-DeepValue {
  param(
    [Parameter(ValueFromPipeline = $true)]
    $Value
  )

  return ConvertTo-PlainData -Value $Value
}

function Merge-StructuredData {
  param(
    [Parameter(ValueFromPipeline = $true)]
    $Base,
    [Parameter(ValueFromPipeline = $true)]
    $Overlay
  )

  if ($null -eq $Base) {
    return Copy-DeepValue -Value $Overlay
  }

  if ($null -eq $Overlay) {
    return Copy-DeepValue -Value $Base
  }

  $basePlain = ConvertTo-PlainData -Value $Base
  $overlayPlain = ConvertTo-PlainData -Value $Overlay

  if (($basePlain -is [System.Collections.IDictionary]) -and ($overlayPlain -is [System.Collections.IDictionary])) {
    $merged = [ordered]@{}
    foreach ($key in $basePlain.Keys) {
      $merged[$key] = Copy-DeepValue -Value $basePlain[$key]
    }
    foreach ($key in $overlayPlain.Keys) {
      if ($merged.Contains($key)) {
        $merged[$key] = Merge-StructuredData -Base $merged[$key] -Overlay $overlayPlain[$key]
      } else {
        $merged[$key] = Copy-DeepValue -Value $overlayPlain[$key]
      }
    }
    return $merged
  }

  if (($basePlain -is [System.Collections.IEnumerable]) -and -not ($basePlain -is [string]) -and
      ($overlayPlain -is [System.Collections.IEnumerable]) -and -not ($overlayPlain -is [string])) {
    $baseItems = @($basePlain)
    $overlayItems = @($overlayPlain)
    $hasComplexItems = @($baseItems + $overlayItems | Where-Object {
      ($_ -is [System.Collections.IDictionary]) -or
      (($_ -is [System.Collections.IEnumerable]) -and -not ($_ -is [string]))
    }).Count -gt 0

    if ($hasComplexItems) {
      $items = @()
      foreach ($item in $overlayItems) {
        $items += ,(Copy-DeepValue -Value $item)
      }
      return ,$items
    }

    $values = New-Object System.Collections.ArrayList
    foreach ($item in $baseItems) {
      if (-not $values.Contains($item)) {
        $values.Add($item) | Out-Null
      }
    }
    foreach ($item in $overlayItems) {
      if (-not $values.Contains($item)) {
        $values.Add($item) | Out-Null
      }
    }
    return ,@($values)
  }

  return Copy-DeepValue -Value $overlayPlain
}

function Ensure-Directory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Resolve-ManagedPathValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$PathValue,
    [Parameter(Mandatory = $true)]
    [string]$HomeDir
  )

  $expanded = $PathValue.Replace('%USERPROFILE%', $HomeDir)
  if ($expanded.StartsWith('~')) {
    $expanded = Join-Path $HomeDir $expanded.Substring(1).TrimStart('\', '/')
  }

  return [System.IO.Path]::GetFullPath($expanded)
}

function Resolve-ToolConfigRoot {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$EffectiveConfig,
    [Parameter(Mandatory = $true)]
    [string]$OsName,
    [Parameter(Mandatory = $true)]
    [string]$HomeDir
  )

  if (-not $EffectiveConfig.Contains('paths')) {
    throw 'Effective config missing paths section.'
  }

  $paths = $EffectiveConfig['paths']
  if (-not ($paths -is [System.Collections.IDictionary]) -or -not $paths.Contains('configRoot')) {
    throw 'Effective config missing paths.configRoot.'
  }

  $configRoot = $paths['configRoot']
  if ($configRoot -is [System.Collections.IDictionary]) {
    if (-not $configRoot.Contains($OsName)) {
      throw "Config root does not define an entry for OS: $OsName"
    }
    $configRoot = $configRoot[$OsName]
  }

  if (-not ($configRoot -is [string]) -or [string]::IsNullOrWhiteSpace($configRoot)) {
    throw 'Resolved configRoot is empty.'
  }

  return Resolve-ManagedPathValue -PathValue $configRoot -HomeDir $HomeDir
}

function Sync-ManagedDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    return
  }

  if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Recurse -Force
  }

  $parent = Split-Path -Parent $Destination
  if ($parent) {
    Ensure-Directory -Path $parent
  }
  Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Read-JsonData {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($content)) {
    return $null
  }

  return ConvertTo-PlainData -Value ($content | ConvertFrom-Json)
}

function Write-JsonData {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(ValueFromPipeline = $true)]
    $Data
  )

  $parent = Split-Path -Parent $Path
  if ($parent) {
    Ensure-Directory -Path $parent
  }

  $Data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Merge-JsonFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
  )

  $source = Read-JsonData -Path $SourcePath
  if ($null -eq $source) {
    return
  }

  $existing = Read-JsonData -Path $DestinationPath
  $merged = if ($null -eq $existing) {
    Copy-DeepValue -Value $source
  } else {
    Merge-StructuredData -Base $existing -Overlay $source
  }

  Write-JsonData -Path $DestinationPath -Data $merged
}

function ConvertTo-TomlString {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

function New-CodexManagedTomlBlock {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$McpServers,
    [Parameter(Mandatory = $true)]
    [string]$Tool,
    [Parameter(Mandatory = $true)]
    [string]$Profile,
    [Parameter(Mandatory = $true)]
    [string]$Version
  )

  $lines = @(
    '# BEGIN MANAGED BY agent-config-hub',
    "# tool = $Tool profile = $Profile version = $Version"
  )

  foreach ($server in $McpServers) {
    $lines += ''
    $lines += "[mcp_servers.$($server.name)]"
    $lines += "type = $(ConvertTo-TomlString -Value $server.transport)"
    $lines += "command = $(ConvertTo-TomlString -Value $server.command)"
    $argValues = @()
    foreach ($arg in @($server.args)) {
      $argValues += (ConvertTo-TomlString -Value $arg)
    }
    $lines += "args = [$($argValues -join ', ')]"
  }

  $lines += '# END MANAGED BY agent-config-hub'
  return $lines -join "`r`n"
}

function Write-CodexManagedConfig {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [object[]]$McpServers,
    [Parameter(Mandatory = $true)]
    [string]$Tool,
    [Parameter(Mandatory = $true)]
    [string]$Profile,
    [Parameter(Mandatory = $true)]
    [string]$Version
  )

  $existing = ''
  if (Test-Path -LiteralPath $Path) {
    $existing = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  }

  $managedBlock = New-CodexManagedTomlBlock -McpServers $McpServers -Tool $Tool -Profile $Profile -Version $Version
  $pattern = '(?ms)\r?\n?# BEGIN MANAGED BY agent-config-hub.*?# END MANAGED BY agent-config-hub\r?\n?'
  $unmanaged = [regex]::Replace($existing, $pattern, '')
  $unmanaged = $unmanaged.TrimEnd()
  $content = if ([string]::IsNullOrWhiteSpace($unmanaged)) {
    $managedBlock
  } else {
    "$unmanaged`r`n`r`n$managedBlock"
  }

  $parent = Split-Path -Parent $Path
  if ($parent) {
    Ensure-Directory -Path $parent
  }

  Set-Content -LiteralPath $Path -Encoding UTF8 -Value $content
}

function Write-ClaudeManagedMcp {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [object[]]$McpServers
  )

  $existing = Read-JsonData -Path $Path
  if ($null -eq $existing -or -not ($existing -is [System.Collections.IDictionary])) {
    $existing = [ordered]@{}
  }

  if (-not $existing.Contains('mcpServers') -or -not ($existing['mcpServers'] -is [System.Collections.IDictionary])) {
    $existing['mcpServers'] = [ordered]@{}
  }

  foreach ($server in $McpServers) {
    $existing['mcpServers'][$server.name] = [ordered]@{
      command = $server.command
      args = @($server.args)
      env = [ordered]@{}
    }
  }

  Write-JsonData -Path $Path -Data $existing
}

function Apply-ManagedToolAssets {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('codex','claudex')]
    [string]$Tool,
    [Parameter(Mandatory = $true)]
    [string]$TargetRoot,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [Parameter(Mandatory = $true)]
    [string]$Profile
  )

  Ensure-Directory -Path $TargetRoot
  Sync-ManagedDirectory -Source (Join-Path $repoRoot 'rules') -Destination (Join-Path $TargetRoot 'rules')

  $runtimeSource = switch ($Tool) {
    'codex' { Join-Path $repoRoot '.codex' }
    'claudex' { Join-Path $repoRoot '.claude' }
  }

  if (Test-Path -LiteralPath $runtimeSource) {
    foreach ($item in Get-ChildItem -LiteralPath $runtimeSource -Force) {
      $destination = Join-Path $TargetRoot $item.Name
      if ($item.PSIsContainer) {
        Sync-ManagedDirectory -Source $item.FullName -Destination $destination
        continue
      }

      if ($item.Name -ieq 'settings.local.json') {
        Merge-JsonFile -SourcePath $item.FullName -DestinationPath $destination
        continue
      }

      Copy-Item -LiteralPath $item.FullName -Destination $destination -Force
    }
  }

  $mcpServers = @(Get-McpServersDetailed -Path (Join-Path $repoRoot 'mcp/servers.yaml'))
  switch ($Tool) {
    'codex' {
      Write-CodexManagedConfig -Path (Join-Path $TargetRoot 'config.toml') -McpServers $mcpServers -Tool $Tool -Profile $Profile -Version $Version
    }
    'claudex' {
      Write-ClaudeManagedMcp -Path (Join-Path $TargetRoot 'mcp.json') -McpServers $mcpServers
    }
  }
}

$isWindows = $false
if ($PSVersionTable.PSVersion.Major -ge 6) {
  $isWindows = $IsWindows
} else {
  $isWindows = ($env:OS -eq 'Windows_NT')
}
$osName = if ($isWindows) { 'windows' } else { 'macos' }

$stateRoot = Join-Path $HOME '.codex-config'
$stateFile = Join-Path $stateRoot 'state.json'
$liveRoot = Join-Path $stateRoot 'live'
$backupRoot = Join-Path $stateRoot 'backups'
$stagingRoot = Join-Path $stateRoot 'live-staging'
$generatedRoot = Join-Path $repoRoot 'generated'
$renderDir = Join-Path $generatedRoot "$Tool/$osName/$Profile"

$requiredPaths = @(
  (Join-Path $repoRoot 'configs/base.yaml'),
  (Join-Path $repoRoot "configs/tools/$Tool.yaml"),
  (Join-Path $repoRoot "configs/os/$osName.yaml"),
  (Join-Path $repoRoot "configs/profiles/$Profile.yaml"),
  (Join-Path $repoRoot 'manifests/manifest.lock.json'),
  (Join-Path $repoRoot 'mcp/servers.yaml')
)

foreach ($p in $requiredPaths) {
  if (!(Test-Path $p)) { throw "Required path missing: $p" }
}

if (!(Test-Path $installToolingScript)) {
  throw "Required path missing: $installToolingScript"
}

New-Item -ItemType Directory -Force -Path $stateRoot, $backupRoot, $generatedRoot | Out-Null

if ($TargetVersion) {
  git fetch --tags | Out-Null
  git checkout $TargetVersion | Out-Null
}

$openSpecAvailable = $null -ne (Get-Command 'openspec.cmd' -ErrorAction SilentlyContinue)
if ($openSpecAvailable) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $validationOutput = & openspec.cmd validate --all 2>&1
  $ErrorActionPreference = $oldPreference
  if ($LASTEXITCODE -ne 0) {
    $combined = ($validationOutput | ForEach-Object { $_.ToString() }) -join "`n"
    if ($combined -match 'Nothing to validate') {
      Write-Warning 'OpenSpec validation skipped: no specs/changes to validate.'
    } else {
      throw "OpenSpec validation failed: $combined"
    }
  }
}

$configLayers = @(
  (Get-SimpleYamlObject -Path (Join-Path $repoRoot 'configs/base.yaml')),
  (Get-SimpleYamlObject -Path (Join-Path $repoRoot "configs/tools/$Tool.yaml")),
  (Get-SimpleYamlObject -Path (Join-Path $repoRoot "configs/os/$osName.yaml")),
  (Get-SimpleYamlObject -Path (Join-Path $repoRoot "configs/profiles/$Profile.yaml"))
)
$localOverridePath = Join-Path $repoRoot 'configs/local.override.yaml'
if (Test-Path -LiteralPath $localOverridePath) {
  $configLayers += (Get-SimpleYamlObject -Path $localOverridePath)
}

$effectiveConfig = [ordered]@{}
foreach ($layer in $configLayers) {
  $effectiveConfig = Merge-StructuredData -Base $effectiveConfig -Overlay $layer
}

if ($TargetVersion) {
  $gitVersion = $TargetVersion
} else {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $gitHead = & git rev-parse --short HEAD 2>$null
  $ErrorActionPreference = $oldPreference
  if ($LASTEXITCODE -eq 0 -and $gitHead) {
    $gitVersion = $gitHead.Trim()
  } else {
    $gitVersion = 'working-tree'
  }
}

$resolvedConfigRoot = Resolve-ToolConfigRoot -EffectiveConfig $effectiveConfig -OsName $osName -HomeDir $HOME
$effectiveConfig['tool'] = $Tool
$effectiveConfig['os'] = $osName
$effectiveConfig['profile'] = $Profile
$effectiveConfig['targetVersion'] = $gitVersion
$effectiveConfig['generatedAt'] = (Get-Date).ToString('s')
if (-not $effectiveConfig.Contains('paths')) {
  $effectiveConfig['paths'] = [ordered]@{}
}
$effectiveConfig['paths']['configRoot'] = $resolvedConfigRoot

if (Test-Path $renderDir) {
  Remove-Item -Recurse -Force -LiteralPath $renderDir
}
New-Item -ItemType Directory -Force -Path $renderDir | Out-Null

$copyMap = @(
  @{ src = 'configs/base.yaml'; dst = 'configs/base.yaml' },
  @{ src = "configs/tools/$Tool.yaml"; dst = "configs/tools/$Tool.yaml" },
  @{ src = "configs/os/$osName.yaml"; dst = "configs/os/$osName.yaml" },
  @{ src = "configs/profiles/$Profile.yaml"; dst = "configs/profiles/$Profile.yaml" },
  @{ src = 'rules'; dst = 'rules' },
  @{ src = 'mcp'; dst = 'mcp' },
  @{ src = 'plugins'; dst = 'plugins' },
  @{ src = 'skills'; dst = 'skills' },
  @{ src = 'tooling'; dst = 'tooling' },
  @{ src = 'manifests/manifest.lock.json'; dst = 'manifests/manifest.lock.json' }
)

foreach ($entry in $copyMap) {
  $srcPath = Join-Path $repoRoot $entry.src
  $dstPath = Join-Path $renderDir $entry.dst
  $parent = Split-Path -Parent $dstPath
  if (!(Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  Copy-Item -LiteralPath $srcPath -Destination $dstPath -Recurse -Force
}

$metaPath = Join-Path $renderDir 'effective-config.json'
$effectiveConfig | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $metaPath

$backupPath = $null
if (Test-Path $liveRoot) {
  $backupPath = Join-Path $backupRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
  Copy-Item -LiteralPath $liveRoot -Destination $backupPath -Recurse -Force
}

$toolRoot = $resolvedConfigRoot
$toolBackupPath = $null
if (Test-Path -LiteralPath $toolRoot) {
  $toolBackupPath = Join-Path $backupRoot ("tool-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
  Copy-Item -LiteralPath $toolRoot -Destination $toolBackupPath -Recurse -Force
}

try {
  if (Test-Path $stagingRoot) { Remove-Item -Recurse -Force -LiteralPath $stagingRoot }
  Copy-Item -LiteralPath $renderDir -Destination $stagingRoot -Recurse -Force

  if (Test-Path $liveRoot) { Remove-Item -Recurse -Force -LiteralPath $liveRoot }
  Move-Item -LiteralPath $stagingRoot -Destination $liveRoot

  $state = [ordered]@{
    targetVersion = $gitVersion
    currentVersion = $gitVersion
    lastSuccessfulVersion = $gitVersion
    tool = $Tool
    os = $osName
    profile = $Profile
    lastSyncAt = (Get-Date).ToString('s')
  }
  $state | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $stateFile

  & $installToolingScript -Tool $Tool -SourceRoot (Join-Path $renderDir 'tooling') | Out-Null
  Apply-ManagedToolAssets -Tool $Tool -TargetRoot $toolRoot -Version $gitVersion -Profile $Profile

  Write-Output "Sync succeeded: tool=$Tool os=$osName profile=$Profile version=$gitVersion"
}
catch {
  if ($backupPath -and (Test-Path $backupPath)) {
    if (Test-Path $liveRoot) { Remove-Item -Recurse -Force -LiteralPath $liveRoot }
    Move-Item -LiteralPath $backupPath -Destination $liveRoot
  }
  if ($toolBackupPath -and (Test-Path -LiteralPath $toolBackupPath)) {
    if (Test-Path -LiteralPath $toolRoot) { Remove-Item -LiteralPath $toolRoot -Recurse -Force }
    Move-Item -LiteralPath $toolBackupPath -Destination $toolRoot
  }
  throw "Sync failed and rollback executed. Error: $($_.Exception.Message)"
}
