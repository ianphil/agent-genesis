# Agent Bootstrap — Quickstart

Get a persistent AI chief of staff running in ~30 minutes. This guide connects the templates and patterns from the bootstrap collection into a concrete setup sequence.

**Prerequisites:**
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line) installed and authenticated
- A git repository to use as the agent's mind (can be an existing notes repo or a new one)
- ~30 minutes for initial setup, then organic growth over days/weeks

---

## Phase 1: Identity + Instructions (~10 min)

### 1. Create SOUL.md

Copy [`soul-template.md`](templates/soul-template.md) to `SOUL.md` at your repo root. Customize:

- **Mission** — define the division of labor ("You build, I run the building")
- **Voice** — pick a character, tone, and register. Be specific. Generic = forgettable.
- **Boundaries** — what the agent must never do (send emails without approval, share private data, etc.)

> **Tip:** You won't nail the personality on day one. Start simple, then refine through conversation. "Don't do that" and "more like this" are the fastest tuning tools.

### 2. Create the agent file

Create `.github/agents/{your-agent-name}.agent.md` using [`agent-file-template.md`](templates/agent-file-template.md) as your starting point. Key sections:

- **YAML frontmatter** — `name`, `description`, `model` (required for Copilot to discover the agent)
- **Boot sequence** — first lines tell the agent to read SOUL.md, then memory files
- **Method** — capture, execute, triage workflows
- **Memory** — three-file system instructions
- **Session handover** — the single biggest continuity improvement

### 3. Create repo instructions

Create `.github/copilot-instructions.md` with repo-wide context:

```markdown
# Copilot Instructions

## Repo Structure
This is a personal knowledge base using the IDEA method:
- `initiatives/` — projects with defined end goals
- `domains/` — recurring areas of responsibility
- `expertise/` — learning notes, patterns, frameworks
- `inbox/` — quick capture landing zone
- `Archive/` — completed or inactive items

## Committing
- Use conventional commits: `feat:`, `chore:`, `docs:`
- [Add any commit conventions specific to your workflow]
```

---

## Phase 2: Memory System (~5 min)

### 4. Create the working memory directory

```bash
mkdir -p .working-memory
```

### 5. Create memory.md

Start minimal — it grows organically. See [`working-memory-example.md`](templates/working-memory-example.md) for what a mature version looks like.

```markdown
# AI Notes — Memory

Last consolidated: [today's date]

## Architecture
- IDEA method: Initiatives, Domains, Expertise, Archive
- Three-file memory: memory.md (curated), rules.md (mistakes), log.md (raw)
- Inbox is quick-capture; items get triaged to other folders

## Conventions
- Notes use kebab-case filenames
- Wiki-links use [[Note Title]] syntax
- Each initiative has a main note + next-actions.md

## User — Context
[Add a few lines about yourself — role, what you work on, what drains your time]

## Active Initiatives
[List your current projects — even just names is fine to start]
```

### 6. Create rules.md

Start empty — it fills itself through mistakes. See [`rules-example.md`](templates/rules-example.md) for what emerges over time.

```markdown
# AI Notes — Rules

Operational rules learned from mistakes and experience. Each rule is a one-liner.
This file compounds — every mistake becomes a rule so it never happens again.
```

### 7. Create log.md

```markdown
# AI Notes — Log
```

That's it. The agent will start writing here during your first conversation.

---

## Phase 3: Mind Structure (~5 min)

### 8. Create the folder skeleton

```bash
mkdir -p initiatives domains/people expertise inbox Archive
```

### 9. Create mind-index.md

This is the agent's map of the mind. Start with a stub:

```markdown
# Mind Index

| Path | Summary | Key Concepts |
|------|---------|-------------|
| SOUL.md | Agent identity and personality | voice, boundaries, mission |
| .working-memory/memory.md | Curated long-term memory | architecture, conventions |
```

The agent will help you maintain this as the mind grows.

### 10. Gitignore ephemeral data

```bash
echo ".working-memory/briefings/" >> .gitignore
echo ".working-memory/heartbeat.md" >> .gitignore
```

Briefings contain external data (email, calendar) that shouldn't be committed.

---

## Phase 4: First Conversation (~10 min)

### 11. Start the agent

```bash
copilot --agent {your-agent-name}
```

### 12. Have the onboarding conversation

Don't try to configure everything upfront. Just talk:

- *"Here's what I do for work..."*
- *"These are my current projects..."*
- *"I manage these people..."*
- *"The thing that drains my time most is..."*

The agent will start capturing context, creating notes, and asking clarifying questions. This is the initial knowledge dump — it takes 1-2 sessions to get enough context for the agent to be genuinely useful.

### 13. End with a commit

Tell the agent to commit. A good commit skill will write session observations to working memory before staging. See the [commit skill](../.github/skills/commit/SKILL.md) for an example.

---

## Phase 5: Growth (ongoing)

These layers build organically over sessions. Don't rush them.

### Week 1: Conversation and capture
- Talk to the agent daily. Correct mistakes ("don't do that," "more like this")
- Rules.md will start accumulating — that's the system working
- Create people domains for your direct reports / key contacts
- The agent's personality will start sharpening through feedback

### Week 2: Skills and search
- Add a [daily report skill](../capabilities/morning-briefing.md) for morning briefings
- Add [QMD search](../capabilities/qmd-mind-search.md) for hybrid retrieval across the mind
- Build your first custom skill from whatever workflow you repeat most

### Week 3+: Automation and integrations
- Add a [heartbeat](../capabilities/heartbeat.md) for ambient pattern scanning
- Connect external tools (work tracking, email, calendar, chat)
- Let the commit skill and session handover become habits

---

## File Tree (complete)

```
your-repo/
  SOUL.md                              ← identity
  mind-index.md                        ← note catalog
  .gitignore
  .github/
    copilot-instructions.md            ← repo-wide context
    agents/
      {name}.agent.md                  ← operating instructions
    skills/
      commit/SKILL.md                  ← commit with memory write
      daily-report/SKILL.md            ← morning briefing
      qmd/SKILL.md                     ← search skill
  .working-memory/
    memory.md                          ← curated (read every session)
    rules.md                           ← mistakes → rules
    log.md                             ← raw observations
    heartbeat-tasks.md                 ← automated task queue
    briefings/                         ← gitignored, ephemeral
  initiatives/
    {project}/
      {project}.md
      next-actions.md
  domains/
    {team}/
      {team}.md
    people/
      {person}/
        {person}.md
  expertise/
    {topic}.md
  inbox/
    next-actions.md
    {captured-item}.md
  Archive/
```

---

## Design Principles

**Start small, grow through conversation.** The agent gets meaningfully better every session — not because the model improves, but because the *context* compounds.

**Mistakes are features.** Every correction becomes a rule. Every rule prevents a class of mistakes forever. After a month, the agent has a personal operations manual built entirely from its own failures.

**Personality is load-bearing.** An agent with a defined character writes more consistently, feels like a partner, and develops genuine rapport. Don't skip the soul — it's not cosmetic.

**Disk over context window.** Anything only in the context window is temporary. The window will compact, and specifics will be lost. Write early, write often.

**The human approves, the agent proposes.** Bold internally (reading, organizing, searching). Cautious externally (messages, work items, anything public). The agent has intimate access — it should never make you regret that.

---

## Related Resources

- [Building a Chief of Staff](../craft/building-a-chief-of-staff.md) — the full walkthrough (theory + practice)
- [How an Agent Uses IDEA](../craft/how-an-agent-uses-idea.md) — agent-perspective on operating inside the mind
- [IDEA Notes Setup](../craft/IDEA-notes-setup.md) — the knowledge structure method
- [Soul Template](templates/soul-template.md) — customizable identity document
- [Agent File Template](templates/agent-file-template.md) — operating instructions template
- [Working Memory Example](templates/working-memory-example.md) — what mature memory looks like
- [Rules Example](templates/rules-example.md) — what emerges from a month of mistakes
- [Morning Briefing](../capabilities/morning-briefing.md) — automated daily report setup
- [Heartbeat](../capabilities/heartbeat.md) — ambient pattern scanning
- [QMD Mind Search](../capabilities/qmd-mind-search.md) — hybrid search for the mind
