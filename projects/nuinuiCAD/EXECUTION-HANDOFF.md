# nuinuiCAD implementation startup and continuation

This document routes **active GitHub-native D1** implementation startup and
same-Task continuation. Physical admission and safe Git transitions belong to
[CHECKOUTS.md](./CHECKOUTS.md); this document does not duplicate that proof.

## Active D1 route

GitHub-native Git-only D1 is active following the completed
[dev-context #268](https://github.com/sayosomi/dev-context/issues/268)
checkpoint. There is no new per-Task activation or separate approval round.
New `sayosomi/nuinuiCAD#N` Work uses ordinary Git in the single registered
implementation checkout. It does **not** use a SAY identifier, Linear execution
checkpoint, `nuinui preflight`, `nuinui begin`, `nuinui handoff`, `nuinui release`,
or a new durable legacy slot. Legacy `FREE` / `preflight=PASS` is not native
admission evidence and legacy `BLOCKED` alone does not diagnose native state.

The current GitHub Issue body owns the approved scope and acceptance; its
material comments own decisions and execution checkpoints. Verify implemented
facts against latest remote `sayosomi/nuinuiCAD`, its current `AGENTS.md`, and
relevant normative specifications. [ISSUES.md](./ISSUES.md) owns Issue readiness
and checkpoints. [CODING-AGENT.md](./CODING-AGENT.md) owns the Human's choice of
agent product, model, effort and session, plus authorized direct-execution
exceptions. An agent's claimed model identity is not startup evidence; the
selected implementation agent performs the actual checkout and Git proof.

## New Task startup

Before product source or branch mutation, ChatGPT and the implementation agent
independently establish current authority and execution eligibility:

1. Resolve the canonical repository-qualified GitHub Issue. Re-read its body,
   material comments, remaining acceptance, dependencies, approved scope,
   non-goals, and applicable policy/spec owners against fresh remote `main`.
   Stop if readiness, contract or intended base is uncertain.
2. Admit only the existing registered `role=implementation` checkout
   `/Users/yosomi/Code/nuinuiCAD`, not `human-e2e` or an invented worktree.
   Validate the current `LANES.conf`, complete registered worktree topology,
   repository/origin identity, branch, HEAD, and tracked/untracked cleanliness
   using the independent [CHECKOUTS.md D1 admission](./CHECKOUTS.md#d1--github-native-git-only-implementation).
3. Prove no conflicting implementation, Human E2E checkout transition, or
   evaluator audit. Inspect current GitHub Research/Improvement audit Issue
   start/stop checkpoints and independent final checkout verification. An
   unmatched audit start, missing independent final proof, or ambiguous
   occupancy blocks D1; Issue comments are operational evidence, not an atomic
   lock. GitHub branches/PRs and historical legacy preflight output alone
   cannot prove the checkout is idle.
4. Inspect the **resolved Git directory** and existing legacy ownership/audit
   records read-only under the schemas in `CHECKOUTS.md`. Missing required,
   malformed, symlinked, inconsistent or ambiguous records; an active legacy
   claim, lock, release-pending tombstone or audit reservation block startup.
   Do not create, initialize, alter, release or infer ownership from the
   absence of records.
5. The implementation agent fetches `origin` with prune, verifies the fresh
   authoritative remote `main`, an exact approved new base, and an unused
   local/remote topic branch. A new Task starts from the declared clean, idle
   `main`. Only after all admission proofs pass may a stale, clean local
   `main` fast-forward normally, following fresh origin/ancestry checks.
   Re-read remote `main` before topic creation; if it advanced, re-audit the
   intended base and relevant contract first. Then create the topic branch in
   the same checkout using ordinary Git.

ChatGPT rechecks remote freshness immediately before agent handoff; the agent's
own fetch and state comparison remain a separate execution-time proof. Agent
implementation, verification, ordinary commit and non-force push then follow
[CODING-AGENT.md](./CODING-AGENT.md) and
[IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md); PR/review/merge
follow [LINEAR-GITHUB.md](./LINEAR-GITHUB.md). No redundant Human terminal
verification or new runtime handoff helper is required for native D1.

## Same-Task continuation

A chat change, agent change, lost output, blocking fix or unrelated remote-main
advance does **not** create a new Task or admit a continuation by itself.
Re-read the current Issue and checkout. The Issue's pushed checkpoint must name
the **exact Issue and slice, topic branch, and pushed SHA**. The clean local
branch/HEAD and freshly fetched remote topic ref must all match that SHA.
If only the local branch is absent and the remote checkpoint matches exactly,
create only a local tracking branch at that remote ref. A missing or moved
remote checkpoint, dirty checkout, uncertain occupancy, or any mismatch stops;
never infer continuation from branch naming or a prior session's output.

Apply the same execution/audit/legacy ownership exclusion as for new startup,
without demanding a legacy `FREE` classification on a clean native topic.
Current remote-main drift and slice integration remain governed by
[IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md), not by an automatic
mid-slice merge/rebase.

## Fail-closed and recovery boundary

Unexpected tracked/untracked changes; a wrong checkout, branch, HEAD, origin,
base or checkpoint; competing or unresolved implementation/audit/E2E ownership;
legacy metadata anomalies; and unclear Issue/policy/remote state are hard
stops. Preserve the checkout and evidence and report the blocker. Do not
reset, stash, clean, force-switch, force-push, overwrite, delete branch/worktree
data, create extra worktrees, or silently repair legacy records. Lost command
output is not proof that a mutation failed; inspect real state before any
separately authorized recovery. No blind retry or new mandatory safety gate.

## Compatible pre-existing SAY only — immutable reference

An actually **already admitted** SAY generation remains bound to its original
claim, Issue, lane, Base, checkpoint, release and exact recovery contract; it
must not be silently converted into native D1. Its compatible public
`nuinui handoff <SAY-N> <expected-main-sha>` command, durable identity
resolution, remote-topic modes, retained startup proof, `HANDOFF VERIFIED`,
terminal failure rules and old Human/agent order are preserved in the
[immutable pre-reduction EXECUTION-HANDOFF.md](https://github.com/sayosomi/dev-context/blob/a387b3b02460683fb8ccdf743600c0a5032d7990/projects/nuinuiCAD/EXECUTION-HANDOFF.md).
Use that history only with [CHECKOUTS.md](./CHECKOUTS.md),
[LOCAL-TOOLS.md](./LOCAL-TOOLS.md), [LINEAR.md](./LINEAR.md), and
[LINEAR-ISSUES.md](./LINEAR-ISSUES.md) for an exact existing legacy owner.
Completed Cloudflare Phase B is historical in [#268](https://github.com/sayosomi/dev-context/issues/268),
not a new-work exception. Do not remove old executable, metadata or evidence.

## Maintenance boundary

Keep only the native implementation handoff/startup routing here. The named
owners retain checkout admission, agent choice, Git mechanics, integration,
review, PR/CI, Manual E2E and legacy release/recovery. Do not add duplicate
checks, commands or obsolete migration procedures to this active loading path.
