# nuinuiCAD ChatGPT watchdog operation

## Purpose

Long-running web ChatGPT development execution tracks can stop unexpectedly during CI waits, large-file work, tool failures, or context exhaustion. The watchdog records liveness directly on GitHub so an unexpected silent stop can be reported to Discord without routing periodic heartbeat writes through Linear or the Linear → GitHub Cloudflare mirror.

This is an execution-liveness mechanism, not a work-management authority. Linear remains the source of truth for Issue state and progress. The GitHub watchdog comment is GitHub-only operational state.

## When to use it

Use the watchdog for a web ChatGPT nuinuiCAD development execution track when the work can materially outlive one response/tool batch or includes a known long-wait / high-risk boundary.

Typical examples:

- waiting on GitHub Actions / CI;
- inspecting or editing large files or large diffs;
- repeated repository/tool operations where an interrupted response would otherwise be silent;
- a long implementation / review / merge sequence spanning many tool batches.

Do not arm the watchdog for ordinary short conversation, research, or one-shot inspection where a timeout alert would be noise.

## State hub

Use `sayosomi/nuinuiCAD` GitHub Issue #514 as the watchdog state hub.

- Use one GitHub Issue comment per active Linear Issue / ChatGPT execution track.
- Reuse and update the same watchdog comment; do not append one comment per heartbeat.
- Never store heartbeat state in the GitHub Issue body. The body is owned by the Linear → GitHub mirror.
- Watchdog comments are GitHub-only. They must not contain `linear-comment-id` mirror markers and must not be copied into Linear merely to persist heartbeat state.
- GitHub-only comments are preserved by the current mirror contract.

The hub may be closed after SAY-198 completes. Comments on a closed GitHub Issue remain valid operational state.

## Record format

The watchdog executor recognizes version 1 records in this exact comment shape:

```text
<!-- chatgpt-watchdog:v1
{"marker":"chatgpt-watchdog:v1","linear_issue":"SAY-198","title":"ChatGPT watchdog — GitHub heartbeat + 5-minute GitHub Actions stalled-session alert","url":"https://linear.app/sayosomi/issue/SAY-198/chatgpt-watchdog-github-heartbeat-5-minute-github-actions-stalled","state":"active","started_at":"2026-08-23T09:00:00.000Z","heartbeat_at":"2026-08-23T09:05:00.000Z"}
-->
ChatGPT watchdog: `SAY-198` — **active**
Last heartbeat: `2026-08-23T09:05:00.000Z`
Linear: https://linear.app/sayosomi/issue/SAY-198/chatgpt-watchdog-github-heartbeat-5-minute-github-actions-stalled
```

Required JSON fields:

- `marker`: exactly `chatgpt-watchdog:v1`
- `linear_issue`: Linear Issue identifier
- `title`: current Linear Issue title
- `url`: direct Linear Issue URL
- `state`: `active`, `timed_out`, or `done`
- `started_at`: UTC ISO-8601 timestamp for the current execution-track start
- `heartbeat_at`: UTC ISO-8601 timestamp for the most recent explicit heartbeat
- `timed_out_at`: required by the executor when `state` is `timed_out`; omit it for a normally active record

The visible lines are for human inspection. The JSON payload is authoritative for the watchdog executor.

## ChatGPT operating sequence

### Start / resume

When a qualifying execution track starts:

1. Find the existing watchdog comment for that Linear Issue / execution track, if one exists.
2. Create it if absent; otherwise update the same comment.
3. Set `state: active`.
4. Set both `started_at` and `heartbeat_at` to the current UTC ISO-8601 time.
5. Remove any previous `timed_out_at`.

A resumed track after a previous timeout is a new explicit start and therefore gets a new `started_at`.

### Heartbeat

While active:

- update `heartbeat_at` approximately every 5 minutes; exact timing is not required;
- also heartbeat immediately before a known high-risk / long-wait boundary such as CI waiting, large-file inspection/editing, or another operation where an interrupted response would otherwise be silent;
- keep `started_at` unchanged;
- set/keep `state: active`;
- remove `timed_out_at` if the record had previously timed out. A heartbeat after `timed_out` therefore re-arms monitoring.

Heartbeat writes go directly to the GitHub Issue comment. Do not write a Linear Comment and do not involve the Cloudflare mirror path.

### Done / handoff

Set `state: done` when the current ChatGPT execution track is intentionally finished or deliberately handed off at a known checkpoint where no silent-progress alert is desired.

Do not mark `done` merely because one tool call, one response, or one intermediate commit completed while the execution track is still expected to continue.

## Timeout executor

The repository workflow is the timeout authority.

- State hub: GitHub Issue #514
- Timeout threshold: 15 minutes since explicit `heartbeat_at`
- Final schedule after activation: `*/5 * * * *`
- Scheduler timing is best-effort; GitHub Actions delay can make detection later than the nominal threshold.
- `workflow_dispatch` is retained for deterministic verification.
- Repository `GITHUB_TOKEN` reads and updates watchdog comments.
- Existing `DISCORD_MERGE_WEBHOOK_URL` is reused for timeout notifications.
- No Linear API key is required by the watchdog executor.

For an expired `active` record the executor:

1. sends one Discord alert identifying the Linear Issue, title, last heartbeat, and direct Linear URL;
2. after the alert succeeds, updates the same comment to `state: timed_out` and sets `timed_out_at`;
3. ignores that record on later polls until a new heartbeat/start makes it `active` again.

`timed_out` and `done` records never alert. A malformed watchdog record is logged and isolated so other valid records are still processed.

The workflow uses a single concurrency group so scheduled and manually dispatched runs do not intentionally execute the watchdog body concurrently.

## Failure boundary

If ChatGPT cannot safely create/update the watchdog comment with the available GitHub capability, do not pretend that the track is armed. Continue only as allowed by the current Task contract and surface the missing watchdog write capability at the next safe checkpoint.

A watchdog alert indicates missing ChatGPT heartbeat, not proof that repository work failed. On resume, inspect current remote state before continuing according to the normal development workflow.

## Loading rule

Read this document when a nuinuiCAD web ChatGPT development execution track is expected to materially outlive one response/tool batch or reaches a known long-wait / high-risk boundary. Do not load it for routine short conversational/research turns.
