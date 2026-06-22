#import "@preview/cmarker:0.1.8"

= Clear stale local issues handoff

_2026-05-22 22:54 UTC — rama `fix/carrier-details-button` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-clear-stale-local-issues.md
  ```,
  h1-level: 4,
  label-prefix: "cc1452-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Picking up the handoff. Starting with inventory before touching anything.
  ```,
  h1-level: 4,
  label-prefix: "cc1453-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Report ready. Inventory of 81 local `.issue.md` vs gh.

  ## Summary

  | Bucket | Count | Action |
  |---|---|---|
  | **GH OPEN** — keep as-is | 2 | leave in `Backlog/` |
  | **GH COMPLETED, in `Done/`** — already correct | 29 | leave |
  | **GH COMPLETED, mislocated** (`Backlog/` or `InReview/`) | 13 | **promote → `Done/`** |
  | **GH closed-NOT_PLANNED** — stale | 34 | **delete (likely)** |
  | **No gh link** | 3 | case-by-case |

  ## Promotions (13 → `Done/`)

  - `Backlog/REQ-FE-00006/00012/00014/00021` — completed in earlier sprints, never moved
  - `InReview/INF-INFRA-00001/00002/00003` (#70/#71/#141) — CI workflows + AWS Terraform shipped
  - `InReview/REF-BE-00001` (#166) — Devise migration shipped
  - `InReview/REF-BE-00002` (#197) — Quote→CargoOffer rename **confirmed merged**
  - `InReview/REQ-BE-00032` (#198) — Cargo fullstack shipped 2026-05-20
  - `InReview/REQ-FE-00006/00015/00016` (#112/#121/#122) — search, offer wizard, TW CRUD shipped
  - `InReview/INF-GEN-00003` (no gh link) — PR **#207 merged 2026-05-21** (team-performance ledger). Move to Done.

  ## NOT_PLANNED — delete candidates (34)

  All in `Backlog/` except 2 in `Done/`:

  - **Backlog (32):** INF-BE-00004, INF-BE-00005, INF-BE-00006, INF-FE-00001, REQ-BE-00006/00007/00008/00011/00012/00013/00014/00015/00016/00017/00018/00019/00025/00026/00027/00028/00029/00030/00031, REQ-FE-00007/00008/00009/00010/00011/00013/00018/00019/00020
  - **Done (2):** INF-FE-00002 (#26, NOT_PLANNED dup), REQ-BE-00004 (#17, NOT_PLANNED) — these already shipped to `Done/` but the gh issue was cancelled; weird but historical

  ## No gh link (3)

  - `Backlog/INF-FE-00003` — "Routing + React Router split" — never filed on gh. Probably stale (starting fresh).
  - `Done/INF-FE-00002` — `.gitignore` update, duplicate TAG with the NOT_PLANNED file. Historical, leave.
  - `InReview/INF-GEN-00003` — team-performance ledger — **PR merged**, move to `Done/`.

  ## Special flags from the handoff

  - **REQ-BE-00007** (US8 payment, very detailed) — handoff says rewrite from scratch
  - **REQ-FE-00009/10/11** (GMaps stack) — overlap with pending GMaps US
  - **REF-BE-00002** — confirmed merged → promote to `Done/`

  Need decisions before touching anything.
  ```,
  h1-level: 4,
  label-prefix: "cc1454-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Lint will run via pre-commit hook on commit. Staging + committing now.
  ```,
  h1-level: 4,
  label-prefix: "cc1455-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Committed `3ca8a45` on `fix/carrier-details-button`. Pre-commit hooks passed.

  ## What landed

  - **35 files deleted** (34 NOT_PLANNED + 1 unfiled `INF-FE-00003` routing draft)
  - **13 files promoted** to `Done/` with `status:done` frontmatter
  - **1 dedup** — `REQ-FE-00006` existed in both `Backlog/` and `InReview/`
  - **`docs/features/ISSUES-INDEX.md`** — 32 rows removed, 12 flipped to `DONE`
  - Tree now matches gh: 45 local files, 2 active in `Backlog/` (#104, #123 — INF-INFRA-00004 was never filed locally)

  ## Out of scope — flagged for separate sweep

  Drift still exists in:
  - **`docs/features/DEPENDENCY-GRAPH.md`** — references deleted TAGs in edges (its own "drift = defect" rule says it should be in sync)
  - **`docs/onboarding/06-roadmap.md`** — narrative refs to `REQ-BE-00006/00011/00018` etc.
  - **`backend/app/models/cargo_offer.rb`** + `cargo_offer_mailer.rb` — comments reference `INF-BE-00006`; handoff said don't touch `backend/`

  These can be a follow-up `chore(docs):` pass or wait for the next docs sweep.

  ## Note re: REQ-BE-00007

  The detailed US8-payment file was deleted per your "delete with the rest" choice — gone from git history forward but still recoverable via `git show 020030b:.gdsi-sdlc/issues/Backlog/REQ-BE-00007-flujo-de-pago-cliente-al-aceptar-oferta.issue.md` when sprint-3 writes the new payment issue.
  ```,
  h1-level: 4,
  label-prefix: "cc1456-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:issues:sync`
  ```,
  h1-level: 4,
  label-prefix: "cc1457-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Stopping before any sync writes — bidirectional dry-run would **undo the cleanup**.

  ## Dry-run summary

  | Action | Count | Direction |
  |---|---|---|
  | CONFLICT | 6 | REF-BE-00002, REQ-BE-00024, REQ-BE-00032, REQ-FE-00014, (and 2 more) — both sides changed since `last_synced` |
  | CREATE_LOCAL | **33** | gh would **re-create the 33 NOT_PLANNED .issue.md files** we just deleted |
  | CREATE_GITHUB | 1 | push INF-GEN-00003 (no gh issue yet) |
  | MOVE_GITHUB | 6 | move project board cards to Done (good — wants the status flip) |
  | UPDATE_GITHUB | 8 | push our `status: done` frontmatter to gh (good) |
  | UPDATE_LOCAL | 1 | pull `INF-FE-00002` from #26 — but we deleted that file |
  | **Total** | **55** | |

  ## Why CREATE_LOCAL: 33

  The 33 closed-NOT_PLANNED gh issues are **still attached to project #7** (the v2 board) — closing as not-planned doesn't remove them from the project. Sync sees them in the project, doesn't find a local mirror, and proposes recreation.

  ## Options
  ```,
  h1-level: 4,
  label-prefix: "cc1458-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  35 items match (33 from deletions + 2 dups: #168 REF-BE-00001 alt, #196 INF-BE-00006 alt). All confirmed `NOT_PLANNED`. Scrubbing the project board now.
  ```,
  h1-level: 4,
  label-prefix: "cc1459-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  CREATE_LOCAL dropped to 0. But 3 problematic CREATE_GITHUB items + 6 conflicts need inspection before sync.
  ```,
  h1-level: 4,
  label-prefix: "cc1460-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Conflicts are flagged-and-skipped, not blocking. Running sync to execute the 14 safe actions; conflicts handled after.
  ```,
  h1-level: 4,
  label-prefix: "cc1461-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Sync done: 14 writes (#209, #210 created; 7 issue updates, 5 project moves). 7 conflicts flagged. Need to (a) close #209/#210 and (b) resolve conflicts.
  ```,
  h1-level: 4,
  label-prefix: "cc1462-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Closing #209/#210 and moving the 5 promoted-conflict items to project Done.
  ```,
  h1-level: 4,
  label-prefix: "cc1463-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Sync complete. Final state below.

  ## What ran

  **Local cleanup** (commit `3ca8a45`):
  - 35 stale `.issue.md` deleted, 14 promoted to `Done/`, ISSUES-INDEX.md reconciled

  **Project board scrub** (gh writes):
  - 35 closed-NOT_PLANNED items removed from project #7 (77 → 42 items)

  **Sync execution** (gh writes + commit `caf901a`):
  - Created #209 (INF-FE-00002 gitignore) + #210 (INF-GEN-00003 team-performance), both immediately closed-as-completed
  - 7 gh issues updated (titles/bodies pushed)
  - 5 project items moved to Done status
  - 5 conflict-promoted items moved to Done manually (REF-BE-00001, REF-BE-00002, REQ-BE-00032, REQ-FE-00014, REQ-FE-00015)

  ## Final state

  | Surface | State |
  |---|---|
  | Open gh issues | 3 (#202, #123, #104) — unchanged from before |
  | Project #7 items | 43 total: 41 Done, 2 Backlog (active OPEN), 2 unset |
  | Local `.issue.md` | 45 files, all aligned with gh |
  | Sync state | 70 synced, **7 flagged conflict** (REF-BE-00001/00002, REQ-BE-00024/00032, REQ-FE-00014/00015/00017) |

  ## Remaining drift (non-blocking)

  - **REQ-BE-00024** and **REQ-FE-00017** — active OPEN issues stuck in conflict state. Metadata-only drift; next planning session can resolve by editing local body to mirror gh + re-running sync, or accepting `--force` direction.
  - **Out of scope** from earlier handoff: `DEPENDENCY-GRAPH.md` and `docs/onboarding/06-roadmap.md` still reference deleted TAGs.
  ```,
  h1-level: 4,
  label-prefix: "cc1464-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/handoff For a new agent to solve the active OPEN issues stuck in conflict state.`
  ```,
  h1-level: 4,
  label-prefix: "cc1465-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff saved to `/tmp/handoff-resolve-active-sync-conflicts.md`. Targets two TAGs (REQ-BE-00024 #104, REQ-FE-00017 #123) stuck in conflict via body/title hash drift since 2026-05-04; covers state-file location, sync engine code paths (`sync.py:468` conflict trigger, `:893` flag handler), three resolution options with tradeoffs, and the 5 cosmetic conflicts as context.
  ```,
  h1-level: 4,
  label-prefix: "cc1466-",
)
