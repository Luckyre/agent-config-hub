$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$generatedRoot = Join-Path $repoRoot 'generated'
$tempRoot = Join-Path $PSScriptRoot 'tmp'
$tempHome = Join-Path $tempRoot 'home'
$backupRoot = Join-Path $tempRoot 'restore'
$shimRoot = Join-Path $tempRoot 'bin'
$renderPaths = @(
  'generated\codex\windows\company',
  'generated\claudex\windows\home'
)

function Backup-Path {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $source = Join-Path $repoRoot $RelativePath
  $backup = Join-Path $backupRoot ($RelativePath -replace '[\\/]', '__')
  if (Test-Path -LiteralPath $backup) {
    Remove-Item -LiteralPath $backup -Recurse -Force
  }

  if (Test-Path -LiteralPath $source) {
    $parent = Split-Path -Parent $backup
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $backup -Recurse -Force
  }
}

function Restore-Path {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $source = Join-Path $backupRoot ($RelativePath -replace '[\\/]', '__')
  $target = Join-Path $repoRoot $RelativePath
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
  if (Test-Path -LiteralPath $source) {
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
  }
}

function Invoke-SyncTestRun {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('codex', 'claudex')]
    [string]$Tool,
    [Parameter(Mandatory = $true)]
    [ValidateSet('company', 'home')]
    [string]$Profile
  )

  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = 'powershell.exe'
  $startInfo.WorkingDirectory = $repoRoot
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\sync.ps1`" -Tool $Tool -Profile $Profile"
  $startInfo.EnvironmentVariables['HOME'] = $tempHome
  $startInfo.EnvironmentVariables['USERPROFILE'] = $tempHome
  $startInfo.EnvironmentVariables['PATH'] = "$shimRoot;$previousPath"

  $process = [System.Diagnostics.Process]::Start($startInfo)
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()

  if ($process.ExitCode -ne 0) {
    throw "sync.ps1 failed for tool=$Tool profile=$Profile`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
  }
}

New-Item -ItemType Directory -Path $tempRoot, $backupRoot -Force | Out-Null
foreach ($relativePath in $renderPaths) {
  Backup-Path -RelativePath $relativePath
}

$previousPath = $env:PATH

Push-Location $repoRoot
try {
  if (Test-Path -LiteralPath $tempHome) {
    Remove-Item -LiteralPath $tempHome -Recurse -Force
  }
  New-Item -ItemType Directory -Path $tempHome -Force | Out-Null
  New-Item -ItemType Directory -Path $shimRoot -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $tempHome '.codex') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $tempHome '.claude') -Force | Out-Null
  @'
@echo off
echo Nothing to validate
exit /b 0
'@ | Set-Content -Encoding ASCII (Join-Path $shimRoot 'openspec.cmd')
  @'
model = "gpt-5.4"

[projects.'D:\work\legacy']
trust_level = "trusted"
'@ | Set-Content -Encoding UTF8 (Join-Path $tempHome '.codex\config.toml')
  @'
{
  "mcpServers": {
    "existing-server": {
      "command": "cmd",
      "args": [
        "/c",
        "echo existing"
      ],
      "env": {}
    }
  }
}
'@ | Set-Content -Encoding UTF8 (Join-Path $tempHome '.claude\mcp.json')
  @'
{
  "permissions": {
    "allow": [
      "WebFetch(domain:example.com)"
    ]
  }
}
'@ | Set-Content -Encoding UTF8 (Join-Path $tempHome '.claude\settings.local.json')

  Invoke-SyncTestRun -Tool codex -Profile company

  $codexEffectivePath = Join-Path $repoRoot 'generated\codex\windows\company\effective-config.json'
  $codexEffective = Get-Content -LiteralPath $codexEffectivePath -Raw | ConvertFrom-Json
  if ($codexEffective.settings.syncMode -ne 'manual-target-first') {
    throw 'Expected effective config to merge base settings.'
  }
  if ($codexEffective.paths.configRoot -ne (Join-Path $tempHome '.codex')) {
    throw 'Expected effective config to resolve codex configRoot for the active OS.'
  }
  if (-not $codexEffective.features.skills) {
    throw 'Expected effective config to include tool feature flags.'
  }
  if (-not $codexEffective.network.proxyEnabled) {
    throw 'Expected effective config to merge profile values.'
  }
  if ($codexEffective.shell -ne 'powershell') {
    throw 'Expected effective config to merge OS values.'
  }

  $codexSkillPath = Join-Path $tempHome '.codex\skills\openspec-apply-change\SKILL.md'
  if (-not (Test-Path -LiteralPath $codexSkillPath)) {
    throw 'Expected sync to apply managed Codex skills into the native tool directory.'
  }
  $codexRulesPath = Join-Path $tempHome '.codex\rules\base.md'
  if (-not (Test-Path -LiteralPath $codexRulesPath)) {
    throw 'Expected sync to apply managed rules into the native Codex directory.'
  }
  $codexConfigPath = Join-Path $tempHome '.codex\config.toml'
  if (-not (Test-Path -LiteralPath $codexConfigPath)) {
    throw 'Expected sync to render a Codex native config.toml file.'
  }
  if (-not (Select-String -Path $codexConfigPath -Pattern 'trust_level = "trusted"' -Quiet)) {
    throw 'Expected sync to preserve existing Codex config content outside the managed block.'
  }
  if (-not (Select-String -Path $codexConfigPath -Pattern '\[mcp_servers\.example-local\]' -Quiet)) {
    throw 'Expected rendered Codex config.toml to include managed MCP server entries.'
  }

  Invoke-SyncTestRun -Tool claudex -Profile home

  $claudeEffectivePath = Join-Path $repoRoot 'generated\claudex\windows\home\effective-config.json'
  $claudeEffective = Get-Content -LiteralPath $claudeEffectivePath -Raw | ConvertFrom-Json
  if ($claudeEffective.network.proxyEnabled) {
    throw 'Expected home profile to override proxyEnabled to false.'
  }
  if ($claudeEffective.paths.configRoot -ne (Join-Path $tempHome '.claude')) {
    throw 'Expected effective config to resolve claudex configRoot for the active OS.'
  }

  $claudeSkillPath = Join-Path $tempHome '.claude\skills\openspec-archive-change\SKILL.md'
  if (-not (Test-Path -LiteralPath $claudeSkillPath)) {
    throw 'Expected sync to apply managed Claude skills into the native tool directory.'
  }
  $claudeCommandPath = Join-Path $tempHome '.claude\commands\opsx\apply.md'
  if (-not (Test-Path -LiteralPath $claudeCommandPath)) {
    throw 'Expected sync to apply managed Claude commands into the native tool directory.'
  }
  $claudeMcpPath = Join-Path $tempHome '.claude\mcp.json'
  if (-not (Test-Path -LiteralPath $claudeMcpPath)) {
    throw 'Expected sync to render a Claude native mcp.json file.'
  }
  if (-not (Select-String -Path $claudeMcpPath -Pattern '"example-local"' -Quiet)) {
    throw 'Expected rendered Claude mcp.json to include managed MCP server entries.'
  }
  if (-not (Select-String -Path $claudeMcpPath -Pattern '"existing-server"' -Quiet)) {
    throw 'Expected sync to preserve existing Claude MCP entries while adding managed ones.'
  }
  $claudeSettingsPath = Join-Path $tempHome '.claude\settings.local.json'
  if (-not (Select-String -Path $claudeSettingsPath -Pattern 'example.com' -Quiet)) {
    throw 'Expected sync to preserve existing Claude settings.local.json permissions.'
  }
}
finally {
  Pop-Location

  foreach ($relativePath in $renderPaths) {
    Restore-Path -RelativePath $relativePath
  }
}

'Sync tests passed.'
