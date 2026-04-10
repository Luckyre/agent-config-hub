$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot '..\..\scripts\release.helpers.ps1')

$fixtureRoot = Join-Path $PSScriptRoot 'fixtures'
New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null

@"
servers:
  - name: example-local
    transport: stdio
    command: node
    args:
      - ./mcp/example-server.js
    capabilities:
      - id: mcp.example.execute
        label: Local example execution
        summary: Runs the bundled local example server over stdio.
      - id: mcp.example.inspect
        label: Example inspection
        summary: Exposes inspection endpoints for local debugging.
"@ | Set-Content -Encoding UTF8 (Join-Path $fixtureRoot 'servers.yaml')

@"
skills:
  - id: skill.sample
    name: Sample Skill
    source: skills/sample
    summary: Sample managed skill.
    capabilities:
      - id: skill.capability.sample
        label: Sample capability
        summary: Demonstrates structured capability parsing.
"@ | Set-Content -Encoding UTF8 (Join-Path $fixtureRoot 'catalog.yaml')

@"
plugins:
  - id: sample.plugin
    enabled: true
    source: local
    capabilities:
      - id: plugin.sample.install
        label: Local plugin install
        summary: Makes the sample plugin available from the local registry.
"@ | Set-Content -Encoding UTF8 (Join-Path $fixtureRoot 'plugins.yaml')

$mcp = @(Get-McpServersDetailed -Path (Join-Path $fixtureRoot 'servers.yaml'))
if ($mcp.Count -ne 1) { throw 'Expected one MCP server.' }
if ($mcp[0].capabilities.Count -ne 2) { throw 'Expected MCP capabilities to be parsed.' }
if ($mcp[0].capabilities[0].id -ne 'mcp.example.execute') { throw 'Expected MCP capability ids to match.' }

$skills = @(Get-SkillsCatalog -Path (Join-Path $fixtureRoot 'catalog.yaml'))
if ($skills.Count -ne 1) { throw 'Expected one skill.' }
if ($skills[0].capabilities[0].id -ne 'skill.capability.sample') { throw 'Expected skill capability ids to be parsed.' }

$plugins = @(Get-PluginsDetailed -Path (Join-Path $fixtureRoot 'plugins.yaml'))
if ($plugins.Count -ne 1) { throw 'Expected one plugin.' }
if ($plugins[0].capabilities[0].id -ne 'plugin.sample.install') { throw 'Expected plugin capability ids to be parsed.' }

$diff = Compare-CapabilitySets -Current @(
  @{ id = 'mcp.example.execute'; kind = 'mcp'; owner = 'example-local' },
  @{ id = 'skill.capability.sample'; kind = 'skill'; owner = 'skill.sample' },
  @{ id = 'plugin.sample.install'; kind = 'plugin'; owner = 'sample.plugin' }
) -Previous @(
  @{ id = 'mcp.example.execute'; kind = 'mcp'; owner = 'example-local' }
)
if ($diff.New.Count -ne 2) { throw 'Expected two new capabilities.' }
if (($diff.New | ForEach-Object { $_.id }) -notcontains 'skill.capability.sample') { throw 'Expected skill capability to be detected as new.' }
if (($diff.New | ForEach-Object { $_.id }) -notcontains 'plugin.sample.install') { throw 'Expected plugin capability to be detected as new.' }

$history = Merge-CapabilityHistory -Current @(
  @{ id = 'skill.capability.sample'; label = 'Sample capability'; kind = 'skill'; owner = 'skill.sample'; summary = 'Demonstrates structured capability parsing.'; ownerSource = 'skills/catalog.yaml' },
  @{ id = 'plugin.sample.install'; label = 'Local plugin install'; kind = 'plugin'; owner = 'sample.plugin'; summary = 'Makes the sample plugin available from the local registry.'; ownerSource = 'plugins/registry.yaml' }
) -History @{} -Version 'v2026.04.10.2'
if ($history['skill.capability.sample'].introducedIn -ne 'v2026.04.10.2') { throw 'Expected introducedIn to be set.' }
if ($history['plugin.sample.install'].introducedIn -ne 'v2026.04.10.2') { throw 'Expected plugin introducedIn to be set.' }

$historyWithPrior = Merge-CapabilityHistory -Current @(
  @{ id = 'mcp.example.execute'; label = 'Local example execution'; kind = 'mcp'; owner = 'example-local'; summary = 'Runs the bundled local example server over stdio.'; ownerSource = 'mcp/servers.yaml' }
) -History @{
  'mcp.example.execute' = @{
    id = 'mcp.example.execute'
    label = 'Local example execution'
    summary = 'Runs the bundled local example server over stdio.'
    kind = 'mcp'
    owner = 'example-local'
    ownerSource = 'mcp/servers.yaml'
    introducedIn = 'v2026.04.10.2'
  }
} -Version 'v2026.04.10.3'
if ($historyWithPrior['mcp.example.execute'].introducedIn -ne 'v2026.04.10.2') { throw 'Expected existing introducedIn to remain stable.' }

$badge = Render-CapabilityBadge -IsNew $true
if ($badge -notmatch 'NEW') { throw 'Expected NEW badge markup.' }
if ($badge -notmatch 'style=') { throw 'Expected inline color badge styling.' }

$section = New-ReadmeCapabilitySection -McpCapabilities @(
  @{ owner = 'example-local'; label = 'Local example execution'; summary = 'Runs the bundled local example server over stdio.'; introducedIn = 'v2026.04.10.2'; isNew = $true }
) -PluginCapabilities @(
  @{ owner = 'sample.plugin'; label = 'Local plugin install'; summary = 'Makes the sample plugin available from the local registry.'; introducedIn = 'v2026.04.10.2'; isNew = $true }
) -SkillCapabilities @(
  @{ owner = 'Sample Skill'; label = 'Sample capability'; summary = 'Demonstrates structured capability parsing.'; introducedIn = 'v2026.04.10.2'; isNew = $true }
)
if ($section -notmatch 'example-local') { throw 'Expected README section to include owner names.' }
if ($section -notmatch 'sample.plugin') { throw 'Expected README section to include plugin names.' }
if ($section -notmatch 'Sample Skill') { throw 'Expected README section to include skill names.' }
if ($section -notmatch 'NEW') { throw 'Expected README section to include NEW badge.' }

'Helper tests passed.'
