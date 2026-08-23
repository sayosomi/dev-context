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

## Plan-time classification

Before `Manual E2E: Ready to Run`, each unit states:

- initial state / fixture;
- action;
- expected observation;
- evidence;
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
3. intended remote repository state / tested commit;
4. initial state / fixture / actions / expected observations;
5. whether proposed Luna units still require production-host action rather than deterministic MCP/script verification;
6. whether the required Luna operation / observation / evidence family remains in the proven baseline without material drift;
7. whether Human judgment has accidentally moved into agent execution.

Safe reclassification:

- Luna unit becomes MCP/script-only → remove from Manual E2E and automate / script;
- `Luna -> Human` when capability / evidence reliability is not sufficient;
- bounded environment / prompt issue with a proven primitive → correct and retry when reasonable;
- `Human -> Luna` only when `Judgment: Objective` and Human assignment existed solely because of Luna capability;
- `Judgment: Human` never becomes Luna solely for efficiency;
- ambiguous product oracle returns contract / plan to non-Ready.

Repeated capability boundaries belong in [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md).

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
- `BLOCKED` — environment / initial state / operation / observation / evidence / oracle prevents reliable execution.

A Luna `BLOCKED` is not product failure.

- bounded environment / instruction issue on a proven primitive → correct and retry when reasonable;
- actual capability / evidence limitation → reclassify Objective unit to Human;
- ambiguous oracle → resolve contract, not Human-judgment fallback.

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

1. identify the concrete failure class and semantic owner;
2. determine Same Issue vs independent new leaf using [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md);
3. determine smallest natural fix slice / safe checkpoint using [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md);
4. classify that fix slice independently under [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md):
   - direct GitHub + CI suitable → `only_chatgpt` fix slice;
   - integration-heavy / local iteration better → standard Coding Agent slice;
5. implement / verify / review / merge;
6. when only required Manual E2E remains again, return to `manual_e2e_only + In Review`.

Do not automatically perform `manual_e2e_only -> only_chatgpt` merely because ChatGPT can technically edit the failure.

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
  YES -> classify failure -> decompose fix -> only_chatgpt or Coding Agent -> merge -> rerun
  NO
  ↓
all required units PASS
  ↓
Manual E2E: Passed
  ↓
Done-before Ready freshness check
  ↓
Done
```

## Loading rule

Read this document whenever planning, classifying, executing, retrying, or handling results for Manual E2E.

For VS Code production-host environment setup also read `VS-CODE-E2E.md`. For Luna prompt / capability / evidence work read shared prompt style + `LUNA-E2E-PLAYBOOK.md`. For implementation fixes, return to normal implementation authorities rather than using the E2E operator role.
