$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$tempRoot = Join-Path $PSScriptRoot 'tmp-wrapper'
$homeRoot = Join-Path $tempRoot 'home'
$binRoot = Join-Path $tempRoot 'bin'

function Invoke-ScriptUnderTest {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(Mandatory = $true)]
    [hashtable]$Environment,
    [string[]]$Arguments = @()
  )

  $quotedArguments = @()
  foreach ($argument in $Arguments) {
    $quotedArguments += ('"{0}"' -f $argument.Replace('"', '\"'))
  }

  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = 'powershell.exe'
  $startInfo.WorkingDirectory = $repoRoot
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $($quotedArguments -join ' ')"
  foreach ($key in $Environment.Keys) {
    $startInfo.EnvironmentVariables[$key] = $Environment[$key]
  }

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

New-Item -ItemType Directory -Path $homeRoot, $binRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $homeRoot '.codex\prompts'), (Join-Path $homeRoot '.claude\prompts') -Force | Out-Null
'codex style' | Set-Content -LiteralPath (Join-Path $homeRoot '.codex\prompts\global-style.md') -Encoding UTF8
'claude style' | Set-Content -LiteralPath (Join-Path $homeRoot '.claude\prompts\global-style.md') -Encoding UTF8
'@echo off' | Set-Content -LiteralPath (Join-Path $binRoot 'fake-codex.cmd') -Encoding ASCII
'@echo off' | Set-Content -LiteralPath (Join-Path $binRoot 'fake-claude.cmd') -Encoding ASCII

$baseEnv = @{
  HOME = $homeRoot
  USERPROFILE = $homeRoot
  PATH = "$binRoot;$env:PATH"
}

$codexRun = Invoke-ScriptUnderTest -ScriptPath (Join-Path $repoRoot 'tooling\codex\start-codex.ps1') -Environment ($baseEnv + @{
  CODEX_BIN = (Join-Path $binRoot 'fake-codex.cmd')
}) -Arguments @('-PreviewPrompt', '-Prompt', 'hello from codex')

if ($codexRun.exitCode -ne 0) {
  throw "Expected Codex wrapper preview to succeed.`nSTDOUT:`n$($codexRun.stdout)`nSTDERR:`n$($codexRun.stderr)"
}
if ($codexRun.stdout -notmatch [regex]::Escape((Join-Path $homeRoot '.codex\prompts\global-style.md'))) {
  throw 'Expected Codex wrapper to resolve the prompt file from the current HOME directory.'
}
if ($codexRun.stdout -notmatch [regex]::Escape((Join-Path $binRoot 'fake-codex.cmd'))) {
  throw 'Expected Codex wrapper to use the CODEX_BIN override instead of a machine-specific path.'
}

$claudeRun = Invoke-ScriptUnderTest -ScriptPath (Join-Path $repoRoot 'tooling\claudex\start-claude.ps1') -Environment ($baseEnv + @{
  CLAUDE_BIN = (Join-Path $binRoot 'fake-claude.cmd')
}) -Arguments @('-PreviewPrompt', '-Prompt', 'hello from claude')

if ($claudeRun.exitCode -ne 0) {
  throw "Expected Claude wrapper preview to succeed.`nSTDOUT:`n$($claudeRun.stdout)`nSTDERR:`n$($claudeRun.stderr)"
}
if ($claudeRun.stdout -notmatch [regex]::Escape((Join-Path $homeRoot '.claude\prompts\global-style.md'))) {
  throw 'Expected Claude wrapper to resolve the prompt file from the current HOME directory.'
}
if ($claudeRun.stdout -notmatch [regex]::Escape((Join-Path $binRoot 'fake-claude.cmd'))) {
  throw 'Expected Claude wrapper to use the CLAUDE_BIN override instead of a machine-specific path.'
}

'Start script tests passed.'
