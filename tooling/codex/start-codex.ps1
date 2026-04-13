param(
    [string]$Prompt,
    [switch]$PreviewPrompt,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CodexArgs
)

function Get-HomeRoot {
    if (-not [string]::IsNullOrWhiteSpace($HOME)) {
        return $HOME
    }

    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        return $env:USERPROFILE
    }

    return [Environment]::GetFolderPath('UserProfile')
}

function Resolve-CodexCommand {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_BIN)) {
        return $env:CODEX_BIN
    }

    $command = Get-Command 'codex.cmd' -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        $command = Get-Command 'codex' -ErrorAction SilentlyContinue
    }

    if ($null -eq $command) {
        return $null
    }

    return $command.Source
}

$homeRoot = Get-HomeRoot
$stylePath = Join-Path $homeRoot '.codex\prompts\global-style.md'
$codexPath = Resolve-CodexCommand

if (!(Test-Path -LiteralPath $stylePath)) {
    Write-Error "Global style prompt not found: $stylePath"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($codexPath) -or !(Test-Path -LiteralPath $codexPath)) {
    Write-Error 'Codex executable not found. Set CODEX_BIN or make codex.cmd available on PATH.'
    exit 1
}

$styleText = (Get-Content -Raw -LiteralPath $stylePath).Trim()
if ([string]::IsNullOrWhiteSpace($styleText)) {
    Write-Error "Global style prompt is empty: $stylePath"
    exit 1
}

$combinedPrompt = if ([string]::IsNullOrWhiteSpace($Prompt)) {
    $styleText
} else {
    @(
        $styleText
        ''
        '---'
        'Current conversation task:'
        $Prompt.Trim()
    ) -join [Environment]::NewLine
}

if ($PreviewPrompt) {
    Write-Output "Resolved style path: $stylePath"
    Write-Output '=== Combined Prompt Preview ==='
    Write-Output $combinedPrompt
    Write-Output '=== Codex Command Preview ==='
    $previewArgs = @($CodexArgs + @('<combined-prompt>')) -join ' '
    Write-Output (('{0} {1}' -f $codexPath, $previewArgs).Trim())
    exit 0
}

$finalArgs = @()
if ($CodexArgs) {
    $finalArgs += $CodexArgs
}
$finalArgs += $combinedPrompt

& $codexPath @finalArgs
exit $LASTEXITCODE
