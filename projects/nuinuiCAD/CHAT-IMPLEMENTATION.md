# nuinuiCAD Implementation chat

## Purpose and route selection

このchatは、承認されたWorkのimplementation、blocking fix、verification、integration、independent blocking
review、PR/merge、後続処理を調整する。**Chatは実行状態の正本ではない。**
現在のIssue、GitHub、実checkoutから状態を再構築する。[CHAT-WORKFLOW.md](./CHAT-WORKFLOW.md)がrotationとchat間handoffをownerする。

- **New GitHub-native Issue:** D1 Git-only route is active. Current scope/acceptance is the
  `sayosomi/nuinuiCAD#N` Issue body; material decisions/checkpoints are Issue comments. Use
  [CHECKOUTS.md](./CHECKOUTS.md) and [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md), not legacy SAY `nuinui
  begin/handoff/release` or Linear lifecycle. The historical activation/pilots are recorded in
  [dev-context #268](https://github.com/sayosomi/dev-context/issues/268); no per-Task D1 activation is
  required.
- **Compatible pre-existing SAY only:** Continue the already-admitted legacy generation and its minimum Linear
  checkpoint lifecycle until [dev-context #286](https://github.com/sayosomi/dev-context/issues/286) safely
  retires it. Follow the separate legacy section below. Do not treat chat creation or rotation as a new lane
  claim.
- **Implementation executor:** [CODING-AGENT.md](./CODING-AGENT.md) owns the lower-tier default (e.g. Luna)
  and Human-explicit upper-tier choice (e.g. Astra / Sol Xhigh), selected outside the prompt. Explicit
  upper-tier selection is not the separate Issue-body opt-in required for autonomous conformance
  discovery/repair. That opted-in mode remains D1 implementation, not D2-C read-only auditing.
- **Direct execution:** [CODING-AGENT.md](./CODING-AGENT.md) alone defines the documentation/policy and narrow
  CI/tooling exceptions. Both require the Human's explicit plan/target/change approval and fresh remote/target
  checks before write; neither claims an implementation lane. If product source/runtime/DSL semantics, broad
  debugging, conflicts or integration-heavy work emerge, stop direct execution and return to the authorized
  implementation Coding Agent route.
- **Manual E2E:** Human alone executes and judges under [MANUAL-E2E.md](./MANUAL-E2E.md). Native GitHub E2E is active after the reviewed #286 checkpoint, subject to fresh [CHECKOUTS.md](./CHECKOUTS.md), [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) and [ISSUES.md](./ISSUES.md) admission/evidence. No separate E2E chat role is needed. Host readiness, CI or PR merge cannot establish Human E2E PASS.

## GitHub-native start and resume

1. ChatGPT re-reads the canonical Issue body and material comments, remaining acceptance, decisions and
   dependencies; re-audits readiness against latest remote product `main`, normative specs, actual
   implementation and relevant dev-context owners. Verify relevant D2-C audit start/stop and independent
   final-checkout proof, including unmatched or unresolved audit/ownership exclusions. Settle the
   implementation slice and verification with [IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md);
   prepare the complete prompt for the Human-selected Coding Agent using
   [shared Coding Agent workflow](../../shared/CODING-AGENT-WORKFLOW.md) and
   [prompt style](../../shared/AGENT-PROMPT-STYLE.md), then supply exact new-Task or same-Task
   continuation arguments. Chat summaries are not authority; [ISSUES.md](./ISSUES.md) owns
   Work/contract checkpoints.
2. Human confirms no otherwise-unobservable competing implementation, evaluator or E2E activity and runs
   **one** read-only `nuinui-checkout-check` invocation for `new` or `continue`, as routed by
   [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md). Only use `--human-clear` when that assertion is true;
   [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) owns exact command syntax. `LOCAL CHECK PASS` is local evidence at
   check time, **not** Issue authorization. Legacy SAY `nuinui preflight FREE` is not native admission.
3. The selected Coding Agent consumes that PASS and the prepared implementation prompt and,
   **immediately before branch or source mutation**, runs
   the existing `git fetch origin --prune` and only the bounded volatile recheck: expected remote
   `main`/topic checkpoint, local branch/HEAD/cleanliness, conflicting live ownership and PASS freshness.
   Stale/expired proof, drift, a wrong or missing pushed checkpoint, unexpected/dirty checkout, or
   unresolved audit/E2E/legacy ownership stops. Do **not** reconstruct the full Human
   manifest/worktree/legacy-metadata inventory or demand another approval.
   [CHECKOUTS.md](./CHECKOUTS.md) owns physical admission and all stop/recovery rules.
4. After those gates, start only the authorized unused topic branch for a new Task, or resume the exact
   pushed same-Task checkpoint; never silently switch Task identity or repair an ambiguous checkout.
   The Agent implements only the authorized slice, verifies, commits intended files and non-force
   pushes the exact topic branch.
5. Independently review the **exact pushed HEAD** rather than trusting the agent's self-report. Resolve
   genuine failures and material contract/owner ambiguities before moving to the protected PR/CI/merge gate.

A chat change, implementation-agent session change, or lost terminal output is not a Task restart. Refresh
current Issue and remote evidence; if local admission must be re-established, use the same one-command
route instead of a separate full checkout inventory. Do not automatically repeat a commit/push/merge or
discard a changed checkout.

## Review, merge and completion

- [LINEAR-GITHUB.md](./LINEAR-GITHUB.md) alone owns PR linking, independent review, required CI, head/base
  freshness, safe auto-merge and ordinary merge. Use `Refs #N` for intermediate or incomplete acceptance;
  `Closes #N` only when the merge meets **all** acceptance, including any required Human Manual E2E.
- When required CI is still running, only the policy's exact owner-authored `/auto-merge-reviewed` reservation
  may be used after a PASS review and fresh eligibility proof. Verify reservation read-back, then end that
  execution track without waiting/polling. A Discord bot merge/CI-failure notification does **not** authorize
  automatic continuation: resume only on Human instruction and fresh evidence. When required CI is already
  successful, perform a fresh merge-gate review and use the ordinary protected merge. Ambiguous, failed or
  missing required checks block; do not bypass or blindly retry.
- After verified merge, read back authoritative GitHub `main`, PR/commit and Issue acceptance, record material
  checkpoints, and return the implementation checkout safely to its normal clean state using
  [CHECKOUTS.md](./CHECKOUTS.md)'s reset-free Git-only transition. Do not create Linear status/checkpoint or
  SAY claims for native Work.
- Merge is not automatically Issue completion. Required Human Manual E2E or any other remaining acceptance
  stays open and is handed to the relevant owner. Never equate E2E host setup, automated verification or a PR
  merge with Human PASS. Follow [ISSUES.md](./ISSUES.md) for evidence and Issue closure.

When ChatGPT can complete independent remote read-back, blocking review, PR/CI routing or Issue bookkeeping
with available tools, do not introduce gratuitous Human handoff steps. Return to the Human for genuine
product/UX/scope decisions, required approval or observation, unsafe local state/destructive risk, uncertain
contract, or a concrete unavailable tool/action.

## Compatible pre-existing SAY start and continuation only

The following rules apply **only** when the Task was already admitted into the legacy `nuinui` lifecycle.
[CHECKOUTS.md](./CHECKOUTS.md) owns its durable lane state/recovery;
[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md) owns handoff identity; [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) owns
the exact command syntax; [LINEAR-ISSUES.md](./LINEAR-ISSUES.md) owns minimum legacy checkpoints.

- Re-read remote/Issue contract, applicable historical Linear checkpoint and actual lane state. A request to
  start/resume must lead to actual execution or the **first complete actionable Human command**, not a
  needless extra preflight round trip. Never ask the Human to repeat fresh evidence already supplied.
- If local legacy lane startup is required, use the canonical named-argument `nuinui begin-command` generator.
  The Human executes its generated exact `nuinui begin` line **in the same terminal**, without reconstructing
  arguments or returning the line to ChatGPT. Mark Linear `In Progress` and save the `Implementation
  checkpoint` / durable claim only **after** verified `IMPLEMENTATION STARTED` success and post-write
  read-back; a mere planned start is not `In Progress`.
- Give the selected Coding Agent the exact `nuinui handoff <SAY-N> <expected-main-sha>` command. The agent
  executes it first; its façade derives lane, branch, Base, claim and remote-topic mode from verified durable
  evidence, not caller guesses. After `HANDOFF VERIFIED`, proceed with implementation. Failure blocks and
  returns to the appropriate owner; no automatic resume or blind retry. The Human does not run the agent's
  handoff or manage prompt/claim/token files.
- Continuing the same durable generation across chat rotation, agent changes, blocking review/fix, integration
  or remote `main` changes does **not** by itself require a new `begin`, claim, or Human handoff. Refresh
  contract/remote identity and continue with the assigned generation.
- If a tracked local mutation's terminal output disappears, use the **read-only** `nuinui last-result` first.
  A matching verified `recovery=READY` and `result=SUCCESS` permits continuation; `BLOCKED`/`ERROR` follows
  that evidence; `NONE`/`INVALID`/`INCOMPLETE` or identity mismatch requires existing diagnosis, not mutation
  replay. Never infer lane `FREE` from missing output.
- At a settled integration checkpoint, eligible conflict-free merge-only work may use Human `nuinui
  integrate-clean` under [IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md),
  [CODING-AGENT.md](./CODING-AGENT.md), and [LOCAL-TOOLS.md](./LOCAL-TOOLS.md). Integration drift/Review Head
  and focused review/CI obligations remain. Conflicts, relevant semantic drift, source change, failed
  verification or ambiguous diagnosis return to the implementation Coding Agent; do not force Human retries.

### Legacy merge, release and E2E barrier

- Use the same independent pushed-HEAD review, protected PR and CI policy in
  [LINEAR-GITHUB.md](./LINEAR-GITHUB.md). Work completion and physical lane release are distinct.
- When merge is authoritatively confirmed, the Human runs the named `nuinui release-command --lane
  <implementation-lane> --issue <SAY-123> --claim <durable-claim>` generator and executes its generated exact
  positional release line **in the same terminal**. Do not transcribe main/merge SHA into a guessed topic
  checkpoint, reorder arguments or substitute a claimless signature. [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) and
  [CHECKOUTS.md](./CHECKOUTS.md) own generator identity, mutation-time proof, duplicate receipts and recovery.
- If required Human Manual E2E alone remains after merge, **release the completed implementation generation
  first**, confirm `IMPLEMENTATION RELEASED` and read back its `Lane release checkpoint`; synchronize the
  minimum applicable Linear `In Review` status; only then admit an E2E run. Do not retain the old
  implementation claim while waiting for a Human-test checkout, and do not treat a BUSY Human-test lane as
  justification to postpone release.
- If release is interrupted or fails, never guess physical `FREE`, revive the old claim, reset metadata, or
  start E2E until the actual release/cleanup is verified under [CHECKOUTS.md](./CHECKOUTS.md). Merged+E2E-only
  Work can remain `In Review` during release recovery; do not incorrectly revert it to `In Progress` because
  the physical checkout is still BUSY/BLOCKED/RELEASE-PENDING.
- Declare **final closure** only after required acceptance and Human E2E finish, the actual legacy lane is
  proven `FREE`, required Linear status and Lane release checkpoint are recorded, and
  [LINEAR-ISSUES.md](./LINEAR-ISSUES.md)'s post-write verification succeeds. A successful physical release is
  not undone because Linear bookkeeping fails. Do not demand a duplicate preflight solely to re-prove a
  complete successful release envelope.

## Chat rotation, loading and maintenance

Rotation does not change Task status, Base, branch, slice, claim or lane occupancy. Reconstruct the present
authoritative state, and use actual pause/release policy only if Work itself pauses. See
[CHAT-WORKFLOW.md](./CHAT-WORKFLOW.md).

Read this document and [CHAT-WORKFLOW.md](./CHAT-WORKFLOW.md) for implementation-chat lifecycle; load the
phase-specific owners through [README.md](./README.md). Keep checkout state machines, agent eligibility,
slicing, command mechanics, PR/CI and Linear status details in their existing canonical documents rather than
copying them here.
