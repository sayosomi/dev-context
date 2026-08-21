# nuinuiCAD Manual E2E execution rules

## Purpose

Manual E2E in nuinuiCAD means verification that requires an actual nuinuiCAD execution environment that web ChatGPT cannot operate directly.

It does **not** mean that every check must be performed by a human.

Manual E2E test units are classified by both judgment type and executor:

- `Judgment: Objective` — PASS / FAIL can be decided from a fully specified observable result without tester discretion.
- `Judgment: Human` — PASS / FAIL intentionally depends on human visual, UX, design, or experiential judgment.
- `Executor: Luna` — the unit is objective and Codex Luna xhigh can perform the required local operation, observation, and evidence capture reliably.
- `Executor: Human` — the unit requires human judgment, or Luna cannot reliably execute / observe the required behavior.

The Linear `Manual E2E` label remains the aggregate state for the whole Issue. Do not create separate Linear labels for Luna / Human execution.

## When Manual E2E is required

Manual E2E is `Required` only when at least one acceptance condition cannot be sufficiently verified by automated tests without operating an actual production execution environment.

Use this decision order:

1. Does acceptance intentionally require human visual / UX / design / experiential judgment?
   - YES → Manual E2E Required.
2. Does acceptance depend on behavior that can only be verified reliably in an actual production host / execution environment, such as host wiring, lifecycle, focus, selection, window/session behavior, or another host-only boundary?
   - YES → Manual E2E Required.
3. Otherwise, can automated tests sufficiently prove all required acceptance against the authoritative production semantics / boundaries?
   - YES → `Manual E2E: Not Required`.

A Task is not Manual-E2E-required merely because it is user-facing, visual, UI-related, or implemented in a production host. If automated verification sufficiently proves the acceptance, do not add a manual check that only duplicates the same oracle.

Luna / Human executor capability does **not** decide whether Manual E2E is required. First decide whether an actual execution-environment check is needed; only then classify its units and executors.

## Timing relative to merge

Required Manual E2E is performed **after merge by default**.

Normal order:

```text
implementation
-> automated verification
-> blocking review
-> merge
-> required Manual E2E
-> PASS
-> Done
```

Pre-merge Manual E2E is an exception and must be stated explicitly in the Task contract. Use it only when merging the unverified behavior creates unusual risk, or when the acceptance contract itself requires the production-host observation before merge.

A post-merge Manual E2E `FAIL` returns the same Issue to its normal fix / review / merge / rerun loop. Do not redefine the default flow as pre-merge simply to avoid post-merge fixes.

## Plan-time classification

When a Manual E2E plan is created, classify each test unit before the Issue is considered `Manual E2E: Ready to Run`.

Each unit should state, at minimum:

- initial state / fixture;
- action;
- expected observation;
- evidence to record;
- `Judgment: Objective | Human`;
- `Executor: Luna | Human`;
- for `Executor: Human`, the reason when useful: `human judgment` or `Luna capability`.

Do not classify at whole-Issue granularity when the Issue contains mixed checks. One Issue may contain both Luna-executable and Human-required units.

### Objective judgment

A test unit is `Judgment: Objective` only when all of the following are true:

- the expected result can be written before execution as a concrete observable condition;
- the observed result can be compared against that condition without subjective interpretation;
- the tester does not need to invent missing product / UX semantics;
- the same initial state and action should lead to the same PASS / FAIL conclusion;
- useful evidence can be recorded after execution.

Typical objective checks include:

- a specified command, menu item, completion candidate, diagnostic, element, or state is present or absent;
- a keyboard action produces a specified source, selection, caret, document, or Canvas state change;
- Undo / redo produces a specified state;
- an exact label, message, value, or source text is shown;
- a popup or element satisfies an explicitly specified geometric condition such as remaining inside the viewport.

A test is not Human-only merely because the result is visual or must be observed in the UI.

### Human judgment

Use `Judgment: Human` when the test intentionally asks whether the result has qualities that cannot be reduced to the stated contract without losing meaning.

This includes checks such as:

- visual or layout discomfort / `違和感`;
- whether spacing, hierarchy, typography, color, iconography, or balance looks appropriate;
- whether a UI feels crowded, natural, confusing, polished, or easy to understand;
- whether an interaction feels awkward or natural;
- whether the overall Canvas / Editor result looks wrong despite satisfying known binary conditions;
- other design or experiential judgments where a human should notice problems not exhaustively described in advance.

Human judgment is an intentional quality gate, not an automation gap.

**Human judgment is not a fallback for an incomplete oracle.**

If multiple reasonable expected outcomes remain because product semantics / acceptance are not settled, the unit is not Ready. Resolve the implementation contract or test plan first. Do not hand an underspecified question to the user as `Judgment: Human` merely because the oracle is ambiguous.

## Executor selection

Apply these rules after judgment classification:

```text
Judgment: Human
=> Executor: Human

Judgment: Objective
+ no known Luna capability / evidence blocker
+ reliable execution is reasonably expected
=> Executor: Luna

Judgment: Objective
+ known required Luna capability is missing or unreliable
=> Executor: Human
   Reason: Luna capability
```

For Objective units, prefer Luna unless a known operation / observation / evidence limitation already makes reliable execution unlikely. Do not route objective work to the user merely because Luna success is not guaranteed in advance.

Do not weaken or rewrite a Human judgment oracle merely to make a unit Luna-executable.

For example, do not replace "the popup has no visual discomfort" with "the popup stays inside the viewport" unless the contract itself defines viewport containment as the required behavior. Those are different checks.

A mixed unit may be split into objective and Human parts only when doing so preserves the original acceptance meaning. The Human part must remain Human.

## Execution-time classification freshness check

Plan-time classification is provisional until execution.

Immediately before generating a Luna prompt or presenting Human test instructions, Sol High must re-check:

1. the latest nuinuiCAD Project Context;
2. the current Issue contract and Manual E2E plan;
3. the latest intended remote repository state / tested commit;
4. whether the initial state, fixture, actions, and expected observations are still valid;
5. whether Luna can still perform and observe each `Executor: Luna` unit reliably;
6. whether any Human-judgment unit has accidentally been moved into agent execution.

This is a freshness check, not a new product-design phase.

Safe reclassification rules:

- `Luna -> Human` is allowed when an actual Luna operation / observation / evidence capability limitation is established.
- bounded environment or prompt/instruction problems should be corrected and retried when clearly fixable; they are not automatically a reason to assign Human execution.
- `Human -> Luna` is allowed automatically only when `Judgment: Objective` and the previous Human assignment existed solely because of Luna capability.
- `Judgment: Human` must not be converted to Luna execution merely for efficiency. Changing that judgment contract requires an explicit product / test-plan decision, not a prompt-generation shortcut.
- newly discovered ambiguity in the product oracle is not a Luna-capability reclassification; return the contract / test plan to a non-Ready state and resolve the missing semantics.

Repeated Luna capability boundaries should be recorded in [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md) and reused in future plan-time classification rather than rediscovered every Issue.

## Sol High -> Luna prompt generation

Sol High owns Manual E2E classification and Luna prompt construction. Luna is the test operator, not the test designer.

Generate a Luna prompt only after the execution-time freshness check passes.

The prompt must contain only the information needed to execute the selected objective units:

- repository / checkout identity and expected remote branch or commit;
- required remote-state verification before testing;
- the exact isolated launch / environment setup required by the current Manual E2E plan;
- task-specific fixture and initial editor / application state;
- the exact Luna-assigned test units;
- for each unit: action, expected observation, required evidence, and whether a failure invalidates later units;
- explicit blocking conditions for stale remote state, unsafe checkout state, missing environment capability, or ambiguous instructions;
- the required result format.

The prompt must explicitly keep Luna within the execution role:

- do not change implementation code;
- do not fix a failure;
- do not redesign or expand the test plan;
- do not invent missing expected behavior;
- do not make product, UX, aesthetic, or design judgments;
- do not perform Human-assigned units;
- do not do unrelated cleanup or investigation.

Do not ask Luna to investigate architecture or choose a different implementation / test design. Sol High must resolve those questions first.

Human-only units should remain outside the executable Luna test instructions. It is acceptable to identify excluded unit IDs so the boundary is explicit, but do not ask Luna to evaluate them.

## Luna execution contract

For Luna-assigned units, Luna should only:

```text
operate
-> observe
-> compare with the predeclared oracle
-> record evidence
```

Per unit, the result should be one of:

- `PASS` — the expected observable condition was verified with sufficient evidence;
- `FAIL` — the observed result objectively differs from the expected condition;
- `BLOCKED` — the test cannot be executed reliably because the required environment, remote state, initial state, operation, observation, or oracle is unavailable / ambiguous.

For `FAIL`, record the expected result, observed result, reproduction steps, and concise evidence.

For `BLOCKED`, report the blocking condition and do not guess.

A Luna `BLOCKED` result does not imply product failure.

- environment / launch / instruction problem that is clearly bounded and fixable → correct it and rerun the affected unit;
- actual Luna operation / observation / evidence capability boundary → reclassify to `Judgment: Objective / Executor: Human`;
- missing or ambiguous product oracle → do not reclassify as Human judgment; resolve the contract / test plan first.

Screenshots may be evidence for objective UI state, but a screenshot is not permission to make an aesthetic or experiential judgment.

If a failed unit invalidates later units, stop as specified by the plan. Otherwise continue independent units so one failure does not hide unrelated evidence.

Luna must not modify repository files or repair the product during Manual E2E execution.

## Result handling by Sol High

Sol High reviews Luna results and evidence before treating Luna-assigned units as complete.

A Luna `PASS` is accepted only when the evidence actually supports the predeclared objective oracle. Luna commentary such as "looks correct" is not sufficient evidence by itself.

A Luna `FAIL` does not authorize Luna to fix the implementation. Return the result to the normal nuinuiCAD execution flow:

- implementation failure within the same Issue and ChatGPT-executable scope: follow the existing `manual_e2e_only -> only_chatgpt` failure loop;
- test-environment or instruction problem: correct the setup / plan and rerun without treating it as an implementation failure;
- newly exposed product / UX decision: stop autonomous implementation and return the contract to the appropriate non-Ready state.

Human-assigned units are performed by the user. A Human failure is returned to Sol High for the same implementation-vs-product-decision classification; Luna does not decide the design outcome.

For mixed Manual E2E, prefer running Luna-assigned objective units before asking the user to perform Human judgment units when dependencies allow. This avoids spending human review effort on an implementation that already fails objective checks.

`Manual E2E: Passed` is set only after **all required test units**, both Luna-executed and Human-executed, have passed.

While only some units have passed, keep the aggregate Linear state consistent with the existing workflow (`Running` while actively testing, `Deferred` when intentionally paused, `Failed` when a confirmed failure remains).

## Standard flow

```text
Manual E2E requirement / plan decided
        ↓
classify each required test unit
  Judgment: Objective / Human
  Executor: Luna / Human
        ↓
implementation / automated verification / review / merge
        ↓
manual_e2e_only
Manual E2E: Ready to Run
        ↓
Sol High execution-time freshness check
        ↓
Luna units ──→ Sol High generates Luna prompt
                 ↓
               Luna executes + records evidence
                 ↓
               Sol High validates result

Human units ─→ user performs assigned checks
                 ↓
               result returned to Sol High
        ↓
all required units PASS
        ↓
Manual E2E: Passed
        ↓
Done-before Ready contract freshness check
        ↓
Done
```
