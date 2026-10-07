# Voiceger Editor GitHub PR / CI Lifecycle

This document owns project-specific pull-request CI gating, merge progression, GitHub Auto-merge use, and Discord lifecycle notifications for `sayosomi/voiceger-editor`.

Generic remote/local verification, checkout, branch, commit, push, and pushed-state review mechanics remain owned by [Shared Git Workflow](../../shared/GIT-WORKFLOW.md). Do not duplicate those mechanics here.

## Authority

Use fresh GitHub state from `sayosomi/voiceger-editor` for implemented workflow files, current PR identity, head/base SHAs, check state, mergeability, and repository settings.

GitHub Issues in the product repository remain the current Work / implementation-contract authority. This document defines lifecycle mechanics, not product scope.

## Required CI surface

The stable merge-gate surface is the aggregate GitHub Actions job named `CI`.

The product workflow may run multiple internal jobs such as unit tests, Windows startup coverage, and package smoke tests. Merge orchestration should depend on the aggregate `CI` result rather than hard-coding the internal job list.

Repository settings must require `CI` on `main` before this policy is treated as active.

## Blocking review and merge progression

After implementation is pushed, ChatGPT performs the normal pushed-state blocking review before merge progression.

Immediately before a merge or Auto-merge reservation, refresh at least:

- PR open/non-draft state;
- exact PR head SHA;
- intended base and current remote `main`;
- mergeability;
- required `CI` state;
- unresolved review or contract blockers.

Then:

- required `CI` queued or in progress: Auto-merge may be reserved only when repository Auto-merge is enabled and the reservation mechanism safely targets the reviewed PR/head state;
- required `CI` successful: use the ordinary safe merge path;
- required `CI` non-success: do not merge.

Auto-merge is never a bypass. Do not use admin merge, force, required-check bypass, or an unsafe fallback because reservation is unavailable.

If the available Auto-merge mechanism cannot safely preserve the reviewed PR/head identity, do not reserve it; wait for the ordinary safe merge path after `CI` succeeds.

After a successful Auto-merge reservation, do not continuously poll for completion. A later CI failure leaves the PR unmerged and the Discord notification path surfaces the failure for Human-visible follow-up.

## Discord notifications

The product repository uses the secret:

`DISCORD_MERGE_WEBHOOK_URL`

The notification workflow reports:

- successful PR merge;
- non-success pull-request CI completion, with failed job/step details when available;
- an open non-draft PR becoming out of date with `main`.

Notifications are informational only. A Discord message does not authorize or trigger:

- automatic ChatGPT resume;
- CI rerun or cancellation;
- source repair;
- merge;
- Issue state mutation.

A failed notification workflow is not itself evidence that product CI failed. Inspect the authoritative product CI run separately.

## Out-of-date PR handling

An out-of-date notification means `main` advanced relative to the PR head. Re-run the normal fresh-main / interference judgment before merge progression.

Do not import nuinuiCAD declared-lane or integration-checkpoint semantics. Whether the branch itself must be updated remains a current Git/contract decision under the shared Git workflow and repository merge requirements.

## Repository setup prerequisites

This lifecycle requires repository configuration outside tracked source:

- GitHub Auto-merge enabled for `sayosomi/voiceger-editor`;
- stable required check `CI` configured for `main`;
- repository secret `DISCORD_MERGE_WEBHOOK_URL` configured.

If connected tooling cannot mutate or verify one of those settings, report the exact missing setup step instead of claiming the lifecycle is fully active.

## Project separation

Do not copy the following nuinuiCAD-specific machinery into voiceger-editor solely to support this lifecycle:

- Linear status automation;
- declared execution lanes;
- ChatGPT watchdog;
- change-based CI classifier;
- Discord-driven automatic resume or repair.

The reusable idea is the stable aggregate CI gate plus safe merge progression and Human-visible lifecycle notifications.
