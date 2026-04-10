# Integration Capability Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add structured MCP/Skills capability metadata, release-to-release NEW markers, and generated capability inventories in README and integration catalog.

**Architecture:** Introduce structured metadata alongside existing MCP and Skills sources, add a reusable PowerShell module for parsing/diff/render logic, and update the release script to persist capability introduction history and regenerate human-readable docs. Verification covers pure parsing/diff/render functions first, then end-to-end release artifact generation in a dry-run path.

**Tech Stack:** PowerShell 5+, Markdown, JSON, YAML-like line parsing, Pester-style script verification via PowerShell assertions

---

### Task 1: Metadata model and test fixture scaffolding

**Files:**
- Create: `docs/superpowers/plans/2026-04-10-integration-capability-catalog.md`
- Create: `skills/catalog.yaml`
- Modify: `mcp/servers.yaml`
- Create: `tests/release/Release.Helpers.Tests.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
. "$PSScriptRoot\..\..\scripts\release.helpers.ps1"

$fixtureRoot = Join-Path $PSScriptRoot 'fixtures'
$null = New-Item -ItemType Directory -Force -Path $fixtureRoot

$mcp = Get-McpServersDetailed -Path (Join-Path $fixtureRoot 'servers.yaml')
if ($mcp[0].capabilities.Count -ne 2) { throw 'Expected MCP capabilities to be parsed.' }

$skills = Get-SkillsCatalog -Path (Join-Path $fixtureRoot 'catalog.yaml')
if ($skills[0].capabilities[0].id -ne 'skill.capability.sample') { throw 'Expected skill capability ids to be parsed.' }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.Helpers.Tests.ps1`
Expected: FAIL because helper script/functions do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```powershell
function Get-McpServersDetailed { param([string]$Path) return @() }
function Get-SkillsCatalog { param([string]$Path) return @() }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.Helpers.Tests.ps1`
Expected: PASS after real parsing is implemented.

- [ ] **Step 5: Commit**

```bash
git add mcp/servers.yaml skills/catalog.yaml tests/release/Release.Helpers.Tests.ps1 scripts/release.helpers.ps1 docs/superpowers/plans/2026-04-10-integration-capability-catalog.md
git commit -m "feat: add structured integration capability metadata"
```

### Task 2: Capability diff/history helpers

**Files:**
- Create: `scripts/release.helpers.ps1`
- Modify: `tests/release/Release.Helpers.Tests.ps1`
- Create: `manifests/integration-history.json`

- [ ] **Step 1: Write the failing test**

```powershell
$diff = Compare-CapabilitySets -Current @(
  @{ id = 'mcp.a'; kind = 'mcp'; owner = 'server-a' },
  @{ id = 'skill.a'; kind = 'skill'; owner = 'skill-a' }
) -Previous @(
  @{ id = 'mcp.a'; kind = 'mcp'; owner = 'server-a' }
)

if ($diff.New.Count -ne 1) { throw 'Expected one new capability.' }

$history = Merge-CapabilityHistory -Current @(
  @{ id = 'skill.a'; label = 'Skill A'; kind = 'skill'; owner = 'skill-a'; summary = '...'; ownerSource = 'skills/catalog.yaml' }
) -History @{} -Version 'v2026.04.10.2'

if ($history['skill.a'].introducedIn -ne 'v2026.04.10.2') { throw 'Expected introducedIn to be set.' }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.Helpers.Tests.ps1`
Expected: FAIL because diff/history helpers are missing.

- [ ] **Step 3: Write minimal implementation**

```powershell
function Compare-CapabilitySets { param($Current,$Previous) return @{ New = @(); Existing = @() } }
function Merge-CapabilityHistory { param($Current,$History,$Version) return @{} }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.Helpers.Tests.ps1`
Expected: PASS with diff/history assertions satisfied.

- [ ] **Step 5: Commit**

```bash
git add scripts/release.helpers.ps1 tests/release/Release.Helpers.Tests.ps1 manifests/integration-history.json
git commit -m "feat: track integration capability release history"
```

### Task 3: Render README and catalog sections

**Files:**
- Modify: `scripts/release.helpers.ps1`
- Modify: `scripts/release.ps1`
- Modify: `README.md`
- Modify: `docs/integration-catalog.md`
- Test: `tests/release/Release.Helpers.Tests.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
$rendered = Render-CapabilityBadge -IsNew $true
if ($rendered -notmatch 'NEW') { throw 'Expected NEW badge markup.' }

$section = New-ReadmeCapabilitySection -McpCapabilities @(
  @{ owner = 'example-local'; label = 'Local example execution'; summary = 'Runs local stdio example'; introducedIn = 'v2026.04.10.2'; isNew = $true }
) -SkillCapabilities @()

if ($section -notmatch 'style=') { throw 'Expected inline color marker.' }
if ($section -notmatch 'example-local') { throw 'Expected owner names in README section.' }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.Helpers.Tests.ps1`
Expected: FAIL because render helpers are missing.

- [ ] **Step 3: Write minimal implementation**

```powershell
function Render-CapabilityBadge { param([bool]$IsNew) if ($IsNew) { return '<span style="color:#d9480f;font-weight:600;">NEW</span>' }; return '' }
function New-ReadmeCapabilitySection { param($McpCapabilities,$SkillCapabilities) return '' }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.Helpers.Tests.ps1`
Expected: PASS with README/catalog render assertions satisfied.

- [ ] **Step 5: Commit**

```bash
git add scripts/release.helpers.ps1 scripts/release.ps1 README.md docs/integration-catalog.md tests/release/Release.Helpers.Tests.ps1
git commit -m "feat: generate capability inventories in docs"
```

### Task 4: End-to-end dry-run release verification

**Files:**
- Modify: `scripts/release.ps1`
- Test: `tests/release/Release.DryRun.Tests.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
& "$PSScriptRoot\..\..\scripts\release.ps1" -Version 'v2099.01.01.1' -Notes 'test release' -SkipGit
if ($LASTEXITCODE -ne 0) { throw 'Release dry-run should succeed.' }
if (-not (Select-String -Path 'docs/integration-catalog.md' -Pattern 'Release Diff Summary' -Quiet)) { throw 'Expected release diff summary.' }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.DryRun.Tests.ps1`
Expected: FAIL because `-SkipGit` and full rendering path do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```powershell
param(
  [string]$Version,
  [string]$Notes = 'Configuration update',
  [switch]$SkipGit
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\release\Release.DryRun.Tests.ps1`
Expected: PASS and artifacts regenerated without git commit/tag side effects.

- [ ] **Step 5: Commit**

```bash
git add scripts/release.ps1 tests/release/Release.DryRun.Tests.ps1
git commit -m "test: cover release dry-run capability generation"
```
