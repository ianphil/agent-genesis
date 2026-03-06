# Using Copilot from PowerShell

Quick reference for GitHub Copilot CLI integration with PowerShell for terminal-based AI coding assistance.

## Installation

**Prerequisites:**
- PowerShell v6 or higher
- Node.js v22+ and npm v10+
- Active GitHub Copilot subscription (Pro, Pro+, Business, or Enterprise)

**Install via npm:**
```powershell
npm install -g @github/copilot
```

Or via WinGet on Windows:
```powershell
winget install GitHub.Copilot
```

## Microsoft FTE Setup (EMU Account)

**Before running Copilot login, Microsoft employees must authenticate with the EMU account first:**

1. Navigate to Microsoft's Enterprise GitHub: https://github.com/enterprises/microsoft

2. Sign in with your Microsoft corporate credentials (if not already authenticated)

3. This grants access to internal GitHub models with:
   - **Unlimited API requests** (vs rate limits for standard accounts)
   - **Higher context windows** for larger code analysis
   - Access to enterprise-specific models and features

4. Ensure your EMU session is active before proceeding with Copilot CLI login

## Getting Started

1. Launch Copilot CLI:
   ```powershell
   copilot
   ```

2. Authenticate with `/login` command (opens browser for GitHub auth)
   - *Note for Microsoft FTEs: You should already be logged into your EMU account*

3. Trust the folder when prompted - Copilot needs permission to read files

## Basic Usage in PowerShell

**Interactive mode:**
```powershell
copilot
```
Type natural language prompts at the `>` prompt

**One-off command:**
```powershell
copilot -p "Create a script that removes all .tmp files"
```

**Run shell commands:**
Type `!` followed by command inside Copilot (e.g., `!ls -al`)

## PowerShell-Specific Tips

Create an alias for quick access with PowerShell context:
```powershell
function ?? {
  $TmpFile = New-TemporaryFile
  github-copilot-cli what-the-shell ('use powershell to ' + $args) --shellout $TmpFile
  if (Test-Path $TmpFile) {
    $TmpFileContents = Get-Content $TmpFile
    if ($TmpFileContents) {
      Invoke-Expression $TmpFileContents
      Remove-Item $TmpFile
    }
  }
}
```

Use `??` to ask questions and execute PowerShell scripts directly.

## Official Resources

- **GitHub Docs - Using Copilot CLI:** https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli
- **GitHub Copilot CLI Repository:** https://github.com/github/copilot-cli
- **Microsoft Learn - Copilot for PowerShell:** https://learn.microsoft.com/en-us/shows/github-copilot-series/copilot-for-powershell
- **Scott Hanselman - GitHub Copilot for CLI for PowerShell:** https://www.hanselman.com/blog/github-copilot-for-cli-for-powershell
- **Microsoft DevBlog - Windows Terminal with Copilot CLI:** https://developer.microsoft.com/blog/making-windows-terminal-awesome-with-github-copilot-cli

## Common Use Cases

- Explain code structure: `"Explain the structure of this repository"`
- Generate scripts: `"Write a PowerShell script to backup this directory"`
- Debug issues: `"Fix the error in app.js"`
- Git operations: `"How can I rebase my last three commits?"`
