# claude-plugin-store-context

Internal Claude Code plugin marketplace. Currently ships one plugin:

- **claude-plugin-store-context** — saves/loads shared, git-tracked feature context
  in a project's `feature_context/` folder. Prompts automatically at the start of
  every session in any project (once the plugin is installed), and can also be run
  manually. Updates to existing features are **append-only** (never in-place edits),
  so concurrent commits from different teammates don't conflict in git. A companion
  `merge-context` command folds those appended updates into clean, readable content
  when you're ready.

## Setting this up (you, the maintainer)

1. Push this folder to a private GitHub repo, e.g. `mikesarafidis/claude-plugin-store-context`.
2. That's it — nothing else needs to go into any individual project repo. The plugin
   applies per-user, across all of that user's projects, once they install it.

## Installing it (you, or anyone you share this with)

From inside any Claude Code session:

```
/plugin marketplace add mikesarafidis/claude-plugin-store-context
/plugin install claude-plugin-store-context@claude-plugin-store-context
```

That's the whole install. From then on, in every project:

- A new session automatically asks whether to save context to `feature_context/`.
- Trigger a save manually any time with `/claude-plugin-store-context:store-context`.
- Trigger a merge of pending updates with `/claude-plugin-store-context:merge-context`
  (typically before committing or opening a PR).

## How the conflict-safety model works

```
Context 1  ──────────────────────────►  Context 1
                                          │  Section 1 (User 1's update, tagged with a unique id)
                                          │  Section 2 (User 2's update, tagged with a unique id)
                                          ▼
                                    /merge-context
                                          │
                                          ▼
                                       Context 2  (sections folded in, pending blocks removed)
```

- Regular saves (`store-context`) on an **existing** feature never edit existing
  prose — they only append a new, uniquely-tagged `## Pending updates` block at the
  end of the file. Two teammates' commits touching only the end of the same file
  merge cleanly in git almost every time, since there's nothing overlapping to
  conflict over.
- `merge-context` is the one deliberate step that reads all pending blocks, folds
  their content into the real sections, and deletes the blocks. It also refreshes the
  root `feature_context/README.md` status table — the only file in the whole
  workflow that isn't purely additive, and the only time it's touched.

## Sharing with teammates

Just give them the two install commands above (with your actual repo path). Each
person runs them once, for themselves — no per-repo setup, no copying files into
project repos.

If you want it to be automatic for your team the moment they open a trusted project
(rather than something they have to remember to run), add this to that project's
`.claude/settings.json` instead of relying on everyone installing it manually:

```json
{
  "extraKnownMarketplaces": {
    "claude-plugin-store-context": {
      "source": {
        "source": "github",
        "repo": "mikesarafidis/claude-plugin-store-context"
      }
    }
  },
  "enabledPlugins": {
    "claude-plugin-store-context@claude-plugin-store-context": true
  }
}
```

With that in a project's committed `.claude/settings.json`, teammates are prompted to
install the marketplace/plugin the first time they trust that project folder — this
is the one piece that *is* still project-specific, but it's a few lines pointing at
the plugin, not the plugin's actual files.

## Updating the plugin

Edit files under `plugins/claude-plugin-store-context/`, bump the `version` in that
plugin's `.claude-plugin/plugin.json`, commit and push. Users refresh with:

```
/plugin marketplace update claude-plugin-store-context
/plugin update claude-plugin-store-context@claude-plugin-store-context
```

## Repo layout

```
.claude-plugin/marketplace.json            <- the marketplace catalog
plugins/claude-plugin-store-context/
  .claude-plugin/plugin.json               <- plugin manifest
  hooks/hooks.json                         <- SessionStart hook (bundled, auto-installed)
  scripts/session-start.sh                 <- the hook's script
  shared/pending-update-format.md          <- the append-only block format both skills use
  skills/store-context/SKILL.md            <- save/load flow (append-only on existing features)
  skills/store-context/reference/
    feature-doc-templates.md               <- per-file templates & guidance
  skills/merge-context/SKILL.md            <- consolidates pending updates, cleans them up
```
