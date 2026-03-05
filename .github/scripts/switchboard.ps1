<#
.SYNOPSIS
    Switchboard — Teams mention monitor and triage system.
    Runs every 15 minutes 9 AM–5 PM ET weekdays via Task Scheduler.

.DESCRIPTION
    1. Runs switchboard-tasks.ps1 to fetch new @mentions
    2. If mentions found, invokes copilot to triage and respond
    3. If no mentions, logs "all quiet" and exits (zero AI cost)
    All runs logged to .working-memory/briefings/run-log.md.
#>

$ErrorActionPreference = "Continue"

# --- Encoding (emoji support) ---
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- Config ---
$VaultRoot = "C:\path\to\your\mind"          # <-- UPDATE THIS
$AgentName = "my-cos"                         # <-- UPDATE THIS (your copilot agent name)
$ScriptsDir = Join-Path $VaultRoot ".github\scripts"
$BriefingsDir = Join-Path $VaultRoot ".working-memory\briefings"
$RunLog = Join-Path $BriefingsDir "run-log.md"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$TimeLabel = Get-Date -Format "HH:mm"

# Ensure directories exist
if (-not (Test-Path $BriefingsDir)) {
    New-Item -ItemType Directory -Path $BriefingsDir -Force | Out-Null
}

# --- Run Log Helper ---
function Write-RunLog {
    param([string]$Message)
    $entry = "| $Timestamp | $Message |"
    Add-Content -Path $RunLog -Value $entry
}

Write-RunLog "SWITCHBOARD STARTED ($TimeLabel)"

# --- Phase 1: Fetch Mentions ---
$StartTime = Get-Date

try {
    Set-Location $VaultRoot
    $mentionOutput = & powershell.exe -ExecutionPolicy Bypass -File (Join-Path $ScriptsDir "switchboard-tasks.ps1") -VaultRoot $VaultRoot 2>&1

    # Check if we got results
    $mentionJson = $mentionOutput | Where-Object { $_ -is [string] } | Out-String
    $mentionJson = $mentionJson.Trim()

    if (-not $mentionJson -or $mentionJson -eq "[]" -or $mentionJson -eq "" -or $mentionJson -eq "null") {
        $Duration = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        Write-RunLog "SWITCHBOARD QUIET ($TimeLabel) — ${Duration}s — no mentions"
        exit 0
    }

    # --- Phase 2: Load agents registry ---
    $AgentsFile = Join-Path $ScriptsDir "switchboard-agents.json"
    $agentsJson = ""
    if (Test-Path $AgentsFile) {
        $agentsJson = Get-Content $AgentsFile -Raw
    }

    # --- Phase 3: Triage with Copilot ---
    # NOTE: Customize this prompt for your agent's personality and triage rules.
    # The three buckets (REPLY/ESCALATE/OBSERVE) and source-aware rules are the
    # core pattern — adapt the voice and guardrails to fit your agent.
    $Prompt = @"
You are an AI Chief of Staff. This is an automated Switchboard run — your Teams mention monitor.

## New Mentions

The following messages mention you:

$mentionJson

## Agent Registry

These are fellow agents in the ecosystem. Use this to distinguish agent posts from human posts:

$agentsJson

## Instructions

1. Read your memory files first (.working-memory/)
2. For each mention, triage into one of three buckets:
   - **REPLY**: You can handle this directly (factual questions, status checks, context retrieval). Reply to the SAME channel the mention came from via MCPorter.
   - **ESCALATE**: Your operator should weigh in (decisions, opinions, anything that's their voice). Post to 48:notes with the context and your recommendation.
   - **OBSERVE**: Conversational mention, no action needed. Log it but don't reply.

3. Triage rules by source:
   - **48:notes from your operator**: Always attempt REPLY — they're giving you a task.
   - **Other channels from humans**: Triage normally — REPLY if you can handle it, ESCALATE if it needs your operator's voice.
   - **Other channels from agents**: REPLY when you have something useful to contribute. These are peers.

4. For REPLY messages, use MCPorter to post your response:
   Use the --args pattern with ConvertTo-Json for HTML content.
   Always use your signature block.
   Keep responses concise — this is async chat, not a briefing.
   **When replying to another agent, @mention them** so their switchboard picks it up.

5. For ESCALATE messages, post to 48:notes with format:
   Switchboard — [who] in [channel]: "[summary]"
   My take: [your recommendation]
   Want me to reply, or will you handle it?

6. For OBSERVE messages, just note them — no post needed.

## Guardrails

- You MAY reply to any channel a mention came from
- You MAY post to 48:notes for escalation
- You MAY NOT post to any other channel
- You MAY NOT write to ADO or send email
- Do NOT ask questions. Triage and act.
- Sign all replies with your signature block
"@

    $output = copilot --agent $AgentName -p $Prompt --yolo -s 2>&1
    $ExitCode = $LASTEXITCODE
    $Duration = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)

    if ($ExitCode -eq 0) {
        $mentionCount = ($mentionJson | ConvertFrom-Json).Count
        if (-not $mentionCount) { $mentionCount = 1 }
        Write-RunLog "SWITCHBOARD SUCCESS ($TimeLabel) — ${Duration}s — ${mentionCount} mention(s) triaged"
    }
    else {
        Write-RunLog "SWITCHBOARD ERROR ($TimeLabel) — exit code $ExitCode — ${Duration}s"
        $errorFile = Join-Path $BriefingsDir "$(Get-Date -Format 'yyyy-MM-dd')-switchboard-error.log"
        Set-Content -Path $errorFile -Value ($output -join "`n")
    }
}
catch {
    $Duration = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    Write-RunLog "SWITCHBOARD EXCEPTION ($TimeLabel) — ${Duration}s — $($_.Exception.Message)"
    $errorFile = Join-Path $BriefingsDir "$(Get-Date -Format 'yyyy-MM-dd')-switchboard-error.log"
    Set-Content -Path $errorFile -Value $_.Exception.ToString()
}
