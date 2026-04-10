param(
    [string]$Prompt,
    [switch]$PreviewPrompt,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CodexArgs
)

$stylePath = 'C:\Users\PC\.codex\prompts\global-style.md'
$codexPath = 'C:\Program Files\nodejs\codex.cmd'

if (!(Test-Path -LiteralPath $stylePath)) {
    Write-Error "Global style prompt not found: $stylePath"
    exit 1
}

if (!(Test-Path -LiteralPath $codexPath)) {
    Write-Error "codex.cmd not found: $codexPath"
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
        '以下是本次会话的用户任务：'
        $Prompt.Trim()
    ) -join [Environment]::NewLine
}

if ($PreviewPrompt) {
    Write-Output '=== Combined Prompt Preview ==='
    Write-Output $combinedPrompt
    Write-Output '=== Codex Command Preview ==='
    $previewArgs = @($CodexArgs + @('<combined-prompt>')) -join ' '
    Write-Output ('{0} {1}' -f $codexPath, $previewArgs).Trim()
    exit 0
}

$finalArgs = @()
if ($CodexArgs) {
    $finalArgs += $CodexArgs
}
$finalArgs += $combinedPrompt

& $codexPath @finalArgs
exit $LASTEXITCODE
