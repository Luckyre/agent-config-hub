[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$checks = @()

function Add-Check {
  param([string]$Name, [bool]$Ok, [string]$Detail)
  $script:checks += [pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail }
}

Add-Check -Name 'git command' -Ok ($null -ne (Get-Command git -ErrorAction SilentlyContinue)) -Detail 'git must be available'
Add-Check -Name 'openspec command' -Ok ($null -ne (Get-Command openspec.cmd -ErrorAction SilentlyContinue)) -Detail 'openspec is optional but recommended'

$required = @(
  'configs/base.yaml',
  'configs/tools/codex.yaml',
  'configs/tools/claudex.yaml',
  'configs/os/windows.yaml',
  'configs/os/macos.yaml',
  'configs/profiles/company.yaml',
  'configs/profiles/home.yaml',
  'manifests/manifest.lock.json',
  'scripts/sync.ps1',
  'scripts/release.ps1'
)

foreach ($rel in $required) {
  $abs = Join-Path $repoRoot $rel
  Add-Check -Name "exists:$rel" -Ok (Test-Path $abs) -Detail $abs
}

try {
  $null = Get-Content -Raw (Join-Path $repoRoot 'manifests/manifest.lock.json') | ConvertFrom-Json
  Add-Check -Name 'manifest json parse' -Ok $true -Detail 'manifest.lock.json is valid JSON'
}
catch {
  Add-Check -Name 'manifest json parse' -Ok $false -Detail $_.Exception.Message
}

$failed = $checks | Where-Object { -not $_.Ok }
$checks | Format-Table -AutoSize

if ($failed) {
  throw "Doctor found $($failed.Count) failing checks."
}

Write-Output 'Doctor checks passed.'