# Bootstrap — CoS Agent Alias in PowerShell

How to set up a one-word command in your PowerShell profile that launches your AI Chief of Staff with the right agent, the right file access, and a morning greeting when you open a terminal.

## Prerequisites

- GitHub Copilot CLI installed (`npm install -g @github/copilot` or `winget install GitHub.Copilot`)
- A Copilot agent configured (via `copilot-instructions.md` or `.github/copilot-instructions.md` in your mind repo)
- PowerShell v6+

## 1. Open Your Profile

```powershell
code $PROFILE
```

If the file doesn't exist yet, create it:

```powershell
New-Item -Path $PROFILE -ItemType File -Force
code $PROFILE
```

## 2. Add the Agent Alias

The core pattern — a function that wraps `copilot` with your agent name and any directories it needs access to:

```powershell
function moneypenny { copilot --agent miss-moneypenny --add-dir c:\src @args }
```

Breaking this down:

| Flag | Purpose |
|------|---------|
| `--agent <name>` | Selects a named agent configuration. Copilot looks for this in your repo's agent setup |
| `--add-dir <path>` | Grants file access to directories outside the current working directory. Your agent can read and edit files across all repos under that path without needing to `cd` |
| `@args` | PowerShell splatting — passes any additional arguments through (e.g., `-p "prompt"`) |

**Multiple directories:**

```powershell
function friday { copilot --agent friday --add-dir ~/workspace --add-dir ~/notes @args }
```

**Minimal version** (no extra directories):

```powershell
function donna { copilot --agent donna @args }
```

## 3. Add a Morning Greeting (Optional)

If your agent generates a daily briefing file, display it automatically when you open a new shell:

```powershell
$briefingFile = "C:\src\my-agent-mind\.working-memory\briefing.md"
if (Test-Path $briefingFile) {
    $lastWrite = (Get-Item $briefingFile).LastWriteTime.Date
    if ($lastWrite -eq (Get-Date).Date) {
        Write-Host "`n📋 Today's briefing:" -ForegroundColor Cyan
        Get-Content $briefingFile | Write-Host
    }
}
```

This only fires if the briefing file exists and was written today — stale briefings stay quiet.

## 4. Reload

Apply changes without restarting your terminal:

```powershell
. $PROFILE
```

## Verify

```powershell
moneypenny "good morning"
```

Your agent should launch in the current directory with access to everything under `--add-dir`.

## Full Example Profile Block

```powershell
# --- AI Chief of Staff ---
function moneypenny { copilot --agent miss-moneypenny --add-dir c:\src @args }

# Morning briefing greeting
$briefingFile = "C:\src\miss-moneypenny\.working-memory\briefing.md"
if (Test-Path $briefingFile) {
    $lastWrite = (Get-Item $briefingFile).LastWriteTime.Date
    if ($lastWrite -eq (Get-Date).Date) {
        Write-Host "`n📋 Today's briefing:" -ForegroundColor Cyan
        Get-Content $briefingFile | Write-Host
    }
}
```

## See Also

- [[Building a Chief of Staff]] — the full walkthrough for setting up a persistent AI CoS
- [[Bootstrap — Morning Briefing]] — how to set up the automated daily briefing that feeds the greeting
- [[Bootstrap — Heartbeat]] — recurring ambient scans that keep your agent's memory fresh
