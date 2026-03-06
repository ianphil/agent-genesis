# Bootstrap — QMD (Mind Search)

Sets up [QMD](https://github.com/tobi/qmd) for hybrid local search across the mind — BM25 keyword matching + vector embeddings + LLM reranking. All local, no cloud APIs.

## What It Does

Three search tiers over the mind's content:

| Command | Speed | Use For |
|---------|-------|---------|
| `qmd search` | Instant | Exact names, IDs, specific phrases |
| `qmd vsearch` | ~seconds | Conceptual queries, "what do I know about X" |
| `qmd query` | Slowest | Best quality — hybrid + reranking for complex searches |

## Prerequisites

- **Node.js** ≥ 22
- **npm** (for global install)
- ~1.5 GB disk for GGUF models (downloaded on first use to `~/.cache/qmd/models/`)
- Initial embedding takes ~20 min on CPU; subsequent runs are incremental

## Setup

### 1. Install QMD

```bash
npm install -g @tobilu/qmd
```

### 2. Fix the Windows PowerShell Wrapper

The npm-generated `.ps1` wrapper doesn't work. Replace it:

```powershell
$wrapper = "$(npm root -g)/../qmd.ps1"
@'
#!/usr/bin/env pwsh
$basedir=Split-Path $MyInvocation.MyCommand.Definition -Parent
$qmdjs="$basedir\node_modules\@tobilu\qmd\dist\qmd.js"

if ($MyInvocation.ExpectingInput) {
  $input | & node $qmdjs @args
} else {
  & node $qmdjs @args
}
exit $LASTEXITCODE
'@ | Set-Content -Path $wrapper -Encoding ASCII
```

On Linux/macOS, the bash wrapper works fine — skip this step.

### 3. Create Collections

From the repo root:

```bash
qmd collection add domains --name domains
qmd collection add initiatives --name initiatives
qmd collection add expertise --name expertise
qmd collection add inbox --name inbox
qmd collection add .working-memory --name working-memory
```

### 4. Add Context Annotations

```bash
qmd context add "qmd://domains" "Recurring areas of responsibility: AET team, blog analytics, people notes"
qmd context add "qmd://initiatives" "Active projects with goals and timelines"
qmd context add "qmd://expertise" "Learning notes, technical references, patterns, frameworks"
qmd context add "qmd://inbox" "Quick-capture landing zone for unprocessed thoughts and tasks"
qmd context add "qmd://working-memory" "Agent working memory: session observations, mind conventions, preferences"
```

### 5. Generate Embeddings

```bash
qmd embed
```

First run downloads ~328 MB embedding model. Takes ~20 min on CPU, much faster with CUDA.

**Low-resource machines:** Skip this step entirely. `qmd search` (BM25 keyword) works with zero models — just needs the SQLite FTS5 index built during `qmd collection add`. You get instant keyword search with no memory overhead. Vector/hybrid search requires the models.

### 6. Install Post-Commit Hook

Git hooks don't travel with clones — create manually on each machine.

**Linux/macOS:**

```bash
cat > .git/hooks/post-commit << 'EOF'
#!/usr/bin/env bash
if command -v qmd &>/dev/null; then
  qmd embed --quiet &>/dev/null &
elif command -v node &>/dev/null; then
  QMD_JS="$(npm root -g 2>/dev/null)/@tobilu/qmd/dist/qmd.js"
  if [ -f "$QMD_JS" ]; then
    node "$QMD_JS" embed --quiet &>/dev/null &
  fi
fi
EOF
chmod +x .git/hooks/post-commit
```

**Windows (Git Bash):**

```bash
cp /dev/stdin .git/hooks/post-commit << 'EOF'
#!/usr/bin/env bash
if command -v qmd &>/dev/null; then
  qmd embed --quiet &>/dev/null &
elif command -v node &>/dev/null; then
  QMD_JS="$(npm root -g 2>/dev/null)/@tobilu/qmd/dist/qmd.js"
  if [ -f "$QMD_JS" ]; then
    node "$QMD_JS" embed --quiet &>/dev/null &
  fi
fi
EOF
```

The hook re-indexes embeddings in the background after every commit — no manual step to remember.

## Verification

```bash
qmd search "test query"      # BM25 keyword — should return results instantly
qmd vsearch "test query"     # Semantic search — needs embeddings
qmd status                   # Show collections, doc count, health
```

## Agent Skill

The QMD skill at `.github/skills/qmd/` teaches Copilot when and how to use each search tier. It loads automatically in this repo.

## Troubleshooting

| Symptom | Likely Cause |
|---------|--------------|
| `qmd` not found in PowerShell | Wrapper is broken — run the fix in step 2 |
| `qmd search` returns nothing | Collections not created — run step 3 |
| `qmd vsearch` fails | Embeddings not generated — run `qmd embed` |
| Post-commit hook not firing | Hook file missing or not executable — recreate per step 6 |
| Embedding takes forever | First run downloads model + processes all docs. Subsequent runs are incremental and fast |
| Want keyword-only on a weak machine | Skip steps 5 and 6. `qmd search` works without models |

## Key Paths

- Collections config: `.qmd/` (in repo root, gitignored)
- Models cache: `~/.cache/qmd/models/`
- Agent skill: `.github/skills/qmd/SKILL.md`
- Post-commit hook: `.git/hooks/post-commit`
