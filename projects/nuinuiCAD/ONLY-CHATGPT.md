# nuinuiCAD execution ownership labels

## Purpose

nuinuiCAD uses two execution-ownership labels for non-parent Issues:

- `only_chatgpt` — the remaining implementation / verification / GitHub / work-management work can be performed by ChatGPT without Coding Agent or local worktree use.
- `manual_e2e_only` — all implementation / review / merge work is complete and the only remaining work is the user's required Manual E2E.

These labels describe **who owns the remaining executable work**. They do not replace Contract, Manual E2E, type, dependency, or status metadata.

**Parent / tracking Issues never receive either label.** Parent state is tracked through ordinary status, Contract / Manual E2E labels, and child / blocker relations.

## `only_chatgpt`

Apply `only_chatgpt` only to a leaf / non-parent Issue when ChatGPT can perform all remaining non-human work without Coding Agent or local worktree use.

Typical ChatGPT-owned work includes:

- latest Project Context / remote repository inspection;
- implementation-contract freshness checks;
- direct GitHub branch/file/commit/PR operations;
- automated test authoring;
- GitHub Actions / CI inspection and fix loops;
- blocking review;
- merge;
- Linear metadata, dependency, and status updates;
- Done-before Ready contract freshness checks.

A future final Manual E2E requirement does not prevent an Issue from being `only_chatgpt` while implementation work remains. The execution label changes when all non-human work is finished.

Do not apply or retain `only_chatgpt` when:

- the Issue is a parent / tracking Issue;
- an unresolved product / UX decision blocks implementation;
- required implementation depends on local-only work ChatGPT cannot perform;
- a required external manual operation other than final Manual E2E remains;
- safe completion would require destructive interaction with unrelated user work.

If direct GitHub + CI is insufficient to complete the contract safely, split the Issue further when there is a real independently verifiable boundary, or remove `only_chatgpt` rather than pretending the Issue is autonomous.

### Starting and executing

`only_chatgpt` does not auto-start a Todo by itself. The normal explicit-start rule still applies unless the current conversation already authorizes continuing the same execution track.

Once started, ChatGPT should continue through implementation, automated verification, blocking review, PR, CI, merge, and Linear updates without asking the user to perform intermediate development work.

### Parallel execution capacity and interference gate

The `LINEAR.md` rule that normally limits simultaneous `In Progress` work to the primary worktree plus the persistent sub worktree applies **only to implementation Tasks that occupy those local worktree slots**.

`only_chatgpt` work does not consume a local worktree slot and therefore does not count toward that two-Task limit. An independent `only_chatgpt` Issue may be moved to `In Progress` even when both local worktree slots are already occupied. There is no separate fixed numeric concurrency cap for `only_chatgpt`; safe parallelism is governed by the interference check below.

Before starting an `only_chatgpt` Issue in parallel with other active implementation work, inspect the latest remote repository, relevant open branches / PRs, and active `In Progress` Issues enough to determine whether the work can proceed independently.

Do **not** start the candidate in parallel when there is a meaningful risk that the Tasks will interfere, including when:

- they use the same GitHub branch / ref, or the candidate expects an unmerged branch / PR from another active Task as its implementation base;
- expected writes overlap the same files / symbols, or the Tasks modify the same tightly coupled subsystem, API, data-flow owner, parser/compiler boundary, or other shared implementation contract in a way likely to race;
- one Task is likely to invalidate the other's `Contract: Ready` implementation facts, automated-test fixture, verification assumptions, or owner/API names before that Task reaches its next safe checkpoint;
- an actual unfinished prerequisite or dependency exists, whether or not the Linear relation has already been recorded;
- safe completion would require rewriting, resetting, force-updating, or otherwise taking ownership of another active Task's branch or user work.

If the conflict is only a temporary parallel-execution hazard and the Issue is otherwise Ready, leave it in `Todo` and choose another independent candidate rather than inventing a dependency. If inspection reveals a real prerequisite, record the dependency and synchronize status according to `LINEAR.md`.

When no meaningful interference is expected, the existence of one or two local-worktree `In Progress` Tasks is **not** a reason to defer the `only_chatgpt` Issue.

For `only_chatgpt` work:

- do not use Coding Agent;
- do not require a local worktree by default;
- use latest GitHub remote state as the implementation authority;
- use direct GitHub operations and GitHub CI as the normal implementation/debug loop;
- preserve unrelated branches/worktrees/user changes;
- follow ordinary PR, blocking-review, merge, and freshness rules.

## `manual_e2e_only`

Apply `manual_e2e_only` only to a leaf / non-parent Issue when **all non-human work is complete** and the user's Manual E2E is literally the only remaining completion step.

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

Do not leave the Issue in `Todo` or `In Progress`, and do not wait for a separate user instruction to mark the handoff ready.

This transition means: **ChatGPT work is finished; the next executable action is the user's Manual E2E.**

If the user postpones the test, keep `manual_e2e_only` and use:

```text
In Review + Manual E2E: Deferred
```

When the user begins testing:

```text
In Review + manual_e2e_only + Manual E2E: Running
```

When all required checks pass:

1. set `Manual E2E: Passed`;
2. perform the normal Done-before Ready contract freshness check;
3. move the Issue to `Done`.

The execution label may remain on the closed Issue as historical metadata; open-issue filtering should use status together with the label.

## Manual E2E failure

If Manual E2E fails because implementation work is required again, the Issue is no longer `manual_e2e_only`.

If the fix remains the same Issue's scope and ChatGPT can perform it:

```text
remove: manual_e2e_only
add:    only_chatgpt
state:  In Progress
Manual E2E: Failed
```

Continue the already-started execution track without requiring a new explicit start. Implement, verify, review, and merge the fix. When only Manual E2E remains again, switch back to `manual_e2e_only` and `In Review` immediately.

If the failure requires a genuinely separate implementation Issue, create/reuse the smallest correct leaf Issue, apply `only_chatgpt` there if it qualifies, and represent the dependency explicitly. Do not create a child mechanically for a small fix that still belongs to the same leaf Issue.

Do not treat a test-environment mistake or unclear E2E instruction as an implementation failure. Correct the E2E setup/plan instead. If the failure exposes a new product decision, stop autonomous implementation and return the affected Contract to the appropriate non-Ready state.

## Parent / child rule

Execution-ownership labels are **leaf-only**.

A parent / tracking Issue must not receive `only_chatgpt` or `manual_e2e_only`, even when:

- every child is `only_chatgpt`;
- every child is already Done;
- the parent's only remaining completion step is an integrated Manual E2E.

The parent continues to use ordinary Linear state + Contract / Manual E2E metadata + relations. If implementation represented by its children is fully merged and the parent's own remaining work is Manual E2E, `In Review` may be the correct ordinary status, but no execution-ownership label is added.

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

In addition to the normal `LINEAR.md` checkpoints, re-evaluate execution ownership whenever:

1. an `only_chatgpt` implementation PR is merged;
2. blocking review / CI becomes complete;
3. a blocker is completed or added;
4. Manual E2E becomes executable;
5. Manual E2E passes or fails;
6. a Ready contract freshness check changes prerequisites.

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
parent / tracking Issue
=> never only_chatgpt
=> never manual_e2e_only
```
