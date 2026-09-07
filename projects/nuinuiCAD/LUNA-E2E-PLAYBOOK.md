# nuinuiCAD Luna Manual E2E playbook

> **Status: Inactive / historical reactivation reference**
>
> **Current Manual E2E executor: Human only.**
>
> Do not load or execute this playbook during normal Manual E2E. This document does not authorize Luna E2E by itself. Reactivation requires an explicit Human decision plus a fresh re-audit and update of the active Manual E2E owners before any Luna execution.

## Purpose

This document preserves historically useful knowledge from the former Codex Luna Manual E2E workflow so a future reactivation evaluation does not have to reconstruct the old operating model from Issues and PRs.

It is **not current executable policy**.

Current active authority is:

- Manual E2E requirement, `Judgment`, PASS / FAIL / BLOCKED, Human runtime control, and result handling: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- E2E chat lifecycle: [`CHAT-E2E.md`](./CHAT-E2E.md)
- Human VS Code production-host baseline: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- local helper mechanics and current Human startup/closure handoff: [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)
- project routing and the Human-only executor decision: [`README.md`](./README.md)

If any historical text in this document conflicts with an active owner, the active owner wins. Do not “refresh” this archive during a normal Human E2E run or use historical Luna mechanics as an implicit exception.

## Reactivation gate

Before any future Luna Manual E2E execution, all of the following are required:

1. Human explicitly decides to reconsider/reactivate Luna Manual E2E.
2. Fresh-read current `README.md`, `MANUAL-E2E.md`, `CHAT-E2E.md`, `VS-CODE-E2E.md`, `LOCAL-TOOLS.md`, current helper behavior, and current nuinuiCAD production-host implementation.
3. Re-evaluate whether an agent executor provides durable value versus Human-only production-host execution and deterministic automation.
4. Define current capability, evidence, environment, security, retry, failure-classification, and Human-control boundaries.
5. Update the active owners so one coherent executor policy exists before the first reactivated run.
6. Verify versioned helper/parser/runtime behavior needed by that policy rather than assuming the historical command shape still works.

Loading this file, finding that the helper still accepts legacy executor metadata, or discovering historical `READY FOR LUNA` behavior is **not** authorization to reactivate Luna E2E.

## Historical operating model

The former model separated test design, host preparation, and agent operation conceptually as:

```text
Sol High
  exact tested state / stable ref / fixture / oracleを固定
      ↓
Human terminal preparation
  exact checkout
  build
  fresh profile / fixture
  isolated Extension Development Host
  CDP readiness
  handoff identity
      ↓
counted Luna run
  prepared hostへattach
  read-only environment identity preflight
  operate -> observe -> compare -> evidence
      ↓
Sol High
  evidence validation / result classification / retry routing
```

Luna was treated as a test operator, not a test designer or product fixer. The intended operator boundary prohibited Luna from changing implementation code, redesigning the test plan, inventing expected behavior, making aesthetic/product decisions, or continuing from an ambiguous environment.

This model is historical only. The active model now has Human operate every Manual E2E production-host unit.

## Historical tested-state discipline

The old workflow required the exact tested commit to be fixed before an agent run. When `main` was moving, a stable remote E2E ref could be used so evidence remained attributable to a specific commit.

Historical identity checks included:

- exact checkout HEAD equals expected tested commit;
- working tree is clean;
- optional stable E2E ref resolves to that exact commit;
- tested commit remains related to current authoritative default branch as required by the then-current policy;
- implementation-specific selectors, command names, labels, and fixtures are checked against the tested commit rather than assumed from newer `main`.

The useful general lesson remains active elsewhere: evidence must be tied to the exact tested state. This archive does not define current tested-ref mechanics.

## Historical host preparation and handoff

The previous Luna path used an isolated VS Code Extension Development Host prepared before the counted agent run. Historical preparation commonly included:

- fresh `--user-data-dir` and `--extensions-dir`;
- exact extension build and Rust evaluator binary;
- task-specific fixture outside the checkout;
- dedicated CDP port where browser automation was required;
- extension-development launch arguments;
- bounded CDP readiness check;
- a small handoff file/path containing exact expected commit, checkout, isolated root, fixture, port, and runtime binary identity.

A normal historical handoff intentionally transported a short identity/path rather than a giant generated prompt or state dump. Host preparation was intended to be completed before the counted agent operation so an environment failure did not consume an agent run merely to discover that the host had not launched.

Current Human-only policy does not require or advertise a Luna handoff. Current `nuinui-e2e-prepare` session metadata remains owned by `LOCAL-TOOLS.md` and current helper behavior.

## Historical attach / preflight discipline

Before product action, the former agent run was expected to verify the prepared environment read-only. Representative checks included:

1. read the exact handoff identity;
2. verify checkout HEAD / stable ref / clean state;
3. verify the prepared host endpoint remained reachable;
4. verify the active workbench contained the current unique fixture;
5. verify language mode and required extension registration;
6. verify any observation surface used by the test resolved the intended fixture/session.

A failed preflight was an environment `BLOCKED`, not a product failure. The historical agent was not supposed to rebuild, switch checkout, kill arbitrary processes, relaunch the host, or ask the Human for mid-run GUI rescue.

## Historical Objective-only agent boundary

Under the old policy, only predeclared Objective units could be candidates for Luna execution. The expected result had to be concrete before execution and evidence had to support direct comparison.

Examples historically considered suitable in principle included:

- specified command/menu/completion/diagnostic presence;
- exact source or selection state after a declared action;
- specified Undo / Redo result;
- exact visible label/message/value;
- deterministic viewport or state condition.

Human visual / UX / experiential judgment remained Human. The old policy explicitly rejected weakening a Human oracle merely to make it agent-executable.

Current policy goes further: **both Objective and Human judgment Manual E2E units are executed by Human**.

## Historical capability calibration

The former workflow allowed a bounded paired calibration when a materially new Objective operation/evidence primitive was strategically worth adding:

```text
same behavior / same oracle
Human ground-truth once
-> Luna executes independently
-> Sol High compares evidence
-> record reusable capability
```

It was not intended as an open-ended experiment inside a product Issue. Capability drift in VS Code, CDP/Playwright, host wiring, observation APIs, or surface structure could invalidate a previously proven primitive.

This capability model is inactive. Do not perform calibration or infer current capability from this archive.

## Historical evidence and result boundary

The former agent result vocabulary was:

- `PASS` — predeclared observable condition verified with sufficient evidence;
- `FAIL candidate` — observed behavior objectively differed from the predeclared oracle, pending normal failure classification;
- `BLOCKED` — environment / remote state / initial state / operation / observation / evidence / oracle prevented reliable execution.

A Luna result was never intended to bypass the active Human actual-host triage and failure-classification rules. A `BLOCKED` result was not product failure, and a mismatch observation alone did not authorize implementation work.

The current authoritative PASS / FAIL / BLOCKED and Human triage semantics are only in `MANUAL-E2E.md`.

## Historical retry boundary

The former design separated host preparation from the counted agent run. If the prepared host became stale or unreachable after the run began, the intended sequence was:

```text
agent returns BLOCKED
-> counted run ends
-> environment is prepared again from fresh declared state if authorized
-> Sol High decides whether affected units should retry
```

Mid-run Human rescue, arbitrary process cleanup, reuse of an uncertain host, and ad-hoc state reconstruction were considered unsafe because they broke evidence identity.

The same underlying principle remains useful for Human E2E: do not claim PASS from an uncertain initial state. Current retry and preparation mechanics belong to active owners.

## Historical process-isolation lessons

The old Luna workflow assumed strong isolation because unattended automation could attach to the wrong VS Code process/window. Historically this motivated dedicated process cleanup and strict CDP identity checks.

Those Luna-specific dedicated-machine/counting rules are **not current Human baseline requirements**. Active Human host isolation is defined in `VS-CODE-E2E.md` and versioned helper behavior. Do not kill unrelated VS Code processes merely because this archive once required it for Luna automation.

## Historical GUI-only blocker rule

The former remote-terminal preparation path treated GUI-only permission prompts, modal dialogs, System Settings requirements, or other non-shell prerequisites as environment blockers rather than asking the Human to intervene inside a counted agent run.

The durable lesson is classification: environment/setup problems are not product failures. Current Human behavior for such blockers belongs to `VS-CODE-E2E.md` and `MANUAL-E2E.md`.

## Historical surface / selector pitfalls

Past Luna operation needed special care around:

- surface-specific Command Palette visibility;
- cold versus warm Webview lifecycle;
- focus-sensitive QuickPick and keyboard paths;
- stale document/version paths that disappear when normal GUI focus closes a picker;
- exact tested-commit selectors/labels rather than newer-main assumptions;
- host/session identity when multiple windows or processes exist;
- screenshots that show state but do not prove a dynamic interaction sequence.

These observations are retained as historical design input. Current Human plans must still derive exact production paths from current implementation through active reverse-map rules; do not copy an old selector or sequence from this archive without fresh verification.

## Historical deterministic-script exclusion

Even when Luna E2E was active, deterministic repository-owned MCP/script checks were supposed to leave Manual E2E when they did not require a production host. Agent execution was not intended as a wrapper around shell/MCP/JSON comparison.

This principle remains active in `MANUAL-E2E.md`, now without any agent-executor branch.

## Historical closure

The current canonical Human closure helper remains active:

```bash
nuinui-e2e-prepare closure-command --issue SAY-123 [--lane <human-test-lane>]
```

Its current semantics are owned by `CHAT-E2E.md`, `LOCAL-TOOLS.md`, and the helper implementation. Historical Luna result handling does not change cleanup, `e2e-release`, `closure-check`, receipts, marker/session authority, duplicate/no-op behavior, or Human stop/pause precedence.

## Archive maintenance rule

Do not move current Manual E2E rules back into this file while it is inactive.

If future investigation uncovers historically useful Luna-specific evidence, it may be recorded here only when doing so does not create current executable authority. Current behavior changes belong in the active owners and require the normal contract/write lifecycle.
