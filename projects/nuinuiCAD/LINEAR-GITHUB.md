# nuinuiCAD GitHub PR linking and merge policy

## Scope and authority

This document owns the **active GitHub-native** PR linking, independent pushed-HEAD
review, required CI, protected merge, and GitHub Actions auto-merge reservation
for `sayosomi/nuinuiCAD`. General D1 Git-only activation is complete;
new native Issues do not use the legacy SAY / `nuinui` execution lifecycle.

Work contract, acceptance, and Issue closure: [`ISSUES.md`](./ISSUES.md).
Slice and integration checkpoints: [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md).
Checkout/startup ownership: [`CHECKOUTS.md`](./CHECKOUTS.md) and
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md).
Human-only E2E: [`MANUAL-E2E.md`](./MANUAL-E2E.md).
Compatible pre-existing SAY operations are historical only; see the final section.

## GitHub-native PR linking and sequential PRs

Read the canonical GitHub Issue body/comments and latest product repository.
Put `Refs #N` in the PR description while acceptance remains outstanding;
GitHub Issue numbers are not SAY identifiers, and branch names need not contain
either identifier.

Use `Closes #N` **only** when that PR's merge plus already completed,
independently verified acceptance satisfies the entire Issue, including any
required Human Manual E2E. Otherwise keep `Refs #N` and the Issue open.
Do not use a closing keyword just to make GitHub integration show a link.

For multiple sequential PRs on one Issue, follow
[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md):
- Intermediate PR: `Refs #N`, coherent merge checkpoint, no Issue closure.
- After intermediate merge: record PR URL, verified checkpoint, and remaining
  acceptance in the GitHub Issue comment; verify the latest intended base
  before starting the next slice.
- Final PR: `Closes #N` only if the full-acceptance condition above is met.
  A final implementation PR may still need `Refs #N` when E2E remains.

## Review, CI, and merge authorization

Human instruction to start Work or continue its execution track authorizes
its normal **safe implementation, PR operations, protected merge, and completion
record**, including intermediate and final PRs. No additional per-PR merge
approval or per-Task D1 activation is required. Stop for a genuine new
product/UX/scope decision, lost contract readiness, unresolved required failure,
unsafe owner/interference conflict, destructive operation, or ambiguous state;
do not introduce a redundant approval template or checkpoint.

For each merge or auto-merge reservation:
- Meet the slice's merge checkpoint and required focused verification.
- Independently review the **exact pushed HEAD**, not the Coding Agent's
  self-report. A subsequent pushed code change needs applicable verification
  and exact-HEAD re-review.
- Freshly check the canonical Issue, PR/head/base, authoritative remote `main`,
  relevant post-integration drift, mergeability, and required protection/CI.
  Follow the integration watermark and `NON-INTERFERING` drift rules in
  [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md); do not routinely
  reintegrate `main` just because it advanced.
- Never merge with unresolved blocker, failed or unproven required checks,
  head/base ambiguity, or an unexpected ownership/contract change. Do not
  bypass branch protection or substitute agent-reported CI evidence.

When all required CI is **already successful**, do not request auto-merge.
Freshly verify the PR, reviewed HEAD, current `main`, drift, required CI,
mergeability, and existing authorization; use the ordinary protected merge.
A CI failure, cancellation, unresolved/skipped required check, or unknown
status is not permission to merge.

## GitHub Actions auto-merge reservation — CI pending

For `sayosomi/nuinuiCAD`, when required `CI` is still queued/in_progress
and an independent blocking review of the pushed exact HEAD is **PASS**,
ChatGPT may post **one** owner-authored PR Conversation comment with this
exact four-line body (40-character lowercase SHA values):

```text
/auto-merge-reviewed
head=<reviewed 40-character lowercase SHA>
base=<fresh authoritative main 40-character lowercase SHA>
review=PASS
```

`review=PASS` attests to the actual ChatGPT blocking review; the comment is
not a substitute for review. Only `sayosomi` as repository OWNER submits it,
not the implementation agent. The workflow obtains the PR number from the
comment's PR context.

Before the comment, prove from fresh GitHub state:
- PR is open, non-draft, targets `main`, and both head/base repositories are
  `sayosomi/nuinuiCAD`; reviewed HEAD equals the current PR head.
- Supplied `base` is the **current** authoritative `main` SHA (PR
  `baseRefOid` alone is insufficient). Unlike ordinary non-interfering drift,
  this reservation workflow requires current `main` to be an ancestor of
  reviewed HEAD; mergeability is unambiguous and no reservation exists.
- Actual protected required check is GitHub Actions App `CI`. Exactly the
  reviewed HEAD's unambiguous `pull_request` CI workflow run is pending,
  no CI job has failed, and the required `CI` aggregator has not concluded.
  The aggregator check may not yet have materialized while its workflow is
  demonstrably in progress; that fact alone does not block reservation.
- Missing/multiple or ambiguous runs, status, permission, API data, checks,
  identities, or protection proof fail closed.

The OWNER comment triggers
[`.github/workflows/auto-merge-reviewed.yml`](https://github.com/sayosomi/nuinuiCAD/blob/main/.github/workflows/auto-merge-reviewed.yml).
It rechecks eligibility immediately before mutation and calls
`enablePullRequestAutoMerge(expectedHeadOid, mergeMethod: MERGE)` to
**reserve**, never to directly merge. No `mergePullRequest`,
`gh pr merge --auto`, force/admin/bypass, or direct-merge fallback is allowed.

Call the reservation successful only after both the workflow's success output
and fresh PR read-back prove `auto_merge.merge_method=merge` and
`enabled_by=github-actions[bot]`. A comment or started workflow is not proof.
If the workflow fails, state is ambiguous, or a reservation is unexpected,
investigate before reposting, canceling, or replacing anything.

If required CI completes before the reservation mutation, the workflow
fails closed; it must not directly merge. Only if fresh evidence establishes
the ordinary merge conditions and existing authorization may ChatGPT use
the separate ordinary merge route. Head/main drift, identity ambiguity, or
CI failure is **not** a harmless CI-completion race.

## Notification, resume, and Issue completion

After verified reservation, do not wait/poll for CI in chat: end that execution
track. GitHub performs the protected merge after required CI becomes green.
[`discord-bot-automerge-reconcile.yml`](https://github.com/sayosomi/nuinuiCAD/blob/main/.github/workflows/discord-bot-automerge-reconcile.yml)
reconciles bot merges, notifies Discord, records a durable GitHub receipt, and
has a bounded scheduled fallback for missed notifications.
[`discord-merge-notification.yml`](https://github.com/sayosomi/nuinuiCAD/blob/main/.github/workflows/discord-merge-notification.yml)
also reports CI failures.

Discord success/failure notifications do **not** authorize automatic resume,
rerun, repair, merge, or Issue/status update. Continue only on explicit Human
resume, with fresh PR/head/base/CI/contract/authoritative-merge evidence.
Do not assume a failure is flaky or blindly retry; apply the existing
CI-incident and blocking-fix ownership rules.

A reservation or PR merge alone does not close an Issue. After confirmed merge,
read back authoritative `main`, PR/merge commit, remaining acceptance, and
Human Manual E2E state; use [`ISSUES.md`](./ISSUES.md) for Issue completion.
Required Manual E2E is Human-only and **post-merge by default**; when it remains,
leave the Issue open. Explicit pre-merge E2E exceptions that failed unresolved
block merge. Do not treat host preparation, CI, or PR merge as E2E PASS.

## Compatible legacy SAY and completed cutover — historical references only

No new Linear/SAY Work, Linear status synchronization for native Issues,
mirror repair, or old `nuinui pr-auto-merge` route is authorized here.
For actually pre-admitted compatible SAY generations, retain the original
PR linking (including `Fixes SAY-N`), exact release/recovery and minimum Linear
checkpoint semantics under [`LINEAR.md`](./LINEAR.md),
[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md),
[`CHECKOUTS.md`](./CHECKOUTS.md), and
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md).
Do not interpret those rules as a new GitHub-native execution route.

The **immutable pre-simplification policy**
[`LINEAR-GITHUB.md` at `402c93e80a524a46b9f9f9c3a717c8a585b3b57c`](https://github.com/sayosomi/dev-context/blob/402c93e80a524a46b9f9f9c3a717c8a585b3b57c/projects/nuinuiCAD/LINEAR-GITHUB.md)
preserves the complete old PR/Linear status ordering, Linear PR automations,
and completed #268 Phase B `Refs sayosomi/dev-context#268` exception.
The disabled mirror and provenance are historical under
[`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md); never restart mirroring.
