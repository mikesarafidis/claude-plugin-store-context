---
name: store-context
description: >
  Save and load shared, git-tracked Claude Code context for a feature, stored in the
  project's feature_context/ folder, so any teammate (or a fresh Claude session) can
  pick up a feature with the same working knowledge instead of re-deriving it. Part of
  the claude-plugin-store-context plugin: invoked automatically once at the start of
  every new session in any project where this plugin is enabled (its bundled
  SessionStart hook injects a reminder to run it), asking whether to save/update
  context now. Also invoke manually with /claude-plugin-store-context:store-context,
  or whenever the user says things like "save context", "save session context",
  "store this session", "load feature context", "continue this feature", "resume work
  on <feature>", or mentions feature_context directly. Updates to existing features
  are append-only (see the companion merge-context skill) so that concurrent commits
  from different teammates never conflict.
---

# store-context

Keeps a project's `feature_context/` folder up to date: a git-tracked, per-feature set
of docs that let anyone (human or a fresh Claude session) resume a feature with the
same context the previous session had — the *why* behind decisions, not just a log of
what happened.

This skill ships as part of the `claude-plugin-store-context` plugin, alongside a
companion `merge-context` skill. Once the plugin is installed, it works in every
project automatically — nothing project-specific to set up, and nothing to commit
into each individual repo.

**Important:** updates to an existing feature are append-only, never in-place edits.
See Step 4 and `../../shared/pending-update-format.md` before writing anything to an
existing feature's files — this is what keeps concurrent commits from different
teammates conflict-free in git.

## When this runs

- **Automatically, once per session, at startup**, in any project where this plugin
  is enabled. The plugin's bundled `SessionStart` hook injects a note telling you to
  run this flow before anything else. Only do this once — if the user says no, don't
  ask again later in the same session.
- **Manually, any time**, via `/claude-plugin-store-context:store-context`. This is
  how the user re-opens the flow after having said no earlier, or wants to save
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
- Updates to an *existing* feature are appended as pending-update blocks, never
  edited in place — see `merge-context` for how those get folded in. This table is
  only refreshed by `merge-context`, not by regular saves.

## Features

| Feature | Folder | Status |
|---------|--------|--------|
```

## Step 3 — Existing feature or new feature

Ask: **"Save to an existing feature, or start a new one?"**

- **Existing** → list the subdirectories of `feature_context/` (each one is a
  feature) and let the user pick, then **immediately load that feature's context
  into this session** (Step 3.1) before doing anything else.
- **New** → ask the user for the **exact folder name** to use. Don't auto-slugify or
  invent one — they may already have a naming convention from other features in the
  repo. Create `feature_context/<name>/`.

### Step 3.1 — Load the selected feature's context into the session

This happens the moment a feature is selected — whether that selection came from the
automatic session-start flow or a manual invocation — and independently of whether
anything gets written later. Loading is not a write-time implementation detail; it's
the point of the skill: the session should immediately have the same working
knowledge the previous session ended with.

1. Read every file in that feature's folder in full (`README.md` and whichever of
   `ARCHITECTURE.md`, `DB_CHANGES.md`, `OPEN_ISSUES.md`, `RUNBOOK.md`,
   `WORKING_AGREEMENTS.md` exist) — **including any `## Pending updates` sections**,
   since those may contain the most recent information even though they haven't been
   merged into the main prose yet.
2. Treat their contents as active working context for the rest of the session — the
   goal & constraints, design decisions and their reasoning, current status, and open
   issues should inform everything you do from this point on, the same as if the
   person who wrote them had just explained it all to you directly.
3. Give the user a short confirmation of what was loaded — feature name, current
   status, and anything from "Open issues" that's still outstanding (including
   unmerged pending updates, if any — mention that a `merge-context` run is pending)
   — so they can correct you immediately if something's stale or wrong.
4. Keep these files in full in context for the rest of the session.

## Step 4 — Write the context

The goal: a teammate or a fresh Claude session should be able to read this folder and
have **equivalent working knowledge** to where this session left off — the actual
reasoning behind decisions, the current state, how to run things, and what's still
open. Not a changelog; a briefing.

### New feature: write real files directly

There's no existing content to conflict with, so write real, final content straight
into the real sections:

- `README.md` (always) — goal & constraints, key design decisions (and *why*),
  current status, quickstart.
- Only as relevant: `ARCHITECTURE.md`, `DB_CHANGES.md`, `OPEN_ISSUES.md`,
  `RUNBOOK.md`, `WORKING_AGREEMENTS.md`.

Don't create a file just to have the full set — an `ARCHITECTURE.md` with nothing
architectural to say is worse than no file at all. Read
[reference/feature-doc-templates.md](reference/feature-doc-templates.md) for the
section-by-section template before writing any of these for the first time.

### Existing feature: append-only, never edit in place

**This is the important part.** Never edit an existing feature's existing prose
directly — even for a small change. Instead, follow
[../../shared/pending-update-format.md](../../shared/pending-update-format.md)
exactly: append one uniquely-`id`-tagged `PENDING-UPDATE` block, under a
`## Pending updates` heading at the very end of the relevant file(s), describing what
changed this session. Do this for `README.md` always, and for any other file where
something relevant changed.

This is what keeps two teammates' commits to the same feature from conflicting in
git — as long as every write is a pure addition at the end of the file, there's
nothing for git to conflict over. Read the shared format doc for the exact block
syntax and id-generation command before writing anything.

Do **not** update the root `feature_context/README.md` status table here — that's
`merge-context`'s job, done once the pending updates are actually folded in, so
regular saves never touch that shared file either.

## What this skill does NOT do

- **It never touches git.** It only writes files to disk — staging and committing is
  left entirely to the user.
- **It doesn't re-prompt mid-session.** The "do you want to save?" question is asked
  once, at session start. After that, saving again requires the user to explicitly
  invoke the skill.
- **It doesn't merge or clean up pending updates.** That's the companion
  `merge-context` skill's job — this skill only ever appends.
