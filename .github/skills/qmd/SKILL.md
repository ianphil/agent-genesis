---
name: qmd
description: Search the notes mind using QMD hybrid search. Use when looking up notes, finding related documents, searching for decisions, people, initiatives, or any mind content. Triggers on search, find, look up, "what do I know about", "where is", recall.
---

# QMD — Mind Search

Local hybrid search engine indexing this mind. BM25 keyword + vector semantic + LLM reranking.

## Status

!`qmd status 2>/dev/null || echo "Not installed: npm install -g @tobilu/qmd"`

## Collections

| Collection | Content |
|------------|---------|
| `domains` | Recurring areas: team notes, people notes, operational concerns |
| `initiatives` | Active projects and their status, decisions, scope |
| `expertise` | Learning notes, technical references, patterns, frameworks |
| `inbox` | Unprocessed captures awaiting triage |
| `working-memory` | Agent working memory: observations, conventions, preferences |

## CLI Usage

```bash
qmd search "keywords"               # BM25 only — fast, exact matches
qmd vsearch "natural language"       # Vector semantic search
qmd query "complex question"         # Full hybrid + reranking (best quality, slowest)
qmd get "#docid"                     # Retrieve by docid from search results
qmd multi-get "journals/2026-*.md"   # Batch retrieve by glob
```

### Structured Queries (advanced)

```bash
qmd query $'lex: sprint review accountability\nvec: how does the team handle check-ins and progress tracking'
```

## Query Types

| Type | Method | When to use |
|------|--------|-------------|
| `lex` | BM25 keyword | Exact names, IDs, specific phrases — "sprint-review", "ADO 2049967", "project-alpha" |
| `vec` | Vector semantic | Conceptual questions — "what coaching frameworks does the team use" |
| `hyde` | Hypothetical doc | You know what the answer looks like — write 50-100 words of expected content |

## Writing Good Queries

**lex (keyword)**
- 2-5 terms, no filler words
- Exact phrase: `"connection pool"` (quoted)
- Exclude terms: `performance -sports` (minus prefix)
- Proper nouns work best here: person names, project names, specific terms

**vec (semantic)**
- Full natural language question
- Be specific: `"what are the gates for private preview"`
- Include context: `"what decisions were made about the prod deployment sequence"`

**hyde (hypothetical document)**
- Write 50-100 words of what the *answer* looks like
- Use the vocabulary you expect in the result

## Combining Strategies

| Goal | Approach |
|------|----------|
| Know exact terms | `qmd search` (BM25 only, instant) |
| Don't know vocabulary | `qmd vsearch` or `qmd query` |
| Best recall on complex topic | `qmd query` with lex + vec lines |
| Quick daily use | `qmd search` for most lookups |

First query line gets 2x weight in fusion — put your best guess first.

## Collection Filtering

```bash
qmd search "API review" -c initiatives    # Search only initiatives
qmd vsearch "coaching" -c domains         # Search only domains
```

Omit `-c` to search all collections.

## Output Formats

```bash
qmd search "term" --json              # Structured JSON for processing
qmd search "term" --all --files       # File paths only, all matches
qmd search "term" --min-score 0.5     # Filter by relevance threshold
```
