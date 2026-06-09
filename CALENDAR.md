# Project Calendar — Truckr® / GDSI

Sprint cadence and key delivery dates for the FIUBA GDSI coursework. All sprints are **weekly (7 days)** and run **Thursday → Wednesday**, with the defense / closure event taking place on the final Wednesday.

This file is the source of truth for `--sprint-start` and `--sprint-length-days` when running the [`team-performance` skill](.claude/skills/team-performance/SKILL.md).

## Phases

| Phase                 | Sprints                    | Window                        |
|-----------------------|----------------------------|-------------------------------|
| Documentation         | Doc Sprint 1 – Doc Sprint 4 | 2026-04-09 → 2026-05-06       |
| Development           | Sprint 1 – Sprint 7        | 2026-05-07 → 2026-06-24       |

## Documentation sprints

These four sprints precede the dev phase. Output: planning artifacts (WBS, personas, USM, features, costs, comms, risks) defended on **2026-05-06**.

| #            | Window (Thu → Wed)             | Closing milestone                                                |
|--------------|--------------------------------|------------------------------------------------------------------|
| Doc Sprint 1 | 2026-04-09 → 2026-04-15        | —                                                                |
| Doc Sprint 2 | 2026-04-16 → 2026-04-22        | —                                                                |
| Doc Sprint 3 | 2026-04-23 → 2026-04-29        | —                                                                |
| Doc Sprint 4 | 2026-04-30 → 2026-05-06        | **Artifact defense** (risks plan, comms plan, costs) + Parcialito |

## Development sprints

Dev phase begins the day after the artifact defense. Sprint *N* defense is the closing event of Sprint *N*.

| #        | Window (Thu → Wed)             | Closing milestone                                              |
|----------|--------------------------------|----------------------------------------------------------------|
| Sprint 1 | 2026-05-07 → 2026-05-13        | Sprint 1 defense (demo + retro; remota) + Parcialito           |
| Sprint 2 | 2026-05-14 → 2026-05-20        | Sprint 2 defense (demo + retro; presencial) + Parcialito       |
| Sprint 3 | 2026-05-21 → 2026-05-27        | Sprint 3 defense (demo + retro; presencial) + Parcialito       |
| Sprint 4 | 2026-05-28 → 2026-06-03        | Sprint 4 defense (demo + retro; remota) + Parcialito           |
| Sprint 5 | 2026-06-04 → 2026-06-10        | Sprint 5 defense (demo + retro; presencial)                    |
| Sprint 6 | 2026-06-11 → 2026-06-17        | Sprint 6 defense (demo + retro; presencial)                    |
| Sprint 7 | 2026-06-18 → 2026-06-24        | Sprint 7 closure + **Final Expo / Delivery** (17:00–21:00, two shifts, presencial) |

## Canonical inputs for `team-performance`

The `team-performance` CLI no longer derives sprint windows from dates — it reads the per-sprint ledger under `docs/progress-reports/` (one `sprint-NN.md` file per sprint, with its window and completed User Stories declared inline). Each ledger file is the machine-readable form of that sprint's progress report (`Informe de Avance`); the report is the source of truth for the file's window and completed/in-progress User Stories. The tables above are the nominal course schedule — the reports may use slightly different (overlapping) day boundaries.

When the question is about the **dev phase** (the default for this skill):

| Flag             | Value           |
|------------------|-----------------|
| `--sprints-dir`  | `docs/progress-reports`  |
| `--phase`        | `development`   |

For the **documentation phase** (rare — typically only for retrospective analysis) pass `--phase documentation`.

Do **not** mix the two phases in a single run — throughput from the documentation phase does not generalise to the development phase (different work type, different cadence). The tool counts only ledger files whose `phase` matches `--phase` and whose `status` is `closed`.
