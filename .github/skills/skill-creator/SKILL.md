---
name: skill-creator
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, update or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.
---

# Skill Creator

A skill for creating new skills and iteratively improving them.

## Core Loop

1. Decide what the skill should do and roughly how
2. Write a draft SKILL.md
3. Create 2-3 test prompts, run them with the skill via subagents
4. Evaluate results — qualitative (user reviews outputs) and quantitative (assertions + benchmarks)
5. Improve the skill based on feedback
6. Repeat until satisfied
7. Optionally run description optimization for better triggering

Your job is to figure out where the user is in this process and help them progress. Maybe they want a new skill from scratch, maybe they already have a draft, maybe they just want to vibe — be flexible.

---

## Creating a Skill

### Capture Intent

Start by understanding what the user wants. If the conversation already contains a workflow to capture (e.g., "turn this into a skill"), extract answers from history first — tools used, steps taken, corrections made, input/output formats observed. Confirm before proceeding.

1. What should this skill enable the agent to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs (file transforms, data extraction, fixed workflows) benefit from test cases. Subjective skills (writing style, design) often don't. Suggest the appropriate default, let the user decide.

### Interview and Research

Ask about edge cases, input/output formats, example files, success criteria, dependencies. Wait to write test prompts until this is ironed out. Check available MCPs for research if useful.

### Write the SKILL.md

Components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. This is the primary triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body.

**Description calibration for small skill sets:** This repo has ~6 project-level skills. Over-triggering is a real risk — a too-pushy `capture` description could swallow prompts meant for `qmd`. Be precise over pushy. Include trigger phrases, but don't claim adjacent territory that belongs to another skill.

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required — no other fields)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

**Frontmatter:** Only `name` and `description`. No `license`, `compatibility`, or other fields — they cause warnings.

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** — As needed (unlimited, scripts can execute without loading)

**Key patterns:**
- Keep SKILL.md under 500 lines; for longer skills, add hierarchy with pointers to reference files
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    └── azure.md
```

#### Writing Patterns

Prefer the imperative form. Explain the **why** behind instructions — LLMs respond better to reasoning than rigid MUSTs. If you're writing ALWAYS or NEVER in all caps, reframe as reasoning.

Include examples where useful:
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

Make skills general, not narrow to specific examples. Write a draft, look at it fresh, improve it.

### Test Cases

After the draft, come up with 2-3 realistic test prompts. Share with the user for confirmation, then run them.

Save test cases to `evals/evals.json` (prompts only — assertions come later):

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema.

---

## Running and Evaluating Test Cases

This section is one continuous sequence — don't stop partway through.

Put results in a gitignored workspace (e.g., `/tmp/<skill-name>-workspace/` or the session state folder). Organize by iteration (`iteration-1/`, `iteration-2/`) and within that, each test case gets a directory. Create directories as you go.

### Step 1: Spawn all runs in the same turn

For each test case, spawn two subagents simultaneously — one with the skill, one without (baseline).

**With-skill run:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
```

**Baseline run:**
- **New skill**: no skill at all → `without_skill/outputs/`
- **Improving existing skill**: snapshot old version first (`cp -r`), point baseline at snapshot → `old_skill/outputs/`

Write `eval_metadata.json` for each test case with a descriptive name.

### Step 2: While runs are in progress, draft assertions

Don't just wait. Draft quantitative assertions for each test case. Good assertions are objectively verifiable with descriptive names. Don't force assertions onto subjective outputs — those need human judgment.

Update `eval_metadata.json` and `evals/evals.json` with assertions.

### Step 3: Capture timing data

When subagent tasks complete, save `total_tokens` and `duration_ms` from the notification to `timing.json` in each run directory. This data only comes through the notification — capture it immediately.

### Step 4: Grade, aggregate, and launch the viewer

1. **Grade each run** — use `agents/grader.md`. Save to `grading.json`. The expectations array must use fields `text`, `passed`, and `evidence`. For programmatically checkable assertions, write and run a script.

2. **Aggregate** — run from the skill-creator directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```

3. **Analyst pass** — read `agents/analyzer.md` and surface patterns: non-discriminating assertions, high-variance evals, time/token tradeoffs.

4. **Launch the viewer:**
   ```bash
   nohup python .github/skills/skill-creator/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   **Headless/no display:** Use `--static <output_path>` to write a standalone HTML file. Feedback downloads as `feedback.json` when user clicks "Submit All Reviews".

   Always use `generate_review.py` — don't write custom HTML. Generate the viewer BEFORE evaluating outputs yourself. Get results in front of the human ASAP.

### Step 5: Read the feedback

Read `feedback.json` when the user is done. Empty feedback = looked fine. Focus improvements on test cases with specific complaints. Kill the viewer server when done.

---

## Improving the Skill

### How to Think About Improvements

1. **Generalize from feedback.** You're iterating on a few examples to build a skill used across many prompts. Don't overfit — if there's a stubborn issue, try different metaphors or patterns rather than fiddly constraints.

2. **Keep the prompt lean.** Remove what isn't pulling its weight. Read transcripts, not just outputs — if the skill makes the model waste time, cut the parts causing it.

3. **Explain the why.** Transmit understanding into instructions. Reasoning beats rigid MUSTs.

4. **Look for repeated work.** If all test runs independently wrote similar helper scripts, bundle that script in `scripts/` and reference it from the skill.

### The Iteration Loop

1. Apply improvements to the skill
2. Rerun all test cases into `iteration-<N+1>/` with baselines
3. Launch the viewer with `--previous-workspace`
4. Wait for user review
5. Read feedback, improve, repeat

Keep going until the user is happy, feedback is empty, or you're not making progress.

---

## Advanced: Blind Comparison

For rigorous comparison between two skill versions: give outputs to an independent agent without revealing which is which. Read `agents/comparator.md` and `agents/analyzer.md` for details. Optional — human review is usually sufficient.

---

## Description Optimization

The description field determines whether the agent invokes a skill. After creating or improving a skill, offer to optimize it.

### Step 1: Generate trigger eval queries

Create 20 eval queries — mix of should-trigger (8-10) and should-not-trigger (8-10). Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

Queries must be realistic — concrete, specific, with detail (file paths, context, casual speech, typos). Focus on edge cases.

**Should-trigger:** Different phrasings of the same intent. Include cases where the user doesn't name the skill explicitly but clearly needs it. Include cases where this skill competes with a sibling skill but should win.

**Should-not-trigger:** Near-misses — queries sharing keywords but needing something different. Adjacent domains, ambiguous phrasing. Don't use obviously irrelevant queries.

### Step 2: Review with user

Use the HTML template at `assets/eval_review.html`:
1. Replace `__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`
2. Write to `/tmp/eval_review_<skill-name>.html` and open it
3. User edits queries, toggles triggers, exports → `eval_set.json`

### Step 3: Run the optimization loop

**Note:** The optimization scripts use `claude -p` (Claude Code CLI). On Copilot CLI, you have two options:
- Adapt `scripts/run_loop.py` to use `copilot -p` instead
- Run the optimization manually: test descriptions against the eval set yourself, propose improvements, iterate

If the scripts work in your environment:
```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id> \
  --max-iterations 5 \
  --verbose
```

### How Skill Triggering Works

Skills appear in the agent's `available_skills` list with name + description. The agent decides whether to consult a skill based on that description. Simple, one-step queries may not trigger a skill even with a matching description — the agent handles them directly. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

Eval queries should be substantive enough that the agent would benefit from consulting a skill.

### Step 4: Apply the result

Update the skill's SKILL.md frontmatter with the best description. Show before/after and report scores.

---

## Reference Files

- `agents/grader.md` — How to evaluate assertions against outputs
- `agents/comparator.md` — How to do blind A/B comparison
- `agents/analyzer.md` — How to analyze benchmark results
- `references/schemas.md` — JSON structures for evals, grading, benchmarks
