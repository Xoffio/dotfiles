/**
 * tmux-agent for OpenCode — Thin Adapter
 *
 * Routes OpenCode events to the tmux-agent CLI, which updates the tmux
 * window name with a status emoji and pushes tmux notifications.
 *
 * Window status mapping:
 *   session.status (busy)          → 💻  busy
 *   session.idle                   → 🥱  idle
 *   session.error                  → ❗  error + low notify
 *   permission.asked               → 🔐  permission + notify "Needs approval"
 *   question(.v2).asked            → ❓  question + notify "Needs input"
 *   question.replied/rejected      → 😊  answered (agent resumes)
 *   session.created (no parent)    → status-clear (fresh start)
 *
 * Subagent sessions are ignored. Requires tmux-agent in PATH
 * (installed via chezmoi: ~/.local/bin/tmux-agent).
 */

import { spawn } from "node:child_process"
import type { Plugin } from "@opencode-ai/plugin"

const MAX_PENDING_QUESTION_IDS = 100

function setTabTitle(title: string): void {
  if (!process.stdout.isTTY) return
  process.stdout.write(`\x1b]0;${title}\x07`)
}

export const TmuxAgentPlugin: Plugin = async () => {
  // Only run inside tmux
  if (!process.env.TMUX) return {}

  const subagentSessionIds = new Set<string>()
  const pendingQuestionIds = new Set<string>()

  function agent(args: string[]): void {
    try {
      const proc = spawn("tmux-agent", args, {
        stdio: ["ignore", "ignore", "ignore"],
      })
      proc.unref()
    } catch {}
  }

  function isSubagent(sid: string | undefined): boolean {
    return !!sid && subagentSessionIds.has(sid)
  }

  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.created": {
          const info = (event as any).properties?.info
          if (info?.parentID) {
            subagentSessionIds.add(info.id)
            break
          }
          agent(["status-clear"])
          break
        }

        case "session.updated": {
          const info = (event as any).properties?.info
          if (info?.parentID) subagentSessionIds.add(info.id)
          break
        }

        case "session.deleted": {
          const info = (event as any).properties?.info
          if (info?.id) subagentSessionIds.delete(info.id)
          break
        }

        case "session.status": {
          const sid = (event as any).properties?.sessionID
          if (isSubagent(sid)) break
          const status = (event as any).properties?.status
          const statusType = typeof status === "object" ? status?.type : status
          if (statusType === "busy" || statusType === "running") {
            agent(["status", "busy"])
          }
          break
        }

        case "session.idle": {
          const sid = (event as any).properties?.sessionID
          if (isSubagent(sid)) break
          agent(["status", "idle"])
          break
        }

        case "session.error": {
          const sid = (event as any).properties?.sessionID
          if (isSubagent(sid)) break
          agent(["status", "error"])
          agent(["notify", "low", "OpenCode", "Something went wrong"])
          break
        }

        case "permission.asked": {
          agent(["status", "permission"])
          agent(["notify", "low", "OpenCode", "Needs approval"])
          break
        }

        case "question.asked":
        case "question.v2.asked": {
          const properties = (event as any).properties
          if (isSubagent(properties?.sessionID)) break
          const requestId = properties?.id
          if (typeof requestId !== "string" || pendingQuestionIds.has(requestId)) break
          if (pendingQuestionIds.size >= MAX_PENDING_QUESTION_IDS) {
            pendingQuestionIds.delete(pendingQuestionIds.values().next().value!)
          }
          pendingQuestionIds.add(requestId)
          agent(["status", "question"])
          agent(["notify", "low", "OpenCode", "Needs input"])
          break
        }

        case "question.replied":
        case "question.rejected":
        case "question.v2.replied":
        case "question.v2.rejected": {
          const properties = (event as any).properties
          const requestId = properties?.requestID ?? properties?.id
          if (typeof requestId === "string") pendingQuestionIds.delete(requestId)
          agent(["status", "answered"])
          break
        }
      }
    },
  }
}

export default TmuxAgentPlugin
