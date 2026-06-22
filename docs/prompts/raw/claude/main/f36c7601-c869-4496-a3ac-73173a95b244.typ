#import "@preview/cmarker:0.1.8"

= Sesión Claude Code — 14/05/2026 23:31

_2026-05-14 23:31 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ````
  Replicate the agents view feature of Claude Code for pi.dev: https://code.claude.com/docs/en/agent-view

  > ## Documentation Index
  > Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
  > Use this file to discover all available pages before exploring further.

  # Manage multiple agents with agent view

  > Dispatch and manage many Claude Code sessions from one screen. Agent view shows what every session is doing and which ones need your input.

  Agent view, opened with `claude agents`, is one screen for all your background sessions: what's running, what needs your input, and what's done. Dispatch new sessions, watch their state at a glance instead of scrolling through transcripts, and step in only when one needs you. Each background session is a full Claude Code conversation that keeps running without a terminal attached, so you can open it, reply, and leave whenever you want.

  [Agent view in a terminal: the header shows Claude Code v2.1.140, the model, the working directory, and a summary count. Sessions are grouped under Needs input, Working, and Completed, with a dispatch input at the bottom and a footer of keyboard hints.](https://mintcdn.com/claude-code/1B48Qz2Z9hac4SLG/images/agent-view-light.png?fit=max&auto=format&n=1B48Qz2Z9hac4SLG&q=85&s=7a186c96ed47d6700d084d77e786be65)

  [Agent view in a terminal: the header shows Claude Code v2.1.140, the model, the working directory, and a summary count. Sessions are grouped under Needs input, Working, and Completed, with a dispatch input at the bottom and a footer of keyboard hints.](https://mintcdn.com/claude-code/1B48Qz2Z9hac4SLG/images/agent-view-dark.png?fit=max&auto=format&n=1B48Qz2Z9hac4SLG&q=85&s=a5bed7434bae368faea3a8f023b52aa2)

  Use agent view when you have several independent tasks Claude can work on without you watching every step. Dispatch a bug fix, a pull request review, and a flaky-test investigation as three rows, keep working in another window, and check back when a row shows it needs you or has a result.

  When you want to work more directly in any agent's session, attach to the row to enter the full conversation.

  To compare agent view with subagents, agent teams, and worktrees, see [Run agents in parallel](/en/agents).

  <Note>
    Agent view is in research preview and requires Claude Code v2.1.139 or later. Check your version with `claude --version`. The interface and keyboard shortcuts may change as the feature evolves.
  </Note>

  This page covers:

  * [Quick start](#quick-start): give Claude a task to work on in the background, check on it, and step in when needed
  * [Monitor sessions with agent view](#monitor-sessions-with-agent-view), including state icons, peeking and replying, attaching, organizing, and keyboard shortcuts
  * [Dispatch new agents](#dispatch-new-agents) from agent view, from inside a session, or from your shell
  * [Manage sessions from the shell](#manage-sessions-from-the-shell)
  * [How background sessions are hosted](#how-background-sessions-are-hosted) by the supervisor process

  ## Quick start

  This walkthrough covers the core agent view loop: dispatch a task, watch its row update as Claude works, peek to check on it and reply, and attach for the full conversation. The session you dispatch keeps running after you close agent view, so you can leave and come back to it.

  <Steps>
    <Step title="Open agent view">
      From your shell, run:

      ```bash theme={null}
      claude agents
      ```

      Agent view opens with an input at the bottom and a table that fills in as sessions start. Press `Esc` at any time to return to your shell. Your sessions keep running while you're away and reappear the next time you open agent view.
    </Step>

    <Step title="Dispatch a session">
      Type a prompt describing a task and press `Enter`. A new background session starts on that task and appears as a row showing whether it's working, waiting on you, or done. The new session uses the model shown in the agent view header and the same [permission mode](#permission-mode-model-and-effort) you'd get running `claude` in that directory.

      Every prompt you enter here starts its own new session. Typing another prompt and pressing `Enter` launches a second session alongside the first rather than sending a follow-up to it. You can run several in parallel this way.

      Each session uses your subscription quota independently, so see [Limitations](#limitations) before dispatching many at once.
    </Step>

    <Step title="Peek and reply">
      Select a row with the arrow keys and press `Space` to open the peek panel. It shows the session's most recent output, or the question it's waiting on, rather than the full transcript. Type a reply and press `Enter` to send it without leaving agent view.
    </Step>

    <Step title="Attach and detach">
      Press `Enter` or `→` on a row to attach when you want the full conversation. The session takes over the terminal exactly as if you had run `claude`. Press `←` on an empty prompt to detach and return to the table.
    </Step>

    <Step title="Bring an existing session in">
      To move a session you already have open into agent view, run `/bg` inside it, or press `←` on an empty prompt to background it and open agent view in one step. The session keeps running and appears as a row alongside the ones you dispatched.
    </Step>
  </Steps>

  You can use `claude agents` as your primary entry point instead of `claude`: dispatch every task from agent view, attach when you want the full conversation, and press `←` to return to the table.

  ## Monitor sessions with agent view

  Run `claude agents` to open agent view. It takes over the full terminal and lists every session grouped by state, with pinned sessions and the ones that need you at the top. Each row shows the session's name, current activity, and how long ago it last changed.

  The list shows every background session you've started, across all your projects. A session working in one repository and another in a different worktree both appear here, regardless of which directory you opened agent view from. Interactive sessions you have open in other terminals don't appear until you [background them](#from-inside-a-session). [Subagents](/en/sub-agents) and [teammates](/en/agent-teams) a session spawns aren't listed as separate rows.

  To scope the view to one project, launch with `claude agents --cwd <path>`. Only sessions started under that directory appear, including any running in a [worktree](/en/worktrees) dispatched from it.

  ```text theme={null}
  Pinned
    ✽ clawd walk cycle          Write assets/sprites/clawd-walk.png           3m

  Ready for review
    ∙ jump physics              github.com/example/game/pull/2048          ●  2h

  Needs input
    ✻ power-up design           needs input: double jump or wall climb?       1m

  Working
    ✽ collision detection       Edit src/physics/CollisionSystem.ts           2m
    ✢ playtest level 3          run 12 · all checkpoints cleared           in 4m

  Completed
    ✻ title screen              result: menu, options, and credits done       9m
    ∙ sound effects             result: 14 SFX exported to assets/audio       4h
    … 6 more
  ```

  ### Read session state

  Each row starts with an icon whose color and animation show the session's state:

  | State       | Icon shows as | What it means                                                            |
  | :---------- | :------------ | :----------------------------------------------------------------------- |
  | Working     | Animated      | Claude is actively running tools or generating a response                |
  | Needs input | Yellow        | Claude is waiting on a specific question or permission decision from you |
  | Idle        | Dimmed        | The session has nothing to do and is ready for your next prompt          |
  | Completed   | Green         | The task finished successfully                                           |
  | Failed      | Red           | The task ended with an error                                             |
  | Stopped     | Grey          | The session was stopped with `Ctrl+X` or `claude stop`                   |

  Separately, the icon's shape shows whether the underlying process is running:

  | Shape               | What it means                                                                                                     |
  | :------------------ | :---------------------------------------------------------------------------------------------------------------- |
  | `✻` or animated `✽` | The session process is alive and replies immediately                                                              |
  | `∙`                 | The process has exited. You can still peek, reply, or attach, and Claude restarts from where it left off          |
  | `✢`                 | A [`/loop`](/en/scheduled-tasks) session sleeping between iterations. The row shows its run count and a countdown |

  Background sessions don't need any terminal open to keep working. A separate [supervisor process](#the-supervisor-process) runs them, so you can close agent view, close your shell, or start a new interactive session and your dispatched work keeps going.

  Session state persists on disk through auto-updates and supervisor restarts. If your machine sleeps or shuts down, running sessions stop; restart them with `claude respawn --all`.

  ### Row summaries

  The one-line summary in each row is generated by a [Haiku-class model](/en/model-config) so the row can tell you what the session is doing, what it needs, or what it produced without opening the transcript. While a session is actively working, the summary refreshes at most once every 15 seconds, plus once when each turn ends.

  Each refresh is one short Haiku-class request through your normal provider, billed and handled under the same [data usage terms](/en/data-usage) as the session itself.

  ### Pull request status

  When a session opens a pull request, a status dot appears at the right edge of the row, linked to the pull request in terminals that support hyperlinks. When the session has opened more than one pull request, the count appears before the dot and the color reflects whichever one most needs attention.

  | Dot color | Pull request status                           |
  | :-------- | :-------------------------------------------- |
  | Yellow    | Waiting on checks or review, or checks failed |
  | Green     | Checks passed and no review is blocking       |
  | Purple    | Merged                                        |
  | Grey      | Draft or closed                               |

  For most tasks this row is where you pick up the result: review and merge the pull request when the dot turns green.

  ### Peek and reply

  Press `Space` on a selected row to open the peek panel. It shows what the session needs from you, its most recent output, and any pull requests it opened. Most of the time this is enough, and you never need to open the full transcript.

  Type a reply in the peek panel and press `Enter` to send it to that session. When the session is asking a multiple-choice question, the peek panel shows the options and you can press a number key to pick one. For other blocked sessions, press `Tab` to fill the input with a suggested reply you can edit before sending. Prefix a reply with `!` to send a Bash command instead.

  Use `↑` and `↓` to peek at adjacent sessions without closing the panel, or `→` to attach.

  ### Attach to a session

  Press `Enter` or `→` on a selected row to attach. Agent view is replaced by the full interactive session, exactly as if you had run `claude` in that directory. When you attach, Claude posts a short recap of what happened while you were away.

  While attached, the session behaves like any other Claude Code session: every [command](/en/commands), keyboard shortcut, and feature works.

  Press `←` on an empty prompt to detach and return to agent view. If a dialog has focus and isn't responding to `←`, press `Ctrl+Z` to detach immediately.

  Detaching never stops a background session: `←`, `Ctrl+C`, `Ctrl+D`, `Ctrl+Z`, and `/exit` all leave it running. To end a session from inside it, run `/stop`.

  After you've dispatched or backgrounded a session, pressing `←` on an empty prompt works from any Claude Code session, not only ones you attached to from agent view. It backgrounds the current session and opens agent view with that session pre-selected, so you can switch sessions without leaving the terminal. You can turn this shortcut off in `/config`.

  ### Organize the list

  Agent view groups sessions so the ones that need input are at the top, with `Ready for review` and `Needs input` above `Working` and `Completed`. These group names don't map one-to-one to the [states](#read-session-state) above: a session moves to `Ready for review` when it has an open pull request, and `Completed` collects finished, failed, and stopped sessions together. Press `Ctrl+S` to group by directory instead. Your choice persists across runs.

  Within a group:

  * Press `Ctrl+T` to pin a session to the top
  * Press `Shift+↑` or `Shift+↓` to reorder sessions
  * Press `Ctrl+R` to rename a session
  * Press `Enter` on a group header to collapse it

  To remove a session from the list, press `Ctrl+X` to stop it and `Ctrl+X` again within two seconds to delete it. Pressing `Ctrl+X` on a group header deletes every session in that group after confirmation.

  Deleting removes the session from agent view and cleans up its [worktree](#how-file-edits-are-isolated), including any uncommitted changes in it, so push or commit work you want to keep before deleting. The conversation transcript stays on disk and remains available through `claude --resume`.

  Older completed sessions fold into a `… N more` row to keep the list short. Failures and sessions with an open pull request always stay visible.

  ### Filter sessions

  Type in the dispatch input to filter instead of dispatching:

  | Filter                  | Shows                                                                                                    |
  | :---------------------- | :------------------------------------------------------------------------------------------------------- |
  | `a:<name>`              | Sessions running the named agent                                                                         |
  | `s:<state>`             | Sessions in the given state, such as `s:working`. Also accepts `s:blocked` for everything waiting on you |
  | `#<number>` or a PR URL | The session working on that pull request                                                                 |

  ### Keyboard shortcuts

  Press `?` in agent view to see every shortcut in context. The table below summarizes them.

  | Shortcut              | Action                                                                              |
  | :-------------------- | :---------------------------------------------------------------------------------- |
  | `↑` / `↓`             | Move between rows                                                                   |
  | `Enter`               | Attach to the selected session, or dispatch if there's text in the input            |
  | `Space`               | Open or close the peek panel for the selected session                               |
  | `Shift+Enter`         | Dispatch and attach immediately                                                     |
  | `→`                   | Attach to the selected session                                                      |
  | `Alt+1`..`Alt+9`      | Attach to session 1–9 in the current group                                          |
  | `Tab`                 | On an empty input, browse all subagents. Otherwise apply the highlighted suggestion |
  | `Ctrl+S`              | Switch grouping between state and directory                                         |
  | `Ctrl+T`              | Pin or unpin the selected session                                                   |
  | `Ctrl+R`              | Rename the selected session                                                         |
  | `Ctrl+G`              | Open the dispatch prompt in your `$EDITOR`                                          |
  | `Ctrl+X`              | Stop the session; press again within two seconds to delete it                       |
  | `Shift+↑` / `Shift+↓` | Reorder the selected session                                                        |
  | `Esc`                 | Close the peek panel, clear the input, or exit                                      |
  | `Ctrl+C`              | Clear the input; press twice to exit                                                |
  | `?`                   | Show all shortcuts                                                                  |

  ## Dispatch new agents

  You can dispatch new background sessions from agent view, send an existing interactive session to the background, or start one directly from the shell.

  ### From agent view

  Type a prompt in the input at the bottom of agent view and press `Enter` to start a new background session. The session is named automatically from the prompt; rename it later with `Ctrl+R`.

  Paste an image into the prompt to include a screenshot or diagram with the task.

  Prefix or mention parts of the prompt to control how the session starts:

  | Input                             | Effect                                                                                                                                                         |
  | :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `<agent-name> <prompt>`           | If the first word matches a custom [subagent](/en/sub-agents) name, that subagent runs as the session's main agent with the configuration from its frontmatter |
  | `@<agent-name>`                   | Mention a custom subagent anywhere in the prompt to run it as the main agent                                                                                   |
  | `@<repo>`                         | Mention a repository under the directory you opened agent view from to run the session there                                                                   |
  | `/<skill>`                        | Suggest [skills](/en/skills) to dispatch as the prompt                                                                                                         |
  | `#<number>` or a pull request URL | If a session is already working on that PR, select it instead of dispatching                                                                                   |
  | `Shift+Enter`                     | Dispatch and immediately attach to the new session                                                                                                             |

  Packaging a recurring task as a [skill](/en/skills) lets you start the same workflow from agent view repeatedly without retyping the prompt.

  When the same `@name` matches both a subagent and a sibling repository, the subagent takes precedence. The bare first-word match also applies, so a prompt that happens to begin with one of your subagent names dispatches that subagent rather than treating the word as plain text. Use the `@` form when you want to be explicit, or start the prompt with a different word to avoid the match.

  #### Dispatch to a specific directory

  A new session runs in the directory you opened agent view from. To target a different directory:

  * Open `claude agents` in that directory.
  * Open `claude agents` in a parent directory that holds several repositories and mention one with `@<repo>` in the prompt to run the session there.
  * From the shell, `cd` into the directory and run `claude --bg "<prompt>"`.

  When agent view is grouped by directory, the highlighted row's directory becomes the dispatch target, so you can scroll to a group and dispatch into it without retyping the path.

  ### From inside a session

  Run `/background` or its alias `/bg` to move the current conversation into a background session. Pass a prompt such as `/bg run the test suite and fix any failures` to give one more instruction first.

  Backgrounding from an interactive session starts a fresh process that resumes from the saved conversation, so running subagents, [monitors](/en/tools-reference#monitor-tool), and background commands do not transfer to it. Claude asks you to confirm before backgrounding when any are running. Once in the background, the session can start new subagents, monitors, and background commands, and those keep running across later detach and reattach.

  ### From your shell

  Pass `--bg` to start a session that goes straight to the background:

  ```bash theme={null}
  claude --bg "investigate the flaky SettingsChangeDetector test"
  ```

  To run a specific subagent as the session's main agent, combine `--bg` with `--agent`:

  ```bash theme={null}
  claude --agent code-reviewer --bg "address review comments on PR 1234"
  ```

  After backgrounding, Claude prints the session's short ID and the commands for managing it:

  ```text theme={null}
  backgrounded · 7c5dcf5d
    claude agents             list sessions
    claude attach 7c5dcf5d    open in this terminal
    claude logs 7c5dcf5d      show recent output
    claude stop 7c5dcf5d      stop this session
  ```

  ### How file edits are isolated

  Every background session, whether started from agent view, `/bg`, or `claude --bg`, starts in your working directory. Before editing files, Claude moves the session into an isolated [git worktree](/en/worktrees) under `.claude/worktrees/`, so parallel sessions can read the same checkout but each writes to its own. Claude skips this when the session is already under `.claude/worktrees/`, when the working directory isn't a git repository, or for writes outside the working directory.

  Outside a git repository, sessions write to the working directory directly and aren't isolated from each other, so avoid dispatching parallel sessions that edit the same files.

  The worktree is removed when you delete the session, so merge or push the changes you want to keep before you delete. To find a session's worktree path, peek the session or attach and check its working directory.

  To make a subagent always run in its own worktree regardless of how it was started, set [`isolation: worktree`](/en/sub-agents#supported-frontmatter-fields) in its frontmatter.

  ### Set the model

  The model name shown in the agent view header is the dispatch default. New sessions you start from the input use this model, which is the same setting [`/model`](/en/model-config) controls in any session. To override it for the whole agent view session, pass `--model` when opening agent view. See [Permission mode, model, and effort](#permission-mode-model-and-effort).

  Each background session can run on a different model. To override it for one session:

  * From the shell, pass `--model` with `claude --bg`.
  * Attach to a running session and run `/model` there. The change persists if the session is respawned.
  * Dispatch a [subagent](/en/sub-agents) whose frontmatter sets a `model` field.

  ### Permission mode, model, and effort

  A background session reads its [settings](/en/settings) from the directory it runs in, the same as if you had started `claude` there.

  The [permission mode](/en/permissions) depends on how you started the session. Backgrounding an existing session with `/bg` or `←` keeps the current permission mode, so a session you switched to `acceptEdits` or `auto` stays in that mode after detaching. Dispatching from the agent view input or running `claude --bg` from your shell uses the `defaultMode` from that directory's settings, or the `permissionMode` from the dispatched [subagent's frontmatter](/en/sub-agents#supported-frontmatter-fields).

  To set defaults for every session you dispatch from agent view, pass any of `--permission-mode`, `--model`, or `--effort` when opening it:

  ```bash theme={null}
  claude agents --permission-mode plan --model opus --effort high
  ```

  <Note>
    Passing `--permission-mode`, `--model`, or `--effort` to `claude agents` requires Claude Code v2.1.142 or later. Earlier versions reject these flags with an unknown-option error.
  </Note>

  The active defaults appear in the footer below the dispatch input.

  Without these flags, the session uses the `defaultMode` from that directory's settings or the `permissionMode` from the dispatched [subagent's frontmatter](/en/sub-agents#supported-frontmatter-fields), and the model shown in the agent view header.

  Using `bypassPermissions` or `auto` is refused until you have accepted that mode by running `claude` with it once interactively, since those modes let a session you aren't watching act without approval. The same applies whether you pass the mode to `claude agents` or to `claude --bg --permission-mode`.

  ### Settings, plugins, and MCP servers

  Agent view accepts the same configuration flags as `claude` for loading settings, plugins, MCP servers, and additional directories. Each flag applies to agent view itself and is passed through to every session you dispatch from it, so a plugin or MCP server you load this way is available in those sessions too.

  | Flag                                                                                             | Effect                                                                         |
  | :----------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------- |
  | [`--settings <file-or-json>`](/en/settings)                                                      | Override settings for agent view and dispatched sessions                       |
  | [`--add-dir <path>`](/en/permissions#additional-directories-grant-file-access-not-configuration) | Grant file access to an additional directory                                   |
  | [`--plugin-dir <path>`](/en/plugins)                                                             | Load a plugin from a local directory                                           |
  | [`--mcp-config <file-or-json>`](/en/mcp)                                                         | Load MCP servers from a config file or JSON string                             |
  | `--strict-mcp-config`                                                                            | Use only the MCP servers from `--mcp-config`, ignoring other MCP configuration |

  Repeat `--add-dir`, `--plugin-dir`, or `--mcp-config` once per value. The space-separated form, such as `--add-dir a b c`, is not supported with `claude agents`.

  The following example opens agent view with a settings override and one extra directory:

  ```bash theme={null}
  claude agents --settings ./ci-settings.json --add-dir ../shared-lib
  ```

  ## Manage sessions from the shell

  Every background session has a short ID you can use from the shell. The ID is printed when you start a session with `claude --bg`, and each session's ID is its directory name under `~/.claude/jobs/`. These commands are useful for scripting or when you don't want to open agent view.

  | Command                | Purpose                                                                                    |
  | :--------------------- | :----------------------------------------------------------------------------------------- |
  | `claude agents`        | Open agent view. Pass `--cwd <path>` to list only sessions started under that directory    |
  | `claude attach <id>`   | Attach to a session in this terminal                                                       |
  | `claude logs <id>`     | Print the session's recent output                                                          |
  | `claude stop <id>`     | Stop a session. Also accepts `claude kill`                                                 |
  | `claude respawn <id>`  | Restart a stopped session with its conversation intact                                     |
  | `claude respawn --all` | Restart every stopped session                                                              |
  | `claude rm <id>`       | Remove a session from the list. Cleans up its worktree if there are no uncommitted changes |

  ## How background sessions are hosted

  Every session listed in agent view is considered a background session, whether or not you're currently attached to it. By contrast, a session started by running `claude` directly is tied to that terminal and ends when it closes, unless you [send it to the background](#from-inside-a-session).

  ### The supervisor process

  Background sessions are hosted by a per-user supervisor process, separate from your terminal and from agent view. The supervisor starts automatically the first time you background a session or open agent view, and you don't manage it directly.

  The supervisor and its sessions authenticate with the same credentials as your interactive sessions and make no additional network connections beyond the model API.

  Each background session is its own Claude Code process, managed by the supervisor rather than tied to your terminal. A session that's actively working, waiting for your input, or has a terminal attached keeps its process running.

  Once a session finishes and sits unattached for about an hour, the supervisor stops its process to free resources. The transcript and state stay on disk, and the next time you attach, peek, or reply, the supervisor starts a fresh process from where it left off. When every session has finished and no terminal is connected, the supervisor itself exits and starts again the next time you need it.

  The supervisor watches the installed Claude Code binary on disk and restarts into the new version after the regular [auto-updater](/en/setup#auto-updates) replaces it. This is a local file watch, not a network check. Background sessions are detached processes, so they keep running through the restart and the new supervisor reconnects to them.

  ### Where state is stored

  Session state is stored under your Claude Code config directory. If you set [`CLAUDE_CONFIG_DIR`](/en/env-vars), the supervisor uses that directory instead of `~/.claude` and runs as a separate instance with its own sessions.

  | Path                             | Contents                                                               |
  | :------------------------------- | :--------------------------------------------------------------------- |
  | `~/.claude/daemon.log`           | Supervisor log                                                         |
  | `~/.claude/daemon/roster.json`   | List of running background sessions, used to reconnect after a restart |
  | `~/.claude/jobs/<id>/state.json` | Per-session state shown in agent view                                  |

  ### Turn off agent view

  To turn off background agents and agent view entirely, set the `disableAgentView` [setting](/en/settings) to `true` or set the `CLAUDE_CODE_DISABLE_AGENT_VIEW` environment variable. Administrators can enforce this through [managed settings](/en/permissions#managed-settings).

  ## Troubleshooting

  ### `claude agents` lists subagents instead of opening agent view

  If `claude agents` prints a count followed by your configured subagents and then exits, agent view is unavailable in your environment. Earlier versions didn't open agent view in every environment, including when connected through Bedrock, Vertex AI, or Foundry. Run `claude update` to install the latest version.

  If agent view still does not open after updating, check whether it has been [turned off](#turn-off-agent-view) by a setting or environment variable.

  ### Agent view opens with no sessions

  Agent view is empty until you dispatch your first session. Type a prompt in the input at the bottom and press `Enter`.

  ### Cannot open agents because background tasks are running

  If pressing `←` to background the current session shows `Cannot open agents — N background task(s) running`, the session has in-flight work such as a subagent, a workflow, or a background shell command, and the shortcut won't silently abandon it. Run `/tasks` to see what's running, then `/bg` to confirm abandoning them. See [From inside a session](#from-inside-a-session) for what does and doesn't transfer when you background.

  ### Prompt rejected as too short

  The dispatch input expects a task description, not a conversational opener. A prompt shorter than four characters is rejected with a `Too short` hint so a stray keystroke doesn't start a session. Describe what you want the session to do, such as `investigate the flaky checkout test`.

  ### Sessions show as failed after waking your machine

  Background sessions don't survive sleep or shutdown, so sessions that were running show as failed after you wake. Attach, peek, or reply to any of them and the session restarts from where it left off. To restart all of them at once, run `claude respawn --all`.

  ### A session is slow to respond after attaching

  Once a session has finished and sat unattached for about an hour, the supervisor stops its process to free resources. Attaching starts a fresh process from where it left off, which takes a moment. Sessions that are working or waiting on you are never stopped this way.

  ### `.claude/worktrees/` is filling up

  Worktrees are removed when you delete the session that created them. If a session ended without cleaning up, list leftover entries with `git worktree list` in the project directory and remove each with `git worktree remove <path>`. See [Clean up worktrees](/en/worktrees#clean-up-worktrees).

  ## Limitations

  Agent view is in research preview with the following limitations:

  * **Rate limits apply**: background sessions consume your subscription usage the same as interactive sessions, so running ten agents in parallel uses quota roughly ten times as fast as running one.
  * **Sessions are local**: background sessions run on your machine and stop if it sleeps or shuts down.
  * **Worktrees are deleted with the session**: merge or push changes before deleting a session that edited files in its own worktree.

  ## Related resources

  For other ways to run Claude in parallel, see:

  * [Run agents in parallel](/en/agents): compare agent view with subagents, agent teams, and worktrees
  * [Agent teams](/en/agent-teams): coordinate multiple sessions that message each other
  * [Claude Code on the web](/en/claude-code-on-the-web): run sessions in a managed cloud environment instead of locally


  Work in a new project in ~/development/pi-agents-view
  ````,
  h1-level: 4,
  label-prefix: "cc2689-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Before I start, I need to clarify a few things — this is a large feature and "pi.dev" isn't something I have context on.

  **1. What is `pi.dev`?** Is it an existing AI coding agent/CLI you're integrating with? Does it expose an SDK or API for spawning/managing sessions? The whole feature hinges on pi.dev having a backgroundable "session" concept — I need to know what primitives exist to build on.

  **2. Scope of the replica.** Agent view is really three layers:
     - **Supervisor/daemon** — hosts detached background sessions, roster persistence, respawn
     - **Session lifecycle** — dispatch, state tracking, worktree isolation, PR status
     - **TUI** — the grouped table, peek panel, attach/detach, keyboard shortcuts

     Do you want all three, or a subset (e.g. just the TUI over a mock backend to start)?

  **3. Tech stack.** Language/framework? A TUI like this is typically Rust (ratatui), Go (bubbletea), or Node (Ink). Does pi.dev's existing codebase dictate this, or is it free choice?

  **4. Is `~/development/pi-agents-view` a standalone repo**, or should it eventually merge into a pi.dev monorepo?

  My recommendation: start with a thin vertical slice — supervisor + one dispatched session + minimal TUI table — in whatever language pi.dev uses, then layer on peek/attach/worktrees. But I can't pick a stack or design the session API without knowing what pi.dev actually is.

  What can you tell me about pi.dev?
  ```,
  h1-level: 4,
  label-prefix: "cc2690-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  initiate the project with a documentation scaffold and README.md first
  ```,
  h1-level: 4,
  label-prefix: "cc2691-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Scaffolded `~/development/pi-agents-view` (git initialized).

  **Created:**
  - `README.md` — overview, three-layer architecture summary, project layout
  - `docs/architecture.md` — supervisor / session / TUI design, state storage paths
  - `docs/feature-spec.md` — full behaviour spec ported from Claude Code agent view
  - `docs/keybindings.md` — keyboard shortcut reference
  - `docs/cli.md` — shell command surface (`pi agents`, `attach`, `logs`, ...)
  - `docs/open-questions.md` — unresolved design inputs

  **Still blocking implementation** (in `open-questions.md`): what `pi.dev` actually is and what session primitives it exposes (Q1), tech stack, scope, repo placement. The docs use `pi`/`~/.pi`/`.pi/worktrees/` as placeholders pending those answers.

  Next: answer the open questions — especially the `pi.dev` session contract — then I can pick a stack and build the first vertical slice.
  ```,
  h1-level: 4,
  label-prefix: "cc2692-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  <skill name="grill-me" location="/home/[user]/.agents/skills/grill-me/SKILL.md">
  References are relative to /home/[user]/.agents/skills/grill-me.

  Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

  Ask the questions one at a time.

  If a question can be answered by exploring the codebase, explore the codebase instead.
  </skill>

  Here is pi.dev's repo https://github.com/earendil-works/pi/tree/main/packages/coding-agent
  ```,
  h1-level: 4,
  label-prefix: "cc2693-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I've now read pi's SDK and RPC docs. Key facts that shape this: pi ships a `pi` CLI with an RPC mode (`pi --mode rpc`, JSONL over stdin/stdout), an in-process SDK (`createAgentSession`, `AgentSessionRuntime`), JSONL tree-structured session files via `SessionManager`, a streaming event bus, and its own `@earendil-works/pi-tui` package. Config dir is `.pi`. That resolves Open Question #1 — pi has everything we need.

  Now let me grill you. One question at a time, walking the decision tree.

  ---

  **Q1 — Session hosting: RPC subprocess per session, or SDK in-process?**

  This is the foundational fork everything else hangs off.

  - **RPC subprocess per session** — supervisor spawns one `pi --mode rpc` child per background session. True process isolation: a crash or OOM in one session can't take down the others or the supervisor. Matches Claude Code agent view's actual model ("each background session is its own process"). Cost: JSONL serialization across pipes, and the supervisor reconnecting to children after its own restart is harder (children are pipe-attached, so a supervisor restart kills them unless we detach them as their own process group + reattach via a socket).
  - **SDK in-process** — supervisor `import`s pi and runs every session as an `AgentSession` inside one Node process. Cheaper, direct access to state/events, no serialization. But one bad session crashes all of them, and "sessions survive supervisor restart" becomes impossible without a separate persistence/replay story.

  **My recommendation: RPC subprocess per session.** The whole point of agent view is *resilient, independent* background work — isolation is the feature, not an optimization. It also keeps the supervisor small and language-agnostic. To get "survive supervisor restart," each session child is spawned `detached` in its own process group, talking to the supervisor over a per-session Unix domain socket (under `~/.pi/jobs/<id>/sock`) rather than inherited stdio pipes — so the supervisor can die and reconnect. We accept that machine sleep/shutdown still kills children (same limitation Claude Code documents).

  Do you agree with RPC subprocess per session, or do you want the simpler in-process SDK model for a first cut?
  ```,
  h1-level: 4,
  label-prefix: "cc2694-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  RPC subprocess per session
  ```,
  h1-level: 4,
  label-prefix: "cc2695-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Q1 locked: **RPC subprocess per session**, detached process groups, per-session Unix socket.

  ---

  **Q2 — Process topology: who owns the `pi --mode rpc` pipes?**

  `pi --mode rpc` talks JSONL over its own stdin/stdout. Something persistent has to own those pipes, and it can't be the supervisor if sessions are to survive a supervisor restart. Three shapes:

  - **A. Supervisor owns pipes directly** — simplest, but sessions die when the supervisor restarts (auto-update, crash). Contradicts the resilience goal we just committed to.
  - **B. Per-session host process** — a thin wrapper (our code) spawns `pi --mode rpc` as its child over pipes, persists state + transcript to `~/.pi/jobs/<id>/`, and listens on `~/.pi/jobs/<id>/sock`. It runs detached in its own process group. The supervisor and the TUI are just *clients* of that socket. Supervisor can die and reconnect; the host (and its pi child) keep running.
  - **C. Daemonless** — same per-session hosts as B, but no supervisor at all; TUI and CLI commands read `roster.json` + sockets directly, and lifecycle chores (idle-reaping, respawn) are done ad hoc by whoever's running.

  **My recommendation: B, plus keep a thin supervisor daemon.** The per-session host is the unit of resilience. The supervisor stays, but slim — it's the single writer of `roster.json` (avoids races), the home for idle-reaping, binary-watch restart, PR-status polling, and row-summary generation (all of which must keep happening when the TUI is closed). It auto-starts on first dispatch / first `pi agents`, and exits when every session is done and nothing is attached — exactly the Claude Code lifecycle.

  The cost: two layers of our own process (supervisor + N hosts) on top of the pi children. More moving parts than C, but C has no home for the always-on chores and a multi-writer `roster.json` race.

  Agree with per-session host processes + a thin supervisor daemon (B)? Or do you want to try daemonless (C) to cut a process layer?
  ```,
  h1-level: 4,
  label-prefix: "cc2696-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  I'd rather have each process have it's own queue file that they write to, the file may be then read by a supervisor process but keeps the processes self-contained. Does it make sense?
  ```,
  h1-level: 4,
  label-prefix: "cc2697-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Yes, it makes sense — and it's better than my socket proposal for the observe path. Each session-host owns `~/.pi/jobs/<id>/` and is the *sole writer* of its files: `state.json` (current snapshot) + an append-only `events.jsonl` (transcript/event log). Supervisor and TUI just tail those files. No connection management, no reconnect logic, survives supervisor restart for free, single-writer-per-file means no corruption. The host never blocks on anyone reading.

  That resolves the outbound direction. **Q3 is the other direction it implies:**

  **Q3 — Inbound command path: how do `reply` / `abort` / `stop` / `rename` reach a running host?**

  The host is self-contained for *writing*, but commands still have to get *in*.

  - **A. Symmetric file queue** — an `inbox.jsonl` per session; clients (TUI, CLI, supervisor) append a command line, the host tails it via fs-watch (pi already has `src/utils/fs-watch.ts`) and records a consumed-offset so it doesn't reprocess after a restart. Fully file-based, zero sockets, same robustness story as the outbound path.
  - **B. Socket just for commands** — keep a tiny per-session Unix socket only for the inbound path. Lower latency, but reintroduces connect/reconnect handling and "is the host listening yet" races — the exact thing the file approach kills.

  **My recommendation: A, symmetric file queue.** Keep the whole system socket-free. The two concerns are minor and solvable: (1) multi-writer on `inbox.jsonl` — clients append single lines; small appends are atomic under `PIPE_BUF`, or each client writes a uniquely-named `inbox/<ulid>.json` drop-file the host consumes and deletes, which sidesteps it entirely; (2) latency — fs-watch is sub-100ms, fine for human-driven replies. The host consumed-offset (or delete-after-consume) gives clean crash recovery.

  One thing this does *not* cleanly cover is **live attach** — taking over the terminal with a real interactive pi conversation — because you can't have two pi processes writing the same session JSONL at once. That's a genuinely separate design question I'll raise next.

  Agree with the symmetric file queue (A), and within it — single `inbox.jsonl` with offset tracking, or per-command drop-files?
  ```,
  h1-level: 4,
  label-prefix: "cc2698-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  I want to go with A but don't understand the live attach problem nor "single inbox.jsonl with offset tracking, or
   per-command drop-files?"
  ```,
  h1-level: 4,
  label-prefix: "cc2699-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Two separate things. Let me explain both.

  ## The sub-choice within A

  Both are file-based inbound queues. The question is the file layout.

  **Single `inbox.jsonl` with offset tracking**
  One file per session. Every client appends a command as one line:
  ```
  {"cmd":"reply","text":"yes","ts":...}
  {"cmd":"abort","ts":...}
  ```
  The host reads the file, processes new lines, and remembers "I've consumed up to byte 4096" in `state.json`. After a host restart it re-opens `inbox.jsonl`, seeks to 4096, continues. The risk: if the TUI and the supervisor append *at the same instant*, the two lines can interleave mid-line and corrupt the file. Small writes (<4KB) are atomic on local filesystems, so in practice it's fine — but it's a "in practice" guarantee, not an absolute one.

  **Per-command drop-files**
  No shared file. Each client writes its own file into an `inbox/` directory:
  ```
  ~/.pi/jobs/<id>/inbox/01HXYZ...-reply.json
  ~/.pi/jobs/<id>/inbox/01HXZA...-abort.json
  ```
  The filename is a ULID (sortable by time). The host watches the directory, reads each file in ULID order, processes it, **deletes it**. No two clients ever touch the same file, so interleaving is structurally impossible. No offset to track — the presence of the file *is* the queue; deletion *is* the ack. Crash recovery is automatic: unprocessed files are still sitting there after a restart.

  **My recommendation: per-command drop-files.** It removes the multi-writer race entirely instead of relying on "appends are usually atomic," and crash recovery is free (no offset bookkeeping). The only cost is more tiny files, which is irrelevant at human command rates.

  ## The live attach problem

  "Attach" (Claude Code: `Enter` on a row → the full interactive conversation takes over your terminal) is the part file queues *don't* cleanly solve.

  A pi session is backed by one JSONL session file. **Only one pi process can drive that session file at a time** — two pi processes appending to the same JSONL would corrupt the conversation tree.

  While a session runs in the background, **the host's `pi --mode rpc` child already owns that session file.** So when you attach, you can't just `cd` in and run `pi` interactively against the same session — that's a second writer.

  Options (this becomes a later question, not now):
  - The host's RPC child *is* the session; "attach" means the TUI renders the interactive UI itself by streaming `events.jsonl` and sending keystrokes through the inbox queue — i.e. we rebuild the interactive frontend on top of RPC, we never spawn a second pi.
  - Or "attach" hands off: TUI tells the host to gracefully shut down its RPC child, then spawns a real interactive `pi --resume <session.jsonl>` in the terminal; on detach, hands back.

  I flagged it now only so you know the file-queue design doesn't extend to attach for free. We'll make it its own question.

  ---

  So, confirming: **A, per-command drop-files.** Agree?
  ````,
  h1-level: 4,
  label-prefix: "cc2700-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  A, per-command drop-files.
  ```,
  h1-level: 4,
  label-prefix: "cc2701-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Q3 locked: **per-command drop-files** (`inbox/<ulid>-<cmd>.json`, host processes in ULID order then deletes).

  ---

  **Q4 — Live attach: how does `pi agents` → `Enter` on a row give you the full interactive session?**

  The constraint: the host's `pi --mode rpc` child already owns the session JSONL. You can't spawn a second pi on it.

  - **A. TUI renders the interactive UI itself** — never spawn a second pi. The TUI streams `events.jsonl` to draw the conversation and sends keystrokes/prompts through the inbox drop-files. "Attached" vs "table" is just two views in *our* app over the same RPC stream. Pro: one writer ever, attach/detach is instant and trivial, peek and attach share all their plumbing. Con: we have to rebuild pi's interactive frontend — editor, scrollback, slash-command UI, image paste — on top of RPC. That's a lot, and it'll always lag pi's real interactive mode.
  - **B. Hand-off** — on attach, the TUI tells the host to gracefully stop its RPC child (which releases the JSONL), then the TUI execs a real interactive `pi --resume <session.jsonl>` that takes over the terminal. On detach, kill the interactive pi and the host respawns its RPC child. Pro: the attached experience *is* real pi, zero frontend to build, always current. Con: attach/detach has a visible hand-off pause (RPC child drains + interactive pi boots); the session is "not observable" during the hand-off window; and if the TUI dies while attached, the host must notice and reclaim.
  - **C. Hybrid** — B's hand-off, but the host stays the supervisor's data source by tailing the JSONL file directly (pi's `SessionManager` can read it) instead of via its RPC child. So even during attach the row still updates. More moving parts.

  **My recommendation: B, hand-off.** Rebuilding pi's interactive frontend (A) is a huge, permanently-lagging surface — and pi *gives us* a first-class interactive mode + `--resume`, so use it. The hand-off pause is a sub-second annoyance, not a correctness problem. We mitigate the "dead TUI while attached" case with a lockfile (`proper-lockfile` is already a pi dep): the attached TUI holds `~/.pi/jobs/<id>/attach.lock`; the host watches it and, if the lock goes stale, respawns its RPC child and reclaims. The "not observable during hand-off" window is fine — the row just shows `attaching…`.

  This keeps our scope honest: we build the *table/peek/dispatch* layer, and we *delegate* the full conversation to pi itself.

  Agree with hand-off (B)? Or do you want C's "host keeps tailing the JSONL during attach" so rows never go stale?
  ```,
  h1-level: 4,
  label-prefix: "cc2702-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  B
  ```,
  h1-level: 4,
  label-prefix: "cc2703-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Q4 locked: **hand-off attach** (host stops its RPC child → TUI execs interactive `pi --resume`; `attach.lock` via `proper-lockfile` lets the host reclaim if the TUI dies).

  ---

  **Q5 — Session state: which states does the host track, and how is "needs input" detected?**

  Claude Code's docs list six states (working / needs-input / idle / completed / failed / stopped). pi's RPC stream doesn't map cleanly to all six. What pi actually gives us:

  - `agent_start` / `agent_end`, `turn_*`, `message_update`, `tool_execution_*`
  - `get_state` → `isStreaming`
  - `extension_ui_request` with `method: select|confirm|input|editor` — a dialog the agent is *blocked* on (this is also how RPC-mode permission prompts surface, e.g. "Allow dangerous command?")
  - `auto_retry_*`, plus the pi child's process exit code

  Mapping that's actually derivable:

  | State | Derived from |
  |---|---|
  | **working** | between `agent_start` and `agent_end`, or `isStreaming` |
  | **needs-input** | an unanswered `extension_ui_request` dialog is outstanding |
  | **idle** | `agent_end` fired, no outstanding dialog, queue empty |
  | **failed** | `agent_end` with error `stopReason`, retry exhausted, or pi child exited non-zero |
  | **stopped** | we issued `stop` / killed the child |

  The odd one out is **completed**. pi has no "the task is done" concept — the agent just stops streaming and waits. Synthesizing a "completed" state would be guesswork.

  **My recommendation: track 5 host states (working / needs-input / idle / failed / stopped) — drop "completed" as a state.** Keep the **"Completed" *group*** in the TUI though: per Claude Code's own docs that group "collects finished, failed, and stopped sessions together," so it maps to *idle-with-history + failed + stopped*. We keep the grouping UX, we just don't invent a state pi can't tell us. And **needs-input = an outstanding `extension_ui_request` dialog** — the only reliable blocked-on-human signal pi emits.

  Agree with 5 states + "Completed" as a derived group? Or do you want us to synthesize a real "completed" state somehow (e.g. first `agent_end` after a user prompt with no error)?
  ```,
  h1-level: 4,
  label-prefix: "cc2704-",
)

== Intercambio 9

=== Prompt

#cmarker.render(
  ```
  Agree with 5 states + "Completed" as a derived group
  ```,
  h1-level: 4,
  label-prefix: "cc2705-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Confirmed by the code: pi has no worktree isolation — it only *tolerates* running inside one, and a pi session's cwd is fixed at creation (you can't relocate a live session). That last fact decides the shape of the answer.

  ---

  **Q6 — Worktree isolation: eager at dispatch, or lazy on first write?**

  Claude Code does it lazily ("before editing files"). But over pi's RPC that's basically infeasible — there's no hook to relocate a running session's cwd, so "lazy" would mean killing the pi child mid-task and restarting it in a new cwd. Options:

  - **A. Eager** — at dispatch, if cwd is a git repo and not already under `.pi/worktrees/`, the host creates `.pi/worktrees/<id>` as a worktree and starts the pi RPC child there. Always isolated, deterministic. Cost: read-only sessions also get a worktree (cheap, cleaned on delete).
  - **B. Lazy** — start in the real cwd, watch `tool_execution_start` for the first `edit`/`write`, then abort + restart the child in a fresh worktree. Racy (a write may already be in flight), and the restart loses in-memory state.
  - **C. No isolation** — every session runs in the real cwd; parallel sessions stomp each other. Defeats the purpose.

  **My recommendation: A, eager.** B isn't realistically doable over RPC for the reason above, and C is unsafe for parallel work. Eager matches the same skip rules Claude Code documents: not a git repo → run directly in cwd, no isolation; already inside `.pi/worktrees/` → don't nest. The worktree (and any uncommitted changes) is removed when the session is deleted, with the same "push/commit before deleting" warning.

  Agree with eager worktree-at-dispatch (A)?
  ```,
  h1-level: 4,
  label-prefix: "cc2706-",
)

== Intercambio 10

=== Prompt

#cmarker.render(
  ```
  A is perfect
  ```,
  h1-level: 4,
  label-prefix: "cc2707-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Confirmed: `@earendil-works/pi-tui` is a real published package (v0.74.0) with `Box`, `Text`, `SelectList`, `Input`, `Editor`, `Markdown`, `Loader`, `fuzzyFilter`, differential rendering — every component we need for the table + peek + dispatch input.

  ---

  **Q7 — Language/runtime + TUI framework**

  These are coupled. Three plausible stacks:

  - **A. TypeScript/Node + `@earendil-works/pi-tui`** — same toolchain as pi, can `import` pi's RPC types directly for type-safe parsing of `events.jsonl`, components match pi visually (same theme system), differential rendering already solved.
  - **B. TypeScript/Node + Ink** — React-style TUI, more popular ecosystem. But it's a second TUI framework alongside the one pi already ships, and we lose direct visual parity.
  - **C. Rust + ratatui** — fastest, single binary, no Node runtime to ship. But every RPC message has to be re-typed by hand from pi's TS types, and we'd be the only Rust thing in a JS ecosystem.

  **My recommendation: A — TypeScript/Node + `@earendil-works/pi-tui`.** Reusing pi-tui means our view *looks like part of pi* (same theme, same input behavior), we get differential rendering for free, and we can `import` pi's RPC types so a malformed event is a compile error, not a runtime mystery. Build with the same `tsgo` setup pi uses; ship as an npm package `@<your-org>/pi-agents-view` whose `bin` is `pi-agents` (so `pi-agents` is the command, leaving `pi` itself untouched). Node ≥20 to match pi's engines field.

  The one cost: we depend on `@earendil-works/pi-tui` and `@earendil-works/pi-coding-agent` as published peers — pi version bumps may break us. Acceptable; we pin a minor range.

  Agree with TypeScript/Node + pi-tui (A)? Or do you want to go Rust (C) for a single binary?
  ```,
  h1-level: 4,
  label-prefix: "cc2708-",
)

== Intercambio 11

=== Prompt

#cmarker.render(
  ```
  We are a pi plugin, we'll stick and adapy to it's ecosystem. Go with A
  ```,
  h1-level: 4,
  label-prefix: "cc2709-",
)

== Intercambio 12

=== Prompt

#cmarker.render(
  ```
  [Request interrupted by user]
  ```,
  h1-level: 4,
  label-prefix: "cc2710-",
)
