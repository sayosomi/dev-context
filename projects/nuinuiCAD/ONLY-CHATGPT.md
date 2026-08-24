# nuinuiCAD execution ownership labels

## Purpose

nuinuiCAD uses two execution-ownership labels for leaf / non-parent Issues:

- `only_chatgpt` — the **current executable implementation slice through its next safe checkpoint** is suitable for direct GitHub + GitHub CI execution by web ChatGPT without Coding Agent or a local nuinuiCAD execution environment.
- `manual_e2e_only` — all implementation / review / merge / management work is complete and the only remaining completion work is required Manual E2E in an actual nuinuiCAD execution environment that web ChatGPT cannot operate directly.

These labels describe the **current execution route**, not product scope, priority, or worker identity. They do not replace Contract, Manual E2E, type, dependency, or status metadata.

`only_chatgpt` does not promise that every future slice of the same Issue will use ChatGPT. Reclassify the next slice at each safe checkpoint. `manual_e2e_only` is different: it is used only when no implementation slice remains at all.

Execution-ownership labels are leaf-only. A retained parent with aggregate acceptance / integrated Manual E2E / final integration work does not receive either label.

Implementation decomposition / sequential PR / execution checkpoint判断は [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) をauthorityとする。Same Issue vs new Issueは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) をauthorityとする。

## Standard implementation route

The normal nuinuiCAD implementation route is the shared development workflow:

```text
ChatGPT
  repository investigation / architecture / implementation contract
-> Implementation Coding Agent
  concrete implementation / tests / git
-> ChatGPT
  blocking review / verification
```

`only_chatgpt` is an additional high-parallelism route for implementation slices whose shape is especially suitable for direct GitHub + CI execution.

Do not ask only whether ChatGPT **can** edit the files remotely. A slice is `only_chatgpt` only when direct GitHub + CI is also a good execution method for that slice.

Absence of `only_chatgpt` does not mean blocked, unready, or manually executed. A Ready implementation Issue without `only_chatgpt` normally uses the standard Implementation Coding Agent route.

## Decomposition-first rule

Do not classify a large Work item as one indivisible execution unit merely because it is represented by one Issue today.

Before deciding that a broad feature / refactor / bug line is unsuitable for `only_chatgpt`, apply [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) and look for natural independently verifiable boundaries such as:

```text
semantic / type foundation
-> host-neutral planner / transformation
-> adapter / protocol / runtime integration
-> host wiring / lifecycle integration
-> interactive UX / production-host acceptance
```

When current repository ownership supports it, actively extract the portions that are good direct GitHub + CI work and route those portions through `only_chatgpt`.

This is not permission to manufacture tiny Issues or artificial PRs. Decompose only when the boundary has real semantic ownership, independent verification, and a safe merge / handoff shape.

A large feature may therefore have a mixed execution shape:

```text
large feature
├─ leaf A: only_chatgpt
├─ leaf B: only_chatgpt
├─ leaf C: standard Coding Agent
└─ aggregate / Manual E2E acceptance
```

Likewise, one Issue may use different execution routes across sequential slices when the Work remains one Issue but implementation boundaries are independently executable.

## `only_chatgpt` eligibility

Apply `only_chatgpt` only to a leaf / non-parent Issue when all of the following are true for the **current executable slice through the next safe checkpoint**:

1. ChatGPT can perform the required repository / verification / GitHub / work-management work with available connected capabilities and without local-only implementation work.
2. The implementation contract is sufficiently settled that direct execution does not require open-ended product / architecture design during coding.
3. The current slice has a bounded semantic footprint and can be reviewed and verified independently.
4. GitHub-visible source + tests + CI provide a sufficiently effective implementation/debug loop for the expected work.
5. Direct GitHub execution is not predictably inferior to a local Coding Agent because of heavy exploratory editing, broad multi-owner integration, or rapid local test/debug iteration.

Typical good shapes include:

- focused parser / compiler / evaluator semantics with clear tests;
- host-neutral pure logic, planners, transformations, queries, or adapters;
- isolated diagnostics / language behavior;
- narrow refactors with a clear owner and regression boundary;
- focused test / fixture work;
- deterministic CI / tooling / documentation changes;
- small implementation fixes with an already-understood failure class.

Typical signals to prefer the standard Coding Agent route for the current slice include:

- multiple semantic owners must be changed as one tightly coupled unit;
- Extension Host / Webview / process / session / lifecycle composition dominates the work;
- implementation requires broad exploratory repository editing or repeated local test/debug loops;
- several independent failure classes remain entangled in one current implementation shape;
- a large integration refactor cannot reach a safe intermediate merge / handoff boundary;
- subjective UX feedback is likely to cause repeated broad implementation changes rather than a narrow follow-up fix.

These are semantic signals, not hard thresholds. File count, diff lines, commit count, and elapsed time are warnings only.

Do not apply or retain `only_chatgpt` for the current slice when:

- the Issue is a parent / tracking Issue;
- an unresolved product / UX / scope decision blocks implementation;
- the slice depends on local-only work ChatGPT cannot perform;
- a required external manual operation other than final Manual E2E remains before the next safe checkpoint;
- safe completion would require destructive interaction with unrelated user work;
- direct GitHub + CI remains technically possible but the current slice has expanded into a shape better executed by the standard Coding Agent route.

A later slice may still be unsuitable without invalidating the current `only_chatgpt` slice. Record the next route at the checkpoint instead of over-constraining the whole Issue up front.

## Starting and executing

`only_chatgpt` does not auto-start a Todo by itself. The normal explicit-start rule still applies unless a dedicated policy such as [`SCHEDULED-RUNNER.md`](./SCHEDULED-RUNNER.md) grants standing authorization.

Once started, ChatGPT should continue through the current safe slice without asking the user to perform intermediate development work.

When the user asks ChatGPT to choose an `only_chatgpt` Issue rather than naming one, prefer a Ready candidate whose semantic footprint is independently verifiable and has the least concrete interference with active reservations. Do not choose solely by issue number, age, apparent diff size, or local worktree availability.

## Execution-route re-evaluation

`only_chatgpt` suitability is not a one-time label decision.

Re-run implementation slicing and execution-route classification at least when:

- the first broad integration test / full suite reveals substantial remaining work;
- a Task pauses / resumes;
- implementation wants to expand beyond the published Parallel footprint;
- a new semantic owner / API / contract / data-flow boundary is required;
- multiple independent failure classes remain;
- one slice is complete but another owner still has significant acceptance;
- PR / fix loops have become a mixture of unrelated semantic changes;
- remote `main` advance changes the remaining implementation shape;
- Manual E2E exposes an implementation failure.

At each checkpoint, prefer this order:

1. identify whether a completed or newly exposed portion is a real independently verifiable Work / implementation boundary;
2. if it is independent Work, use `CONTRACT-DECISIONS.md` to decide whether to create / reuse a separate leaf Issue;
3. if it remains the same Work, use `IMPLEMENTATION-SLICING.md` to choose Same Issue + same PR or Same Issue + next PR;
4. classify each next executable leaf / slice independently as `only_chatgpt` or standard Coding Agent work.

Do not keep `only_chatgpt` merely because the current Issue started that way. Switching the next slice to Coding Agent is a normal routing decision, not a failure.

Conversely, a broad Work item routed partly through Coding Agent may later expose a clean remaining leaf / slice that is suitable for `only_chatgpt`.

## Parallel execution capacity

Local worktree capacity constrains local Coding Agent / local execution Tasks, not `only_chatgpt`.

`only_chatgpt` does not consume a local worktree slot. There is no fixed numeric concurrency cap; safe parallelism is governed by semantic interference.

Do not defer an otherwise independent `only_chatgpt` leaf merely to preserve local checkout capacity.

## Parallel footprint

Every active `only_chatgpt` implementation Issue must publish a current **Parallel footprint** in Linear before the first repository write for that execution track.

Use:

```text
Parallel footprint
- Base main: <current remote main SHA>
- Writes: <semantic owner / symbol / API / data-flow boundary>
- Shared contracts: <contract or assumption another Task could invalidate, or none>
- Depends on: <Issue / PR / unfinished base, or none>
- Exclusive: <precise owner / contract requiring one active writer, or none>
```

Rules:

- `Writes` names semantic targets; paths alone are insufficient.
- `Shared contracts` records semantics / fixtures / ownership / API assumptions shared with other work.
- `Depends on` records a real implementation dependency, not a temporary scheduling hazard.
- `Exclusive` is a narrow soft lock only where concurrent writers cannot be safely separated or refreshed.
- Same file or subsystem is only a warning; different files can still conflict through one API / semantic owner.
- Update the footprint whenever current implementation scope changes.

## Reservation protocol

For newly started `only_chatgpt` work:

1. inspect latest remote `main`, relevant branches / PRs, and active implementation Issues;
2. inspect active Parallel footprints;
3. derive the candidate footprint from current repository + contract;
4. move the explicitly started Issue to `In Progress` and publish the footprint in the same startup checkpoint;
5. re-read active reservations / relevant PR state;
6. only then perform the first repository write.

If the second read discovers a concrete pre-existing conflict, the new candidate yields. If the hazard is temporary and not a real prerequisite, return it to `Todo`; do not invent a dependency.

If two new conflicting reservations appear concurrently and reliable temporal precedence is unavailable, the lower numeric Linear Issue identifier wins the race. The losing Issue returns to `Todo` before any repository write. This is only a race-resolution rule, not normal priority.

Before writing a new semantic owner outside the footprint, first re-run implementation slicing / route classification, then update the footprint and interference check.

A current-slice reservation ends when that implementation ownership ends. An intermediate merge may release the current slice reservation before the same Issue begins its next slice.

## Interference gate

Parallel work is allowed unless there is a concrete interference path.

Block when any of these applies:

1. unfinished implementation dependency / base;
2. same branch / ref ownership;
3. incompatible writes to the same symbol / API / semantic contract / data-flow owner;
4. overlap with another Task's `Exclusive` reservation;
5. likely Ready-contract invalidation before a safe checkpoint;
6. completion would require unsafe reset / force-update / rewrite of unrelated work.

When the conflict is only temporary, keep the Issue Ready and schedule another independent leaf instead. When inspection reveals a real prerequisite, record it according to the Linear workflow.

Temporary interference is scoped to the conflicting current reservation / slice, not to the lifetime or status of the other Issue. Do not wait for the other Issue to reach `Done` unless a real implementation prerequisite exists. When retrying the deferred Issue, re-read the latest repository state and active footprints; if the concrete interference is gone, execution may start even while the other Issue remains `In Progress`.

For `only_chatgpt` work:

- do not use Coding Agent inside the same current `only_chatgpt` slice;
- do not require a local worktree by default;
- use latest GitHub remote state as implementation authority;
- use direct GitHub operations + GitHub CI as the implementation/debug loop;
- preserve unrelated branches / worktrees / user changes;
- follow ordinary authorization, blocking-review, merge, and freshness rules.

If the slice should move to Coding Agent, end / checkpoint the `only_chatgpt` slice first and hand off the next slice explicitly rather than silently mixing execution owners.

## CI failure fallback

Unavailable GitHub Actions log text is a tooling / evidence limitation, not an automatic blocker.

When required CI fails:

1. establish the exact run, head SHA, failing job / step, and available conclusions;
2. attempt normal log retrieval;
3. if unavailable, inspect workflow command, diff, relevant tests / fixtures / source owners, and artifacts when useful;
4. make only a narrow evidence-backed fix within the current slice contract;
5. use subsequent CI as verification / additional evidence.

Do not make arbitrary speculative patches only to probe CI. Do not ask the user for logs before exhausting web-accessible evidence.

The Issue becomes blocked or loses `only_chatgpt` only when materially necessary evidence / capability is unavailable or the current failure diagnosis expands into a shape that no longer suits direct GitHub + CI execution.

Required CI must still pass or be resolved by its authoritative contract before merge.

### Shared CI incident escalation

When evidence suggests a failure comes from shared `main` state or common CI infrastructure rather than this Issue, load [`CI-INCIDENTS.md`](./CI-INCIDENTS.md).

Signals include the same required job / step failing across unrelated PRs, failure outside the current footprint after `main` advance, or the same signature on latest `main` / another unrelated branch.

Do not load shared-incident policy for ordinary issue-local failures.

## Main-advance checkpoint

Before another write, blocking-review completion, or merge when remote `main` has advanced beyond the published `Base main`, inspect intervening changes by semantic owner / API / contract / data flow.

- no relevant invalidation → update `Base main` and continue;
- fact drift with one uniquely determined implementation path → refresh contract / footprint while retaining `Contract: Ready`;
- concrete conflict → stop writes at the safe checkpoint;
- real prerequisite → record dependency;
- new product / UX / scope decision → return contract to the appropriate non-Ready state;
- remaining implementation shape becomes poorly suited to direct GitHub + CI → checkpoint and route the next slice to Coding Agent.

## `manual_e2e_only`

Apply `manual_e2e_only` only when all implementation / automated verification / blocking review / merge / management work is complete and required Manual E2E is literally the only remaining completion step.

Required conditions:

- required implementation is merged to the intended base;
- automated verification / CI and blocking review are complete;
- no implementation / review / merge / management work remains;
- Contract remains `Ready` against latest remote `main`;
- required Manual E2E plan is executable;
- no unfinished blocker remains;
- the Issue is a leaf / non-parent.

Transition immediately:

```text
remove: only_chatgpt   # if present
add:    manual_e2e_only
state:  In Review
Manual E2E: Ready to Run
```

Executor classification is owned by [`MANUAL-E2E.md`](./MANUAL-E2E.md).

If testing is postponed, keep `manual_e2e_only` with `In Review + Manual E2E: Deferred`.

When testing begins, use `In Review + manual_e2e_only + Manual E2E: Running`.

When all required units pass:

1. set `Manual E2E: Passed`;
2. perform Done-before Ready contract freshness check;
3. move the Issue to `Done`.

## Manual E2E failure

A confirmed product implementation failure ends `manual_e2e_only` because implementation work exists again.

Do **not** automatically restore `only_chatgpt` merely because ChatGPT could technically edit the fix remotely.

First classify the failure and re-run implementation decomposition / route selection:

1. determine whether the failure is implementation, test environment/instruction, Luna capability, or a newly exposed product decision;
2. if implementation, identify the concrete failure class and semantic owner;
3. use `CONTRACT-DECISIONS.md` to decide Same Issue vs independent new leaf;
4. use `IMPLEMENTATION-SLICING.md` to isolate the smallest natural fix slice / checkpoint;
5. classify that fix slice independently as `only_chatgpt` or standard Coding Agent work.

If the resulting fix slice is `only_chatgpt`:

```text
remove: manual_e2e_only
add:    only_chatgpt
state:  In Progress
Manual E2E: Failed
```

Refresh the Parallel footprint and reservation before the first fix write. This is continuation of an already-started Work item and does not require a new explicit start.

If the fix is better executed by Coding Agent, remove `manual_e2e_only`, keep the Issue in the normal active implementation state, create a narrow implementation handoff for the selected fix slice, and do not add `only_chatgpt`.

After the fix is merged and only required Manual E2E remains again, transition back to `manual_e2e_only + In Review`.

Do not treat a test-environment mistake, unsupported Luna operation, or unclear E2E instruction as product implementation failure. Correct the E2E setup / executor classification instead. A new product decision returns the contract to the appropriate non-Ready state.

## Parent / decomposition rule

Do not keep a pure tracking parent by default.

When original scope is decomposed into independently verifiable leaf Issues and all scope / acceptance has been transferred, the original Issue stops acting as an aggregate execution shell.

Retain a parent only when it owns real aggregate work such as integrated Manual E2E, cross-child acceptance, final cutover / migration / integration, or another completion condition that cannot belong to one child.

A retained parent never receives `only_chatgpt` or `manual_e2e_only`.

Decomposition is not performed merely to maximize label count or parallel worker count. However, when a large Work item contains real independently verifiable semantic boundaries, actively consider extracting the direct-GitHub-friendly leaves instead of forcing the entire feature through one execution route.

## Status synchronization checkpoints

Re-evaluate execution ownership, slicing, and reservations whenever:

1. an implementation Task starts or resumes;
2. a broad/full test exposes multiple failure classes or substantial remaining acceptance;
3. implementation expands beyond the current footprint;
4. `main` advances before another write / review / merge checkpoint;
5. an implementation branch / PR reaches a safe merge / handoff checkpoint or is merged;
6. blocking review / CI becomes complete;
7. a blocker changes;
8. Manual E2E becomes executable, passes, or fails;
9. Ready-contract freshness changes prerequisites;
10. decomposition transfers scope between parent / leaves.

Critical leaf transition:

```text
implementation/review/CI/merge complete
+ required Manual E2E is the only remaining work
=> release implementation reservation
=> manual_e2e_only
=> In Review + Manual E2E: Ready to Run
```
