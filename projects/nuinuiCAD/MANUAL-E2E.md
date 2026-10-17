# nuinuiCAD Manual E2E execution rules

## Purpose

Manual E2E in nuinuiCAD means verification that requires an actual nuinuiCAD execution environment that web ChatGPT cannot operate directly.

Current Manual E2E execution policy is **Human only**. Every Manual E2E unit is operated by the Human in the production host. ChatGPT / Sol High owns plan construction, oracle definition, freshness review, result classification, and routing.

Each Manual E2E unit is classified by judgment only:

- `Judgment: Objective` — PASS / FAIL follows a predeclared observable oracle without tester discretion.
- `Judgment: Human` — PASS / FAIL intentionally depends on Human visual / UX / design / experiential judgment.

`Judgment` does not select a different executor. Both kinds are executed by Human under current policy.

Canonical GitHub Issue comments own Manual E2E plans, results and operational evidence under [ISSUES.md](./ISSUES.md). Only compatible already-admitted SAY generations retain applicable Linear bookkeeping.

## When Manual E2E is required

Manual E2E is `Required` only when at least one acceptance condition cannot be sufficiently verified by automated tests without operating an actual production execution environment.

Decision order:

1. acceptance intentionally requires Human visual / UX / design / experiential judgment → Manual E2E Required;
2. acceptance depends on production-host / session behavior that automated tests cannot sufficiently prove, such as host wiring, lifecycle, focus, selection, window/session state, or another host-only boundary → Manual E2E Required;
3. otherwise, if automated verification sufficiently proves acceptance → `Manual E2E: Not Required`.

A Task is not Manual-E2E-required merely because it is UI-related, visual, user-facing, or implemented in a production host.

## Deterministic MCP / script verification is not Manual E2E

Do not spend Human production-host time on a check that can be fully executed and judged by deterministic repository-owned MCP calls or equivalent local scripts without operating a production host / UI / session.

Examples include frozen-fixture calls to `document_inspect`, `document_evaluate`, `document_definition`, or `document_references` with structured-result comparison.

For these checks:

- prefer automated CI tests when the same boundary is reliable there;
- otherwise use deterministic terminal / script verification as supporting evidence;
- split MCP-only semantics from genuine host-only actions when acceptance meaning is preserved;
- avoid duplicate semantic oracles unless cross-boundary agreement is itself acceptance.

Client/MCP path itself remains part of acceptance only when the Task explicitly tests that boundary, such as MCP registration / startup / interoperability or attached production-host observation.

Native E2E admission, dogfood snapshot/hash validation, signed VS Code validation, host readiness, and fixture/self-test success are preparation or automated evidence. None of them is a Human Manual E2E execution or PASS; only the Human operates and judges the declared product action in the actual host.

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

A post-merge confirmed product FAIL normally returns the Work to implementation decomposition / fix / review / merge / rerun flow. The repeated-failure stabilization gate below overrides that normal narrow-fix route when its threshold or Human override fires. Do not make pre-merge E2E the default merely to avoid post-merge fixes.

## Post-merge implementation-backed reverse-map re-audit

Before required post-merge Human E2E, verify the latest tested SHA and map each affected unit to its **actual current production path**. The Issue/normative product contract defines behavior; the implementation identifies entrypoint, host lifecycle/state transition and observable branch; the E2E plan supplies fixture, action, concrete expected observation and evidence. Never weaken the product oracle to match a defect.

Follow relevant owners, guards and error paths, not the entire source tree. Host-independent deterministic checks belong in automation. A stale QuickPick test must actually reach its pending-QuickPick guard; an objective rewrite oracle must specify the concrete expected output, not merely “works correctly”.

When the tested ref changes, revalidate affected owner/path mappings. Unaffected units do not need a full redesign merely because the SHA changed.

## Plan-time classification

Before `Manual E2E: Ready to Run`, each unit states:

- initial state / fixture;
- action;
- expected observation;
- evidence;
- for required post-merge Manual E2E, the current tested implementation owner / production-path mapping, including the relevant state transition or failure branch;
- `Judgment: Objective | Human`;
- when the unit belongs to an interaction workflow covered by repeated-failure handling, its stable `E2E Stabilization Key`.

Do not classify only at whole-Issue granularity when units differ.

Before retaining Objective work as Manual E2E, remove deterministic MCP / script-only checks that do not require the production host.

An `E2E Stabilization Key` identifies the stable user-facing interaction model being validated, for example `creation-assist/reference-pick`. It is not a source file, implementation owner, branch, tested SHA, individual fix, or transient execution generation. A normal fix, refactor, owner move, or tested-ref change does not reset or rename the key. Changing the key requires a material interaction-contract change and must be explicit in the current contract / Manual E2E plan; never infer a new key from code movement.

Stabilization history is preserved in the Issue / Manual E2E plan and result evidence. Do not create a second helper/runtime state machine or infer failure history from checkout metadata.

## Test-unit boundaries

A unit's initial state is part of its oracle.

Split materially distinct lifecycle paths when starting state changes the production path, for example cold vs already-open surface / session. Do not build a mechanical Cartesian product of every possible state.

When one scenario contains independently judgeable Objective observations and Human visual / UX judgment, split them by default. Keep together only when separation changes acceptance meaning.

Units may share setup without sharing judgment classification.

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
- Undo / Redo produces specified state;
- exact label / message / value / source text appears;
- explicit geometric condition such as viewport containment holds.

Visual observation alone does not make a unit Human judgment.

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

The Human operates the production GUI directly with mouse / keyboard, performs the required live objective observation or visual / interaction judgment, and may submit screenshots as evidence or diagnostic context.

Use screenshot evidence efficiently:

- when multiple cases are simultaneously observable in one frame, compose the fixture / viewport so one screenshot covers them together rather than requesting one screenshot per case;
- do not split otherwise equivalent cases into separate units or screenshots only to increase evidence count;
- split when a different initial state, lifecycle path, dynamic interaction, mutation / revert boundary, or other materially different execution path makes one-frame judgment unreliable;
- a static screenshot does not replace a live interaction oracle. For stepping, focus, drag, stale-state cleanup, or transition quality, Human live observation plus a concise result report is sufficient when persistent visual evidence is not required;
- request additional screenshots when failure, ambiguity, or diagnosis benefits from them rather than mechanically on every normal path.

For `Judgment: Human`, Human PASS / FAIL remains the final quality judgment. ChatGPT may inspect submitted screenshots to confirm objective visible facts, summarize evidence, and help diagnose anomalies, but must not silently replace required Human aesthetic / experiential judgment.

## Common runtime control after a unit result

Human explicit stop / pause / abort / discontinue instructions have the highest priority:

- stop requesting or initiating further E2E operations, even when independent units remain executable;
- retain and summarize evidence already collected;
- record remaining units as unexecuted where relevant, without inferring PASS or FAIL;
- treat the instruction as execution control, not as product `FAIL` or `BLOCKED`.

When no Human stop / pause instruction exists, a product `FAIL` candidate is not a whole-run abort. For each remaining unit, inspect whether the failed unit invalidates its declared initial state, required fixture, production lifecycle path, action feasibility, expected observation / oracle, or evidence meaning. Stop only invalidated dependent units. Continue independent remaining units against the same tested ref and collect available `PASS` / `FAIL` / `BLOCKED` evidence.

Do not begin implementation-failure decomposition immediately when safely executable independent units remain. After runnable independent units are complete, or execution has stopped by explicit Human instruction, aggregate evidence and apply the result-handling rules below.

## Execution-time freshness check

Immediately before Human instructions, verify current Issue plan, tested SHA, valid fixture/action/oracle and affected implementation-backed paths, plus same-key stabilization and re-entry eligibility. If relevant owners/paths did not drift, the prior mapping remains valid; do not repeat a full redesign.

Remove host-independent deterministic checks. Return ambiguous product oracles for contract clarification. Preserve intentional Human UX/visual judgment.

## Native GitHub Issue start and resume

Starting or resuming required E2E means reaching an actionable Human handoff, not creating an E2E-specific chat or only changing state. First verify current Issue plan, tested SHA, reverse map, stabilization eligibility and exact checkout ownership.

For native Issues [CHECKOUTS.md](./CHECKOUTS.md) and [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) own `nuinui-e2e --production` admission/start/closure; [VS-CODE-E2E.md](./VS-CODE-E2E.md) owns VS Code host setup. Only the Human operates and judges GUI units. Record plan, start, observations, results and exact closure under [ISSUES.md](./ISSUES.md#native-github-manual-e2e-checkpoints); host readiness never means product PASS.

Do not use `nuinui e2e-start-command`, `nuinui-e2e-prepare`, SAY/Linear state or a legacy implementation-release gate for new native Issues. Exact compatible already-admitted SAY recovery remains reachable through CHECKOUTS / LOCAL-TOOLS legacy references.

## Result handling by Sol High

A unit-level observed mismatch is a `FAIL` candidate for classification, not yet a confirmed product failure. Do not set Manual E2E to product `FAIL` or begin implementation-failure decomposition from an observation alone.

### Mandatory Human actual-host triage gate for FAIL candidates

After safely executable independent units have finished, or after execution has stopped by explicit Human instruction, aggregate available evidence under [common runtime control](#common-runtime-control-after-a-unit-result). If the aggregate contains a `FAIL` candidate and no explicit stop / pause interrupted before triage completes, Human must complete focused triage before any final Manual E2E product `FAIL` classification.

Before cleanup, release, close, revert, or teardown would destroy the current failure state, preserve production host / session / fixture long enough to collect and record transient evidence needed to classify that failure. Sol High determines the focused evidence set from current production path and observed failure class; do not make Human mechanically collect every possible artifact.

Relevant transient evidence may include, when materially discriminating:

- completion / warning / error notifications;
- Output, logs, diagnostics, or other host-owned result surfaces;
- final UI state or screenshot;
- active surface, focus, selection, or session state;
- host / process / session identity needed to prove which runtime handled the action;
- temporary UI or host state that exists only while failure is live.

Do not tear down host/session/fixture until focused evidence capture is complete unless Human explicitly stops or abandons further evidence collection. If environment, safety, host loss, or another concrete blocker makes preservation impossible, record which transient evidence could not be collected and why before necessary teardown.

Human performs triage on current tested ref using actual production host / physical environment and verifies at minimum:

- tested ref / build is intended one;
- declared fixture and initial state are actually established;
- execution uses current production path;
- reproduction steps are reproducible;
- observed behavior reproduces under same conditions;
- setup, environment, host state, instruction, or oracle problems do not explain observation.

Classify only after these checks:

- fixture / setup / environment / instruction / host-state problem → do not confirm product `FAIL`; correct setup / plan and rerun necessary units;
- ambiguous oracle / newly exposed product decision → return Contract / Manual E2E plan to non-Ready; do not confirm product `FAIL`;
- actual behavior on current tested ref and production path, reproducibly disagreeing with contract-defined oracle after test-side explanations are excluded → confirm Manual E2E product `FAIL` and enter repeated-failure classification before choosing an implementation route.

If Human explicitly stops or pauses before triage completes, stop/pause remains highest priority: request no further E2E operation, record triage as incomplete / not performed, and do not infer product `FAIL`.

Triage is limited to failure classification and minimal reproduction evidence collection. It is not implementation debugging. Do not modify product code in Human-test checkout, perform ad-hoc repair, or turn triage into open-ended source investigation.

### Repeated-failure stabilization gate

Repeated-failure handling starts only after the current result is sufficiently classified by the triage rules above. It does not convert setup, environment, stale-plan, instruction, or `BLOCKED` outcomes into product failures.

A `qualifying failure` for an `E2E Stabilization Key` is a completed production-host Manual E2E result that establishes either:

- product behavior `FAIL` against the predeclared oracle; or
- Human UX / visual / experiential rejection for a `Judgment: Human` unit belonging to that same key.

The following do **not** increment the qualifying-failure streak:

- fixture / setup mistake;
- environment or host-launch failure;
- stale or invalid Manual E2E plan;
- operator / tester instruction mistake;
- `BLOCKED` where product behavior was not judged;
- failure belonging to another stabilization key.

For a key that has never completed a stabilization cycle:

```text
1st qualifying failure
-> record streak=1
-> one normal focused re-audit / fix / review / merge / rerun is allowed

2nd qualifying failure
-> record the failure normally
-> stabilization gate fires
-> no 3rd Human E2E generation for that key
```

A `PASS` for that key resets the ordinary pre-stabilization qualifying-failure streak. It does not erase historical evidence or a previously completed stabilization cycle.

Once a key has completed one stabilization cycle and re-entered Manual E2E, any later qualifying failure for that same key fires the stabilization gate immediately. Do not grant another two-failure allowance after re-entry.

Human execution control overrides the numeric threshold. If the Human explicitly says to stop repeating E2E and perform a fundamental / stabilization review, fire the gate immediately for the identified key even on the first qualifying failure or before a second qualifying failure exists. This routing instruction does not itself create or infer an additional product `FAIL`; preserve the actual result classification separately.

The gate is scoped to its stabilization key by default. It does not automatically stop unrelated keys or Issues. A broader Human stop / pause instruction remains authoritative and may suspend a wider queue.

#### Mandatory stabilization re-audit

While the gate is active for a key:

- do not start another Human E2E generation for that key;
- do not treat another narrow symptom patch followed by another Human rerun as the default next action;
- preserve all prior PASS / FAIL / Human judgment evidence and the stable key identity;
- return the affected product / interaction contract to non-Ready when current state or interaction semantics are not sufficiently settled;
- fresh-read the current product contract and latest remote implementation before proposing repair scope;
- re-audit the end-to-end interaction/state transition across all materially relevant owners rather than stopping at the latest visible symptom;
- inspect, where relevant, UI surface/input owner, host adapter, command/session lifecycle, document-version synchronization, selection/context ownership, semantic planner/query owner, production-host reverse map, keyboard/input precedence, and testability;
- keep every product-code fix off Human-test lanes;
- identify Objective observations that should move to automated regression or deterministic production-host qualification before another Human run;
- preserve genuinely Human visual / UX / experiential judgment as Human acceptance rather than weakening the oracle.

Before implementation may restart, the stabilization re-audit record must contain at least:

- confirmed root cause, or if not yet confirmed, the exact unresolved failure boundary;
- adjacent owners inspected;
- why each materially adjacent owner is implicated or ruled out;
- consolidated repair scope across the whole failure chain;
- regression coverage that prevents recurrence of the interaction/state failure chain rather than only the latest visible symptom.

If the material root cause / failure boundary is still unresolved, do not start implementation. Continue investigation and contract/state-model clarification until an executable consolidated repair scope exists.

#### Re-entry requirements

A new Human E2E generation for a gated key is authorized only after all applicable conditions are satisfied:

1. the affected product / interaction contract is again `Ready` under current authority;
2. the mandatory stabilization re-audit record is complete and the consolidated repair scope has been implemented and reviewed;
3. the latest implementation has a fresh production-path / reverse-map audit for the affected units;
4. Objective failures previously found by Human are covered by automated regression or equivalent deterministic host qualification wherever practical;
5. required automated tests / production-host qualification for the exact candidate / tested ref pass before the Human rerun;
6. remaining Manual E2E scope is reduced to genuinely necessary Human judgment and/or host-only observations that cannot be sufficiently automated;
7. the rerun plan explicitly preserves historical evidence and names the same stabilization key.

If an Objective prior failure cannot reasonably be automated, the contract / re-audit must explicitly record why and why another Human host check remains necessary. Do not silently omit that analysis.

Completion of these requirements is an explicit stabilization-cycle re-entry record. That record is durable historical evidence for the key, so a later qualifying recurrence re-fires the gate immediately.

### Implementation failure follow-up

After actual-host triage confirms product failure, classify same-key stabilization history before routing. A gated key must complete the cross-owner re-audit and re-entry rules above; a first ungated qualifying failure permits one normal focused fix/rerun.

Use latest contract and implementation to identify failure class, semantic owner and fix scope. Record current decisions/evidence under [ISSUES.md](./ISSUES.md); consult [CONTRACT-REAUDIT.md](./CONTRACT-REAUDIT.md), [CONTRACT-DECISIONS.md](./CONTRACT-DECISIONS.md) and [IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md) only as relevant. Product changes follow [CODING-AGENT.md](./CODING-AGENT.md), [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md), checkout and PR owners. Never modify product code in the Human-test checkout or create an Issue for every symptom.

Verify, review, merge and rerun affected units; retain prior evidence and stabilization history. All required units must actually PASS before final Passed.

## Rerun after implementation fix

Rerun each affected unit from its **declared initial state**.

Reconstruct lifecycle-sensitive cold / fresh state rather than continuing from incidental mutated state. A diagnosis spot-check is not formal PASS unless it exactly matches declared initial state and full oracle.

Previously passed unaffected units need not repeat mechanically. Repeat only when fix changed a shared owner / contract / lifecycle path / premise that makes previous evidence stale.

Before rerunning an affected stabilization key, prove that it is either ungated with its normal first-failure rerun allowance, or that every re-entry requirement above has been completed. A merged fix alone is not re-entry evidence.


## Result and closure boundary

Human stop/pause overrides further operations. Otherwise finish safely executable independent units, preserve necessary transient failure evidence before teardown, complete focused Human actual-host triage, record PASS/FAIL/BLOCKED and unexecuted units, apply same-key stabilization rules and perform exact-generation closure through existing owners.

## Loading rule

Read this document for Human Manual E2E planning, execution, judgment and result handling. Load [VS-CODE-E2E.md](./VS-CODE-E2E.md) only for VS Code host work. [CHECKOUTS.md](./CHECKOUTS.md), [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) and [ISSUES.md](./ISSUES.md) own their existing native checkout, helper and checkpoint responsibilities. `LUNA-E2E-PLAYBOOK.md` is inactive history.
