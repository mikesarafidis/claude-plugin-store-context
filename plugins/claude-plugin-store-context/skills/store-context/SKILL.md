---
name: store-context
description: >
  Save and load shared, git-tracked Claude Code context for a feature, stored in the
  project's feature_context/ folder, so any teammate (or a fresh Claude session) can
  pick up a feature with the same working knowledge instead of re-deriving it. Part of
  the claude-plugin-store-context plugin: invoked automatically once at the start of every
  new session in any project where this plugin is enabled (its bundled SessionStart
  hook injects a reminder to run it), asking whether to save/update context now. Also
  invoke manually with /claude-plugin-store-context:store-context, or whenever the user
  says things like "save context", "save session context", "store this session",
  "load feature context", "continue this feature", "resume work on <feature>", or
  mentions feature_context directly.
---

# store-context

Keeps a project's `feature_context/` folder up to date: a git-tracked, per-feature set
of docs that let anyone (human or a fresh Claude session) resume a feature with the
same context the previous session had — the *why* behind decisions, not just a log of
what happened.

This skill ships as part of the `claude-plugin-store-context` plugin. Once the plugin is
installed, it works in every project automatically — nothing project-specific to set
up, and nothing to commit into each individual repo.

## When this runs

- **Automatically, once per session, at startup**, in any project where this plugin
  is enabled. The plugin's bundled `SessionStart` hook injects a note telling you to
  run this flow before anything else. Only do this once — if the user says no, don't
  ask again later in the same session.
- **Manually, any time**, via `/claude-plugin-store-context:store-context`. This is how
  the user re-opens the flow after having said no earlier, or wants to save
  mid-session.

## Step 1 — Ask permission

Ask the user: **"Do you want to save this session's context to the project's
`feature_context` folder?"** (yes/no)

- **No** → stop here. Do nothing further. Don't bring this up again unless the user
  runs the skill manually.
- **Yes** → continue to Step 2.

## Step 2 — Locate or create `feature_context/`

1. Determine the project root: run `git rev-parse --show-toplevel`. If that fails
   (not a git repo), fall back to the current working directory.
2. Check whether `<root>/feature_context/` exists.
   - **Exists** → tell the user you found it at that path and ask them to confirm
     it's the right one.
   - **Doesn't exist** → create it, along with a root `README.md` (template below),
     then tell the user you created it there and ask them to confirm.
3. If the user says the confirmed/created location is wrong, ask directly where it
   should live instead, and use that path for the rest of the session. (This should
   be rare — project root is the convention — but don't force it on a repo layout
   where it genuinely doesn't fit.)

**Root `feature_context/README.md` template** (only needed the first time the folder
is created):

```markdown
# feature_context

Shared, version-controlled **Claude Code / development context** for features in this
repo.

The goal: when someone (or a fresh Claude session) picks up a feature, they can pull
this folder from git and get the full working context — the *why* behind the design,
the current state of the code, how to run it, what's still open, and the working
agreements — without re-deriving everything.

## Convention

- **One subdirectory per feature**, named after the feature.
- Each feature folder is self-contained. Start with its `README.md`.
- Keep these docs updated as the feature evolves — treat them like code.

## Features

| Feature | Folder | Status |
|---------|--------|--------|
```

## Step 3 — Existing feature or new feature

Ask: **"Save to an existing feature, or start a new one?"**

- **Existing** → list the subdirectories of `feature_context/` (each one is a
  feature) and let the user pick. **Read that feature's existing files in full**
  before writing anything — you need their current content to merge into, not
  overwrite.
- **New** → ask the user for the **exact folder name** to use. Don't auto-slugify or
  invent one — they may already have a naming convention from other features in the
  repo. Create `feature_context/<name>/`.

## Step 4 — Write the context

The goal: a teammate or a fresh Claude session should be able to read this folder and
have **equivalent working knowledge** to where this session left off — the actual
reasoning behind decisions, the current state, how to run things, and what's still
open. Not a changelog; a briefing.

**Always write/update:**
- `README.md` — goal & constraints, key design decisions (and *why*), current status,
  quickstart. This is the entry point; everything else is optional supporting detail.

**Write/update only if actually relevant to this feature:**
- `ARCHITECTURE.md` — components involved, with exact file paths and current state
- `DB_CHANGES.md` — DB tables/columns the feature reads or writes
- `OPEN_ISSUES.md` — diagnosis of current problems and what's left to do
- `RUNBOOK.md` — how to build, run, test, or operate the feature
- `WORKING_AGREEMENTS.md` — approval workflows, build quirks, or team conventions
  specific to this feature

Don't create a file just to have the full set — an `ARCHITECTURE.md` with nothing
architectural to say is worse than no file at all. **Read
[reference/feature-doc-templates.md](reference/feature-doc-templates.md) before
writing any of these for the first time** — it has the section-by-section template
and guidance on when each file earns its place.

### Updating an existing feature: merge, don't overwrite

1. Read each existing file fully first.
2. Update only the sections that actually changed this session (status, new
   decisions, newly-open issues, etc.).
3. Leave everything else untouched — don't rewrite prose that's still accurate just
   to rephrase it.
4. Add to "Current status" rather than replacing it wholesale, so progress stays
   visible over time.
5. If a decision from this session reverses or invalidates an earlier one, keep the
   old entry and note that it changed and why, rather than silently deleting it —
   that reasoning is often exactly what the next person needs.

### Update the root index

After writing a feature's files, update `feature_context/README.md`'s feature table:
add a row for a new feature, or update the status cell for an existing one.

## What this skill does NOT do

- **It never touches git.** It only writes files to disk — staging and committing is
  left entirely to the user.
- **It doesn't re-prompt mid-session.** The "do you want to save?" question is asked
  once, at session start. After that, saving again requires the user to explicitly
  invoke the skill.
