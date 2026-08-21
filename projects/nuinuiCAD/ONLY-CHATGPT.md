# nuinuiCAD `only_chatgpt` workflow

## Purpose

`only_chatgpt` is a Linear label for work where all non-human implementation, verification, GitHub, and work-management steps can be handled by ChatGPT.

The label does **not** mean that the Issue can always reach `Done` without any human action. A decomposed user-facing parent Issue may still require one final Manual E2E run by the user. In that case, every implementation child is completed by ChatGPT, and the parent becomes a pure Manual E2E handoff.

This document is a narrow nuinuiCAD exception/extension to the normal status rules in `LINEAR.md`. Where this document defines a special status transition for an `only_chatgpt` Issue, this document takes precedence for that case only.

## What qualifies for `only_chatgpt`

An Issue may receive `only_chatgpt` when its remaining non-human work can be completed without Coding Agent or local worktree use.

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

Do not apply or retain `only_chatgpt` if completion requires an unresolved product / UX decision, local-only environment work that ChatGPT cannot perform, an external manual operation other than the explicitly retained final Manual E2E, or destructive interaction with unrelated user work.

`only_chatgpt` does not replace Contract, Manual E2E, type, dependency, or status metadata.

## Two valid `only_chatgpt` shapes

### A. Autonomous implementation Issue

A leaf implementation/research/cleanup Issue may be fully completed by ChatGPT.

Typical metadata:

```text
only_chatgpt
Contract: Ready
Manual E2E: Not Required
```

Readiness and status otherwise follow `LINEAR.md`:

```text
Backlog -> Todo -> In Progress -> Done
```

`only_chatgpt` alone does not auto-start a Todo. The user still explicitly starts the Issue unless the current conversation already authorizes continuing the same execution track.

Once started, ChatGPT should continue through implementation, automated verification, review, PR, CI, merge, Linear updates, and final freshness checks without asking the user to perform intermediate development work.

### B. Decomposed parent with only final Manual E2E remaining

A larger user-facing Issue may also retain `only_chatgpt` when all implementation has been decomposed into `only_chatgpt` child Issues and the only human work left on the parent is its final Manual E2E.

Typical shape:

```text
Parent: only_chatgpt + Contract: Ready + Manual E2E: Ready to Run
  |- Child A: only_chatgpt + Manual E2E: Not Required
  |- Child B: only_chatgpt + Manual E2E: Not Required
  `- Child C: only_chatgpt + Manual E2E: Not Required
```

The parent may have no PR of its own. It represents the integrated user-facing contract whose implementation is delivered by the merged child PRs.

While any implementation child is unfinished, keep the parent in `Backlog` with explicit `blockedBy` relations to the unfinished children.

When the final implementation child reaches `Done`, ChatGPT must immediately re-evaluate the parent. If all of the following are true:

- every required implementation child is `Done`;
- the parent Contract remains `Ready` against latest remote `main`;
- the parent Manual E2E plan is `Ready to Run`;
- no other unfinished blocker exists;
- no implementation, review, CI, merge, or management work remains;

then the parent is now a pure human Manual E2E handoff.

At that checkpoint, move the parent **directly from `Backlog` to `In Review`**.

Do not route this parent through `Todo` or `In Progress` merely because its blockers disappeared. This is the `only_chatgpt` Manual-E2E-handoff exception to the normal Ready Queue materialization rule.

Expected state:

```text
In Review
only_chatgpt
Contract: Ready
Manual E2E: Ready to Run
```

`In Review` in this case means: all implementation required by the parent is already merged through its children, and only required Manual E2E remains.

## Manual E2E handoff lifecycle

For an `only_chatgpt` parent that has become a pure E2E handoff:

```text
Backlog
  -> In Review + Ready to Run
  -> In Review + Running
  -> Done + Passed
```

If the user postpones the test, use:

```text
In Review + Manual E2E: Deferred
```

When the user starts testing, set `Manual E2E: Running`.

When all required checks pass, set `Manual E2E: Passed`, perform the normal Done-before Ready contract freshness check, then move the parent to `Done`.

## Manual E2E failure

If final Manual E2E fails because implementation work is required again, the parent is no longer a pure E2E handoff.

At the same checkpoint:

1. set the parent Manual E2E state to `Failed`;
2. create or reuse the smallest focused fix Issue that owns the failure;
3. apply `only_chatgpt` to the fix Issue if it satisfies this workflow;
4. add an explicit `blockedBy` relation from the parent to the fix Issue;
5. move the parent from `In Review` back to `Backlog`;
6. implement/verify/merge the fix Issue through the normal `only_chatgpt` flow.

When the fix Issue reaches `Done`, re-check the parent. If only Manual E2E remains again, set the parent Manual E2E state back to `Ready to Run` and move it directly to `In Review` again.

Do not create a fix Issue for a mere test-environment mistake or unclear test instruction. Correct the E2E setup/plan in the owning Issue instead. If the failure exposes a new product decision, stop autonomous execution and return the affected Contract to the appropriate non-Ready state.

## Decomposition rules

Do not split Issues only to maximize the number carrying `only_chatgpt`.

A child should be a real independently verifiable implementation boundary, typically one owner/subsystem/API/data-flow layer with automated acceptance.

Prefer decomposition such as:

```text
host-neutral/core semantics
-> adapter/protocol/transport
-> user-facing integration
```

or another sequence that follows actual repository ownership.

Each implementation child should normally be `Manual E2E: Not Required` when automated verification is sufficient. The parent retains the integrated user-facing Manual E2E contract.

Only the first unblocked child in a dependency chain should materialize into `Todo`; later Ready children remain `Backlog` while blocked. This avoids inflating the Ready Queue.

## Execution constraints

For `only_chatgpt` implementation Issues:

- do not use Coding Agent;
- do not require a local worktree by default;
- use the latest GitHub remote state as the implementation authority;
- use direct GitHub operations and GitHub CI as the normal implementation/debug loop;
- preserve unrelated branches/worktrees/user changes;
- follow the ordinary PR, blocking-review, merge, and freshness rules;
- if direct GitHub + CI is insufficient to complete the contract safely, stop, split the work further when there is a natural boundary, or remove `only_chatgpt` rather than pretending the Issue is autonomous.

## Status synchronization checkpoints

In addition to the normal `LINEAR.md` checkpoints, re-evaluate `only_chatgpt` parent/child state whenever:

1. a child Issue reaches `Done`;
2. the last unfinished child/blocker reaches `Done`;
3. Manual E2E becomes `Ready to Run`;
4. Manual E2E passes or fails;
5. a new implementation blocker/fix child is added;
6. a Ready contract freshness check changes the parent's prerequisites.

The critical automatic transition is:

```text
last required implementation child Done
+ parent only needs Manual E2E
=> parent immediately In Review + Manual E2E: Ready to Run
```
