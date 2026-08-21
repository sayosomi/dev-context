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

### Parallel execution capacity

Local worktree capacity is a constraint for local Coding Agent / local execution Tasks, not for `only_chatgpt`.

`only_chatgpt` does not consume a local worktree slot. There is no fixed numeric concurrency cap for `only_chatgpt`; safe parallelism is governed by the interference gate below.

Do not defer an otherwise independent `only_chatgpt` Issue merely to preserve local checkout capacity. When multiple `only_chatgpt` Issues can proceed safely, continue the work that web ChatGPT can perform.

### Interference gate

Before starting an `only_chatgpt` Issue in parallel with other active implementation work, inspect the latest remote repository, relevant open branches / PRs, and active `In Progress` Issues enough to determine whether the work can proceed independently.

Parallel work is allowed unless there is a **concrete interference path**. Block parallel start when any of the following is true:

1. **unfinished implementation dependency / base** — the candidate actually depends on another active Task's unmerged result or unfinished prerequisite;
2. **same branch / ref ownership** — both Tasks would write or move the same GitHub branch / ref;
3. **conflicting shared write target** — both Tasks need incompatible changes to the same symbol, API, shared contract, data-flow owner, parser/compiler boundary, or other coupled owner;
4. **Ready-contract invalidation before a safe checkpoint** — one Task is likely to invalidate the other's `Contract: Ready` facts, fixtures, verification assumptions, or ownership names before the other Task can safely refresh;
5. **unsafe ownership rewrite** — safe completion would require resetting, force-updating, rewriting, or otherwise taking ownership of another active Task's branch or user work.

Same file, directory, subsystem, or nearby code is a **warning signal**, not an automatic block. It becomes a block only when the actual write targets / contracts / data flow can conflict or one Task can invalidate the other's premises.

Likewise, different files do not guarantee independence if both changes meet at the same API / semantics / data-flow contract.

If the conflict is only a temporary parallel-execution hazard and the Issue is otherwise Ready, leave it in `Todo` and choose another independent candidate rather than inventing a dependency. If inspection reveals a real prerequisite, record the dependency and synchronize status according to `LINEAR-ISSUES.md`.

For `only_chatgpt` work:

- do not use Coding Agent;
- do not require a local worktree by default;
- use latest GitHub remote state as the implementation authority;
- use direct GitHub operations and GitHub CI as the normal implementation/debug loop;
- preserve unrelated branches/worktrees/user changes;
- follow ordinary authorization, blocking-review, merge, and freshness rules.

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

Continue the already-started execution track without requiring a new explicit start. Implement, verify, review, and merge the fix. When only execution-environment-bound Manual E2E remains again, switch back to `manual_e2e_only` and `In Review` immediately.

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

Do not split Issues only to maximize `only_chatgpt` coverage.

A child should be a real independently verifiable implementation boundary, typically one owner/subsystem/API/data-flow layer with automated acceptance.

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

In addition to the normal `LINEAR-ISSUES.md` checkpoints, re-evaluate execution ownership whenever:

1. an `only_chatgpt` implementation branch / PR is merged;
2. blocking review / CI becomes complete;
3. a blocker is completed or added;
4. Manual E2E becomes executable;
5. Manual E2E passes or fails;
6. a Ready contract freshness check changes prerequisites;
7. decomposition transfers all remaining acceptance out of a former tracking parent.

Critical automatic leaf transition:

```text
only_chatgpt leaf
+ implementation/review/CI/merge complete
+ required Manual E2E is the only remaining work
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
