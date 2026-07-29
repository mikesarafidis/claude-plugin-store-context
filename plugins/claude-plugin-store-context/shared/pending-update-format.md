# Pending-update block format

Shared by both skills in this plugin (`store-context` writes these; `merge-context`
consumes and removes them). The whole point of this format is that adding an update
is a **pure append** — nothing else in the file is ever touched — so that two people
committing changes to the same feature file at the same time produce a clean git
merge instead of a conflict.

## The rule

When adding new information to an **existing** feature file (as opposed to writing a
brand-new file for a brand-new feature), never edit existing prose. Instead:

1. Make sure the file ends with a `## Pending updates` section (create it, at the
   very end of the file, if it doesn't exist yet — do not place it anywhere else).
2. Append exactly one new block after the last existing block in that section (or
   right after the heading if there are none yet). Do not modify, reorder, or remove
   any existing block.
3. Do not touch anything above the `## Pending updates` heading.

## Block format

```markdown
## Pending updates

<!-- PENDING-UPDATE id="upd-20260729T143210Z-a1b2c3" user="alice@example.com" date="2026-07-29" -->
### Update — alice@example.com — 2026-07-29
<Whatever changed this session, in the same voice/detail level as the rest of the
file — new decisions and why, status changes, new open issues, etc. Write it as
content meant to be folded into the real sections later, not as a chat log.>
<!-- END-PENDING-UPDATE id="upd-20260729T143210Z-a1b2c3" -->
```

## Generating the id

Don't invent an id by hand — run a command so it's actually unique:

```bash
echo "upd-$(date -u +%Y%m%dT%H%M%SZ)-$(head -c3 /dev/urandom | xxd -p)"
```

Use the same id in both the opening and closing HTML comments of the block.

## What counts as "an existing feature" vs. "a new one"

- **Brand-new feature** → write the real files directly (README.md, and whichever
  others are relevant) with real content in their real sections. There's no existing
  content to conflict with yet, so there's no need for pending-update blocks here.
- **Existing feature, adding to it** → always use a pending-update block. Never edit
  the file's existing sections directly, even if the change seems small.

## What `merge-context` does with these

`merge-context` is the only place these blocks ever get folded into the real content
and removed. Regular saves (via `store-context`) only ever add new blocks — they
never merge or delete existing ones. This keeps every day-to-day write a pure
addition, and concentrates the one operation that touches existing prose (the actual
merge) into a single deliberate, user-invoked step.
