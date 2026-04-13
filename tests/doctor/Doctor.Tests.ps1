$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$tempRoot = Join-Path $PSScriptRoot 'tmp-doctor'
$binRoot = Join-Path $tempRoot 'bin'

function Invoke-Doctor {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Tool,
    [Parameter(Mandatory = $true)]
    [string]$PathValue
  )

  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = 'powershell.exe'
  $startInfo.WorkingDirectory = $repoRoot
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\doctor.ps1`" -Tool $Tool"
  $startInfo.EnvironmentVariables['PATH'] = $PathValue

  $process = [System.Diagnostics.Process]::Start($startInfo)
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()

  return [pscustomobject]@{
    exitCode = $process.ExitCode
    stdout = $stdout
    stderr = $stderr
  }
}

if (Test-Path -LiteralPath $tempRoot) {
  Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $binRoot -Force | Out-Null
'@echo off' | Set-Content -LiteralPath (Join-Path $binRoot 'git.cmd') -Encoding ASCII
'@echo off' | Set-Content -LiteralPath (Join-Path $binRoot 'node.cmd') -Encoding ASCII
'@echo off' | Set-Content -LiteralPath (Join-Path $binRoot 'codex.cmd') -Encoding ASCII

$codexRun = Invoke-Doctor -Tool codex -PathValue $binRoot
if ($codexRun.exitCode -ne 0) {
  throw "Expected doctor to pass when required Codex dependencies are available.`nSTDOUT:`n$($codexRun.stdout)`nSTDERR:`n$($codexRun.stderr)"
}
if ($codexRun.stdout -notmatch 'node command') {
  throw 'Expected doctor output to include node dependency checks.'
}
if ($codexRun.stdout -notmatch 'codex command') {
  throw 'Expected doctor output to include the selected tool dependency check.'
}

$claudeRun = Invoke-Doctor -Tool claudex -PathValue $binRoot
if ($claudeRun.exitCode -eq 0) {
  throw 'Expected doctor to fail when the Claude CLI dependency is missing.'
}
if (($claudeRun.stdout + $claudeRun.stderr) -notmatch 'claude') {
  throw 'Expected doctor failure output to mention the missing Claude command.'
}

'Doctor tests passed.'
