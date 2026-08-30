# nuinuiCAD Manual E2E execution rules

## Purpose

Manual E2E in nuinuiCAD means verification that requires an actual nuinuiCAD execution environment that web ChatGPT cannot operate directly.

It does **not** mean every check is performed by a human.

Each Manual E2E unit is classified by:

- `Judgment: Objective` — PASS / FAIL follows a predeclared observable oracle without tester discretion.
- `Judgment: Human` — PASS / FAIL intentionally depends on human visual / UX / design / experiential judgment.
- `Executor: Luna` — an Objective unit whose required production-host operation / observation / evidence path is currently reliable for Codex Luna xhigh.
- `Executor: Human` — Human judgment is required, or the necessary Luna capability / evidence path is not reliable enough.

The Linear `Manual E2E` label is aggregate state for the Issue. Do not create separate Luna / Human labels.

## When Manual E2E is required

Manual E2E is `Required` only when at least one acceptance condition cannot be sufficiently verified by automated tests without operating an actual production execution environment.

Decision order:

1. acceptance intentionally requires human visual / UX / design / experiential judgment → Manual E2E Required;
2. acceptance depends on production-host / session behavior that automated tests cannot sufficiently prove, such as host wiring, lifecycle, focus, selection, window/session state, or another host-only boundary → Manual E2E Required;
3. otherwise, if automated verification sufficiently proves acceptance → `Manual E2E: Not Required`.

A Task is not Manual-E2E-required merely because it is UI-related, visual, user-facing, or implemented in a production host.

Executor capability does not decide requirement. First decide whether production-host Manual E2E is necessary; then classify executor.

## Deterministic MCP / script verification is not Luna Manual E2E

Do not spend Luna on a check that can be fully executed and judged by deterministic repository-owned MCP calls or equivalent local scripts without operating a production host / UI / session.

Examples include frozen-fixture calls to `document_inspect`, `document_evaluate`, `document_definition`, or `document_references` with structured-result comparison.

For these checks:

- prefer automated CI tests when the same boundary is reliable there;
- otherwise use a deterministic terminal / script verification as supporting evidence;
- do not use Luna merely as a wrapper around shell / MCP / JSON comparison;
- split MCP-only semantics from genuine host-only actions when acceptance meaning is preserved;
- avoid duplicate semantic oracles unless cross-boundary agreement is itself acceptance.

MCP evidence may support a real Luna host run after Luna performs the required production-host action.

Client/MCP path itself remains part of acceptance only when the Task explicitly tests that boundary, such as MCP registration / startup / interoperability or attached production-host observation.

## Timing relative to merge

Required Manual E2E is **after merge by default**.

```text
implementation
-> automated verification
-> blocking review
-> merge
-> required Manual E2E
-> PASS
-> Done
```

Pre-merge Manual E2E is an explicit Task-contract exception only when unusual merge risk or acceptance requires it.

A post-merge FAIL returns the Work to normal implementation decomposition / fix / review / merge / rerun flow. Do not make pre-merge E2E the default merely to avoid post-merge fixes.

## Post-merge implementation-backed reverse-map re-audit

For Required Manual E2E whose timing is post-merge, do not finalize `Manual E2E: Ready to Run`, or synchronize it to `Ready to Run` after merge, until Sol High has freshly checked the latest merged tested ref and completed a focused reverse-map re-audit against the relevant current implementation.

The authority order is:

```text
Issue / normative product contract
    defines required behavior

current tested implementation
    defines the concrete production path that Manual E2E must exercise

Manual E2E plan
    proves the contract through that current production path
```

The current implementation is not the product-contract owner. If the implementation and the normative contract disagree, do not weaken or rewrite the E2E oracle to match the implementation. Treat the discrepancy as an implementation defect or contract mismatch and resolve it through the normal contract / implementation path.

For each required post-merge Manual E2E unit, complete and retain a focused mapping equivalent to:

```text
current implementation owner / production entrypoint
    -> actual host path / state transition / failure branch
    -> user-observable behavior
    -> fixture / action / expected observation / evidence
```

The re-audit follows only relevant implementation owners and paths; it does not require reading the entire source tree. When acceptance depends on them, check:

- the actual production entrypoint, command, menu, context, and host wiring;
- the relevant state guard, lifecycle path, and error branch;
- the exact user-facing label, message, or result when objectively derivable;
- the exact source transformation or output shape when objectively derivable;
- native-host boundaries such as Undo / Redo transactions, QuickPick, focus, and session behavior;
- whether deterministic semantics are already sufficiently proven by automated tests and should therefore not be duplicated as Manual E2E units.

The current Manual E2E plan must connect each unit's fixture, action, oracle, and evidence to this actual production owner / path. Reading an implementation path does not by itself make a deterministic MCP / script check Manual E2E; preserve the deterministic-verification exclusion above.

### Concrete drift examples

The following SAY-224 examples describe the reverse-map failure mode; they are methodology examples, not SAY-224-specific permanent product requirements:

- **Qualified / scoped rewrite:** when automated or current-implementation evidence objectively establishes a concrete result such as `@Outer::A -> @Other::B`, the Human oracle must name and check that concrete expected rewrite. A generic instruction such as “resolves correctly” leaves the tester to invent qualification semantics.
- **Stale QuickPick guard:** when the implementation's stale path depends on a pending QuickPick observing a document-version or text change, the action must actually exercise that pending-QuickPick path and observe its specific stale result. An instruction that merely says “change Source while QuickPick is open” is insufficient if normal GUI focus behavior can dismiss the QuickPick before the guard is reached.

### Tested-ref drift after mapping

After an implementation-backed mapping has been established, a tested-ref change caused by a fix merge or other relevant implementation update makes the affected owner / path mappings stale until they are re-audited. Sol High must fresh-read the affected production owner / path and revalidate the affected units' fixture, action, oracle, and evidence mapping. Do not mechanically redesign unaffected units.

If the tested ref changes but the relevant owners and paths do not drift, revalidate that the existing mapping remains valid; a full plan redesign is not required solely because the commit identity changed.

This re-audit does not change Judgment / Executor selection or Human / Luna semantics. Issue #92 separately owns FAIL-time runtime control and Human stop / pause precedence; those semantics are outside this change and must not be reorganized here.

## Plan-time classification

Before `Manual E2E: Ready to Run`, each unit states:

- initial state / fixture;
- action;
- expected observation;
- evidence;
- for required post-merge Manual E2E, the current tested implementation owner / production-path mapping, including the relevant state transition or failure branch;
- `Judgment: Objective | Human`;
- `Executor: Luna | Human`;
- for Human when useful: `Reason: human judgment | Luna capability`.

Do not classify only at whole-Issue granularity when units differ.

Before assigning Objective work to Luna, remove deterministic MCP / script-only checks from Manual E2E.

## Test-unit boundaries

A unit's initial state is part of its oracle.

Split materially distinct lifecycle paths when starting state changes the production path, for example cold vs already-open surface / session. Do not build a mechanical Cartesian product of every possible state.

When one scenario contains independently judgeable Objective observations and Human visual / UX judgment, split them by default. Keep together only when separation changes acceptance meaning.

Units may share setup without sharing judgment / executor classification.

## Objective judgment

Use `Judgment: Objective` only when:

- expected result is concrete before execution;
- observation can be compared without subjective interpretation;
- tester need not invent missing semantics;
- same initial state / action should yield the same PASS / FAIL;
- useful evidence can be recorded.

Examples:

- specified command / menu / completion / diagnostic / element / state present or absent;
- keyboard action produces specified source / selection / caret / Canvas state;
- Undo / redo produces specified state;
- exact label / message / value / source text appears;
- explicit geometric condition such as viewport containment holds.

Visual observation alone does not make a unit Human.

## Human judgment

Use `Judgment: Human` for intentionally non-reducible quality judgment, including:

- visual / layout discomfort or `違和感`;
- spacing / hierarchy / typography / color / iconography / balance;
- whether UI feels crowded, natural, confusing, polished, or understandable;
- whether interaction feels awkward / natural;
- overall Canvas / Editor result looking wrong despite binary checks passing.

Human judgment is an intentional quality gate, not an automation gap.

Do not use Human judgment as a fallback for an incomplete oracle. If product semantics remain ambiguous, return the contract / plan to non-Ready and resolve them first.

## Human execution and screenshot evidence

For `Executor: Human`, the Human may operate the production GUI directly with mouse / keyboard, make the required live visual or interaction judgment, and submit screenshots as evidence or diagnostic context.

Use screenshot evidence efficiently:

- when multiple cases are simultaneously observable in one frame, compose the fixture / viewport so one screenshot covers them together rather than requesting one screenshot per case;
- do not split otherwise equivalent cases into separate test units or separate screenshots only to increase evidence count;
- split when a different initial state, lifecycle path, dynamic interaction, mutation / revert boundary, or other materially different execution path makes one-frame judgment unreliable;
- a static screenshot does not replace a live interaction oracle. For dynamic behavior such as stepping, focus, drag, stale-state cleanup, or transition quality, Human live observation plus a concise result report is sufficient when the declared acceptance does not require persistent visual evidence;
- request additional screenshots when a failure, ambiguity, or diagnosis benefits from them rather than requiring them mechanically on every normal path.

For `Judgment: Human`, Human PASS / FAIL remains the final quality judgment. ChatGPT may inspect submitted screenshots to confirm objective visible facts, summarize evidence, and help diagnose anomalies, but must not silently replace the required Human aesthetic / experiential judgment with its own screenshot interpretation.

## Executor selection

Apply after judgment classification and removal of MCP/script-only checks.

```text
Judgment: Human
=> Executor: Human

Judgment: Objective
+ production-host / session operation required
+ required operation / observation / evidence family is covered by the current proven Luna baseline
+ no known blocker / material drift
=> Executor: Luna

Judgment: Objective
+ production-host / session operation required
+ required Luna capability is unknown, missing, unreliable, or materially drifted
=> Executor: Human
   Reason: Luna capability
```

For Objective work, prefer Luna **within the proven capability baseline**. Do not use a live product Issue as an open-ended Luna capability experiment merely because the oracle is objective.

Do not weaken a Human oracle to make it Luna-executable.

## First-use capability calibration

When a new Objective operation / evidence primitive is strategically worth adding to the reusable Luna baseline, use one bounded paired calibration when practical:

```text
same behavior / same oracle
Human ground-truth once
-> Luna executes independently
-> Sol High compares evidence
-> record reusable capability
```

This is capability calibration, not permanent Human assignment or a new quality gate.

Use it for materially new operation/evidence families such as new VS Code surface interaction, webview interaction type, popup/hover/Quick Fix path, drag/selection mechanism, or observation path.

Do not force calibration inside a product Issue when doing so would create more operational overhead than simply assigning the current Objective unit to Human. Capability improvement can be tracked separately.

Do not repeat Human calibration for already-proven primitives unless material drift in VS Code / Playwright/CDP / host wiring / observation API / surface structure invalidates the baseline.

Human judgment units remain Human regardless of Luna capability.

If Human ground truth and Luna disagree, classify the mismatch as fixture/oracle, environment, operation, evidence, Luna capability, or product behavior before retrying. Do not repeatedly ask the Human to rerun by default.

## Execution-time freshness check

Immediately before Luna prompt generation or Human instructions, Sol High re-checks:

1. latest Project Context;
2. current Issue contract / Manual E2E plan;
3. intended remote repository state / tested commit and whether the tested ref or relevant implementation owners / paths have drifted;
4. initial state / fixture / actions / expected observations and each unit's implementation-backed mapping;
5. whether each planned unit still exercises the current tested implementation's actual production path and can observe the contract-defined oracle;
6. whether proposed Luna units still require production-host action rather than deterministic MCP/script verification;
7. whether the required Luna operation / observation / evidence family remains in the proven baseline without material drift;
8. whether Human judgment has accidentally moved into agent execution.

When the implementation-backed mapping was completed at `Ready to Run` time and the tested ref and relevant owners / paths have not drifted, this check only needs to prove that the mapping remains valid; it does not require a full plan redesign.

Safe reclassification:

- Luna unit becomes MCP/script-only → remove from Manual E2E and automate / script;
- `Luna -> Human` when capability / evidence reliability is not sufficient;
- bounded environment / prompt issue with a proven primitive → correct and retry when reasonable;
- `Human -> Luna` only when `Judgment: Objective` and Human assignment existed solely because of Luna capability;
- `Judgment: Human` never becomes Luna solely for efficiency;
- ambiguous product oracle returns contract / plan to non-Ready.

Repeated capability boundaries belong in [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md).

## Meaning of start for In Review Manual E2E

When the user asks to start, restart, or resume an `In Review` Issue whose current execution track is Manual E2E, do not stop after re-audit, classification, or Linear state transition.

`Start` is complete only when the next executor has an immediately actionable first handoff in the same response, unless a concrete blocker prevents execution.

Before that handoff:

1. re-audit the current Issue / Manual E2E plan;
2. perform the execution-time freshness check;
3. when local execution is required, determine the execution checkout using [`CHECKOUTS.md`](./CHECKOUTS.md) and its reuse-first rule before generating a launch/setup command;
4. move Manual E2E to `Running` only when execution is actually beginning;
5. provide the first executable handoff immediately.

For `Executor: Human`:

- if local environment preparation is required and the safe checkout is already known, provide the complete copy/paste-ready terminal setup block required by the environment owner document;
- do not make the Human manually substitute commit SHAs, checkout paths, fixture source, ports, or other values that Sol High can fix in advance;
- do not choose the primary checkout merely because it is the canonical repository path, and do not create an additional/disposable worktree merely to avoid selecting among existing standard / reusable checkouts;
- if the current local usage / cleanliness of candidate checkouts is not known to Sol High, the first handoff must instead be one copy/paste-ready **read-only checkout-selection preflight command** that inspects the standard / reusable candidates without switching branches, resetting, stashing, cleaning, or otherwise mutating user work;
- after the Human returns that preflight output, select the safe checkout and provide the next complete copy/paste-ready setup block.

Do not report an `In Review` Manual E2E Issue as newly started while the user still has to ask separately for the first command.

## Sol High -> Luna prompt

Sol High owns classification and prompt construction. Luna is test operator, not designer or fixer.

Prompt includes only what is needed:

- repository / checkout identity and expected branch / commit;
- remote-state verification;
- exact isolated launch / environment setup;
- fixture / initial state;
- exact Luna-assigned units;
- per unit action / expected observation / evidence / failure dependency;
- blocking conditions;
- required result format.

Luna must not:

- change implementation code;
- fix failures;
- redesign / expand test plan;
- invent expected behavior;
- make product / UX / aesthetic judgments;
- perform Human-assigned units;
- do unrelated cleanup / investigation.

Do not include deterministic MCP/script-only work in Luna prompt merely because Luna can call it.

## Luna execution contract

Luna only:

```text
operate
-> observe
-> compare with predeclared oracle
-> record evidence
```

Per unit:

- `PASS` — expected observable condition verified with sufficient evidence;
- `FAIL` — observed product behavior objectively differs;
- `BLOCKED` — environment / remote state / initial state / operation / observation / evidence / oracle prevents reliable execution.

For `FAIL`, record the expected result, observed result, concise reproduction steps, and evidence.

For `BLOCKED`, record the exact blocking condition and do not guess through it.

A Luna `BLOCKED` is not product failure.

- bounded environment / instruction issue on a proven primitive → correct and retry when reasonable;
- actual capability / evidence limitation → reclassify Objective unit to Human;
- ambiguous oracle → resolve contract, not Human-judgment fallback.

If a failed unit invalidates the initial state or meaning of later units, stop those dependent units. Otherwise continue independent units so one failure does not hide unrelated evidence.

Screenshots may be evidence for Objective state but do not authorize aesthetic judgment.

Luna never modifies repository files during Manual E2E.

## Result handling by Sol High

Sol High validates evidence before accepting Luna result.

A Luna `PASS` requires evidence supporting the predeclared oracle; commentary such as “looks correct” is insufficient.

A Luna or Human product `FAIL` does **not** choose the implementation executor.

First classify the result:

- test environment / instruction problem → correct setup / plan and rerun;
- Luna capability problem → reclassify executor; do not treat as product failure;
- ambiguous / newly exposed product decision → return Contract / plan to non-Ready;
- confirmed implementation failure → return to implementation decomposition.

### Implementation failure decomposition

For confirmed implementation failure:

1. before returning the Work to the implementation queue, perform a focused contract re-audit against the latest Project Context, current Issue record, and latest remote `main`; use the individual re-audit criteria in [`CONTRACT-REAUDIT.md`](./CONTRACT-REAUDIT.md) and do not treat the prior `Contract: Ready` or failed tested commit as current implementation authority;
2. identify the concrete failure class and semantic owner;
3. determine Same Issue vs independent new leaf using [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md);
4. determine smallest natural fix slice / safe checkpoint using [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md);
5. synchronize the re-audit result before implementation resumes:
   - current authority uniquely determines the fix contract / acceptance → `Contract: Ready`;
   - a real product / UX / scope / compatibility decision remains → `Contract: Pending`;
   - a prerequisite prevents an executable contract → `Contract: Blocked`;
   - keep `Manual E2E: Failed` as failure evidence until a later rerun passes;
6. only `Contract: Ready` + unblocked Work returns to normal implementation execution under [`CHECKOUTS.md`](./CHECKOUTS.md) and [`CODING-AGENT.md`](./CODING-AGENT.md):
   - select a `FREE` `main` or `sub` implementation lane;
   - freeze the fix Base checkpoint SHA and record the implementation checkpoint;
   - Codex Luna xhigh performs implementation / blocking fix / verification / git work;
   - never implement or repair the product from the `e2e` checkout;
7. implement / verify / review / merge;
8. when only required Manual E2E remains again, return to `manual_e2e_only + In Review`.

Do not create a direct web-ChatGPT implementation route for an E2E failure. ChatGPT owns failure classification, focused re-audit, fix contract, slicing, lane assignment, blocking review, and management; Luna owns the repository implementation/fix execution.

Multiple independent failure classes may become separate leaf Issues or sequential slices when natural. Do not create a new Issue mechanically for every Human comment or micro-fix.

For mixed Manual E2E, run Luna Objective units before Human judgment when dependencies allow and the Luna units are within proven capability. This avoids spending Human quality-review effort on a product that already fails objective behavior.

`Manual E2E: Passed` is set only after all required units pass.

## Rerun after implementation fix

Rerun each affected unit from its **declared initial state**.

Reconstruct lifecycle-sensitive cold / fresh state rather than continuing from incidental mutated state. A diagnosis spot-check is not formal PASS unless it exactly matches the declared initial state and full oracle.

Previously passed unaffected units need not repeat mechanically. Repeat only when the fix changed a shared owner / contract / lifecycle path / premise that makes previous evidence stale.

## Aggregate Linear state

Use existing aggregate workflow:

```text
Plan Pending -> Ready to Run -> Running -> Passed
Ready to Run -> Deferred -> Running -> Passed
Running -> Failed
```

While only some units pass, keep `Running` while active, `Deferred` when intentionally paused, or `Failed` while a confirmed failure remains.

## Standard flow

```text
acceptance
  ↓
can automated test / deterministic script prove it without production host?
  YES -> automate / script; no Manual E2E
  NO
  ↓
Manual E2E plan
  ↓
Judgment: Objective / Human
  ↓
Human judgment -> Human
Objective -> proven Luna capability?
              YES -> Luna
              NO  -> Human / Luna capability
  ↓
implementation / automated verification / review / merge
  ↓
manual_e2e_only + Ready to Run
  ↓
execute units
  ↓
FAIL?
  YES -> classify failure -> focused latest-main re-audit
         -> Ready + unblocked -> FREE main/sub -> Luna fix -> merge -> rerun
         -> Pending / Blocked -> Backlog until resolved
  NO
  ↓
all required units PASS
  ↓
Manual E2E: Passed
  ↓
Done-before Ready contract freshness check
  ↓
Done
```

## Loading rule

Read this document whenever planning, classifying, executing, retrying, or handling results for Manual E2E.

For VS Code production-host environment setup also read `VS-CODE-E2E.md`. For Luna prompt / capability / evidence work read shared prompt style + `LUNA-E2E-PLAYBOOK.md`. For implementation fixes, return to normal implementation authorities rather than using the E2E operator role.
