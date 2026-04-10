[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('codex','claudex')]
  [string]$Tool,

  [string]$SourceRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  $SourceRoot = Join-Path $repoRoot 'tooling'
}

function Get-TargetRoot {
  param([string]$SelectedTool)

  switch ($SelectedTool) {
    'codex' { return (Join-Path $HOME '.codex') }
    'claudex' { return (Join-Path $HOME '.claude') }
    default { throw "Unsupported tool: $SelectedTool" }
  }
}

function Ensure-ParentDirectory {
  param([string]$Path)

  $parent = Split-Path -Parent $Path
  if ($parent -and !(Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
}

$toolingSource = Join-Path $SourceRoot $Tool
if (!(Test-Path $toolingSource)) {
  throw "Tooling source not found: $toolingSource"
}

$targetRoot = Get-TargetRoot -SelectedTool $Tool
New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

$filesToInstall = switch ($Tool) {
  'codex' {
    @(
      @{ src = 'prompts/global-style.md'; dst = 'prompts/global-style.md' },
      @{ src = 'start-codex.ps1'; dst = 'start-codex.ps1' }
    )
  }
  'claudex' {
    @(
      @{ src = 'prompts/global-style.md'; dst = 'prompts/global-style.md' },
      @{ src = 'start-claude.ps1'; dst = 'start-claude.ps1' }
    )
  }
}

foreach ($entry in $filesToInstall) {
  $srcPath = Join-Path $toolingSource $entry.src
  if (!(Test-Path $srcPath)) {
    throw "Required tooling file missing: $srcPath"
  }

  $dstPath = Join-Path $targetRoot $entry.dst
  Ensure-ParentDirectory -Path $dstPath
  Copy-Item -LiteralPath $srcPath -Destination $dstPath -Force
}

Write-Output "Installed tooling: tool=$Tool target=$targetRoot source=$toolingSource"
