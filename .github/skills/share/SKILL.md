---
description: Publish files to the public repo. Use when the user asks to "share this", "publish this note", "push to public", or wants to make a specific file available publicly.
name: share
---

# Share — Publish to Public Repo

Publish selected files from the private mind to a public repo via an orphan branch worktree. Handles checkout, PII review, commit, and push in one guided flow.

## When to Use

When the user asks to "share this", "publish this note", "push to public", or wants to make a specific file available in the public repo.

## Prerequisites

- A git worktree for the public branch (e.g., at `~/public-notes` on branch `public-branch`)
- A remote (e.g., `public`) pointing to the public repo
- Optionally, a pre-commit hook for PII scanning

## Workflow

### Step 1: Identify the File(s)

Confirm which file(s) to publish. Accept paths relative to the private repo root.

If the user says something vague like "share the attitude doc", resolve it to the actual path before proceeding.

### Step 2: PII Pre-Check

Before touching the worktree, read each file and scan for PII yourself:

- **Real names** (team members, contacts — except the user's first name)
- **ADO identifiers** (org URLs, project names, area paths, work item IDs)
- **Teams thread IDs** (`@thread.v2`, `@thread.tacv2`)
- **Internal email addresses or corporate aliases**
- **Sensitive file paths** from the private repo

If PII is found, **stop and tell the user**. Show exactly what needs scrubbing and where. Do NOT proceed until the file is clean.

If the file needs modifications for public consumption (removing private context, generalising examples), make the edits in the private repo first, then proceed. This keeps the private repo as the source of truth.

### Step 3: Checkout to Worktree

From the worktree directory, pull the file from master:

```bash
cd ~/public-notes
git checkout master -- path/to/file.md
```

If the file needs to land at a different path in the public repo, copy it manually instead of using `git checkout`.

### Step 4: Review the Diff

Show what's about to be committed:

```bash
git diff --cached --stat
git diff --cached
```

If nothing is staged, stage it first:

```bash
git add -A
git diff --cached --stat
```

Show the user what's changing and confirm before committing.

### Step 5: Commit and Push

```bash
git commit -m "Add {brief description}"
git push public public-branch:main
```

Clean commit message. No trailers.

The pre-commit hook (if configured) will run automatically and block the commit if it detects PII patterns.

### Step 6: Confirm

Verify the push succeeded:

```bash
git log --oneline -1
```

Tell the user the file is live and link to the public repo.

## Safety Rails

- **NEVER push the main private branch to the public remote.** Only the orphan `public-branch`.
- **NEVER bulk-copy.** Each file is a deliberate choice.
- The pre-commit hook is the last line of defence, not the first. Do your own PII scan in Step 2.
- If in doubt about whether something is safe to publish, ask the user. Don't guess.
