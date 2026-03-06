# Setting Up an AI-Powered Private/Public Note-Taking System

A step-by-step guide to building a personal knowledge base with the IDEA method, GitHub Copilot CLI, and selective public publishing.

## Why This System

Most note-taking tools are editors that happen to have search. This system flips that — your notes are plain markdown files in a git repo, and your AI assistant is the editor. You talk to it, it creates and organizes notes, and git gives you history, branching, and publishing for free.

The key insight: **a knowledge base is just a codebase where the code is prose.** The same tools that make AI great at navigating code — grep, file trees, structured conventions — make it great at managing notes.

What you get:
- **Private by default.** Everything lives in a private git repo you control.
- **Selectively public.** Cherry-pick individual notes to publish via an orphan branch — zero history leaks.
- **AI-native.** GitHub Copilot CLI is your primary interface for capturing, triaging, searching, and connecting notes.
- **No vendor lock-in.** It's markdown files in folders. Use any editor, any viewer, any platform.

## The IDEA Structure

Every note lands in one of four categories:

| Folder | Purpose | Examples |
|--------|---------|----------|
| **I**nitiatives | Projects with a defined end goal | `initiatives/mobile-app/`, `initiatives/home-renovation/` |
| **D**omains | Recurring areas of responsibility | `domains/finances/`, `domains/people/jane/` |
| **E**xpertise | Notes about things you learn | `expertise/rust/`, `expertise/docker-networking.md` |
| **A**rchive | Completed or inactive items | `Archive/initiative/old-project/` |

There's also an **inbox** — a catch-all for quick captures you haven't classified yet.

Each initiative, domain, or expertise area can have:
- A main note (e.g., `mobile-app.md`) with timestamped entries
- A `next-actions.md` tracking open and completed tasks

```
notes/
├── initiatives/
│   └── mobile-app/
│       ├── mobile-app.md
│       └── next-actions.md
├── domains/
│   ├── finances/
│   └── people/
│       └── jane/
├── expertise/
│   └── docker-networking.md
├── Archive/
├── inbox/
│   └── renew-ssl-cert.md
├── .github/
│   ├── copilot-instructions.md
│   └── skills/
├── vault-index.md
└── README.md
```

## Step 1: Create Your Private Repo

```bash
mkdir notes && cd notes
git init
```

Create the folder structure:

```bash
mkdir -p initiatives domains/people expertise Archive inbox .github/skills
```

Create a `.gitignore`:

```
.obsidian/
.DS_Store
Thumbs.db
```

Create `README.md`:

```markdown
# Notes

Personal knowledge management using the IDEA method.

| Folder | Purpose |
|--------|---------|
| **I**nitiatives | Projects with a defined end goal |
| **D**omains | Recurring areas of responsibility |
| **E**xpertise | Notes about things I learn |
| **A**rchive | Completed or inactive items |
| Inbox | Quick capture for notes to classify later |
```

Add `.gitkeep` files so empty folders are tracked:

```bash
touch initiatives/.gitkeep domains/.gitkeep expertise/.gitkeep Archive/.gitkeep inbox/.gitkeep
```

Initial commit and push to a **private** repo on GitHub:

```bash
git add -A
git commit -m "Init IDEA vault"
gh repo create notes --private --source=. --push
```

## Step 2: Install GitHub Copilot CLI

GitHub Copilot CLI is the AI assistant that will manage your vault. Install it:

```bash
# macOS/Linux
brew install github/gh-copilot/gh-copilot

# Or via npm
npm install -g @githubnext/github-copilot-cli
```

Authenticate with GitHub:

```bash
gh auth login
gh copilot --version   # verify it works
```

> **Note:** You need an active GitHub Copilot subscription. See [GitHub Copilot CLI docs](https://docs.github.com/en/copilot/github-copilot-in-the-cli) for the latest install instructions.

## Step 3: Add Copilot Instructions

Create `.github/copilot-instructions.md` — this tells Copilot about your vault's structure and conventions:

```markdown
# Copilot Instructions

## Repo Structure
This is a private notes vault using the IDEA method.

| Folder | Purpose |
|--------|---------|
| initiatives/ | Projects with a defined end goal |
| domains/ | Recurring areas of responsibility (includes people/) |
| expertise/ | Notes about things I learn |
| Archive/ | Completed or inactive items |
| inbox/ | Quick capture, triaged later |

## Conventions
- Notes use descriptive, lowercase-hyphenated filenames (e.g., `docker-networking.md`, `renew-ssl-cert.md`)
- Each initiative/domain/expertise folder has a main note + `next-actions.md`
- next-actions items use `- [ ]` for open and `- [x]` for done
- Sections: `## Open` and `## Done` in next-actions.md

## Committing
- Use conventional commits: `feat:`, `chore:`, `docs:`
```

Commit:

```bash
git add .github/copilot-instructions.md
git commit -m "Add copilot instructions"
git push
```

## Step 4: Add Skills

Skills are small instruction files that teach Copilot specific workflows for your vault. They live in `.github/skills/` and each skill has a `SKILL.md` file.

You can start from the reference implementation:

```bash
# Clone the example repo for its skills
git clone https://github.com/ipdelete/IDEA-notes /tmp/idea-notes
cp -r /tmp/idea-notes/.github/skills/* .github/skills/
rm -rf /tmp/idea-notes
```

Or create them one at a time. Here are the core skills:

| Skill | What it does |
|-------|-------------|
| `capture-triage` | Quick capture notes, list inbox, classify notes into IDEA folders |
| `entity-notes` | Create new initiative/domain/expertise/person folders with templates |
| `next-actions` | Manage per-entity task lists with open/done sections |
| `discovery` | Search notes and list recently modified files |
| `links` | Suggest and add wiki-style links between notes |
| `lifecycle` | Archive completed entities, commit and push changes |

Each skill's `SKILL.md` defines triggers, behavior, and templates. See the [IDEA-notes example repo](https://github.com/ipdelete/IDEA-notes) for the full set.

Commit:

```bash
git add .github/skills/
git commit -m "Add vault skills"
git push
```

## Step 5: Set Up Public Publishing

This is the key feature — selectively publishing notes from your private repo without exposing its history. The technique uses git's orphan branch feature.

> For a deep-dive on the mechanics, see [[git-orphan-branch-public-publishing]].

### Create a public repo

```bash
gh repo create public-notes --public --description "Public notes from my IDEA vault"
```

### Create an orphan branch

From your private notes repo:

```bash
git switch --orphan public-branch
git commit --allow-empty -m "Init public branch"
git switch main   # or master, whatever your default branch is
```

> `git switch --orphan` starts with an empty working tree — cleaner than `git checkout --orphan`.

### Add the public remote

```bash
git remote add public git@github.com:YOUR_USERNAME/public-notes.git
```

### Set up a worktree

```bash
git worktree add ../public-notes public-branch
```

Now `../public-notes/` is a separate checkout on the `public-branch`. Files you add there never touch your private branch.

### Add a pre-push safety hook

This prevents accidentally pushing your private branch to the public remote:

```bash
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
remote="$1"

if [[ "$remote" != "public" ]]; then
  exit 0
fi

echo "⚠️  Pushing to PUBLIC remote"
echo "Files in this push:"
echo "---"
git diff --name-only HEAD~1 HEAD
echo "---"
read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Push aborted."
  exit 1
fi

PRIVATE_PATTERNS=("secret" "private" "draft" "journal")
FILES=$(git diff --name-only HEAD~1 HEAD)

for pattern in "${PRIVATE_PATTERNS[@]}"; do
  if echo "$FILES" | grep -qi "$pattern"; then
    echo "🚫 Blocked: found file matching '$pattern'"
    exit 1
  fi
done
EOF
chmod +x .git/hooks/pre-push
```

### Create a public README

From your worktree (`../public-notes/`):

```bash
cd ../public-notes
cat > README.md << 'EOF'
# Notes

These are my public notes — things I've chosen to share from my private
knowledge base. The folder structure mirrors the IDEA method; not everything
is public, just what I've decided is worth sharing.

See [Setting Up IDEA Notes](expertise/IDEA-notes-setup.md) for how to
build your own system.
EOF
git add README.md
git commit -m "Add public README"
git push public public-branch:main
```

## Step 6: Daily Workflow

With everything set up, here's how the system works day-to-day. All of these happen through conversation with Copilot CLI.

### Capture

Just talk to Copilot. It routes notes to the right place:

```
> note jane Had coffee, discussed the timeline for Q3
  → appends to domains/people/jane/jane.md

> note mobile-app Decided to use React Native for the prototype
  → appends to initiatives/mobile-app/mobile-app.md

> note Remember to renew the SSL cert
  → inbox/renew-ssl-cert.md  (no match, lands in inbox)
```

### Triage

Review what's accumulated in the inbox:

```
> inbox
  3 notes waiting:
  - renew-ssl-cert.md
  - docker-tip.md
  - budget-review.md

> classify docker-tip.md expertise docker-networking
  → Moved to expertise/docker-networking.md

> classify budget-review.md domain finances
  → Moved to domains/finances/
```

### Track next actions

```
> next-action add initiative mobile-app Write the API spec
> next-action add domain finances Review Q1 actuals
> next-action list initiative mobile-app
  ## Open
  - [ ] Write the API spec
  - [ ] Set up CI/CD
  ## Done
  - [x] Choose framework
```

### Search and discover

```
> search React Native
  Found in 3 notes: initiatives/mobile-app/...

> recent
  10 most recently modified notes...
```

### Commit and publish

```
> ship
  → git add -A && git commit && git push

# To publish a note publicly (from the public-notes worktree):
cd ../public-notes
git checkout master -- expertise/docker-networking.md
git commit -m "Publish docker networking note"
git push public public-branch:main
```

## Wiki Links

As your vault grows, connect notes with `[[wiki links]]` woven into your prose. Instead of a "Related" section at the bottom, link inline — `the [[Ralph Wiggum Pattern]] applies here` — so the link IS part of your reasoning.

Use the `links` skill to get suggestions: it scans your vault and proposes connections you might have missed. The `vault-index` skill generates a master index (`vault-index.md`) with one-line descriptions of every note, giving both you and the AI a quick map of the whole vault.

> For more on linking strategy, see [[wiki-links-and-vault-indexing]].

## Quick Start (Fork and Go)

If you want to skip the manual setup, fork the [IDEA-notes example repo](https://github.com/ipdelete/IDEA-notes). It includes:

- The full IDEA folder structure
- All skills pre-configured in `.github/skills/`
- A `copilot-instructions.md` template
- Sample notes showing the conventions

Then follow Steps 2, 5, and 6 above to connect Copilot CLI and set up public publishing.

## Summary

| Component | What it does |
|-----------|-------------|
| Private git repo | Stores all your notes in IDEA folders |
| `.github/copilot-instructions.md` | Teaches Copilot your vault's structure |
| `.github/skills/` | Automates capture, triage, search, linking, lifecycle |
| Orphan branch + worktree | Publishes select notes without history leaks |
| Pre-push hook | Prevents accidental publishing of private content |
| `vault-index.md` | Master index for fast vault navigation |
| GitHub Copilot CLI | Your primary interface for everything |

The system is intentionally simple — markdown files, git, and an AI that knows the conventions. No database, no proprietary format, no sync service. Your notes are yours.
