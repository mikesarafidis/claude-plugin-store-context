# Feature doc templates & guidance

Matches the structure already in use in this repo's `feature_context/` folder. Read
this before writing any of these files for a feature for the first time.

## README.md (always create/update)

```markdown
# <Feature Title>

**Ticket / branch:** <ticket-id> (`<branch-name>`)

<One or two sentences: what this feature does and why it exists.>

## Read this in order

1. **README.md** (this file) — goal, design decisions, status, quickstart.
2. [ARCHITECTURE.md](ARCHITECTURE.md) — components + file paths + current state. *(if present)*
3. [DB_CHANGES.md](DB_CHANGES.md) — DB dependencies. *(if present)*
4. [RUNBOOK.md](RUNBOOK.md) — how to build/run/test. *(if present)*
5. [OPEN_ISSUES.md](OPEN_ISSUES.md) — diagnosis + what's left. *(if present)*
6. [WORKING_AGREEMENTS.md](WORKING_AGREEMENTS.md) — conventions/gotchas. *(if present)*

(Only list the files that actually exist for this feature — drop the rest.)

## Goal & constraints

- <What outcome is required, in concrete terms>
- <Hard constraints from the product owner / spec>
- <Inputs available, inputs explicitly off-limits, etc.>

## Key design decisions (and why)

- **<Decision>.** <What was chosen, what was considered and rejected, and why.>
- Keep adding entries here across sessions — don't delete old ones even if a later
  decision supersedes them. Note the supersession instead of erasing history.

## Current status

- ✅ / ⚠️ / ❌ bullet list of what's done, what's partially working, what's not
  started. Update this every session rather than replacing it — append or edit the
  relevant bullet.

## Quickstart

<Shortest path to build/run/verify this feature locally. Link to RUNBOOK.md for
detail if one exists.>
```

## ARCHITECTURE.md (only if there's real architecture to document)

Numbered sections, one per component, each naming the exact file path(s) involved and
its current state (implemented / partial / not started):

```markdown
# Architecture & File Map

## 1. <Component name> — `<exact/file/path>`
<What it does, current state.>

## 2. <Component name> — `<exact/file/path>`
...
```

Skip this file entirely if the feature is small enough that README.md's goal section
already covers "where the code lives."

## DB_CHANGES.md (only if the feature touches the database)

```markdown
# Database Changes / Dependencies

## `<table_name>` (<one-line purpose>)
<Columns added/used, why.>
```

One section per table/column group touched. Skip this file if there's no DB
involvement.

## OPEN_ISSUES.md (only if there are real open problems or next steps)

```markdown
# Open Issues, Diagnosis & Next Steps

## 1. <Issue title> ⚠️ (or ✅ if resolved this session, keep for history)
<Root cause diagnosis, fix path, status.>

## 2. Not yet done
<Explicit list of remaining work.>
```

Keep resolved issues in the file (marked ✅) rather than deleting them — the
diagnosis is often useful later even after the fix ships.

## RUNBOOK.md (only if there's a non-obvious build/run/test procedure)

```markdown
# Runbook

## Build
<Exact commands.>

## The end-to-end workflow
<Step-by-step: e.g. refresh data, retrain, verify, deploy.>

## Notes
<Gotchas, timing, things that trip people up.>
```

Skip this if `npm start` / `dotnet run` / equivalent is genuinely all there is to it
— that belongs in the README quickstart instead.

## WORKING_AGREEMENTS.md (only if there are team-specific conventions)

```markdown
# Working Agreements & Environment Gotchas

## <Agreement or gotcha title> (IMPORTANT if it's easy to violate accidentally)
<What the agreement is and why it exists.>

## Repo layout: submodules
<If relevant.>

## Build gotchas
<If relevant.>

## How the product owner / stakeholder tests this
<If relevant.>
```

Typical contents: code-review/approval workflow quirks, submodule layout, build
gotchas specific to this feature, how a non-engineer stakeholder verifies the work.
