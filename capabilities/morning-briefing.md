# Bootstrap — Morning Briefing

Sets up the daily morning briefing that runs Moneypenny autonomously to generate a report covering ADO work items, M365 (Teams, email, calendar), and mind-wide pattern scanning.

## What It Does

1. Runs `copilot --agent miss-moneypenny` with a structured prompt
2. Generates a full daily report → `.working-memory/briefings/YYYY-MM-DD.md`
3. Generates a condensed terminal greeting → `.working-memory/briefing.md`
4. Logs each run → `.working-memory/briefings/run-log.md`

## Prerequisites

- **Copilot CLI** installed and authenticated (`copilot` on PATH)
- **WorkIQ** installed and authenticated (for M365 queries — email, calendar, Teams)
- **Azure CLI** with DevOps extension (`az boards`) for ADO queries
- **pwsh** (PowerShell 7+)
- Repo cloned to a known path (default: `C:\src\miss-moneypenny`)

## Setup — Windows Task Scheduler

### Create the Task

```powershell
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\src\miss-moneypenny\.github\scripts\morning-briefing.ps1"' `
    -WorkingDirectory "C:\src\miss-moneypenny"

$trigger = New-ScheduledTaskTrigger `
    -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday `
    -At "10:30AM"

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "MorningBriefing" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Moneypenny daily morning briefing — ADO, M365, mind scan"
```

### Schedule

- **When:** 10:30 AM ET, weekdays (Mon–Fri)
- **RunAs:** Current user (needs to be logged in, or configure "Run whether user is logged on or not")
- **DaysOfWeek value:** 62 (Mon=2 + Tue=4 + Wed=8 + Thu=16 + Fri=32)

## Setup — Linux (cron)

```bash
# Edit crontab
crontab -e

# Add (10:30 AM ET = 15:30 UTC during EST, 14:30 UTC during EDT)
30 15 * * 1-5 cd /home/$USER/src/miss-moneypenny && pwsh -NoProfile -ExecutionPolicy Bypass -File .github/scripts/morning-briefing.ps1 >> /tmp/moneypenny-briefing.log 2>&1
```

**Note:** Linux machines may not have WorkIQ or ADO CLI. The briefing will still run but those sections will be empty. Consider whether it's worth running on machines without M365/ADO access.

## PowerShell Profile Greeting

Add to `$PROFILE` so the condensed briefing shows when you open a terminal:

```powershell
# Morning briefing greeting
$briefingFile = "C:\src\miss-moneypenny\.working-memory\briefing.md"
if (Test-Path $briefingFile) {
    $lastWrite = (Get-Item $briefingFile).LastWriteTime.Date
    if ($lastWrite -eq (Get-Date).Date) {
        Write-Host ""
        Get-Content $briefingFile
        Write-Host ""
    }
}
```

Adjust the path if the repo lives somewhere else on the machine.

## Verification

After setup, confirm:

1. `Get-ScheduledTask -TaskName "MorningBriefing"` shows **Ready**
2. Trigger time, working directory, and script path are correct
3. Run manually: `pwsh -NoProfile -ExecutionPolicy Bypass -File .github/scripts/morning-briefing.ps1`
4. Check `.working-memory/briefings/run-log.md` for SUCCESS entry
5. Check `.working-memory/briefing.md` exists and has today's date
6. Open a new terminal — greeting should display

## Troubleshooting

| Symptom | Likely Cause |
|---------|--------------|
| No briefing file generated | Copilot CLI not on PATH, or not authenticated |
| Briefing appears in wrong directory | Script has stale path references — check for `.ainotes` remnants |
| WorkIQ sections empty | WorkIQ not installed or token expired — run `workiq auth` |
| Run log shows ERROR | Check the `YYYY-MM-DD-error.log` file in briefings directory |
| Terminal greeting doesn't show | `$PROFILE` path doesn't match briefing file location |
| Task shows "Ready" but never runs | Machine was asleep/off at trigger time — enable "Start when available" |

## Key Files

- Script: `.github/scripts/morning-briefing.ps1`
- Output: `.working-memory/briefings/YYYY-MM-DD.md`
- Condensed: `.working-memory/briefing.md`
- Run log: `.working-memory/briefings/run-log.md`
- Task config: `.working-memory/heartbeat-tasks.md` (queue items the briefing may consume)
