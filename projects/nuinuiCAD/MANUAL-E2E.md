# nuinuiCAD Manual E2E execution rules

## Purpose

Manual E2E in nuinuiCAD means verification that requires an actual nuinuiCAD execution environment that web ChatGPT cannot operate directly.

Current Manual E2E execution policy is **Human only**. Every Manual E2E unit is operated by the Human in the production host. ChatGPT / Sol High owns plan construction, oracle definition, freshness review, result classification, and routing.

Each Manual E2E unit is classified by judgment only:

- `Judgment: Objective` — PASS / FAIL follows a predeclared observable oracle without tester discretion.
- `Judgment: Human` — PASS / FAIL intentionally depends on Human visual / UX / design / experiential judgment.

`Judgment` does not select a different executor. Both kinds are executed by Human under current policy.

The Linear `Manual E2E` label is aggregate state for the Issue. Do not create separate executor labels.

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

The current implementation is not the product-contract owner. If implementation and normative contract disagree, do not weaken or rewrite the E2E oracle to match the implementation. Treat the discrepancy as an implementation defect or contract mismatch and resolve it through the normal contract / implementation path.

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
- exact user-facing label, message, result, transformation, or output shape when objectively derivable;
- native-host boundaries such as Undo / Redo transactions, QuickPick, focus, and session behavior;
- whether deterministic semantics are already sufficiently proven by automated tests and should therefore not be duplicated as Manual E2E units.

The current Manual E2E plan must connect each unit's fixture, action, oracle, and evidence to this actual production owner / path.

### Concrete drift examples

The following SAY-224 examples describe the reverse-map failure mode; they are methodology examples, not SAY-224-specific permanent product requirements:

- **Qualified / scoped rewrite:** when automated or current-implementation evidence objectively establishes a concrete result such as `@Outer::A -> @Other::B`, the Human oracle must name and check that concrete expected rewrite. A generic instruction such as “resolves correctly” leaves the tester to invent qualification semantics.
- **Stale QuickPick guard:** when the implementation's stale path depends on a pending QuickPick observing a document-version or text change, the action must actually exercise that pending-QuickPick path and observe its specific stale result. An instruction that merely says “change Source while QuickPick is open” is insufficient if normal GUI focus behavior can dismiss the QuickPick before the guard is reached.

### Tested-ref drift after mapping

After an implementation-backed mapping has been established, a tested-ref change caused by a fix merge or other relevant implementation update makes affected owner / path mappings stale until they are re-audited. Sol High must fresh-read the affected production owner / path and revalidate affected units' fixture, action, oracle, and evidence mapping. Do not mechanically redesign unaffected units.

If the tested ref changes but the relevant owners and paths do not drift, revalidate that the existing mapping remains valid; a full plan redesign is not required solely because commit identity changed.

Issue #92 remains the owner of FAIL-time runtime control and Human stop / pause precedence.

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

Immediately before Human instructions, Sol High re-checks:

1. latest Project Context;
2. current Issue contract / Manual E2E plan;
3. intended remote repository state / tested commit and whether tested ref or relevant implementation owners / paths have drifted;
4. initial state / fixture / actions / expected observations and each unit's implementation-backed mapping;
5. whether each planned unit still exercises the current tested implementation's actual production path and can observe the contract-defined oracle;
6. whether any planned unit has become deterministic MCP/script-only work that should leave Manual E2E;
7. whether a `Judgment: Human` quality gate has accidentally been reduced to an incomplete objective oracle;
8. whether any selected `E2E Stabilization Key` is currently gated and, if so, whether every re-entry requirement below has been explicitly satisfied.

When implementation-backed mapping was completed at `Ready to Run` time and tested ref and relevant owners / paths have not drifted, this check only needs to prove that the mapping remains valid; it does not require a full plan redesign.

Safe changes:

- host-independent deterministic unit → remove from Manual E2E and automate / script;
- bounded environment / instruction issue → correct when reasonable without changing product oracle;
- ambiguous product oracle → return contract / plan to non-Ready.

## Meaning of start for In Review Manual E2E

When the user asks to start, restart, or resume an `In Review` Issue whose current execution track is Manual E2E, do not stop after re-audit, classification, or Linear state transition.

`Start` is complete only when Human has an immediately actionable first handoff in the same response, unless a concrete blocker prevents execution.

Before that handoff:

1. re-audit current Issue / Manual E2E plan;
2. perform the execution-time freshness check, including stabilization-gate/re-entry state for every affected key;
3. when local execution is required, fix semantic Issue / tested ref / fixture / locale / port inputs and use the canonical same-terminal startup generator in [`CHECKOUTS.md`](./CHECKOUTS.md);
4. move Manual E2E to `Running` only when execution is actually beginning;
5. provide the first executable handoff immediately.

A gated key is not eligible for startup merely because a Human-test lane is `FREE`, a new tested SHA exists, or a narrow fix merged. Do not create the next generation for that key until the re-entry requirements are complete.

For normal startup:

- provide one named `nuinui e2e-start-command` invocation with semantic values fixed and `--executor human` as the current compatibility metadata;
- Human executes the emitted continuation verbatim; do not ask Human to substitute commit SHAs, checkout paths, fixture source, ports, or positional argument order;
- the generator must not choose tested ref, test oracle, stabilization eligibility, or ambiguous Human-test lane, and it must not create a checkout or run GUI actions;
- if generation is `BLOCKED` because state is ambiguous, stale, dirty, malformed, or helper is unavailable, use exceptional read-only checkout/preflight and diagnosis paths in [`CHECKOUTS.md`](./CHECKOUTS.md), without turning output into a normal paste/reconstruction round-trip.

Do not report an `In Review` Manual E2E Issue as newly started while the Human still has to ask separately for the first command.

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

### Implementation failure decomposition

For confirmed implementation failure when the stabilization gate has not fired, or after a gated key has completed the mandatory stabilization re-audit and has an executable consolidated repair scope:

1. before returning Work to implementation queue, perform focused contract re-audit against latest Project Context, current Issue record, and latest remote `main`; use [`CONTRACT-REAUDIT.md`](./CONTRACT-REAUDIT.md) and do not treat prior `Contract: Ready` or failed tested commit as current implementation authority;
2. identify concrete failure class and semantic owner;
3. determine Same Issue vs independent new leaf using [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md);
4. determine smallest natural fix slice / safe checkpoint using [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md); for a gated key this slicing must stay within the consolidated whole-chain repair scope rather than reverting to symptom-only patches;
5. synchronize re-audit result before implementation resumes:
   - current authority uniquely determines fix contract / acceptance → `Contract: Ready`;
   - a real product / UX / scope / compatibility decision remains → `Contract: Pending`;
   - a prerequisite prevents executable contract → `Contract: Blocked`;
   - keep `Manual E2E: Failed` as failure evidence until later rerun passes;
6. only `Contract: Ready` + unblocked Work returns to normal implementation execution under [`CHECKOUTS.md`](./CHECKOUTS.md) and [`CODING-AGENT.md`](./CODING-AGENT.md):
   - select a `FREE` manifest-declared implementation lane;
   - freeze fix Base checkpoint SHA and record implementation checkpoint;
   - implementation / blocking-fix Coding Agent performs repository implementation, verification, and Git work;
   - never implement or repair product from a Human-test checkout;
7. implement / verify / review / merge;
8. when only required Manual E2E remains again, return to `manual_e2e_only + In Review` only if any applicable stabilization re-entry requirements are already satisfied.

Do not create a direct web-ChatGPT implementation route for an E2E failure. ChatGPT owns failure classification, focused or stabilization re-audit, fix contract, slicing, lane assignment, blocking review, and management; the implementation Coding Agent owns repository implementation/fix execution.

Multiple independent failure classes may become separate leaf Issues or sequential slices when natural. Do not create a new Issue mechanically for every Human comment or micro-fix.

`Manual E2E: Passed` is set only after all required units pass.

## Rerun after implementation fix

Rerun each affected unit from its **declared initial state**.

Reconstruct lifecycle-sensitive cold / fresh state rather than continuing from incidental mutated state. A diagnosis spot-check is not formal PASS unless it exactly matches declared initial state and full oracle.

Previously passed unaffected units need not repeat mechanically. Repeat only when fix changed a shared owner / contract / lifecycle path / premise that makes previous evidence stale.

Before rerunning an affected stabilization key, prove that it is either ungated with its normal first-failure rerun allowance, or that every re-entry requirement above has been completed. A merged fix alone is not re-entry evidence.

## Aggregate Linear state

Use existing aggregate workflow:

```text
Plan Pending -> Ready to Run -> Running -> Passed
Ready to Run -> Deferred -> Running -> Passed
Running -> Failed
```

While only some units pass, keep `Running` while active, `Deferred` when intentionally paused, or `Failed` while a confirmed failure remains. A stabilization gate does not redefine `Failed`; it restricts the next execution route for its key.

## Standard flow

```text
acceptance
  ↓
can automated test / deterministic script prove it without production host?
  YES -> automate / script; no Manual E2E
  NO
  ↓
Manual E2E plan
  -> Judgment: Objective / Human
  -> stable E2E Stabilization Key where applicable
  ↓
Human executes production-host unit
  ↓
implementation / automated verification / review / merge
  ↓
manual_e2e_only + Ready to Run
  ↓
startup freshness + stabilization eligibility check
  ↓
execute units
  ↓
unit FAIL candidate?
  YES -> common runtime control:
         stop dependent units; continue independent units
         unless Human explicitly stops / pauses
         -> collect available evidence
  ↓
runnable units complete or Human stops / pauses
  ↓
aggregate PASS / FAIL candidate / BLOCKED evidence
  ↓
FAIL candidate present?
  YES -> mandatory Human actual-host focused triage
         -> fixture / setup / environment / instruction / host-state problem:
            correct setup / plan -> rerun necessary units; no streak increment
         -> ambiguous oracle / new product decision: Contract / plan non-Ready; no streak increment
         -> confirmed qualifying failure:
            classify same-key history
            -> first pre-stabilization qualifying failure:
               focused latest-main re-audit -> fix -> merge -> one rerun allowed
            -> second pre-stabilization qualifying failure OR post-stabilization recurrence
               OR explicit Human stabilization override:
               stabilization gate -> preserve evidence -> canonical current-generation closure
               -> mandatory cross-owner full re-audit
               -> no symptom-only implementation restart
               -> re-entry requirements before another same-key Human generation
         -> Human stops / pauses before triage completes:
            record incomplete / not performed -> no inferred product FAIL
  NO
  ↓
all required units PASS
  -> reset ordinary pre-stabilization streak for passed key
  ↓
Manual E2E: Passed
  ↓
Done-before Ready contract freshness check
  ↓
Done
```

## Loading rule

Read this document whenever planning, classifying, executing, retrying, or handling results for Manual E2E.

For VS Code production-host environment setup also read `VS-CODE-E2E.md`. `LUNA-E2E-PLAYBOOK.md` is inactive historical reactivation reference and is not loaded or used during normal Manual E2E. For implementation fixes, return to normal implementation authorities rather than using the E2E operator role.