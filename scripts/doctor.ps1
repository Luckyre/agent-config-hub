[CmdletBinding()]
param(
  [ValidateSet('codex','claudex')]
  [string]$Tool
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

. (Join-Path $PSScriptRoot 'doctor.helpers.ps1')

$checks = @(Get-DoctorChecks -RepoRoot $repoRoot -Tool $Tool)
$checks | Format-Table Name, Ok, Required, Detail -AutoSize

$failedRequired = @($checks | Where-Object { -not $_.Ok -and $_.Required })
if ($failedRequired.Count -gt 0) {
  throw "Doctor found $($failedRequired.Count) required check failures."
}

$failedOptional = @($checks | Where-Object { -not $_.Ok -and -not $_.Required })
if ($failedOptional.Count -gt 0) {
  Write-Warning "Doctor found $($failedOptional.Count) optional check failures."
}

Write-Output 'Doctor checks passed.'
