---
description: Wrap-up before /clear â€” surface anything that exists only in this conversation so it doesn't get lost.
---

# /handover

The user is about to clear context. Capture anything that exists only in this conversation so nothing is lost on `/clear`.

The failure mode this prevents: finishing items, feeling like they're "ticked off," then later finding they were never actually written down.

## Steps

### 1. Detect what's actually been logged

- Run `git status` and `git log -10 --oneline` in the working directory (and any nested repo we've been working in). Note uncommitted work and recent commits.
- Discover trackers in the project. Look at the project root and one level deep for: `TODO.md`, `TODOS.md`, `TASKS.md`, `ROADMAP.md`, `PLAN.md`, `CHANGELOG.md`, `HISTORY.md`, `NEWS.md` (and lowercase variants). If a `CLAUDE.md` exists, scan it for any other tracker paths it mentions.
- For each item this session discussed completing, advancing, or deciding, check whether it's reflected in those trackers and in git.

### 2. Audit memory candidates

Walk back through the session for things worth saving to auto-memory:
- **Feedback** â€” corrections received, or non-obvious approaches the user confirmed worked.
- **Project facts** â€” deadlines, ownership, motivations, decisions that aren't derivable from code or git.
- **Stale memories** â€” anything in `MEMORY.md` this session contradicted or made obsolete.

Skip things excluded by the auto-memory rules (code patterns, file paths, ephemeral task state, anything already in `CLAUDE.md`).

### 3. Catch unwritten decisions

Design choices made in chat that haven't landed in a project doc â€” naming conventions, scope boundaries, "we decided to do it this way becauseâ€¦". These usually belong in a tracker or reference file, not memory.

### 4. Present a punch-list â€” do not auto-write

Group findings by destination (each tracker file, memory, decision log). For each item use one of:
- âœ“ already logged â€” list briefly so the user can confirm coverage
- âœ— missing â€” needs writing, propose the exact text/edit
- ? unclear â€” ask before deciding

Wait for user approval before writing. Apply only what the user confirms. Batch the writes once approved.

### 5. Do not clear context

`/handover` prepares for a clear. The user decides when to `/clear`.

## What to skip

- Freeform "what we did this session" summaries â€” they don't survive `/clear` and the punch-list already covers it.
- Items already correctly logged â€” only surface gaps and ambiguities.
- Speculative follow-ups the user hasn't endorsed.
