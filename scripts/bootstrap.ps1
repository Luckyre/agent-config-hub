[CmdletBinding()]
param(
  [ValidateSet('codex','claudex')]
  [string]$Tool = 'codex',

  [ValidateSet('company','home')]
  [string]$Profile = 'company',

  [string]$TargetVersion
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$syncScript = Join-Path $scriptPath 'sync.ps1'

if (!(Test-Path $syncScript)) {
  throw "sync.ps1 not found at $syncScript"
}

& $syncScript -Tool $Tool -Profile $Profile -TargetVersion $TargetVersion

$toolingTarget = switch ($Tool) {
  'codex' { Join-Path $HOME '.codex' }
  'claudex' { Join-Path $HOME '.claude' }
}

Write-Output "Bootstrap completed: global tooling installed to $toolingTarget"
