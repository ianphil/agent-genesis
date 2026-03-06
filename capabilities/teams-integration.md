# Capability — Teams Integration (Read, Post, Monitor)

Give your AI agent the ability to read, post, and monitor Microsoft Teams chats and channels — all via CLI calls through MCPorter. No Bot Framework, no Graph API wrangling, no always-on sidecar.

This builds on the [MCPorter + Agency](mcporter-agency.md) foundation. Set that up first.

## The Pattern

Your agent stores known chat/channel IDs in its mind (instructions file, memory, or a lookup table) and calls MCPorter on demand. No discovery calls needed for routine operations — the agent already knows where to post.

```
Agent needs to post → looks up chat ID from memory → mcporter call → done
```

This matters because Teams API discovery (listing chats, searching for channels) is slow and token-expensive. Store the IDs once, use them forever.

## Core Operations

### Read Messages

```powershell
npx mcporter call teams ListChatMessages chatId:"<thread-id>" top:10
```

### Post a Message (Plain Text)

```powershell
npx mcporter call teams PostMessage chatId:"<thread-id>" content:"Your message here"
```

### Post a Message (HTML — Preferred for Structured Content)

```powershell
npx mcporter call teams PostMessage chatId:"<thread-id>" content:"<h3>Title</h3><p>Body</p>" contentType:"html"
```

### Post with Links (Use --args Pattern)

The `key:value` syntax breaks on `<a href="...">` tags — inner quotes confuse the parser. Use `--args` with JSON instead:

```powershell
$payload = @{
    chatId = "<thread-id>"
    contentType = "html"
    content = '<p>Check <a href="https://example.com">this link</a> for details.</p>'
} | ConvertTo-Json -Compress
npx mcporter call teams.PostMessage --args $payload
```

### Search Messages

```powershell
npx mcporter call teams SearchTeamsMessages query:"search terms"
```

### Find a Chat ID (One-Time Discovery)

```powershell
npx mcporter call teams ListChats topic:"Channel Name"
```

Once you have the ID, store it in your agent's instructions or memory — don't discover it every time.

## Store Chat IDs in the Mind

This is the single biggest efficiency win. Instead of calling `ListChats` every time your agent needs to post, store known IDs where the agent can find them:

```markdown
## Teams Channels

| Chat Name | Thread ID |
|-----------|-----------|
| My Notes | 48:notes |
| Team Chat | 19:{thread-id-here} |
| Project Channel | 19:{channel-id-here} |
```

Put this in your agent's instructions file, a dedicated config note, or wherever your agent reads context at session start. The ID format is stable — once discovered, it doesn't change.

**Why this matters:** Each `ListChats` call costs time and tokens. An agent that posts to 3 channels daily saves hundreds of unnecessary API calls per week by just... remembering.

## HTML Formatting Reference

Teams supports rich HTML in messages when using `contentType:"html"`. Key tags:

| Tag | Use For |
|-----|---------|
| `<h3>`, `<h4>` | Section headers (native Teams sizes) |
| `<b>`, `<i>`, `<u>`, `<s>` | Text formatting |
| `<ul><li>`, `<ol><li>` | Lists (nesting works) |
| `<a href="url">` | Clickable links (must use `--args` pattern) |
| `<code>` | Inline code / status tags |
| `<pre>` | Code blocks |
| `<table>` | Tabular data (`<th>`, `<td>`, `<tr>` all work) |
| `<blockquote>` | Callouts |
| `<hr/>` | Horizontal rule / separator |
| `<br/>` | Line breaks |
| `<p>` | Paragraphs with spacing |

### What Does NOT Work

- **Markdown** — `**bold**`, `- bullets`, `# headers` render as literal text
- **Inline CSS** — `style=""` attributes are stripped by Teams
- **Adaptive Cards** — require Bot Framework, not supported via MCPorter
- **Bare URLs in HTML mode** — Teams only auto-links URLs in `text` mode; in `html` mode, use `<a href>` tags
- **`<h1>`, `<h2>`** — oversized; stick with `<h3>`/`<h4>`

### Send Raw HTML, Not Entities

```
✅  content:"<b>This works</b>"
❌  content:"&lt;b&gt;This breaks&lt;/b&gt;"
```

## Emoji on Windows (Automated Runs)

Windows PowerShell defaults to system locale encoding, which corrupts multi-byte emoji (📋 → `�`) in Task Scheduler or automated sessions. Fix:

```powershell
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

Run this at the top of any script that posts emoji via MCPorter.

## Less Common Tools

| Tool | Purpose |
|------|---------|
| `GetChat` | Chat metadata |
| `GetChatMessage` | Single message by ID |
| `ListChatMembers` | Members of a chat |
| `ListChannels` | Channels in a team (needs `teamId`) |
| `PostChannelMessage` | Post to a team channel (needs `teamId` + `channelId`) |
| `ReplyToChannelMessage` | Reply in a thread |
| `UpdateChatMessage` | Edit a sent message |

## Putting It Together

A typical agent Teams workflow:

1. **Session start** — agent reads its stored chat IDs from memory/config
2. **Monitoring** — scheduled script fetches recent messages, filters for @mentions
3. **Triage** — agent classifies mentions (reply, escalate, observe)
4. **Response** — agent posts via MCPorter using stored chat IDs, HTML formatting, and signature
5. **State** — agent tracks last-seen message IDs to avoid reprocessing

The [Switchboard](switchboard/) capability guide covers steps 2–5 in detail.
