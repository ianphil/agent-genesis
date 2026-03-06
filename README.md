# Agent Genesis

Build a persistent AI chief of staff — an agent with identity, memory, and growing capability — using GitHub Copilot and a markdown repository.

This repo is both the bootstrap kit and the growth path: start from nothing, end up with an agent that knows you, remembers across sessions, and runs your operation.

## Start Here

**[`genesis/GENESIS.md`](genesis/GENESIS.md)** — The bootstrap wizard. Drop it into an empty repo, start a Copilot session, and it walks you through building your agent from scratch. Self-deleting — it replaces itself when the job is done.

**[`genesis/quickstart.md`](genesis/quickstart.md)** — The manual path. Step-by-step guide if you prefer to understand each piece as you build it.

## Capabilities

Feature guides for an agent that already exists. Each one adds a new dimension:

| Guide | What it adds |
|-------|-------------|
| [Heartbeat](capabilities/heartbeat.md) | Ambient pattern scanning on a schedule |
| [Morning Briefing](capabilities/morning-briefing.md) | Automated daily report across all your surfaces |
| [Switchboard](capabilities/switchboard/switchboard.md) | Teams mention monitor — the agent's inbox |
| [MCPorter + Agency](capabilities/mcporter-agency.md) | Microsoft 365 access via CLI |
| [QMD Mind Search](capabilities/qmd-mind-search.md) | Hybrid search (keyword + semantic) across the mind |

## Craft

The thinking behind the system:

| Article | About |
|---------|-------|
| [Building a Chief of Staff](craft/building-a-chief-of-staff.md) | Full walkthrough — identity, memory, retrieval, continuity |
| [Building an Agent with Attitude](craft/building-an-agent-with-attitude.md) | Why personality is load-bearing, not cosmetic |
| [How an Agent Uses IDEA](craft/how-an-agent-uses-idea.md) | Agent-perspective on operating inside the knowledge structure |
| [IDEA Notes Setup](craft/IDEA-notes-setup.md) | The knowledge structure method |
| [Git Orphan Branch Publishing](craft/git-orphan-branch-public-publishing.md) | Selectively publish from a private repo |

## Skills

Portable Copilot skills in [`.github/skills/`](.github/skills/) — drop them into any agent's repo:

- **commit** — stage, write session observations, commit, push
- **capture** — classify and place knowledge in the mind
- **daily-report** — morning briefing generator
- **qmd** — hybrid search skill
- **share** — publish to a public repo via orphan branch
- **skill-creator** — create, test, and benchmark new skills

## Origin

This grew out of [Miss Moneypenny](https://github.com/ianphil/miss-moneypenny) — an AI chief of staff built on Copilot. What started as personal notes became a bootstrap kit when others started building their own agents. Six chiefs of staff and counting.
