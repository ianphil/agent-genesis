# Heartbeat Tasks — Example

Example of a real heartbeat-tasks.md file, sanitized. Use this as a starting template — adapt the standing tasks and queue to your agent's domain.

Tasks for the agent to execute during heartbeat runs. Either the human or agent can add items.

## Scope
- ✅ Mind operations: reorganize notes, archive, fix links, update mind-index, memory maintenance
- ✅ Work tracking read-only: query work items, check for stale/aging items, surface status changes
- ✅ Personal Notes chat: read for tasks from human, post summaries, acknowledge completed tasks
- ❌ No other external writes: no work item updates, no emails, no other chats, no git push

## Pacing

Every heartbeat run:
1. **Check all standing task triggers** — these are cheap condition checks, do them every time
2. **Execute any standing tasks whose triggers fired** — respect cooldowns
3. **Pick 1-2 queue items** if time allows, prioritize by age and urgency

---

## Standing Tasks

Recurring work with trigger conditions. Checked every run, executed only when conditions are met.

| Task | Trigger | Cooldown | Last Run |
|------|---------|----------|----------|
| **Mind-index refresh** | >5 new/moved/archived files since last refresh | 7 days min | 2026-03-02 |
| **Memory consolidation** | log.md >150 lines OR >14 days since last OR 3+ major decisions/new initiatives since last | 14 days min | 2026-02-28 |
| **Stale item scan** | always — multi-dimensional staleness sweep (see details) | 7 days min | 2026-03-04 |
| **Inbox triage** | >5 items in inbox/ OR any inbox item >7 days old | 7 days min | 2026-03-04 |
| **Initiative lifecycle** | any initiative with empty next-actions AND no file modified >21 days | 14 days min | 2026-03-04 |
| **1:1 prep** | today's calendar has a meeting with a direct report | daily | — |
| **Notes inbox** | new message from human addressed to agent | every run | 2026-03-04 |

### Standing Task Details

**Mind-index refresh:** Regenerate mind-index.md — scan all domains/, initiatives/, expertise/, inbox/, Archive/ for .md files. Update summaries and key concepts. Remove entries for deleted/moved files, add entries for new ones. **Validation pass:** verify all indexed paths still resolve to existing files, verify all .md files in mind folders have an entry. Report any broken links or missing entries.

**Memory consolidation:** Read log.md → distill patterns into memory.md → trim absorbed entries. Rules: preserve emotional patterns, never delete entries <3 days old, write a consolidation summary entry to log.md as audit trail. Keep memory.md under ~200 lines. **Density trigger:** if 3+ new initiatives or major architectural decisions have landed since last consolidation, consolidate early regardless of line count or date — dense weeks outpace the normal cadence.

**Stale item scan:** Multi-dimensional staleness sweep across the mind:
- **Next-actions:** Sweep all next-actions.md files across initiatives and domains. Flag items >14 days untouched. Check for cross-initiative dependency conflicts.
- **Work item snapshots:** Flag people with stale snapshots (>7 days old) for refresh.
- **People note stubs:** Flag direct-report notes with `<!-- TODO -->` placeholders — suggest filling after next 1:1.
- **Inbox count:** If inbox/ has >5 items, flag for triage (hands off to Inbox triage task if cooldown allows).

**Inbox triage:** Scan inbox/ for accumulation. For each item: classify by type (initiative material, domain knowledge, expertise, personal, actionable task). Suggest destination folder. Flag items >7 days old as overdue. The inbox is a pass-through, not a parking lot — if items are piling up, something upstream is broken.

**Initiative lifecycle:** Scan initiatives/ for dormant projects. Trigger: empty next-actions.md AND no file in the initiative folder modified in >21 days. Action: flag for archival to `Archive/initiative/`. Parked initiatives with substantial content (like execution plans) get noted as "parked with plan" — the archive preserves the work, it just clears the active view.

**1:1 prep:** Check today's calendar for meetings with direct reports. For each match, refresh their work item snapshot. If calendar access is unavailable, fall back to running for all reports.

**Notes inbox:** Read recent messages from the personal Notes chat. Look for messages addressed to the agent. For each task found: execute it (within heartbeat scope), then reply acknowledging completion or noting what couldn't be done and why. Skip messages already acknowledged by a prior heartbeat.

---

## Queue

One-shot tasks. Heartbeat picks 1-2 per run, marks done when complete.

### Open

- [ ] **Remind human to review teammate's PR** — Post to Notes chat: "PR #1234 (Feature X) needs your review. Full analysis in `inbox/pr-review-1234.md`. Key question: merge before or after resolving bug #5678?"

### Done

- [x] Add mind-index entries for new files — 2026-03-03: Added new person notes and initiative entries to mind-index.md.
- [x] Reconcile initiative next-actions with merged PRs — 2026-03-03: Confirmed 4 PRs merged. Checked off completed items, updated section headers for next phase.
- [x] Regenerate mind-index.md — 2026-03-02: Full regeneration. Added 16 new entries, fixed 5 incorrect paths, updated summaries.
- [x] Triage stale inbox items — 2026-03-02: Archived 4 items, moved 2 to expertise/. Inbox backlog cleared.
- [x] Pull GitHub issues to inbox — 2026-03-02: Captured 4 issues as inbox notes. Did NOT close issues on GitHub — external writes out of scope for heartbeat.
- [x] Update initiative execution plan — removed stale date markers, marked completed subtask, added cross-initiative dependency link — 2026-02-27
- [x] Evaluate dormant initiatives for archiving — archived 4, kept 3 still relevant — 2026-02-27
