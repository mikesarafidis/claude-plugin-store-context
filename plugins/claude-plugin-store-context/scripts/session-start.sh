#!/bin/bash
# Bundled with the claude-plugin-store-context plugin.
#
# Fires once at the start of every new session in ANY project where this plugin is
# enabled (matcher: "startup" only, so it does NOT fire on --resume/--continue/
# /clear/compaction). It doesn't ask the yes/no question itself -- it just tells
# Claude to run the claude-plugin-store-context skill, which contains the actual flow.

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "A new Claude Code session has started. Before doing anything else, invoke the claude-plugin-store-context:store-context skill to ask the user whether they want to save this session's context to the project's feature_context/ folder."
  }
}
EOF
