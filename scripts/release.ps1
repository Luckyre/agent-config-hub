[CmdletBinding()]
param(
  [string]$Version,
  [string]$Notes = 'Configuration update'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$scanRoots = @('rules','mcp','plugins','skills','configs')
$files = @()
foreach ($root in $scanRoots) {
  if (Test-Path $root) {
    $files += Get-ChildItem -Path $root -Recurse -File
  }
}
$files = $files | Sort-Object FullName

if (-not $Version) {
  $datePart = Get-Date -Format 'yyyy.MM.dd'
  $prefix = "v$datePart."
  $tags = git tag --list "$prefix*"
  $maxSeq = 0
  foreach ($tag in $tags) {
    $parts = $tag -split '\.'
    if ($parts.Length -ge 4) {
      $candidate = 0
      if ([int]::TryParse($parts[3], [ref]$candidate)) {
        if ($candidate -gt $maxSeq) { $maxSeq = $candidate }
      }
    }
  }
  $Version = "$prefix$($maxSeq + 1)"
}

$manifestEntries = @()
foreach ($file in $files) {
  $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName
  $relative = $file.FullName.Substring($repoRoot.Path.Length + 1).Replace('\\','/')
  $manifestEntries += [ordered]@{
    path = $relative
    sha256 = $hash.Hash.ToLowerInvariant()
  }
}

$manifest = [ordered]@{
  repoVersion = $Version
  generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  rulesVersion = $Version
  mcpVersion = $Version
  pluginsVersion = $Version
  skillsVersion = $Version
  compatibility = [ordered]@{
    tools = @('codex','claudex')
    os = @('windows','macos')
  }
  files = $manifestEntries
}

$manifestPath = Join-Path $repoRoot 'manifests/manifest.lock.json'
$manifest | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $manifestPath

$today = Get-Date -Format 'yyyy-MM-dd'
$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogBlock = @"

## [$Version] - $today

- $Notes
"@
Add-Content -Encoding UTF8 -Path $changelogPath -Value $changelogBlock

git add manifests/manifest.lock.json CHANGELOG.md
$staged = git diff --cached --name-only
if ($staged) {
  git commit -m "release: $Version" | Out-Null
}

$existingTag = git tag --list $Version
if ($existingTag) {
  throw "Tag already exists: $Version"
}
git tag $Version

Write-Output "Release prepared: $Version"
Write-Output "Next: git push origin HEAD --tags"