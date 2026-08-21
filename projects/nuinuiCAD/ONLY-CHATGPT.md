# nuinuiCAD `only_chatgpt` workflow

## Purpose

`only_chatgpt` is a Linear label for work where all non-human implementation, verification, GitHub, and work-management steps can be handled by ChatGPT.

The label does **not** mean that the Issue always reaches `Done` without any human action. The only human action that may remain is the final Manual E2E explicitly owned by the Issue.

This means all of the following may legitimately carry `only_chatgpt`:

- an implementation/research/cleanup Issue that needs no Manual E2E;
- an implementation Issue that ChatGPT can implement and merge completely, after which the user only runs final Manual E2E;
- a decomposed user-facing parent whose implementation is fully delivered by `only_chatgpt` children and whose only remaining work is final Manual E2E.

This document is a narrow nuinuiCAD exception/extension to the normal status rules in `LINEAR.md`. Where this document defines a special status transition for an `only_chatgpt` Issue, this document takes precedence for that case only.

## What qualifies for `only_chatgpt`

Apply `only_chatgpt` when all non-human work for the Issue can be completed without Coding Agent or local worktree use.

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

A final Manual E2E run by the user is compatible with `only_chatgpt`. Other required human implementation/debugging/management work is not.

Do not apply or retain `only_chatgpt` if completion requires an unresolved product / UX decision, local-only environment work that ChatGPT cannot perform, an external manual operation other than the explicitly retained final Manual E2E, or destructive interaction with unrelated user work.

`only_chatgpt` does not replace Contract, Manual E2E, type, dependency, or status metadata.

## Valid `only_chatgpt` shapes

### A. Fully autonomous Issue — no Manual E2E

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

### B. ChatGPT implementation Issue — final human Manual E2E

An Issue may require Manual E2E while still qualifying for `only_chatgpt` when ChatGPT can perform every implementation step through merge and the user is only needed for the final Manual E2E.

Typical execution:

```text
Todo
-> In Progress
-> implementation / CI / review / merge completed by ChatGPT
-> In Review + Manual E2E: Ready to Run
-> Done + Manual E2E: Passed
```

After the implementation is merged, do not ask the user to perform additional development setup that ChatGPT could have completed itself. Prepare the standard isolated E2E launch instructions/fixture and leave only the actual human observation/interaction to the user.

If the user postpones the test, use `In Review + Manual E2E: Deferred`.

### C. Decomposed parent — pure Manual E2E handoff

A larger user-facing parent Issue must carry `only_chatgpt` once its implementation has been completely decomposed into `only_chatgpt` child Issues and the only intended human work on the parent is its integrated final Manual E2E.

Typical shape:

```text
Parent: only_chatgpt + Contract: Ready + Manual E2E: Ready to Run
  |- Child A: only_chatgpt + Manual E2E: Not Required
  |- Child B: only_chatgpt + Manual E2E: Not Required
  `- Child C: only_chatgpt + Manual E2E: Not Required
```

The parent may have no PR of its own. It represents the integrated user-facing contract whose implementation is delivered by the merged child PRs.

While any required implementation child is unfinished, keep the parent in `Backlog` with explicit `blockedBy` relations to the unfinished children.

When the final required implementation child reaches `Done`, ChatGPT must immediately re-evaluate the parent. If all of the following are true:

- every required implementation child is `Done`;
- the parent Contract remains `Ready` against latest remote `main`;
- the parent Manual E2E plan is `Ready to Run`;
- no other unfinished blocker exists;
- no implementation, review, CI, merge, or management work remains;

then the parent is now a pure human Manual E2E handoff.

At that checkpoint, move the parent **directly from `Backlog` to `In Review`**.

Do not route this parent through `Todo` or `In Progress` merely because its blockers disappeared. This is the `only_chatgpt` pure-E2E-handoff exception to the normal Ready Queue materialization rule.

Expected state:

```text
In Review
only_chatgpt
Contract: Ready
Manual E2E: Ready to Run
```

`In Review` in this case means: all implementation required by the parent is already merged through its children, and only required Manual E2E remains.

The transition does not consume an `In Progress` implementation slot because no implementation work is starting on the parent.

## Manual E2E handoff lifecycle

For any `only_chatgpt` Issue whose implementation is complete and only Manual E2E remains:

```text
In Review + Ready to Run
-> In Review + Running
-> Done + Passed
```

If the user postpones the test:

```text
In Review + Manual E2E: Deferred
```

When the user starts testing, set `Manual E2E: Running`.

When all required checks pass, set `Manual E2E: Passed`, perform the normal Done-before Ready contract freshness check, then move the Issue to `Done`.

For a decomposed parent, the entry into this lifecycle is automatic as soon as the last required implementation child is `Done` and the parent has no other blocker.

## Manual E2E failure

If final Manual E2E fails because implementation work is required again, the Issue is no longer a pure E2E handoff.

For a decomposed parent, at the same checkpoint:

1. set Manual E2E to `Failed`;
2. create or reuse the smallest focused fix Issue that owns the failure;
3. apply `only_chatgpt` to the fix Issue if it satisfies this workflow;
4. add an explicit `blockedBy` relation from the parent to the fix Issue;
5. move the parent from `In Review` back to `Backlog`;
6. implement/verify/merge the fix Issue through the normal `only_chatgpt` flow.

When the fix Issue reaches `Done`, re-check the parent. If only Manual E2E remains again, set Manual E2E back to `Ready to Run` and move the parent directly to `In Review` again.

For a non-parent `only_chatgpt` Issue, a focused fix may stay on the same Issue/branch when that remains the correct work item under the normal workflow. Do not create a child mechanically when the failure is still the same small implementation task.

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

When the decomposition is complete and every remaining implementation step is represented by `only_chatgpt` children, apply/retain `only_chatgpt` on the parent as well. The label on the parent means that the only human responsibility for the track is the eventual final Manual E2E.

## Execution constraints

For `only_chatgpt` implementation work:

- do not use Coding Agent;
- do not require a local worktree by default;
- use the latest GitHub remote state as the implementation authority;
- use direct GitHub operations and GitHub CI as the normal implementation/debug loop;
- preserve unrelated branches/worktrees/user changes;
- follow the ordinary PR, blocking-review, merge, and freshness rules;
- if direct GitHub + CI is insufficient to complete the contract safely, stop, split the work further when there is a natural boundary, or remove `only_chatgpt` rather than pretending the Issue is autonomous.

## Status synchronization checkpoints

In addition to the normal `LINEAR.md` checkpoints, re-evaluate `only_chatgpt` parent/child state whenever:

1. an `only_chatgpt` implementation PR is merged;
2. a child Issue reaches `Done`;
3. the last unfinished child/blocker reaches `Done`;
4. Manual E2E becomes `Ready to Run`;
5. Manual E2E passes or fails;
6. a new implementation blocker/fix child is added;
7. a Ready contract freshness check changes the Issue prerequisites.

The critical automatic parent transition is:

```text
last required implementation child Done
+ parent only needs Manual E2E
=> parent immediately In Review + Manual E2E: Ready to Run
```

Do not leave such a parent in `Backlog`, move it to `Todo`, or wait for a separate user instruction to mark the E2E handoff ready.
