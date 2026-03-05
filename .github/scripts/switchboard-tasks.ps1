<#
.SYNOPSIS
    Switchboard Tasks — fetch Teams messages and filter for @mentions.
    Called by switchboard.ps1. No AI — pure PowerShell + MCPorter.

.DESCRIPTION
    Iterates through monitored chat IDs, fetches recent messages via MCPorter,
    filters for @mentions matching your agent's name, skips already-processed
    messages via state file, and outputs matching messages as JSON.

.OUTPUTS
    JSON array of mention objects to stdout, or empty string if nothing found.
#>

param(
    [string]$VaultRoot = "C:\path\to\your\mind"    # <-- UPDATE THIS
)

# --- Config ---
$ChatIds = @(
    "48:notes"                                       # Your personal Notes chat
    # "19:your-channel-id-here"                    # Add more channel IDs here
)
$MentionPattern = "(?i)@myagent\b"                   # <-- UPDATE THIS (your agent's @mention)
$MessagesPerFetch = 15
$StateFile = Join-Path $VaultRoot ".working-memory\switchboard-state.json"

# --- Load State (last-seen message ID per channel) ---
if (Test-Path $StateFile) {
    $state = Get-Content $StateFile -Raw | ConvertFrom-Json
} else {
    $state = @{}
}

# --- Collect Results ---
$results = @()

foreach ($chatId in $ChatIds) {

    $lastSeenId = $null
    if ($state.PSObject.Properties[$chatId]) {
        $lastSeenId = $state.$chatId
    }

    $ErrorActionPreference = "Continue"
    $raw = npx mcporter call teams ListChatMessages chatId:"$chatId" top:$MessagesPerFetch 2>&1
    $ErrorActionPreference = "Stop"

    # Extract JSON from mcporter output (skip node warnings)
    $jsonLines = $raw | Where-Object { $_ -is [string] -and $_ -notmatch "ExperimentalWarning|node --trace-warnings|^\s*$" }
    $jsonText = ($jsonLines -join "`n").Trim()

    $jsonStart = $jsonText.IndexOf('{')
    if ($jsonStart -lt 0) { continue }
    $jsonText = $jsonText.Substring($jsonStart)

    $response = $jsonText | ConvertFrom-Json

    if (-not $response.messages) { continue }

    # Track the newest message ID for state update
    $newestId = $response.messages[0].id

    foreach ($msg in $response.messages) {
        # Skip system messages
        if (-not $msg.from.displayName) { continue }

        # Stop if we've reached already-processed messages
        if ($msg.id -eq $lastSeenId) { break }

        $content = $msg.body.content
        # Strip HTML for pattern matching
        $plainText = $content -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '&#\d+;', ''

        if ($plainText -match $MentionPattern) {
            $results += @{
                chatId    = $chatId
                messageId = $msg.id
                from      = $msg.from.displayName
                timestamp = $msg.createdDateTime
                content   = $plainText.Trim()
            }
        }
    }

    # Update state with newest message ID
    if ($newestId) {
        $state | Add-Member -NotePropertyName $chatId -NotePropertyValue $newestId -Force
    }
}

# --- Save Updated State ---
$state | ConvertTo-Json -Depth 2 | Set-Content $StateFile

# --- Output Results ---
if ($results.Count -gt 0) {
    $results | ConvertTo-Json -Depth 3 -Compress
}
