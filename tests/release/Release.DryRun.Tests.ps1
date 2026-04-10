$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$pathsToRestore = @(
  'README.md',
  'README.en.md',
  'docs/integration-catalog.md',
  'manifests/manifest.lock.json',
  'manifests/integration-history.json',
  'CHANGELOG.md'
)
$backupRoot = Join-Path $PSScriptRoot 'tmp-restore'
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

Push-Location $repoRoot
try {
  foreach ($relativePath in $pathsToRestore) {
    $source = Join-Path $repoRoot $relativePath
    $target = Join-Path $backupRoot ($relativePath -replace '[\\/]', '__')
    Copy-Item -LiteralPath $source -Destination $target -Force
  }

  & (Join-Path $repoRoot 'scripts\release.ps1') -Version 'v2099.01.01.1' -Notes 'test release' -SkipGit
  if (-not (Select-String -Path 'docs/integration-catalog.md' -Pattern 'Release Diff Summary' -Quiet)) {
    throw 'Expected release diff summary in integration catalog.'
  }
  if (-not (Select-String -Path 'README.md' -Pattern 'NEW' -Quiet)) {
    throw 'Expected README capability section to include NEW markers in dry-run output.'
  }
  if (-not (Select-String -Path 'README.en.md' -Pattern 'Plugin Capabilities' -Quiet)) {
    throw 'Expected English README capability section.'
  }
  if (-not (Select-String -Path 'docs/integration-catalog.md' -Pattern 'Plugin Capabilities' -Quiet)) {
    throw 'Expected plugin capabilities in integration catalog.'
  }
}
finally {
  foreach ($relativePath in $pathsToRestore) {
    $source = Join-Path $backupRoot ($relativePath -replace '[\\/]', '__')
    $target = Join-Path $repoRoot $relativePath
    if (Test-Path -LiteralPath $source) {
      Copy-Item -LiteralPath $source -Destination $target -Force
    }
  }
  Pop-Location
}

'Dry-run release test passed.'
