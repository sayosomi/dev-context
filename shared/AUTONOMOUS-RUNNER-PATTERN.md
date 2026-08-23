# Shared autonomous ChatGPT runner pattern

## Purpose

This is a reusable design note for projects that want a user-created ChatGPT Scheduled Task to continue or start repository work autonomously.

It is not automatically active for every project. Each project should adopt only the parts that fit its own work-management system, repository rules, execution ownership model, and available ChatGPT capabilities.

The nuinuiCAD scheduled runner is the first concrete implementation of this pattern. Its project-specific policy remains authoritative for nuinuiCAD.

## Core architecture

Use three distinct layers instead of copying a large policy block into the Scheduled Task prompt:

1. **fixed Project Context entrypoint** — every run begins from one durable project README/router in the rules repository;
2. **project-specific owner policy** — selection, authorization, recovery, watchdog, merge, completion, and stop boundaries live in versioned policy documents reached from that entrypoint;
3. **small Scheduled Task prompt** — identifies the runner, requires loading the fixed entrypoint first, and contains only task-runtime hints that are impractical to express through repository state alone.

This keeps future runs on the latest policy without manually rewriting the task whenever project rules change.

## Authority split

Keep operational signals separate from sources of truth.

- latest remote repository: implementation / branch / PR / code facts;
- project work-management system: Issue state, dependencies, readiness, ownership metadata;
- watchdog state: execution liveness only;
- recent ChatGPT project conversations: **early duplicate-start signal only**, when available.

Recent conversation context must never become the authority for implementation facts or durable Issue state.

## Standing authorization must be explicit

A runner that is expected to finish work without user presence needs durable standing authorization for every action that ordinary chat policy would otherwise require the user to approve repeatedly.

At minimum, decide explicitly whether creating/enabling the runner grants standing authorization to:

- select and start an eligible work item;
- create/manage its branch and PR;
- merge its own PR after all normal pre-merge gates pass.

If merge normally requires explicit user authorization, failing to grant a narrow standing merge authorization causes the autonomous track to stop at an otherwise-ready PR.

Standing merge authorization should be narrow. It should apply only to PRs belonging to the runner's selected/recovered execution track and only after required CI, blocking review, freshness/interference checks, mergeability, branch protection, and other current project gates permit merge. It must not authorize force updates, protection bypasses, administrative overrides, or unrelated PRs.

## Recovery before new work

Each scheduled invocation should recover existing autonomous work before starting a new item.

Typical priority:

1. recover a timed-out unfinished runner track;
2. continue an active unfinished runner track that still has executable work;
3. only otherwise select a new eligible work item.

Never assume an interrupted in-memory operation succeeded. Reconcile persisted repository and work-management state first.

A scheduled invocation that finds no safe executable work may complete as a successful no-op.

## Parallel lanes and interference

Do not require a global concurrency limit unless the project genuinely needs one. A human-started ChatGPT lane and an autonomous runner lane can coexist when their semantic footprints are independent.

Parallel work should stop or yield when there is a concrete conflict, for example:

- the same Issue is already being executed by another ChatGPT track;
- unfinished dependency / unmerged base;
- same branch or ref ownership;
- incompatible writes to the same symbol, API, shared contract, parser/compiler boundary, data-flow owner, or other coupled semantic owner;
- overlap with an exclusive reservation;
- one track is likely to invalidate the other's Ready-contract facts before a safe refresh point;
- continuing would require rewriting or taking ownership of another track's work.

File overlap alone is only a warning signal. Different files can still conflict through a shared contract, and the same file can sometimes host independent changes.

## Duplicate-start guard with recent conversations

Connected work-management plugins can have enough propagation delay that two chats may briefly observe stale Issue state. For users who switch among several project chats frequently, checking only the single most recent conversation is insufficient.

Before selecting a **new** work item, the Scheduled Task prompt should instruct the runner to inspect the **recent available project conversation context across multiple recent conversations**, when that context is available.

Give strong weight to explicit signals such as:

- "start ISSUE-X" / "continue ISSUE-X";
- statements that ISSUE-X is currently being implemented;
- recent progress reports showing an execution track is still active.

If recent conversation context indicates that another chat may already have started the same Issue, treat that as a conservative early duplicate-start signal and choose another eligible non-interfering item. Do not create a second execution track merely because the formal work-management update has not propagated yet.

This conversation check is a supplement, not a replacement, for repository/work-management/watchdog/reservation checks. If conversation context is unavailable or ambiguous, fall back to those authoritative mechanisms.

## Reservation race handling

A robust start sequence should include a second interference check after publishing the new reservation/status update and before the first repository write.

Example:

1. inspect current repository, active work, PRs, and reservations;
2. choose a candidate and derive its semantic footprint;
3. publish the reservation / move the Issue to active state;
4. re-read active reservations and relevant remote state;
5. if a concrete conflict appeared, yield before the first write;
6. otherwise begin repository work.

This reduces races between two sessions that inspected the same pre-reservation state.

## Watchdog pattern

For long-running ChatGPT execution tracks, use a durable liveness record outside the chat itself.

Recommended properties:

- one stable state record per execution track;
- update the same record for heartbeats instead of appending one per heartbeat;
- states such as `active`, `timed_out`, and `done`;
- heartbeat before known long waits and periodically while active;
- an external timeout executor may alert on stale `active` records and transition them to `timed_out`;
- watchdog state is liveness evidence only, never the work-management authority.

On resume after timeout, inspect current persisted repository/work-management state before continuing.

## Per-run work limit

A useful safety rule is **at most one newly started work item per scheduled invocation**.

This should not limit progress on the chosen/recovered track. Once selected, the runner may continue implementation, CI, review, merge, watchdog, and work-management synchronization as far as current policy permits.

## Completion and handoff

Define explicit completion boundaries before enabling the runner.

A project should specify:

- when implementation/review/merge work is considered complete;
- whether a final Manual E2E or other environment-bound step remains;
- how labels/status change when autonomous web work is finished;
- what freshness check is required before marking Done;
- which conditions require stopping instead of guessing, such as a new product/UX/scope decision, unavailable local capability, destructive interference, or missing connector permission.

## Generic Scheduled Task prompt shape

Keep the prompt short and point it at current policy instead of embedding policy copies.

```text
Run the user-authorized <project> autonomous runner.
At the start of this run, load the latest Project Context from <fixed project README URL> and follow its current loading rules for recovery, selection, execution, watchdog handling, merge, and completion.
Before selecting any new work item, inspect the recent available <project> conversation context across multiple recent conversations for evidence that another chat already started or is actively working a candidate. Treat conversation context only as an early duplicate-start signal; if such evidence exists, do not create a separate track for the same work item. If conversation context is unavailable or ambiguous, continue with the authoritative repository/work-management/watchdog/reservation checks.
Do not rely on policy copied into this task.
```

Project-specific policy should define the actual eligibility, reservation, interference, merge, watchdog, and completion rules.

## Portability checklist

Before reusing this pattern in another project/repository, define all of the following:

- fixed Project Context entrypoint URL;
- repository implementation authority;
- work-management authority and readiness model;
- which work items are autonomous-eligible;
- standing start authorization;
- standing merge authorization and its gates;
- semantic reservation / interference model;
- same-Issue duplicate-start handling;
- whether recent multi-conversation context is available to the runner;
- watchdog location, states, heartbeat interval, timeout executor, and alert destination;
- recovery priority;
- per-run new-start limit;
- Manual E2E / environment-bound handoff policy;
- safe no-op behavior;
- stop boundaries for new decisions, unavailable capabilities, or destructive interference;
- task cadence supported by the current ChatGPT Scheduled Tasks platform.

Do not copy project-specific identifiers, repository names, issue hubs, webhook names, or stale platform limits into a new project's generic policy without revalidating them.