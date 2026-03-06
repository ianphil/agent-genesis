# Bootstrap — MCPorter + Agency (Microsoft 365 Tools for AI Agents)

MCPorter gives your AI agent **direct CLI access to MCP servers** — no sidecar process eating context budget, no schema bloat flattening personality. Agency provides **Microsoft's MCP servers** (Teams, Mail, Calendar, ADO, and more) with zero config.

Together they're how an AI Chief of Staff reads Teams, posts messages, queries email, and checks calendars — all from simple CLI calls that any automation script can use.

## Why This Pattern

Most MCP setups load servers as always-on sidecars. Every tool schema gets injected into your agent's context window on every turn — even when the agent doesn't need them. For an agent with personality and memory, that schema bloat is a tax on quality.

The MCPorter pattern flips this: **call tools on demand via CLI, not always-loaded context.** Your agent learns the call patterns once (in its instructions or skills) and invokes them only when needed. Zero overhead on quiet turns.

## Prerequisites

- **Node.js** 18+ (for `npx`)
- **Microsoft work/school account** (for Agency's Entra ID auth)

## Step 1: Install Agency

Agency is Microsoft's agent platform CLI. It provides pre-configured MCP servers for Microsoft 365 services.

**Windows:**
```powershell
iex "& { $(irm aka.ms/InstallTool.ps1)} agency"
```

**macOS / Linux:**
```bash
curl -sSfL https://aka.ms/InstallTool.sh | sh -s agency && exec $SHELL -l
```

Verify:
```bash
agency --help
```

## Step 2: Configure MCPorter

Create `~/.mcporter/mcporter.json`:

```json
{
  "mcpServers": {
    "teams": {
      "command": "agency",
      "args": ["mcp", "teams"],
      "lifecycle": "keep-alive"
    }
  }
}
```

The `lifecycle: "keep-alive"` setting tells MCPorter to keep the Teams MCP server running as a daemon between calls — faster response on subsequent calls, no cold start.

### Available Agency MCP Servers

Agency ships with many servers. Add whichever you need:

| Server | Command | What It Does |
|--------|---------|--------------|
| `teams` | `agency mcp teams` | Read/post Teams messages, list chats |
| `mail` | `agency mcp mail` | Read/send email |
| `calendar` | `agency mcp calendar` | Read/manage calendar events |
| `ado` | `agency mcp ado` | Azure DevOps work items, PRs, pipelines |
| `enghub` | `agency mcp enghub` | Search EngineeringHub (eng.ms) docs |
| `workiq` | `agency mcp workiq` | Natural language M365 queries |
| `kusto` | `agency mcp kusto` | Azure Kusto/ADX queries |
| `icm` | `agency mcp icm` | Incident management |

Example config with multiple servers:

```json
{
  "mcpServers": {
    "teams": {
      "command": "agency",
      "args": ["mcp", "teams"],
      "lifecycle": "keep-alive"
    },
    "mail": {
      "command": "agency",
      "args": ["mcp", "mail"],
      "lifecycle": "keep-alive"
    },
    "calendar": {
      "command": "agency",
      "args": ["mcp", "calendar"],
      "lifecycle": "keep-alive"
    }
  }
}
```

## Step 3: Verify

List available tools:
```bash
npx mcporter list teams
```

This shows every tool the Teams MCP server exposes, with typed signatures you can copy-paste into calls.

Send a test message to your personal Notes chat:
```bash
npx mcporter call teams PostMessage chatId:"48:notes" content:"Hello from MCPorter" contentType:"text"
```

Read recent messages:
```bash
npx mcporter call teams ListChatMessages chatId:"48:notes" top:5
```

## Step 4: Wire Into Your Agent

The key insight: **your agent doesn't need MCP loaded as a sidecar.** It just needs to know the CLI patterns. Teach it via instructions or skills.

### In agent instructions or skills:

```markdown
To post to Teams, use MCPorter:
  npx mcporter call teams PostMessage chatId:"<id>" content:"<message>" contentType:"text"

For HTML content with links or formatting, use the --args pattern:
  $payload = @{chatId="48:notes"; contentType="html"; content="<b>Bold</b>"} | ConvertTo-Json -Compress
  npx mcporter call teams PostMessage --args $payload
```

### Common Teams patterns:

```bash
# List your chats (find chat IDs)
npx mcporter call teams ListChats

# Read messages from a chat
npx mcporter call teams ListChatMessages chatId:"48:notes" top:15

# Post a plain text message
npx mcporter call teams PostMessage chatId:"48:notes" content:"Hello" contentType:"text"

# Post an HTML message (for rich formatting)
npx mcporter call teams PostMessage chatId:"48:notes" content:"<b>Hello</b>" contentType:"html"
```

### The `--args` pattern (for complex content):

When your message contains URLs, quotes, or special characters, the `key:value` syntax can break. Use `--args` with JSON instead:

```powershell
$payload = @{
    chatId = "48:notes"
    contentType = "html"
    content = '<p>Check <a href="https://example.com">this link</a></p>'
} | ConvertTo-Json -Compress
npx mcporter call teams PostMessage --args $payload
```

```bash
# Bash equivalent
npx mcporter call teams PostMessage --args '{"chatId":"48:notes","contentType":"html","content":"<p>Hello</p>"}'
```

## Daemon Mode

MCPorter can run MCP servers as background daemons. When `lifecycle: "keep-alive"` is set in config, the first call starts the server and subsequent calls reuse it. The daemon state lives in `~/.mcporter/daemon/`.

To check daemon status:
```bash
npx mcporter daemon status
```

## Tips

- **Start with Teams only.** Add more servers as you need them — each one adds auth surface and daemon overhead.
- **`48:notes`** is your personal Teams Notes chat — useful as an operator channel between you and your agent.
- **Use `npx mcporter list <server> --schema`** to see full tool schemas when debugging call arguments.
- **HTML mode** (`contentType:"html"`) supports full HTML: `<b>`, `<em>`, `<ul>`, `<table>`, `<code>`, `<a href>`, `<hr/>`, etc.
- **Bare URLs don't auto-link** in HTML mode — wrap them in `<a href="...">` tags.

## Further Reading

- [MCPorter GitHub](https://github.com/steipete/mcporter) — full CLI reference, TypeScript API, code generation
- [MCPorter CLI Reference](https://github.com/steipete/mcporter/blob/main/docs/cli-reference.md)
- [Agency](https://aka.ms/agency) — Microsoft's agent platform
