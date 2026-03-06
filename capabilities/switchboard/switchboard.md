# Bootstrap — Switchboard (Teams Mention Monitor)

The Switchboard gives your AI Chief of Staff a **Teams inbox**. It monitors channels for @mentions, triages each one, and either replies directly, escalates to the operator, or silently observes.

This pairs with the [Heartbeat](../heartbeat.md) (ambient mind scan) and [Morning Briefing](../morning-briefing.md) (daily report). Together they form the agent's autonomous loop: the briefing sets context, the heartbeat watches the mind, and the switchboard watches the world.

## Prerequisites

> **Start here first:** [MCPorter + Agency Bootstrap](../mcporter-agency.md) — install Agency, configure MCPorter, and verify Teams access before setting up the Switchboard.

- MCPorter configured with Teams access (see link above)
- Copilot CLI (`copilot` command available)
- Your agent configured as a copilot agent (e.g., `--agent my-cos`)
- Windows Task Scheduler (or cron on Linux/macOS)

## Architecture

```
┌─────────────────────┐
│  Task Scheduler      │  Every 15 min, 9 AM–5 PM ET weekdays
│  (switchboard.ps1)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  switchboard-tasks   │  Fetch + filter (no AI, pure PowerShell)
│  .ps1                │  • MCPorter → ListChatMessages per channel
│                      │  • Regex filter for @mentions
│                      │  • State tracking (last-seen ID per channel)
│                      │  • Dedup across runs
└──────────┬──────────┘
           │ JSON array of mentions (or empty)
           ▼
┌─────────────────────┐
│  copilot CLI         │  Only invoked if mentions found (zero AI cost otherwise)
│  --agent <your-cos>  │
│  --yolo -s           │
│                      │  Triage: REPLY / ESCALATE / OBSERVE
│                      │  Reply via MCPorter to source channel
└─────────────────────┘
```

**Key design choice:** The fetch layer (`switchboard-tasks.ps1`) has zero AI cost. It runs every 15 minutes, checks for mentions, and exits silently if nothing's there. The copilot agent only spins up when there's something to triage. Most runs are sub-5-second no-ops.

## Files

| File | Location | Purpose |
|------|----------|---------|
| `switchboard.ps1` | `.github/scripts/` | Orchestrator — fetch, triage, log |
| `switchboard-tasks.ps1` | `.github/scripts/` | Fetch layer — MCPorter + filter + state |
| `switchboard-agents.json` | `.github/scripts/` | Agent registry — who's a CoS vs. a human |
| `switchboard-state.json` | `.working-memory/` | Runtime state — last-seen message ID per channel |

## Setup

### 1. Copy the scripts

Place `switchboard.ps1` and `switchboard-tasks.ps1` in your `.github/scripts/` directory. Update the `$VaultRoot` path in both to match your mind's root.

### 2. Configure monitored channels

In `switchboard-tasks.ps1`, set `$ChatIds` to the Teams channel IDs you want to monitor:

```powershell
$ChatIds = @(
    "48:notes",                                              # Your personal Notes chat
    "19:your-channel-id-here"                              # A group chat
)
```

To find a chat ID, use MCPorter: `npx mcporter call teams ListChats` and look for the `id` field.

### 3. Configure mention pattern

The default pattern matches your agent's short name. Change it to match yours:

```powershell
$MentionPattern = "(?i)@<your-agent-name>\b"
```

### 4. Set up the agents registry

Create `switchboard-agents.json` to help your agent distinguish CoS agents from humans:

```json
{
  "agents": [
    {
      "name": "Your Agent Name",
      "shortname": "youragent",
      "operator": "Your Name",
      "mention": "@youragent",
      "active": true
    }
  ]
}
```

When replying to a CoS agent, your agent should @mention them so their switchboard picks it up — enabling agent-to-agent conversation.

### 5. Create Task Scheduler task

```powershell
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\path\to\your\.github\scripts\switchboard.ps1"' `
    -WorkingDirectory "C:\path\to\your\mind"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At "9:00AM"
$trigger.Repetition = (New-ScheduledTaskTrigger -Once -At "9:00AM" `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Hours 8 -Minutes 15)).Repetition

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask -TaskName "YourAgentSwitchboard" `
    -Action $action -Trigger $trigger -Settings $settings `
    -Description "Teams mention monitor — every 15 min during work hours"
```

### 6. Initialize state

The state file is created automatically on first run. To start fresh:

```json
{}
```

Place at `.working-memory/switchboard-state.json`.

## Triage Model

The switchboard prompt gives your agent three buckets:

| Bucket | When | Action |
|--------|------|--------|
| **REPLY** | Agent can handle directly (facts, status, context) | Post response to source channel |
| **ESCALATE** | Needs operator judgment (decisions, opinions, voice) | Post summary + recommendation to operator's channel |
| **OBSERVE** | Conversational mention, no action needed | Log it, stay quiet |

### Source-Aware Rules

- **Operator's channel**: Always attempt REPLY — they're giving you a task
- **Group channels from humans**: Triage normally
- **Group channels from CoS agents**: REPLY as peers — @mention them so their switchboard picks it up

## Tuning

- **Frequency**: 15 minutes balances responsiveness with cost. Tighter intervals (5 min) for high-traffic channels, longer (30 min) for quiet ones.
- **Messages per fetch**: Default 15. Increase if a channel is high-volume and you might miss mentions between runs.
- **Self-mention filtering**: The fetch layer doesn't currently filter out your own posts. If your agent posts with its @mention in the content, it'll pick itself up next run. Low priority — the triage layer handles it gracefully (OBSERVE).
- **Run logging**: All runs are logged to `.working-memory/briefings/run-log.md` — useful for debugging and monitoring cost.

## Cost Model

- **Quiet run** (no mentions): ~2 seconds, zero AI tokens. Just MCPorter fetch + regex.
- **Active run** (mentions found): Full copilot invocation. Cost depends on your model and context. Typically 30–90 seconds.
- **Daily budget**: At 15-minute intervals across 8 hours = 33 checks. Most will be quiet. Expect 1–5 active runs per day in a typical team channel.
