# Cross-Device Bootstrap Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the most immediate gaps preventing this repo from being practically reusable on another device without rebuilding Codex/Claude runtime config from scratch.

**Architecture:** Add a minimal repository-local MCP server and make sync rewrite runtime MCP paths to the live snapshot so generated config is runnable after sync. Extend doctor checks and startup wrappers so bootstrap behavior becomes portable and the final sync output clearly describes what is automated versus still manual.

**Tech Stack:** PowerShell, Node.js, repository-local tests

---

### Task 1: Lock Portable Wrapper Behavior

**Files:**
- Create: `tests/tooling/StartScripts.Tests.ps1`
- Modify: `tooling/codex/start-codex.ps1`
- Modify: `tooling/claudex/start-claude.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
$tempRoot = Join-Path $PSScriptRoot 'tmp-wrapper'
$homeRoot = Join-Path $tempRoot 'home'
$binRoot = Join-Path $tempRoot 'bin'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\tooling\StartScripts.Tests.ps1`
Expected: FAIL because wrappers still use machine-specific paths.

- [ ] **Step 3: Write minimal implementation**

```powershell
$stylePath = Join-Path $HOME '.codex\prompts\global-style.md'
$codexCommand = if ($env:CODEX_BIN) { $env:CODEX_BIN } else { (Get-Command 'codex.cmd').Source }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\tooling\StartScripts.Tests.ps1`
Expected: PASS

### Task 2: Lock MCP Runtime Closure

**Files:**
- Create: `mcp/example-server.js`
- Modify: `scripts/sync.ps1`
- Modify: `tests/sync/Sync.Tests.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
if (-not (Select-String -Path $codexConfigPath -Pattern [regex]::Escape($expectedMcpPath) -Quiet)) {
  throw 'Expected Codex MCP config to point to the synced live snapshot path.'
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\sync\Sync.Tests.ps1`
Expected: FAIL because sync still writes repo-relative MCP paths and no example server exists.

- [ ] **Step 3: Write minimal implementation**

```powershell
if ($arg.StartsWith('./')) {
  return (Join-Path $LiveRoot $arg.Substring(2))
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\sync\Sync.Tests.ps1`
Expected: PASS

### Task 3: Lock Doctor Dependency Checks

**Files:**
- Create: `tests/doctor/Doctor.Tests.ps1`
- Create: `scripts/doctor.helpers.ps1`
- Modify: `scripts/doctor.ps1`
- Modify: `scripts/bootstrap.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
if (-not ($output -match 'node command')) {
  throw 'Expected doctor output to include node dependency checks.'
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\doctor\Doctor.Tests.ps1`
Expected: FAIL because doctor does not yet check runtime dependencies by tool.

- [ ] **Step 3: Write minimal implementation**

```powershell
Add-Check -Name 'node command' -Ok ($null -ne (Get-Command node -ErrorAction SilentlyContinue)) -Detail 'node is required for repository-local MCP servers'
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\doctor\Doctor.Tests.ps1`
Expected: PASS

### Task 4: Lock Sync Result Summary

**Files:**
- Modify: `scripts/sync.ps1`
- Modify: `tests/sync/Sync.Tests.ps1`
- Modify: `README.md`
- Modify: `README.en.md`

- [ ] **Step 1: Write the failing test**

```powershell
if ($codexRun.stdout -notmatch 'Manual steps remaining') {
  throw 'Expected sync output to include a manual follow-up summary.'
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\sync\Sync.Tests.ps1`
Expected: FAIL because sync only prints a single success line.

- [ ] **Step 3: Write minimal implementation**

```powershell
Write-Output 'Manual steps remaining:'
Write-Output '- Plugins registry synced, but plugin installation is not automated yet.'
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File tests\sync\Sync.Tests.ps1`
Expected: PASS
