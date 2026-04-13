$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-DoctorCheck {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [bool]$Ok,
    [Parameter(Mandatory = $true)]
    [bool]$Required,
    [Parameter(Mandatory = $true)]
    [string]$Detail
  )

  return [pscustomobject]@{
    Name = $Name
    Ok = $Ok
    Required = $Required
    Detail = $Detail
  }
}

function Resolve-FirstCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Names
  )

  foreach ($name in $Names) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
      return $command.Source
    }
  }

  return $null
}

function Get-DoctorChecks {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [ValidateSet('codex','claudex')]
    [string]$Tool
  )

  $checks = @()
  $gitCommand = Resolve-FirstCommand -Names @('git')
  $checks += New-DoctorCheck -Name 'git command' -Ok ($null -ne $gitCommand) -Required $true -Detail 'git is required for clone/fetch/sync.'

  $nodeCommand = Resolve-FirstCommand -Names @('node')
  $checks += New-DoctorCheck -Name 'node command' -Ok ($null -ne $nodeCommand) -Required $true -Detail 'node is required for repository-local MCP servers.'

  $openSpecCommand = Resolve-FirstCommand -Names @('openspec.cmd', 'openspec')
  $checks += New-DoctorCheck -Name 'openspec command' -Ok ($null -ne $openSpecCommand) -Required $false -Detail 'openspec is optional but recommended for spec validation.'

  if ($Tool) {
    $toolCommandNames = switch ($Tool) {
      'codex' { @('codex.cmd', 'codex') }
      'claudex' { @('claude.exe', 'claude') }
    }
    $toolCommand = Resolve-FirstCommand -Names $toolCommandNames
    $toolLabel = switch ($Tool) {
      'codex' { 'codex command' }
      'claudex' { 'claude command' }
    }
    $checks += New-DoctorCheck -Name $toolLabel -Ok ($null -ne $toolCommand) -Required $true -Detail "Tool runtime required for $Tool bootstrap."
  }

  $requiredPaths = @(
    'configs/base.yaml',
    'configs/tools/codex.yaml',
    'configs/tools/claudex.yaml',
    'configs/os/windows.yaml',
    'configs/os/macos.yaml',
    'configs/profiles/company.yaml',
    'configs/profiles/home.yaml',
    'manifests/manifest.lock.json',
    'mcp/servers.yaml',
    'mcp/example-server.js',
    'scripts/sync.ps1',
    'scripts/release.ps1'
  )

  foreach ($relativePath in $requiredPaths) {
    $absolutePath = Join-Path $RepoRoot $relativePath
    $checks += New-DoctorCheck -Name "exists:$relativePath" -Ok (Test-Path -LiteralPath $absolutePath) -Required $true -Detail $absolutePath
  }

  $manifestPath = Join-Path $RepoRoot 'manifests/manifest.lock.json'
  try {
    $null = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $checks += New-DoctorCheck -Name 'manifest json parse' -Ok $true -Required $true -Detail 'manifest.lock.json is valid JSON'
  }
  catch {
    $checks += New-DoctorCheck -Name 'manifest json parse' -Ok $false -Required $true -Detail $_.Exception.Message
  }

  return $checks
}
