$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$serverPath = Join-Path $repoRoot 'mcp\example-server.js'

if (-not (Test-Path -LiteralPath $serverPath)) {
  throw 'Expected example MCP server file to exist.'
}

$output = & node $serverPath --self-test
if ($LASTEXITCODE -ne 0) {
  throw 'Expected example MCP server self-test to exit with code 0.'
}
if ($output -notmatch 'example-local self-test ok') {
  throw 'Expected example MCP server self-test output.'
}

'MCP example server tests passed.'
