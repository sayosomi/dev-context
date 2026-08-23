# nuinuiCAD scheduled `only_chatgpt` runner

## Purpose

A single user-created ChatGPT Scheduled Task may autonomously continue or start eligible nuinuiCAD `only_chatgpt` work while the user is away.

This document owns periodic runner selection, standing start / merge authorization, recovery priority, and scheduled-run continuation. It does not replace the normal execution-ownership rules in [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md), the watchdog state/heartbeat semantics in [`WATCHDOG.md`](./WATCHDOG.md), or Linear readiness/status rules in [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md).

The runner is an ordinary ChatGPT Scheduled Task. Do not add another daemon, browser automation, Tampermonkey script, or external scheduler for this behavior.

## Single runner

Maintain exactly one Scheduled Task for autonomous nuinuiCAD `only_chatgpt` execution.

- cadence: once per hour;
- do not create staggered or equivalent duplicate tasks to simulate a sub-hour cadence;
- every run starts by loading the latest Project Context entrypoint from GitHub:
  `https://github.com/sayosomi/dev-context/blob/main/projects/nuinuiCAD/README.md`;
- after loading that README, follow its current loading rules rather than relying on policy copied into the task prompt;
- use connected GitHub / Linear capabilities only through the permissions available to the Scheduled Task at execution time.

A suitable task prompt stays intentionally small: identify the run as the user-created nuinuiCAD autonomous `only_chatgpt` runner, require loading the fixed README entrypoint first, then require following the current Project Context rules to recover/continue/select work. Do not embed a stale copy of this document or other Project Context policy in the Scheduled Task prompt.

## Standing start and merge authorization

The user explicitly creating the Scheduled Task described by this document is standing explicit authorization for that task to:

- select and start an eligible `only_chatgpt` Issue;
- create and manage Pull Requests that belong to the selected / recovered autonomous execution track; and
- merge those Pull Requests when the current Project Context rules say the PR is ready to merge.

This is a narrow exception to the ordinary [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) rules that a Todo does not auto-start merely because it has `only_chatgpt` and that merge requires explicit authorization. The Scheduled Task does not need to ask the user for another merge confirmation for a PR covered by this standing authorization.

The Scheduled Task may newly start a candidate only when all of the following are currently true:

- the runner is the user-created Scheduled Task governed by this document;
- the candidate is a leaf / non-parent Issue with `only_chatgpt`;
- the candidate remains `Contract: Ready` against current authority;
- its Manual E2E state permits implementation to begin or continue under current Issue / Manual E2E policy;
- it has no unfinished blocker;
- the normal `only_chatgpt` reservation / interference gate passes.

A merge is covered by the standing authorization only when all of the following are currently true:

- the PR belongs to the currently selected / recovered eligible `only_chatgpt` execution track;
- required implementation, automated verification / CI, blocking review, main-advance interference checks, and any other current pre-merge gates are complete and permit merge;
- the current PR head / base and mergeability have been refreshed from GitHub immediately before merge;
- no unresolved blocker, required review, branch protection, or current policy rule forbids the merge;
- the merge does not require force-updating refs, bypassing required checks or protections, destructive interference with unrelated work, or an administrative override outside ordinary connected-app permissions.

When those conditions pass, merge as part of the autonomous execution track instead of stopping only to request a second user confirmation.

This standing authorization does not apply to arbitrary scheduled prompts, ordinary chat turns, unrelated Pull Requests, or non-`only_chatgpt` Issues. It does not authorize guessing through a new product / UX / scope decision, bypassing a required local/manual operation, bypassing repository protections, or taking destructive ownership of unrelated work.

Resuming an unfinished autonomous track selected by this runner remains within the same standing start / merge authorization, but the runner must still refresh remote state before acting.

## Per-run priority: recovery before new work

Before starting any new Issue, inspect the latest watchdog state in the GitHub Issue #514 hub according to [`WATCHDOG.md`](./WATCHDOG.md), then reconcile candidate records with current Linear and GitHub state.

Use this priority order:

1. an unfinished `only_chatgpt` autonomous track whose watchdog record is `timed_out`;
2. an unfinished `active` autonomous track that still has executable web-ChatGPT work;
3. only when no recoverable / continuable autonomous track exists, select a new eligible Todo `only_chatgpt` Issue.

A watchdog record is liveness evidence, not work-management authority. For every recovery candidate, re-read current Linear status/labels/dependencies and current GitHub repository/PR/branch state before deciding what remains unfinished.

For a `timed_out` record, resume only from state actually persisted remotely. Never assume an interrupted in-memory write, CI action, merge, comment, or status update succeeded. Once execution actually resumes, arm/heartbeat the record back to `active` using the normal watchdog semantics.

If a watchdog record is stale relative to authoritative remote state, follow the authoritative state and repair/finish the execution track only as permitted by current policy; do not manufacture work merely to match the watchdog record.

## New candidate selection

When recovery/continuation does not take precedence, choose from current Todo Issues that satisfy the normal `only_chatgpt` eligibility rules.

Before selection:

- inspect latest remote repository state;
- inspect current `In Progress` implementation Issues;
- read their published Parallel footprints;
- inspect relevant open branches / PRs when they can affect interference or readiness;
- refresh the candidate's `Contract: Ready` facts against current authority.

Prefer a Ready candidate with the least concrete interference risk. Do not choose solely by issue number, age, apparent diff size, or local worktree capacity.

Before the first repository write for a newly selected Issue, run the full reservation protocol from [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md): publish the current Parallel footprint while moving the Issue to `In Progress`, re-read active reservations / relevant PR state, and proceed only if the second interference check passes.

If no safe candidate exists, perform no repository write for invented work. A no-op scheduled run is successful.

## At most one new Issue per scheduled run

One scheduled invocation may newly start at most one `only_chatgpt` Issue.

This limit is about **new starts**, not the amount of progress on the selected/recovered track. Once a track is selected or recovered, continue it as far as safely possible within the invocation, including repository inspection/writes, CI/review/merge work, watchdog updates, and Linear synchronization when its contract permits.

Do not start a second new Issue in the same invocation merely because the first newly started Issue finishes quickly.

## Watchdog integration

After selecting or recovering an autonomous execution track, use [`WATCHDOG.md`](./WATCHDOG.md) exactly as the liveness authority.

- arm/reset the record to `active` when autonomous execution begins or resumes;
- heartbeat while work is actively continuing and before known high-risk / long-wait boundaries;
- keep periodic heartbeat writes on GitHub Issue #514, never through Linear / Cloudflare mirror infrastructure;
- after a `timed_out` recovery, the resumed heartbeat re-arms the same track according to watchdog semantics.

When an hourly invocation ends but the same autonomous Issue is intentionally still unfinished and has executable web-ChatGPT work for the next run, leave the track `active` and write a fresh heartbeat near the safe invocation boundary. Do not mark it `done` merely because one Scheduled Task invocation ended.

Set the watchdog record to `done` when the ChatGPT execution track is intentionally complete, is handed off at a known checkpoint with no autonomous work remaining, or is stopped by a synchronized policy boundary where continued autonomous execution is no longer authorized.

## Completion, handoff, and stop boundaries

When the Issue's implementation/review/merge/management work is complete:

- if required Manual E2E remains, immediately transition according to [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) to the appropriate `manual_e2e_only + In Review` state, then finish the autonomous watchdog track;
- if Manual E2E is `Not Required`, perform the normal Done-before Ready contract freshness check and complete the Issue rather than leaving it artificially `In Progress` for the next hour;
- synchronize Linear metadata at the same logical checkpoint before treating the autonomous work as complete.

Stop autonomous execution at a safe checkpoint instead of guessing when current authority reveals any of the following:

- a new product / UX / scope / compatibility decision is required;
- implementation now requires a local-only or otherwise unavailable execution capability;
- a required external manual operation outside the allowed final Manual E2E boundary appears;
- continuing would require destructive interference with unrelated work;
- connected-app permissions or another platform capability required for safe execution is unavailable.

Update the Issue's status/labels/dependencies/footprint as current policy requires, and set the watchdog state so the next hourly run does not falsely imply authorized progress.

## Platform and safety boundary

Use ordinary ChatGPT Scheduled Tasks and normal connected-app permissions only.

- do not create multiple equivalent runner tasks to bypass the maximum task frequency;
- do not attempt to bypass active-task, approval, usage, or safety limits;
- do not treat a previously granted connected-app permission as a permanent platform guarantee;
- if a run begins requiring approvals or loses a required connector capability, stop at the safe policy checkpoint rather than introducing an alternate bypass mechanism;
- if Scheduled Task behavior or permission requirements materially change, refresh the Issue/policy contract before autonomous execution continues.

## Activation / configuration verification

The runner may be activated only when the SAY-198 watchdog foundation is complete and this durable runner policy is available from the Project Context default branch.

After activation, verify that:

- exactly one nuinuiCAD autonomous runner Scheduled Task is active;
- its recurrence is hourly;
- its prompt points to the fixed Project Context README entrypoint and does not embed a policy copy;
- the next invocation can use the normal recovery/selection path described here.

## Loading rule

Read this document whenever:

- creating, updating, enabling, or inspecting the nuinuiCAD autonomous Scheduled Task; or
- executing a run from that Scheduled Task.

A scheduled runner run must also load [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) for execution ownership/reservation semantics and [`WATCHDOG.md`](./WATCHDOG.md) for heartbeat/recovery state semantics. Linear Issue operations continue to follow the Project Context Linear loading rules.
