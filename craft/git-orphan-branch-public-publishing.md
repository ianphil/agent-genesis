# Publishing Select Notes Publicly with Git Orphan Branches

Orphan branches let you publish a clean file tree from a private repo without exposing its history. The `--orphan` option was added to git in v1.7.2 (2010) specifically for this use case.

## Setup

### 1. Create a public repo

Create a new empty public repo on GitHub (e.g. `ianphil/public-notes`).

### 2. Create an orphan branch locally

From your private repo:

```bash
git switch --orphan public-branch
git commit --allow-empty -m "Init public branch"
git switch main
```

> Prefer `git switch --orphan` over `git checkout --orphan` — it starts with an empty working tree automatically (no need for `git rm -rf .`).

### 3. Add the public repo as a remote

```bash
git remote add public git@github.com:ianphil/public-notes.git
```

### 4. Set up a worktree for the public branch

```bash
git worktree add ../public-notes public-branch
```

## Daily Workflow

### Add or update a file

From within the worktree (`../public-notes`):

```bash
git checkout main -- path/to/file.md
git commit -m "Add file"
git push public public-branch:main
```

> **Never push `main` to the public remote** — commits carry full tree history. Only ever push `public-branch`.

## Safety: Pre-push Hook

Add a pre-push hook to prevent accidentally publishing private content. Hooks live in the main repo's `.git/hooks/` and apply to worktrees automatically.

```bash
#!/bin/bash
# .git/hooks/pre-push

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
```

```bash
chmod +x .git/hooks/pre-push
```

## Key Rules

- The orphan branch ensures zero private content leaks into the public repo
- Never push `main` to the `public` remote
- Use `git checkout main -- <file>` to cherry-pick individual files onto the public branch
- The worktree at `../public-notes` is checked out on `public-branch` — commits there never touch `main`
