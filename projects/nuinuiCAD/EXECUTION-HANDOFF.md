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

## Active new-Task and same-Task route

ChatGPT verifies the current GitHub Issue, decisions, required checkpoints,
latest product main and relevant audit final proof, then supplies exact
arguments for the [single Human command](./LOCAL-TOOLS.md#active-native-d1-checkout-admission-nuinui-checkout-check).
Human checks that there is no otherwise unobservable concurrent implementation,
evaluator or E2E owner, and runs `nuinui-checkout-check new` with the approved
main SHA and unused topic, or `continue` with the exact pushed topic checkpoint.
`LOCAL CHECK PASS` is a read-only local proof, not Issue authorization.

The implementation Agent consumes the short PASS result; immediately before
mutation it performs the minimal volatile recheck required in
[CHECKOUTS.md](./CHECKOUTS.md#startup-admission--one-human-command-one-mutation-boundary-recheck):
fetch with prune; compare remote main/topic, local branch/HEAD/cleanliness,
and conflicting live ownership. Stop on drift. Do not reconstruct the entire
Human inventory, repeat approval, or treat legacy SAY `FREE` as evidence.
After a successful bounded check, perform the exact authorized native D1
branch start/continuation and implementation. Fresh remote-main ancestry is
required for any stale-main fast-forward; a missing local continuation branch
may be created only at its exact independently verified pushed checkpoint.
Slicing and integration remain with [IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md).

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
