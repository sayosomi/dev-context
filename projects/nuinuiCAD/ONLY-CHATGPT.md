# nuinuiCAD execution ownership labels

## Purpose

nuinuiCAD uses two execution-ownership labels for leaf / non-parent Issues:

- `only_chatgpt` — the remaining implementation / verification / GitHub / work-management work can be performed by web ChatGPT without Coding Agent or a local nuinuiCAD execution environment.
- `manual_e2e_only` — all implementation / review / merge / management work available to web ChatGPT is complete and the only remaining completion work is required Manual E2E in an actual nuinuiCAD execution environment that web ChatGPT cannot operate directly.

These labels describe whether the remaining executable work is **web-ChatGPT-executable or execution-environment-bound**. They do not mean `ChatGPT vs human`.

A `manual_e2e_only` Issue may have Manual E2E units executed by Codex Luna xhigh or by the user according to [Manual E2E execution rules](./MANUAL-E2E.md). Human judgment is required only for the units classified as Human there.

These labels do not replace Contract, Manual E2E, type, dependency, or status metadata.

Execution-ownership labels are leaf-only. A retained parent with its own aggregate acceptance / integrated Manual E2E / final execution work does not receive either label.

## `only_chatgpt`

Apply `only_chatgpt` only to a leaf / non-parent Issue when ChatGPT can perform all remaining pre-E2E implementation / verification / GitHub / work-management work without Coding Agent or local worktree use.

Typical ChatGPT-owned work includes:

- latest Project Context / remote repository inspection;
- implementation-contract freshness checks;
- direct GitHub branch/file/commit operations and PR operations when explicitly authorized;
- automated test authoring;
- GitHub Actions / CI inspection and fix loops;
- blocking review;
- merge when explicitly authorized;
- Linear metadata, dependency, and status updates;
- Done-before Ready contract freshness checks.

A future final Manual E2E requirement does not prevent an Issue from being `only_chatgpt` while implementation work remains. The execution label changes when all web-ChatGPT-executable implementation / verification / management work is finished.

Do not apply or retain `only_chatgpt` when:

- the Issue is a parent / tracking Issue;
- an unresolved product / UX decision blocks implementation;
- required implementation depends on local-only work ChatGPT cannot perform;
- a required external manual operation other than final Manual E2E remains;
- safe completion would require destructive interaction with unrelated user work.

If direct GitHub + CI is insufficient to complete the contract safely, split the Issue further when there is a real independently verifiable boundary, or remove `only_chatgpt` rather than pretending the Issue is autonomous.

### Starting and executing

`only_chatgpt` does not auto-start a Todo by itself. The normal explicit-start rule still applies unless the current conversation already authorizes continuing the same execution track.

Once started, ChatGPT should continue through all work that it can safely perform without asking the user to do intermediate development work. Do not stop merely because local Coding Agent worktrees are occupied.

When the user asks ChatGPT to choose an `only_chatgpt` Issue rather than naming one, prefer a Ready candidate whose planned semantic footprint has the least interference with currently active reservations. Do not choose solely by issue number, age, or apparent diff size when another independent candidate is available.

### Parallel execution capacity

Local worktree capacity is a constraint for local Coding Agent / local execution Tasks, not for `only_chatgpt`.

`only_chatgpt` does not consume a local worktree slot. There is no fixed numeric concurrency cap for `only_chatgpt`; safe parallelism is governed by semantic interference, not by a global worker count.

Do not defer an otherwise independent `only_chatgpt` Issue merely to preserve local checkout capacity. When multiple `only_chatgpt` Issues can proceed safely, continue the work that web ChatGPT can perform.

### Parallel footprint

Every active `only_chatgpt` implementation Issue must publish a current **Parallel footprint** in its Linear Issue before the first repository write for that execution track. This is a soft reservation used by other ChatGPT sessions to coordinate parallel work.

Derive the footprint from the latest remote repository and the current implementation contract. Prefer semantic ownership and contract boundaries from current repository architecture over file or directory names.

Use this shape:

```text
Parallel footprint
- Base main: <current remote main SHA>
- Writes: <semantic owner / symbol / API / data-flow boundary>
- Shared contracts: <contract or assumption that another Task could invalidate, or none>
- Depends on: <Issue / PR / unfinished base, or none>
- Exclusive: <precise owner / contract that requires a single active writer, or none>
```

Rules:

- `Writes` names what the Task intends to change semantically. A file list may be added as supporting detail, but paths alone are not a sufficient footprint.
- `Shared contracts` names current API, semantics, fixtures, ownership, or data-flow assumptions whose change could invalidate this Task even when files do not overlap.
- `Depends on` records a real implementation dependency. Do not use it for a temporary parallel-execution hazard.
- `Exclusive` is a narrow semantic soft lock. Use it only when concurrent writers to the same shared owner / contract cannot be safely separated or refreshed at a checkpoint. Do not lock an entire broad subsystem when the actual shared target is narrower.
- High-coupling shared changes such as parser/compiler semantics, canonical document mutation boundaries, evaluator transport/semantic contracts, shared command infrastructure, or a normative DSL contract are common signals that an `Exclusive` reservation may be appropriate, but the current repository ownership is authoritative.
- Two Tasks may touch the same file or subsystem without conflicting if their semantic write targets are independent. Conversely, different files may conflict through a shared API, semantic contract, or data-flow owner.

The footprint is current execution state, not a permanent specification. Update it when actual implementation scope or ownership changes.

### Reservation protocol

For a newly started `only_chatgpt` Issue, use this order:

1. inspect latest remote `main`, relevant open branches / PRs, and active `In Progress` implementation Issues;
2. inspect the active Issues' published Parallel footprints;
3. determine the candidate's footprint from the latest repository and implementation contract;
4. in the same startup checkpoint, move the explicitly started Issue to `In Progress` and publish its Parallel footprint in Linear;
5. re-read active reservations / relevant PR state after publishing;
6. only after that second check passes, perform the first repository write.

The second read is required because two ChatGPT sessions may have inspected the same pre-reservation state concurrently.

If the second check discovers a concrete conflict with a reservation that was already active, the new candidate yields. If the hazard is temporary and there is no real prerequisite, return the candidate to `Todo`; do not invent a dependency.

If two new conflicting reservations appear concurrently and reliable temporal precedence is not available, use the lower numeric Linear Issue identifier as the deterministic winner. The losing Issue returns to `Todo` before any repository write. This tie-break is only a race-resolution rule; it is not a priority policy for normal Issue selection.

Before expanding implementation into a semantic owner, API, contract, or data-flow boundary not covered by the published footprint, update the footprint and rerun the interference gate **before writing that new target**.

The implementation reservation ends when implementation ownership ends: after the Issue is merged and no implementation/fix work remains, or when it is otherwise returned to a non-active state. `manual_e2e_only` does not retain an implementation-owner reservation.

### Interference gate

Before starting or materially expanding an `only_chatgpt` Issue in parallel with other active implementation work, inspect the latest remote repository, relevant open branches / PRs, and active reservations enough to determine whether the work can proceed independently.

Parallel work is allowed unless there is a **concrete interference path**. Block parallel execution when any of the following is true:

1. **unfinished implementation dependency / base** — the candidate actually depends on another active Task's unmerged result or unfinished prerequisite;
2. **same branch / ref ownership** — both Tasks would write or move the same GitHub branch / ref;
3. **conflicting shared write target** — both Tasks need incompatible changes to the same symbol, API, shared contract, data-flow owner, parser/compiler boundary, or other coupled owner;
4. **exclusive reservation overlap** — a Task would write an owner / contract currently reserved as `Exclusive` by another active Task;
5. **Ready-contract invalidation before a safe checkpoint** — one Task is likely to invalidate the other's `Contract: Ready` facts, fixtures, verification assumptions, ownership names, or published footprint before the other Task can safely refresh;
6. **unsafe ownership rewrite** — safe completion would require resetting, force-updating, rewriting, or otherwise taking ownership of another active Task's branch or user work.

Same file, directory, subsystem, or nearby code is a **warning signal**, not an automatic block. It becomes a block only when the actual write targets / contracts / data flow can conflict or one Task can invalidate the other's premises.

Likewise, different files do not guarantee independence if both changes meet at the same API / semantics / data-flow contract.

If the conflict is only a temporary parallel-execution hazard and the Issue is otherwise Ready, leave or return it to `Todo` and choose another independent candidate rather than inventing a dependency. If inspection reveals a real prerequisite, record the dependency and synchronize status according to `LINEAR-ISSUES.md`.

For `only_chatgpt` work:

- do not use Coding Agent;
- do not require a local worktree by default;
- use latest GitHub remote state as the implementation authority;
- use direct GitHub operations and GitHub CI as the normal implementation/debug loop;
- preserve unrelated branches/worktrees/user changes;
- follow ordinary authorization, blocking-review, merge, and freshness rules.

### CI failure fallback when job logs are unavailable

An `only_chatgpt` execution must not treat inability to download a completed GitHub Actions job log as an automatic blocker. An empty, unavailable, permission-denied, or otherwise inaccessible job-log response is a tooling / evidence limitation; by itself it does not establish that the Issue cannot continue.

When required CI fails, use this fallback sequence:

1. establish the exact workflow run, head SHA, failing job, failing step, and available conclusions / step summaries from GitHub metadata;
2. attempt the normal job-log retrieval path;
3. if log text is unavailable, continue diagnosis from the available evidence, including the workflow YAML and exact command executed by the failing step, the PR / commit diff, relevant tests / fixtures / configuration / source owners, and workflow artifacts when they are material and accessible;
4. if repository evidence identifies a concrete plausible cause, make the narrow fix allowed by the Issue contract and use the subsequent CI run as verification / additional evidence;
5. continue any other safe, deterministic Issue work that does not depend on the missing log while diagnosis remains incomplete.

Do not make arbitrary speculative patches merely to probe CI when repository evidence does not connect the change to the failure. Conversely, do not stop at "job logs unavailable" when the failing command, changed code, test definitions, step metadata, artifacts, or a subsequent run can still narrow or verify the problem.

Do not ask the user to manually retrieve or paste CI logs as the first fallback. Exhaust the web-ChatGPT-accessible evidence paths first.

The Issue may be treated as blocked, or `only_chatgpt` removed, only when the unavailable log contains materially necessary evidence and no supported fallback can safely determine the failure cause or verify a fix. Record the exact missing evidence and why it is indispensable rather than reporting only that the log API failed.

A required failing CI check remains unresolved until it passes or is otherwise resolved by the authoritative workflow / Task contract. Missing log text never converts a failing or unknown required check into PASS and never authorizes merge / completion by itself.

### Main-advance interference checkpoint

Parallel safety must be refreshed when `main` advances while an `only_chatgpt` Issue is still active.

Before a further repository write, blocking review completion, or merge, compare the latest remote `main` with the Issue's published `Base main` when they differ.

Inspect intervening merged changes by semantic owner / API / contract / data flow, not only by path overlap:

- no relevant overlap or invalidation → update `Base main` in the footprint and continue;
- current facts drifted but the established semantics / scope / acceptance still determine one implementation path → refresh the contract / footprint while keeping `Contract: Ready` according to `CONTRACT-DECISIONS.md`;
- a concrete parallel conflict now exists → stop writes at the safe checkpoint until the conflicting Task merges / releases the owner or another non-conflicting path is established;
- a real prerequisite is revealed → record the dependency and synchronize status;
- a new product / UX / scope decision is required → return the contract to the appropriate non-Ready state.

When an `only_chatgpt` PR is merged, the completing ChatGPT should also inspect other active `only_chatgpt` footprints that could plausibly be invalidated by the merged semantic changes and leave the affected Task to perform this freshness check before further writes. Do not rewrite another active Task's contract merely because it may have drifted.

## `manual_e2e_only`

Apply `manual_e2e_only` only to a leaf / non-parent Issue when **all web-ChatGPT-executable implementation / review / merge / management work is complete** and required Manual E2E in the actual nuinuiCAD execution environment is literally the only remaining completion step.

Required conditions:

- implementation required by the Issue is merged to the intended base;
- required automated verification / CI is complete;
- blocking review is complete;
- no implementation / review / merge / management work remains;
- Contract remains `Ready` against latest remote `main`;
- Manual E2E is required and its plan is ready to execute;
- no unfinished blocker remains;
- the Issue is not a parent / tracking Issue.

When these conditions first become true, ChatGPT must perform the transition immediately:

```text
remove: only_chatgpt
add:    manual_e2e_only
state:  In Review
Manual E2E: Ready to Run
```

Do not leave the Issue in `Todo` or `In Progress`, and do not wait for a separate user instruction to mark the E2E handoff ready.

This transition means: **web ChatGPT's implementation / remote-management work is finished; the next executable action requires the actual nuinuiCAD execution environment.**

Who performs each Manual E2E test unit is determined by `MANUAL-E2E.md`:

- objective units use Luna by default when no known capability / evidence blocker exists;
- visual / UX / design / experiential judgment units use `Executor: Human`;
- objective units with an established Luna capability limitation use `Executor: Human / Reason: Luna capability`.

If testing is postponed, keep `manual_e2e_only` and use:

```text
In Review + Manual E2E: Deferred
```

When Luna or the user begins testing:

```text
In Review + manual_e2e_only + Manual E2E: Running
```

When all required Manual E2E units, across both Luna and Human executors, pass:

1. set `Manual E2E: Passed`;
2. perform the normal Done-before Ready contract freshness check;
3. move the Issue to `Done`.

The execution label may remain on the closed Issue as historical metadata; open-issue filtering should use status together with the label.

## Manual E2E failure

If Manual E2E fails because implementation work is required again, the Issue is no longer `manual_e2e_only`.

If the fix remains the same Issue's acceptance / scope and ChatGPT can perform it:

```text
remove: manual_e2e_only
add:    only_chatgpt
state:  In Progress
Manual E2E: Failed
```

Before the first fix write, publish / refresh the Parallel footprint and run the normal reservation protocol. Continue the already-started execution track without requiring a new explicit start. Implement, verify, review, and merge the fix. When only execution-environment-bound Manual E2E remains again, switch back to `manual_e2e_only` and `In Review` immediately.

Whether a discovered fix stays in the same Issue or becomes a new Issue is determined by [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md). Do not create a child mechanically for a small fix that remains necessary for the original acceptance.

Do not treat a test-environment mistake, unsupported Luna operation, or unclear E2E instruction as an implementation failure. Correct the E2E setup / plan instead. If the failure exposes a new product decision, stop autonomous implementation and return the affected Contract to the appropriate non-Ready state.

## Parent / decomposition rule

Do not keep a pure tracking parent by default.

When an original Issue is fully decomposed into independently verifiable leaf Issues **and all original scope / acceptance has been transferred to those children**, the original Issue should stop acting as an aggregate tracking shell. Use child relations / dependency relations for execution tracking.

- If the original Issue's actual Work was research / decomposition and that acceptance is complete, it may be `Done`.
- If the original Issue represented feature delivery but no longer owns any remaining acceptance because that scope has been superseded by the child Issues, close it as no-longer-active tracking work according to the normal Issue / capacity policy; do **not** mark the feature delivered merely because decomposition happened.
- Record the child Issue identifiers so the decomposition remains discoverable.

Retain a parent Issue only when the parent itself owns real aggregate work that cannot be attributed to individual children, for example:

- integrated Manual E2E that is meaningful only after multiple children merge;
- cross-child aggregate acceptance;
- final cutover / migration / cleanup / integration execution owned by the parent.

A retained parent uses ordinary Linear status + Contract / Manual E2E metadata + relations. It never receives `only_chatgpt` or `manual_e2e_only`.

## Decomposition rules

Do not split Issues only to maximize `only_chatgpt` coverage or parallel worker count.

A child should be a real independently verifiable implementation boundary, typically one owner/subsystem/API/data-flow layer with automated acceptance.

When multiple independently verifiable boundaries genuinely exist, prefer a leaf scope that stays within one semantic owner / contract / data-flow layer where practical. This reduces the number of active reservations held by one Issue without inventing artificial decomposition.

Prefer decomposition such as:

```text
host-neutral/core semantics
-> adapter/protocol/transport
-> user-facing integration
```

or another sequence that follows actual repository ownership.

Each implementation child should normally use `Manual E2E: Not Required` when automated verification is sufficient. If a leaf child itself owns a required Manual E2E, it may transition from `only_chatgpt` to `manual_e2e_only` after merge.

Only the first unblocked child in a dependency chain should materialize into `Todo`; later Ready children remain `Backlog` while blocked.

## Status synchronization checkpoints

In addition to the normal `LINEAR-ISSUES.md` checkpoints, re-evaluate execution ownership and parallel reservations whenever:

1. an `only_chatgpt` Issue starts implementation or resumes implementation after a fix handoff;
2. an active Issue's implementation expands beyond its published Parallel footprint;
3. remote `main` advances beyond the Issue's published `Base main` before another write / review-completion / merge checkpoint;
4. an `only_chatgpt` implementation branch / PR is merged;
5. blocking review / CI becomes complete;
6. a blocker is completed or added;
7. Manual E2E becomes executable;
8. Manual E2E passes or fails;
9. a Ready contract freshness check changes prerequisites;
10. decomposition transfers all remaining acceptance out of a former tracking parent.

Critical automatic leaf transition:

```text
only_chatgpt leaf
+ implementation/review/CI/merge complete
+ required Manual E2E is the only remaining work
=> release implementation reservation
=> replace only_chatgpt with manual_e2e_only
=> immediately In Review + Manual E2E: Ready to Run
```

Critical parent rule:

```text
pure tracking parent after complete scope transfer
=> do not keep as active aggregate tracker

retained parent with own aggregate work
=> never only_chatgpt
=> never manual_e2e_only
```