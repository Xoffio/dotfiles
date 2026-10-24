---
name: herdr-orchestrate
description: Drive Herdr to orchestrate parallel coding agents. Create one worktree per feature, spawn minion agents in them, give the human an editor pane per worktree, collect results, and merge/remove worktrees on request. Use when the orchestrator agent (or the user) asks to fan out work across Herdr worktrees/panes. Requires HERDR_ENV=1.
---

# Herdr Orchestration Playbook

Exact commands for the orchestrator to fan out work across Herdr worktrees. This skill assumes the `herdr` skill's concepts (workspace/tab/pane IDs, agent lifecycle). Load it for the CLI patterns; keep prompts to minions small and bounded.

## Preconditions

```bash
test "${HERDR_ENV:-}" = 1 || { echo "not in herdr"; exit 1; }
command -v jq >/dev/null || echo "warning: jq not found, parse JSON manually"
```

All Herdr responses are JSON. Read IDs from them; never predict them. Use `--no-focus` on every layout/spawn command so the user's focus never moves.

## 1. Create a worktree for a feature

Run from the main checkout (the repo root). Creates branch, checks it out under `~/.herdr/worktrees/<repo>/<branch>`, and opens a new workspace whose root pane cwd is the worktree.

```bash
herdr worktree create --cwd "$PWD" --branch "feat/<slug>" --no-focus
```

Response shape (read these):
- `.result.workspace.workspace_id`  -> new workspace, e.g. `wM`
- `.result.root_pane.pane_id`       -> root pane in the worktree, e.g. `wM:p1`
- `.result.worktree.path`           -> checkout path
- `.result.worktree.branch`         -> branch name

Store `WS`, `ROOT`, `WT_PATH`, `BRANCH` per feature.

## 2. Lay out panes: minions left, editor right

Editor gets the right 50%. Split it off the root pane:

```bash
EDITOR=$(herdr pane split "$ROOT" --direction right --ratio 0.5 --no-focus | jq -r '.result.pane.pane_id')
herdr pane rename "$EDITOR" editor
```

The editor pane is a plain shell in the worktree. Do NOT start an agent in it. It is for the human (nvim, etc.).

Minions go on the left, stacked in rows. The root pane is the top-left minion slot; split it downward for each additional minion:

```bash
# first minion reuses $ROOT (top-left). For a 2nd, 3rd... minion:
MIN2=$(herdr pane split "$ROOT" --direction down --no-focus | jq -r '.result.pane.pane_id')
```

## 3. Spawn a minion agent

Pick an installed kind (on this machine `opencode` is available; `claude`/`codex` may not be). Detect before spawning:

```bash
for k in claude codex opencode; do command -v "$k" >/dev/null && { echo "$k"; break; }; done
```

Start the agent in a left pane with a unique name (`[a-z][a-z0-9_-]{0,31}`):

```bash
herdr agent start minion1 --kind opencode --pane "$ROOT"
```

Optionally pin a model via native args after `--` (opencode accepts `-m provider/model`):

```bash
herdr agent start minion1 --kind opencode --pane "$ROOT" -- -m github-copilot/<model>
```

`agent start` returns when the agent is ready. If it returns `agent_not_ready`, wait for `idle` before prompting:

```bash
herdr agent wait minion1 --until idle --timeout 60000
```

## 4. Prompt the minion and wait

Give a bounded task: goal, the exact files/area it may touch, and a verify command. The agent already runs with cwd = the worktree, but state the worktree path and that it must not touch the main checkout or other worktrees.

```bash
herdr agent prompt minion1 "Work only in $WT_PATH. <task>. Verify with: <cmd>. Do not run git. Reply with the result." --wait --timeout 600000
```

`--wait` returns on the first settled `idle`/`done`/`blocked`. A timeout does not prove the prompt was not delivered — inspect before resending.

For multiple minions, send prompts in parallel (background each `herdr agent prompt ... &` and `wait`).

## 5. Read results

```bash
herdr agent read minion1 --source recent-unwrapped --lines 120
```

If `blocked`, inspect with `herdr agent get minion1` and `agent read`, then ask the user before answering any approval dialog. Do not answer it yourself.

## 6. Report

Report per feature: branch, worktree path, workspace id, and the minion's result. Tell the user the editor pane is ready for review. Then stop — do not merge or remove unless asked.

## 7. Merge (only when the user asks)

Confirm the minion's work is complete and committed in the worktree. Then, from the main checkout:

```bash
git -C "<main-checkout>" merge --no-ff "$BRANCH"
```

Resolve conflicts if any; if it gets messy, stop and hand back to the user.

## 8. Remove the worktree (only when the user asks, after merge or abort)

```bash
herdr worktree remove --workspace "$WS" --force
```

This removes the Herdr workspace, the git worktree, and its checkout. Confirm the branch was merged (or the user accepts losing it) before `--force`.

## Safety

- Never touch a workspace/worktree/pane you did not create unless the user asked.
- Never run `herdr server stop` or kill the main Herdr process.
- Keep the user's focus in place: always `--no-focus`.
- Do not commit secrets. Minions are told not to run git; the orchestrator handles merge/removal explicitly and only on request.
