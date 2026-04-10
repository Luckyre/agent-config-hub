param(
    [string]$Prompt,
    [switch]$PreviewPrompt,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
)

$stylePath = 'C:\Users\PC\.claude\prompts\global-style.md'
$claudePath = 'C:\Users\PC\.local\bin\claude.exe'

if (!(Test-Path -LiteralPath $stylePath)) {
    Write-Error "Global style prompt not found: $stylePath"
    exit 1
}

if (!(Test-Path -LiteralPath $claudePath)) {
    Write-Error "claude executable not found: $claudePath"
    exit 1
}

$styleText = (Get-Content -Raw -LiteralPath $stylePath).Trim()
if ([string]::IsNullOrWhiteSpace($styleText)) {
    Write-Error "Global style prompt is empty: $stylePath"
    exit 1
}

if ($PreviewPrompt) {
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
