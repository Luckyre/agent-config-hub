param(
    [string]$Prompt,
    [switch]$PreviewPrompt,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
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

function Resolve-ClaudeCommand {
    if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_BIN)) {
        return $env:CLAUDE_BIN
    }

    $command = Get-Command 'claude.exe' -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        $command = Get-Command 'claude' -ErrorAction SilentlyContinue
    }

    if ($null -eq $command) {
        return $null
    }

    return $command.Source
}

$homeRoot = Get-HomeRoot
$stylePath = Join-Path $homeRoot '.claude\prompts\global-style.md'
$claudePath = Resolve-ClaudeCommand

if (!(Test-Path -LiteralPath $stylePath)) {
    Write-Error "Global style prompt not found: $stylePath"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($claudePath) -or !(Test-Path -LiteralPath $claudePath)) {
    Write-Error 'Claude executable not found. Set CLAUDE_BIN or make claude available on PATH.'
    exit 1
}

$styleText = (Get-Content -Raw -LiteralPath $stylePath).Trim()
if ([string]::IsNullOrWhiteSpace($styleText)) {
    Write-Error "Global style prompt is empty: $stylePath"
    exit 1
}

if ($PreviewPrompt) {
    Write-Output "Resolved style path: $stylePath"
    Write-Output '=== Appended System Prompt Preview ==='
    Write-Output $styleText
    Write-Output '=== Claude Command Preview ==='

    $previewParts = @($claudePath, '--append-system-prompt', '<global-style>')
    if ($ClaudeArgs) {
        $previewParts += $ClaudeArgs
    }
    if (![string]::IsNullOrWhiteSpace($Prompt)) {
        $previewParts += '<user-prompt>'
    }

    Write-Output ($previewParts -join ' ')
    exit 0
}

$finalArgs = @('--append-system-prompt', $styleText)
if ($ClaudeArgs) {
    $finalArgs += $ClaudeArgs
}
if (![string]::IsNullOrWhiteSpace($Prompt)) {
    $finalArgs += $Prompt.Trim()
}

& $claudePath @finalArgs
exit $LASTEXITCODE
