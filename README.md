# claude-plugin-store-context

Internal Claude Code plugin marketplace. Currently ships one plugin:

- **claude-plugin-store-context** — saves/loads shared, git-tracked feature context in a
  project's `feature_context/` folder. Prompts automatically at the start of every
  session in any project (once the plugin is installed), and can also be run manually.

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
- You can trigger the flow manually any time with `/claude-plugin-store-context:store-context`.

## Sharing with teammates

Just give them the two commands above (with your actual repo path). Each person runs
them once, for themselves — no per-repo setup, no copying files into project repos.

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
install the marketplace/plugin the first time they trust that project folder — this is
the one piece that *is* still project-specific, but it's a few lines pointing at the
plugin, not the plugin's actual files.

## Updating the plugin

Edit files under `plugins/claude-plugin-store-context/`, bump the `version` in that
plugin's `.claude-plugin/plugin.json`, commit and push. Users refresh with:

```
/plugin marketplace update claude-plugin-store-context
/plugin update claude-plugin-store-context@claude-plugin-store-context
```

## Repo layout

```
.claude-plugin/marketplace.json          <- the marketplace catalog
plugins/claude-plugin-store-context/
  .claude-plugin/plugin.json             <- plugin manifest
  hooks/hooks.json                       <- SessionStart hook (bundled, auto-installed)
  scripts/session-start.sh               <- the hook's script
  skills/store-context/SKILL.md          <- the actual save/load flow
  skills/store-context/reference/
    feature-doc-templates.md             <- per-file templates & guidance
```
