# Cross-Device Bootstrap Closure

## Goal

Make this repository materially closer to "clone and sync on another device" for Codex and Claude by closing the most immediate runtime gaps in MCP assets, dependency checks, and portable tooling wrappers.

## Scope

- Add a real repository-local MCP example server that matches `mcp/servers.yaml`.
- Make synced MCP config point at a runnable file on the target machine instead of a repo-relative path that breaks after sync.
- Extend environment checks so maintainers can tell whether a target machine is ready for `bootstrap/sync`.
- Remove machine-specific hardcoded paths from startup wrappers copied into `~/.codex` and `~/.claude`.
- Make sync output explicitly distinguish automated work from remaining manual steps such as plugin installation.

## Non-Goals

- Full native plugin installation for Codex or Claude.
- Package manager automation for all dependencies.
- A complete production-grade MCP feature set beyond a minimal example server.

## Requirements

### MCP Runtime Closure

- `mcp/servers.yaml` must reference a file that exists in the repository.
- After `sync`, the generated Codex and Claude MCP config must reference a path that exists on the target machine.
- The example server must support a minimal self-test path so repository verification can confirm the file is runnable.

### Environment Closure

- `doctor.ps1` must check required commands for sync execution.
- Required failures must stop `doctor` with a non-zero exit.
- Optional checks such as `openspec.cmd` should remain visible but non-blocking.

### Portable Tooling

- `tooling/codex/start-codex.ps1` and `tooling/claudex/start-claude.ps1` must derive prompt paths from the target machine home directory.
- Tool executable discovery must avoid machine-specific paths and support environment override plus PATH lookup.

### Sync UX

- `sync.ps1` must print a short summary that distinguishes:
  - automated actions completed
  - manual follow-up still required
- Plugin installation must be called out as not yet automated.
