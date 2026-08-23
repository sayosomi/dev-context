# nuinuiCAD scheduled `only_chatgpt` runner

## Purpose

A single user-created ChatGPT Scheduled Task may autonomously continue or start eligible nuinuiCAD `only_chatgpt` work while the user is away.

This runner is intentionally limited to **already-decomposed direct GitHub + CI suitable work**. It does not take a broad feature and force the whole feature through autonomous ChatGPT implementation.

Large Work is decomposed under [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) / [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md). The runner consumes the eligible `only_chatgpt` leaves / current slices produced by that policy and stops at safe checkpoints when the remaining shape belongs to another execution route.

This document owns periodic selection, standing start / merge authorization, recovery priority, and scheduled-run continuation. Execution ownership is [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md); liveness is [`WATCHDOG.md`](./WATCHDOG.md); Linear status is [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md).

The runner is an ordinary ChatGPT Scheduled Task. Do not add another daemon, browser automation, Tampermonkey script, or external scheduler.

## Single runner

Maintain exactly one Scheduled Task for autonomous nuinuiCAD `only_chatgpt` execution.

- cadence: once per hour;
- do not create staggered duplicate tasks to simulate sub-hour cadence;
- every run starts by loading the latest Project Context entrypoint from GitHub:
  `https://github.com/sayosomi/dev-context/blob/main/projects/nuinuiCAD/README.md`;
- after loading that README, follow its current loading rules instead of relying on policy copied into the task prompt;
- use only connected GitHub / Linear capabilities available to the Scheduled Task.

The Scheduled Task prompt should remain small: identify this runner, require loading the fixed Project Context README, then follow current policy for recovery / continuation / candidate selection. Do not embed a stale policy copy in the task prompt.

## Standing start and merge authorization

Creating this Scheduled Task is standing authorization for the task to:

- select and start an eligible `only_chatgpt` leaf / current slice;
- create and manage PRs for that selected / recovered autonomous track;
- merge those PRs when current Project Context gates permit merge.

This is the narrow Scheduled Task exception to the ordinary explicit-start / merge-authorization rules. It applies only to the runner-selected eligible autonomous track.

The Scheduled Task may newly start a candidate only when:

- it is the user-created runner governed by this document;
- candidate is a leaf / non-parent Issue with `only_chatgpt`;
- `Contract: Ready` remains fresh;
- Manual E2E state permits implementation;
- no unfinished blocker exists;
- current `only_chatgpt` suitability still passes, including direct GitHub + CI execution-loop suitability;
- reservation / interference gate passes.

A merge is covered by standing authorization only when:

- PR belongs to the current eligible autonomous track;
- required implementation, automated verification / CI, blocking review, main-advance checks, and other pre-merge gates pass;
- PR head / base / mergeability are refreshed immediately before merge;
- no protection / blocker / current policy forbids merge;
- no force update, protection bypass, destructive unrelated-work takeover, or administrative override is required.

Standing authorization does not apply to arbitrary scheduled prompts, ordinary chat turns, unrelated PRs, non-`only_chatgpt` work, or a slice that has ceased to satisfy `only_chatgpt` suitability. It does not authorize guessing through product / UX / scope decisions, local-only work, or unsupported execution methods.

## Recovery before new work

Before starting new work, inspect watchdog state according to [`WATCHDOG.md`](./WATCHDOG.md) and reconcile it with current Linear + GitHub state.

Priority:

1. unfinished `only_chatgpt` autonomous track whose watchdog is `timed_out`;
2. unfinished `active` autonomous track that still has an eligible direct GitHub + CI slice;
3. only when no recoverable / continuable autonomous track exists, select a new eligible Todo `only_chatgpt` leaf.

Watchdog is liveness evidence, not work-management authority. For every recovery candidate, re-read current Linear labels / status / dependencies and remote repository / branch / PR state.

For a `timed_out` track, resume only from state actually persisted remotely. Never assume an interrupted in-memory write, CI action, merge, comment, label update, or status update succeeded. Once execution actually resumes, re-arm / heartbeat the watchdog according to `WATCHDOG.md`.

If watchdog state is stale relative to authoritative remote state, follow the authoritative state. Do not manufacture work merely to match the watchdog record.

If persisted branch / PR work proves an earlier checkpoint incorrectly returned an unfinished track to `Todo` or watchdog `done`, treat it as recoverable unfinished work when current policy still authorizes that current slice. Repair the work-management / watchdog state and recover it before selecting a new Issue.

If the persisted track's remaining work has changed execution shape and no longer qualifies for `only_chatgpt`, do not recover it as autonomous implementation. Reconcile to a safe handoff checkpoint and end the autonomous watchdog track.

## New candidate selection

When recovery does not take precedence, choose from current Todo leaves satisfying normal `only_chatgpt` eligibility.

Before selection:

- inspect latest remote repository state;
- inspect active implementation Issues and Parallel footprints;
- inspect relevant open branches / PRs;
- refresh candidate `Contract: Ready` facts;
- confirm that the candidate is a natural independently verifiable leaf / current slice rather than a broad unresolved implementation shape.

Prefer candidates with:

- bounded semantic footprint;
- clear automated acceptance;
- strong direct GitHub + CI execution suitability;
- low concrete interference risk.

Do not choose solely by issue number, age, apparent diff size, or available local worktree capacity.

If a broad Ready Issue appears promising but is not yet decomposed enough to qualify, the runner may inspect and record that it needs decomposition, but it must not invent leaf Issues or rewrite product scope merely to create runner work. Decomposition that follows uniquely from current authority may be performed only when ordinary work-management policy permits it; otherwise skip the candidate.

Before first write, run the full reservation protocol in `ONLY-CHATGPT.md`.

If no safe eligible candidate exists, no-op is successful.

## At most one new Issue per run

One scheduled invocation may newly start at most one `only_chatgpt` Issue.

This limits **new starts**, not progress on the selected / recovered track. Continue the current slice as far as safely possible within the invocation, including repository writes, CI / review / merge, watchdog updates, and Linear synchronization.

Do not start a second Issue in the same invocation only because the first finished quickly.

## Mid-track decomposition / route change

The runner must re-run implementation slicing / route classification at the normal triggers from `IMPLEMENTATION-SLICING.md` and `ONLY-CHATGPT.md`.

Typical triggers:

- broad/full test exposes multiple failure classes;
- implementation wants a new semantic owner / API / data-flow boundary;
- current PR reaches a safe merge checkpoint with substantial remaining acceptance;
- repeated fix loops expand beyond the original footprint;
- `main` advance changes the remaining implementation shape;
- Manual E2E failure returns implementation work.

When a safe next boundary exists:

```text
current only_chatgpt slice
-> verify / review / merge or persist handoff checkpoint
-> classify next slice independently
```

If the next slice is still `only_chatgpt`, continue / recover under normal runner rules.

If the next slice is better suited to Coding Agent or requires local-only work:

- do not continue merely because the Issue itself still exists;
- persist completed / remaining acceptance and next semantic boundary;
- release the current Parallel footprint when implementation ownership ends;
- remove `only_chatgpt` if the current next executable slice is no longer direct-GitHub suitable;
- leave the Issue in the normal Ready / active state required by Linear policy;
- set watchdog `done` for the autonomous track;
- hand off the next implementation slice to the standard Coding Agent workflow outside this runner.

Route change is a successful safe stop, not runner failure.

## Watchdog integration

After selecting or recovering an autonomous track:

- arm / reset watchdog to `active`;
- heartbeat while actively continuing and before high-risk / long-wait boundaries;
- write heartbeat state only through the watchdog mechanism defined by `WATCHDOG.md`;
- after timed-out recovery, re-arm the same track.

An hourly invocation boundary is not itself a stop boundary.

If the same `only_chatgpt` slice remains unfinished and eligible for the next run, persist remote state, keep Issue `In Progress`, keep watchdog `active`, and require next invocation to recover it before starting new work.

Do not return an unfinished eligible track to `Todo` or mark watchdog `done` merely because the current Scheduled Task invocation ended. `Todo + watchdog done + unfinished autonomous Draft PR/branch` is invalid unless an independent current policy reason intentionally ended autonomous ownership.

Set watchdog `done` when:

- autonomous implementation / review / merge / management work is complete;
- current slice is intentionally handed off to another execution route at a safe checkpoint;
- current policy removes authorization to continue autonomously.

## Completion and Manual E2E handoff

When implementation / review / merge / management work is complete:

- required Manual E2E remains → transition immediately according to `ONLY-CHATGPT.md` to `manual_e2e_only + In Review`, then finish watchdog track;
- Manual E2E `Not Required` → perform Done-before Ready contract freshness check and complete the Issue;
- synchronize Linear metadata at the same logical checkpoint.

A later Manual E2E implementation failure does not automatically restore the whole Issue to autonomous execution. `ONLY-CHATGPT.md` / `IMPLEMENTATION-SLICING.md` first isolate the failure class and classify the fix slice. The runner may recover it only if that resulting slice actually qualifies for `only_chatgpt`.

## Stop boundaries

Stop autonomous execution at a safe checkpoint when:

- new product / UX / scope / compatibility decision is required;
- implementation requires unavailable local / external capability;
- remaining slice is better suited to standard Coding Agent execution;
- required external manual operation outside final Manual E2E appears;
- continuing requires destructive interference with unrelated work;
- connected capability required for safe execution is unavailable.

Synchronize labels / status / dependency / footprint and watchdog state so the next run does not falsely imply autonomous progress.

## Platform and safety boundary

- use ordinary ChatGPT Scheduled Tasks and connected-app permissions only;
- do not create duplicate runners to bypass frequency limits;
- do not bypass approvals, usage, safety, branch protection, or permissions;
- if required connector capability changes, stop at a safe checkpoint rather than inventing a bypass;
- if Scheduled Task behavior materially changes, refresh policy before continuing.

## Activation / configuration verification

The runner may be active only when its required watchdog foundation and durable policy are available from the default Project Context branch.

Verify:

- exactly one autonomous runner is active;
- recurrence is hourly;
- prompt points to the fixed Project Context README and embeds no stale policy copy;
- next invocation can use recovery / selection / decomposition-aware stop rules.

## Loading rule

Read this document whenever:

- creating, updating, enabling, or inspecting the autonomous Scheduled Task; or
- executing a run from it.

A run also loads `ONLY-CHATGPT.md` and `WATCHDOG.md`; implementation decomposition uses `IMPLEMENTATION-SLICING.md`; Linear operations follow the Project Context Linear loading rules.
