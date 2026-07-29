---
name: merge-context
description: >
  Consolidates the append-only pending-update blocks that store-context writes for
  existing features into real, clean prose, then removes those blocks. Part of the
  claude-plugin-store-context plugin. Invoke manually with
  /claude-plugin-store-context:merge-context, or whenever the user says things like
  "merge context", "merge pending updates", "consolidate feature context", "clean up
  feature_context", or mentions pending updates piling up. This is never triggered
  automatically — merging is a deliberate, user-initiated step, typically run before
  committing or opening a PR.
---

# merge-context

The companion to `store-context`. Where `store-context` only ever *appends*
pending-update blocks (to avoid git conflicts from concurrent teammates), this skill
is the one place those blocks actually get folded into the real, readable content —
and it's the only place that updates the root `feature_context/README.md` status
table. Read
[../../shared/pending-update-format.md](../../shared/pending-update-format.md) before
doing anything here if you haven't already — this skill depends on that exact format.

## When this runs

Only manually, via `/claude-plugin-store-context:merge-context`, or when the user
asks for it in conversation. Never automatically — folding pending updates into real
prose is a deliberate edit, not something that should happen silently in the
background.

## Step 1 — Locate `feature_context/`

Same as `store-context`: run `git rev-parse --show-toplevel` (fall back to cwd if not
a git repo), then look for `feature_context/` there. If it's missing entirely, tell
the user there's nothing to merge and stop.

## Step 2 — Find features with pending updates

Scan every feature subdirectory for files containing a `## Pending updates` heading
with at least one `<!-- PENDING-UPDATE ... -->` block. Only list features that
actually have pending updates — don't ask about features with nothing to merge.

- **None found anywhere** → tell the user there's nothing pending and stop.
- **One or more found** → ask the user which feature to merge (or offer "all of
  them" if there's more than one).

## Step 3 — Merge each affected file

**This is a knowledge merge, not a text merge.** The goal is a single, internally
consistent statement of what's currently true — not the old line and the new line
both left sitting in the file for a reader to reconcile themselves. Git can merge
*files* by concatenating non-overlapping hunks; that's exactly what makes
pending-update blocks safe to append concurrently. But folding those blocks into the
real prose is a job for actual reading comprehension, not text concatenation — that's
why this step is a Claude skill and not a git merge driver.

**Worked example.** Suppose `README.md`'s real "Working agreement" section currently
says:

> Do not end trips.

and a pending-update block says:

> End trips when idle.

The correct merged result is a single rewritten statement that's true given both
inputs, e.g.:

> Do not end trips, unless they are idle.

Not "Do not end trips. End trips when idle." (contradictory, left for someone else to
figure out) and not silently picking one line and discarding the other. Read both,
understand what each is actually saying, and rewrite the statement so it correctly
reflects both — refining, narrowing, or extending the original rule as needed.

For the selected feature, for every file that has a `## Pending updates` section:

1. Read the whole file.
2. Parse out every `PENDING-UPDATE` block: its `id`, `user`, `date`, and content.
3. For each real statement a pending update touches (a rule, a decision, a status, an
   open issue, etc.), **rewrite that statement** so it's accurate in light of the new
   information — don't just append the new line next to the old one. Apply blocks in
   **id/date order** (oldest first) so later updates build on or refine earlier ones
   correctly:
   - Update "Current status" by folding new information into the relevant bullet
     (rewriting it if the situation changed), not by appending a second, possibly
     contradictory bullet next to it.
   - For "Key design decisions": if a pending update *refines or narrows* an earlier
     decision (like the trips example), rewrite the decision as one coherent
     statement. If it *reverses* an earlier decision outright (a genuinely different
     choice, not a refinement), keep the old entry for history but clearly mark it
     superseded, and write the new decision as the current one.
   - Add new open issues to `OPEN_ISSUES.md`; if a pending update reports one as
     fixed, rewrite that issue's entry to reflect resolution (✅) rather than leaving
     the old "open" wording next to a new "fixed" note.
   - Route content to whichever file it actually belongs to, even if the pending
     block happened to be appended to README.md's own pending section — a pending
     update mentioning a DB change belongs in `DB_CHANGES.md`'s real content once
     merged, even if it was queued in README.md.
4. Once every block in the file's `## Pending updates` section has been folded in,
   **delete the entire section** — heading and all blocks — from the file. Nothing
   pending should remain if everything in it was merged.
5. If merging surfaces a genuine conflict between two teammates' updates (e.g. two
   different, contradictory decisions about the same thing), don't silently pick one
   — keep both, clearly attributed by user and date, and flag it to the user so a
   person resolves it.

## Step 4 — Update the root index

After merging a feature, update `feature_context/README.md`'s feature table (name /
folder / status) for that feature — add a row if it's new, or refresh the status cell
based on the just-merged "Current status." This is the only time in the whole
save/load/merge workflow that this shared file gets touched, which keeps it low-risk
even though it's shared across every feature.

## Step 5 — Report back

Tell the user, briefly: which feature was merged, which files changed, how many
pending-update blocks were consumed (and from whom/when), and whether anything was
flagged as a genuine conflict needing their attention. Remind them the usual
git add/commit is still on them — this skill only writes files.

## What this skill does NOT do

- **It never touches git.** Same as `store-context` — writes files, nothing more.
- **It doesn't run automatically.** No hook triggers this; it's always a deliberate
  invocation.
- **It doesn't invent resolutions to genuine conflicts.** It merges cleanly whenever
  updates are additive or sequential, and surfaces true contradictions to the user
  instead of guessing.
