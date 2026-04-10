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
  (Join-Path $repoRoot 'manifests/manifest.lock.json')
)

foreach ($p in $requiredPaths) {
  if (!(Test-Path $p)) { throw "Required path missing: $p" }
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
$renderMeta = [ordered]@{
  generatedAt = (Get-Date).ToString('s')
  tool = $Tool
  os = $osName
  profile = $Profile
  targetVersion = $gitVersion
  mergePriority = @('base', 'tool', 'os', 'profile', 'local.override')
}

$metaPath = Join-Path $renderDir 'effective-config.json'
$renderMeta | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $metaPath

$backupPath = $null
if (Test-Path $liveRoot) {
  $backupPath = Join-Path $backupRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
  Copy-Item -LiteralPath $liveRoot -Destination $backupPath -Recurse -Force
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

  Write-Output "Sync succeeded: tool=$Tool os=$osName profile=$Profile version=$gitVersion"
}
catch {
  if ($backupPath -and (Test-Path $backupPath)) {
    if (Test-Path $liveRoot) { Remove-Item -Recurse -Force -LiteralPath $liveRoot }
    Move-Item -LiteralPath $backupPath -Destination $liveRoot
  }
  throw "Sync failed and rollback executed. Error: $($_.Exception.Message)"
}
