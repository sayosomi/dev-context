# nuinuiCAD execution lane / checkout policy

## Scope and declared checkouts

The checked-in [`LANES.conf`](./LANES.conf) and registered Git worktrees
define execution capacity; Issue count and agent/chat count do not. Generic
roles, capacity, ownership, locks and recovery states belong to
[shared declared-lane execution](../../shared/DECLARED-LANE-EXECUTION.md).
No dynamic implementation or Human-test checkout may be created to gain
capacity. Each declared checkout keeps its role.

| Lane | Checkout | Role / idle |
| --- | --- | --- |
| `main` | `/Users/yosomi/Code/nuinuiCAD` | implementation / `branch` |
| `human-e2e` | `/Users/yosomi/Code/nuinuiCAD-e2e` | Human-test / `detached` |

These are current manifest values, not permanent assumptions about lane
names. Both are already registered. This document owns their nuinuiCAD-specific
physical admission, D1/D2-C exclusion and Human E2E checkout boundaries;
[execution handoff](./EXECUTION-HANDOFF.md),
[evaluator policy](./ASTRA-AUDIT.md),
[Manual E2E](./MANUAL-E2E.md) and
[GitHub Issue checkpoints](./ISSUES.md) own their respective details.

Only the **active** GitHub-native routes below admit new Work:
D1 Git-only implementation (activated in
[dev-context #268](https://github.com/sayosomi/dev-context/issues/268)),
D2-C reservation-free read-only audit (separate #268 checkpoint), and native
Human E2E (activated under [#286](https://github.com/sayosomi/dev-context/issues/286)).
Historical SAY `nuinui` lifecycle and Phase B are not new-work routes.
Activation checkpoints already recorded do not need repeating per Task.

## D1 — GitHub-native Git-only implementation

Use only the registered implementation checkout. New GitHub Issues never use
legacy `nuinui preflight/begin/handoff/release`, create SAY claims or write
Linear checkpoints. The Human-selected implementation agent follows
[`CODING-AGENT.md`](./CODING-AGENT.md); Issue-body autonomous conformance
opt-in also remains D1, not a D2-C audit. D1 cannot proceed during an
unfinished D2-C audit or active/ambiguous legacy ownership.

### Startup admission — one Human command, one mutation-boundary recheck

The native GitHub D1 entrypoint is the generated, read-only
[`nuinui-checkout-check`](./scripts/nuinui-checkout-check). Its public
usage and invocation examples are owned by [LOCAL-TOOLS.md](./LOCAL-TOOLS.md).
It does not call legacy SAY preflight and does not grant authorization by
itself.

1. ChatGPT verifies the open GitHub Issue, approved scope, exact pushed
   checkpoint for continuation, current product remote main, and audit
   start/stop/independent-final-proof records. Unfinished audits or unresolved
   occupancy block before handoff. ChatGPT fixes all command arguments.
2. Human runs exactly one `nuinui-checkout-check new` or `continue`
   invocation and explicitly asserts `--human-clear` only when no
   unobservable concurrent implementation, evaluator or Human E2E activity
   exists. The command emits `LOCAL CHECK PASS` or `LOCAL CHECK BLOCKED`
   with a reason. The PASS proves local Git/topology/legacy metadata at the
   instant of execution, not GitHub Issue readiness or Human occupancy.
3. Immediately before source/branch mutation, the selected Agent runs the
   existing required `git fetch origin --prune` and one bounded volatile
   check of expected remote main/topic SHA, branch/HEAD, clean state, and
   conflicting ownership/E2E evidence. A changed or expired Human proof stops;
   do not repeat the full Human inventory or demand a second approval.
   A stale clean local main may fast-forward only after the fetched commit
   proves ancestry. A remote-only continuation may create only the verified
   exact local tracking branch. No speculative Git repair.
4. Implementation then proceeds in the declared checkout on the exact
   approved branch. Neither this command nor the Agent allocates a new
   legacy slot, receipt, lock or worktree.

The checker derives exact paths from `LANES.conf` and reuses the existing
manifest parser, registered-worktree inventory, repository identity and
legacy ownership validators. It fails closed for mismatched/missing metadata,
dirty or unknown checkouts, unexpected branches, drift, stale checkpoint,
active SAY ownership, audit reservation, native E2E marker, and unknown
occupancy. Legacy `nuinui preflight FREE` is not a native admission result.

### Defined state handling

A. Clean but stale local main: complete every admission and legacy-ownership
check first, fetch and verify current origin/main, then use fast-forward only.
If local main is not an ancestor of origin/main, stop without rewriting it.

B. Dirty tracked files or unexpected untracked files: stop and preserve them.
Do not begin, resume, switch branches, stash, clean, or overwrite. A dirty
checkout is not an ordinary interrupted-run continuation.

C. Unexpected topic branch or unrelated active work: stop and preserve the
branch and checkout. Do not switch away, repurpose the branch, or treat a
remote PR as proof that local work is concluded. Resume only after the owner
and exact Task state are established.

D. Active legacy claim, audit reservation, lock, release-pending state, or
ambiguous durable metadata blocks native admission even when Git is clean. Leave
that state to its existing legacy owner and lifecycle; do not release or repair
it for Git-only startup.

E. A new Task's exact ChatGPT-approved topic branch must be unused. If the
requested local or remote target branch already exists, stop and preserve it;
ChatGPT must establish and authorize a new exact topic-branch name before the
agent proceeds. The implementation agent must not silently choose a
replacement name. Same-Task continuation may reuse a branch only when the
current Issue checkpoint names that exact branch and checkpoint, the remote
topic ref equals the expected pushed SHA, and the local branch is clean at the
same SHA. If the local branch is absent but the remote checkpoint is exact,
create only a local tracking branch from that remote ref. Any local/remote
mismatch or missing expected remote checkpoint is a stop condition.

F. Recover an interrupted implementation only from a freshly verified pushed
checkpoint recorded for the same Issue and slice. Re-read the exact remote
topic SHA and local branch/HEAD/status, then re-audit the current Issue and
relevant policy before continuing. Lost terminal output alone is not evidence
that a commit, push, merge, or other mutation failed; inspect authoritative
state and never replay a mutation from that assumption. Preserve and report
uncommitted or mismatched state.

G. If remote main advances before startup, refresh the Issue and owner audit and
establish a new exact intended base before creating a branch. If it advances
during an active slice, do not routinely merge or rebase main into the slice.
Save a verified pushed checkpoint and assess the drift at the integration
checkpoint under IMPLEMENTATION-SLICING.md. Relevant or ambiguous drift stops
for contract and slice re-evaluation.

H. After a PR is confirmed merged, read back the authoritative merge and latest
main. Deletion of the remote topic branch after merge is expected and is not a
missing-checkpoint error. Do not recreate it. Preserve unfinished acceptance
and required Manual E2E; merge alone does not close the Issue.

I. To return safely to updated main, first verify the checkout is clean, fetch
and read back origin/main, then use ordinary git switch to the existing local
main and fast-forward it only when its current HEAD is an ancestor of
origin/main. If switching or fast-forwarding is unsafe, stop. Keep the merged
topic branch and unrelated local branches; do not reset main or delete local
branches as cleanup.

## Human-authorized forensic inventory exception

通常policyは`LANES.conf`に宣言されたlaneだけを許可する。現在の1 implementation lane / 1 Human-test laneはmanifestの現行構成であり、別の有効な宣言数・名前・pathも同じgeneric policyで扱う。

forensic checkoutの作成・利用には、事前の明示的なHuman authorizationが必要である。`--forensic-worktree <absolute-path>` flagは、既にHumanがauthorizedしたcheckoutをcurrent invocationのinventory exceptionとして認識するだけであり、作成・利用をauthorizeしない。

current `preflight` / `begin` / `start` invocationで認識できるsupplied registered forensic worktreeは正確に1つだけである。persistent allowlist、marker、config、receipt、environment settingは存在せず、directory nameやbranch nameのnaming conventionもexceptionを付与しない。forensic worktreeは宣言laneにならず、execution capacity・implementation capacity・Human-test capacityを消費も追加もしない。また、durable implementation metadataをownerできない。

exceptionを使う場合も、supplied pathはcanonical absolute directoryであり、同じnuinuiCAD repositoryにregisteredされた唯一のextra worktreeでなければならない。standalone clone、別repositoryのworktree、alias path、declared lane path、追加のunknown worktreeはBLOCKする。forensic checkoutのdirty state、branch、HEADはinventory validationの対象外だが、宣言laneに対する通常のlane safety checkはすべて引き続き適用される。

## D2-C — fixed-SHA, read-only evaluator audit

D2-C uses the existing implementation checkout only, at a freshly admitted
fixed authoritative product `main` SHA. It does not reserve a legacy SAY
slot, change either checkout or implement defects. Role, evidence, budgets
and escalation belong to [`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md);
GitHub start/progress/stop/independent PASS fields belong to
[`ISSUES.md`](./ISSUES.md). The old D2-B pilot SHA is historical, not a
future fixed SHA.

### Admission

Before each new GitHub-native audit starts, all of the following must be
verified read-only:

- A current canonical `sayosomi/nuinuiCAD#N` Research/Improvement Issue is
  open. Its body owns the approved bounded semantic-conformance scope and
  acceptance; material decisions are in its comments. The D2-C activation
  checkpoint is already present in dev-context #268.
- The exact fixed audit SHA is the freshly verified authoritative product
  `main` commit. Read the current canonical `LANES.conf` and validate its
  complete declared-checkout inventory against the repository's complete
  registered Git worktree topology. Every lane name and checkout path must be
  unique and canonical; every declared path must be registered to the same
  `sayosomi/nuinuiCAD` repository identity and common Git directory with the
  declared role and idle policy. Missing, duplicate, unknown, extra, or
  foreign checkouts, invalid roles or paths, and any incomplete or ambiguous
  topology fail closed.
- `/Users/yosomi/Code/nuinuiCAD` is the registered `main` lane with
  `role=implementation` and `idle=branch`. It is the sole D2-C audit execution
  checkout. Require its current branch to be exactly `main`, HEAD to be exactly
  the fixed audit SHA, and tracked and untracked state to be clean. Never use
  the Human-test checkout for evaluator execution.
- Read-only admission for `/Users/yosomi/Code/nuinuiCAD-e2e` proves its exact
  registered path and shared repository identity, `role=human-test`, and
  `idle=detached`. Its tracked and untracked state must be clean and it must
  remain detached. Do not require its idle HEAD to equal the audit SHA: a
  previously released clean detached checkout may be at an older revision.
  Record its exact HEAD and state for final comparison, and do not advance or
  otherwise mutate this checkout for the audit.
- The Human-test checkout has no active or pending E2E generation, marker,
  session, host ownership, cleanup, or release operation; no unresolved host
  process or foreign ownership; and no ambiguous metadata or incomplete
  recovery. Reconcile its occupancy with the complete registered topology.
  Missing evidence or any inconsistent or ambiguous state fails closed.
- Inspect current legacy ownership and audit metadata read-only using the
  existing v1 schemas in `shared/local-tools/lane-execution/ownership.sh` and
  retained compatible SAY records. The native D1 checkout checker is not D2-C
  audit authorization. Missing required records, symlinks, malformed or
  inconsistent state, and ambiguous ownership block
  admission, as do any active implementation claim, mutation lock,
  release-pending state, audit reservation, or other unresolved owner. Do not
  create, initialize, rewrite, release, or replace legacy metadata. A
  recursive metadata path/type/content-fingerprint baseline is not required
  for this audit: closure rechecks current ownership and exclusion state
  rather than attesting that every historical metadata byte is unchanged.
- Current Issue/PR checkpoints and checkout evidence show no active, paused,
  or otherwise unfinished implementation execution, no competing evaluator
  audit, and no unmatched evaluator-audit start checkpoint. They also show no
  Manual E2E operation or checkout transition involving either declared
  checkout. A not-yet-started Issue alone is not execution occupancy. Branches
  or PRs alone do not prove a checkout is idle. Any ambiguous implementation,
  audit, E2E, transition, or ownership state blocks admission.
- The Human/operator explicitly confirms that no implementation, Manual E2E,
  evaluator audit, or checkout transition involving either checkout is in
  progress and that both checkouts are available for this audit. If process or
  execution occupancy cannot be established, admission fails closed.

Re-read authoritative remote `main` after the other admission checks and
immediately before the start checkpoint. If it no longer equals the fixed SHA,
stop and repeat admission for the new intended revision.

A new GitHub-native audit uses the independent read-only checks above instead
of legacy `nuinui preflight`. A historical `FREE` output cannot override an
active or ambiguous GitHub audit checkpoint. Do not run `nuinui audit-begin` or
`nuinui audit-release` for a new GitHub-native audit. Do not create,
initialize, rewrite, or automatically release legacy metadata or reservations.
If local `main` is behind authoritative remote `main`, stop admission. Perform
any needed synchronization separately through the established safe Git
workflow, then repeat the complete admission check against a new fixed SHA.

### Fixed-revision execution and sequential exclusion

Sol operates on the exact admitted SHA in `/Users/yosomi/Code/nuinuiCAD` only.
The audit does not switch branches, detach HEAD, merge, rebase, reset, or
fast-forward either checkout. Keep tracked product source read-only. Place
temporary harnesses, reducers, logs, outputs, caches, and evidence outside both
product checkouts. Do not add a permanent audit checkout or worktree.

From the audit-start checkpoint until independent final checkout verification
passes, maintain complete sequential exclusion: no implementation, Manual E2E,
second evaluator audit, or checkout transition involving either the `main` or
`human-e2e` checkout may start. Record audit start, progress, stop, any
revision/scope/evidence/residual updates, and final checkout proof in the
current GitHub Issue comments using the fields owned by `ISSUES.md`. Issue
comments are operational checkpoints, not atomic or machine-enforced locks:
this workflow does not provide the machine-enforced exclusion formerly
supplied by the durable audit reservation. All participants must follow the
sequence, and missing or ambiguous occupancy blocks execution. The D1
implementation admission must check for an unfinished evaluator audit regardless
of any historical legacy preflight `FREE` output.

If remote product `main` advances during an active audit, record the new SHA
as drift in the Issue comments. Keep the local checkout and audit evidence at
the admitted fixed SHA; the remote advance does not invalidate historical
evidence. Defer any synchronization until the audit has safely completed.

### Completion and interruption recovery

After audit execution stops, Sol records the stop and executor final checkout
proof under [`ISSUES.md`](./ISSUES.md): both checkout identities and admitted
states, current legacy/E2E ownership exclusion, stopped processes, retained
evidence, residuals and any remote-main drift. Sol's proof is not independent
verification or permission to reuse either checkout.

After receiving Sol's final report and executor proof, ChatGPT prepares **one
self-contained, read-only Mac terminal block**, following the existing
[`human-terminal-instructions` skill](../../shared/skills/human-terminal-instructions/SKILL.md).
The Human executes it once and returns the complete output without a separate
approval round. The block collects **physical facts**, not a newly invented
all-in-one verifier implementing GitHub reconciliation or historical metadata
fingerprinting. Use standard read-only Git commands and existing proven
read-only inspections where applicable. Take the current run's fixed SHA,
Human-test admission HEAD and external evidence location from the actual
Issue and executor proof; discover real evidence filenames. Do not invent file
names, metadata counts, schema shapes or manually join relative Git paths.

Gather enough evidence in that one invocation to establish:

- **Repository/topology:** `LANES.conf`, canonical origin/repository and all
  registered Git worktrees agree on exactly the two declared paths, roles,
  idle policies and common repository identity. Resolve Git directories
  through Git; do not guess the common-dir path.
- **Checkout state:** implementation is clean on `main` at the original fixed
  SHA; Human-test is clean, detached, idle and unchanged at the recorded
  admission HEAD. Remote `main` may have advanced without changing this proof.
- **Exclusion/occupancy:** no active or ambiguous legacy claim, mutation lock,
  releasing state, audit reservation, malformed/missing/symlinked required
  record, native E2E generation/marker/session/host/cleanup, audit-owned
  process, concurrent checkout work or unexplained process candidate.
  Inspect current ownership under its existing schema; do not compare
  historical metadata content snapshots.
- **Physical evidence:** the actual external evidence directory exists and
  contains the retained report and run records. Return their discovered paths
  and sufficient record contents or verified facts to reconcile them with
  GitHub checkpoints; a filename list alone is insufficient.

No fetch, branch switch/detach, reset, stash, clean, process termination,
release, metadata mutation or interactive-shell termination is permitted.
Do not repeat equivalent local checks solely to expand the checklist. If a
required local fact cannot be proven, return `BLOCKED`, not an optimistic PASS.

ChatGPT—not Sol or the terminal block—independently compares the complete
Human output against the current GitHub Issue's start, all material progress,
stop and executor-proof checkpoints and the run's external evidence, using
the exact fields and detailed reconciliation owned by
[`ISSUES.md`](./ISSUES.md). Preserve file/checkpoint agreement on run identity,
original fixed SHA, retained findings, evidence and checkout/process state.
A printed local PASS or Sol's executor proof alone is insufficient. ChatGPT
must not claim to have executed the Human's Mac commands.

On independently verified PASS, ChatGPT immediately posts the
`Independent final checkout verification PASS` checkpoint defined in
[`ISSUES.md`](./ISSUES.md). That GitHub checkpoint ends the audit-specific
exclusion for both declared checkouts. No additional verifier agent, Human
approval round, release command, local mutation, persistent reservation, new
tool, script, helper, lock, checkout, or runtime behavior is part of this
closeout. Checkout reuse eligibility only permits a later operation to seek
its own separate fresh admission; it does not admit an implementation, another
audit, or Manual E2E run. The next implementation Task uses the existing D1
freshness and safe fast-forward procedure.

If the Human output is incomplete, blocked, erroneous, or ambiguous; any
required proof is missing; or ChatGPT cannot reconcile the current Issue and
physical evidence, preserve both checkouts and evidence, report `BLOCKED`, and
do not post PASS or lift the exclusion. An audit-stop or executor-proof
checkpoint alone does not release either checkout. Never reset, clean, stash,
delete, auto-release, or repair ambiguous state.

Compatible pre-existing SAY audit reservations remain governed by the
existing lifecycle in [`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md) and
[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md); the GitHub-native route does not alter
that lifecycle.
Any forensic worktree use remains subject to its separate explicit Human
authorization and inventory rule.

## Native Human Manual E2E

Native GitHub E2E uses only the declared, already registered
`role=human-test` checkout and `nuinui-e2e --production`, never the legacy
SAY helper or implementation lane. The Human alone executes/judges the real
GUI; infrastructure success does not imply product PASS. The complete
[Manual E2E contract](./MANUAL-E2E.md),
[VS Code host isolation](./VS-CODE-E2E.md),
[local tool lifecycle](./LOCAL-TOOLS.md), and
[Issue checkpoints](./ISSUES.md#native-github-manual-e2e-checkpoints)
remain authoritative. No new registration, replacement checkout, automatic
E2E judgment or inferred PASS is permitted.

### Production lifecycle

The live helper requires explicit `--production` and selects only the canonical
standard-clone executable and versioned manifest. It accepts canonical
`sayosomi/nuinuiCAD#N`, issue URL, or `GH-sayosomi-nuinuiCAD-N` identities.
Production rejects caller-supplied manifests / adapters and every
`NUINUI_E2E_TEST_*` override. The explicit `--self-test --manifest` mode remains
fixture-only and cannot supply production checkout authority.

For one canonical Issue, generation, and exact tested SHA, the lifecycle is:

1. `admit` proves the Human-test lane is FREE, clean, detached, registered, and
   at its independently verified idle revision. It also proves complete
   topology and an idle implementation lane.
2. `start` fetches authoritative `main`, requires the caller's tested SHA to
   match it exactly, detaches the Human-test checkout to that SHA, and writes
   the generation-bound marker. A duplicate start is read-only only when every
   identity still matches.
3. `host-check` validates an external fixture, explicit port, exact immutable
   dogfood snapshot, artifact hashes / paths, signed Microsoft VS Code app,
   and process / listener availability. `host-prepare` launches the isolated
   host and records the generation-owned profile, snapshot, process, and
   loopback CDP listener. Host readiness is not product PASS.
4. Only the Human performs and judges Manual E2E in the actual VS Code GUI.
5. `host-closure` proves and removes only the owned host resources, binds the
   host cleanup receipt to the native generation, releases the checkout, and
   independently proves final clean detached closure. `recover` and
   `host-recover` handle only their exact recorded interruption cases; unclear
   ownership or process identity remains blocked.

Every production operation reruns complete preflight. Missing / dirty / named
checkouts, incomplete registered topology, stale or wrong tested SHA, foreign
markers / sessions / processes / listeners, malformed receipts, and artifact
mismatches fail closed before the relevant mutation. The helper does not
choose an oracle, operate the GUI, or judge product behavior.

### Native generation, occupancy and recovery

The native Work identity is the canonical GitHub identity in
[`ISSUES.md`](./ISSUES.md#native-github-manual-e2e-checkpoints).
The native helper stores the reserved `GH-sayosomi-nuinuiCAD-<N>` token and
reverse-maps it exactly to that Issue. The old `nuinui` and
`nuinui-e2e-prepare` executables remain SAY-compatible only; never pass the
native token to them. This implementation creates no live metadata,
reinterprets no existing `SAY-N` record, and does not change the legacy marker
schema.

Native marker and session evidence is strict, generation-scoped,
and mutually consistent. Bind the canonical Issue, reserved local token, exact
manifest lane and checkout identity, immutable tested ref, and unique
generation identity; bind any session to that same generation. Treat the
active marker as current-generation authority and give it precedence over
completed receipts. A receipt cannot override an active marker or session, and
an old SAY marker, session, or receipt cannot be adopted as native state.

Session, process, handoff, and temporary-root ownership must be proved against
that exact generation before any cleanup. Cleanup may affect only the owned
session, processes, handoff, and root. A durable cleanup receipt and its
read-back must precede release completion. A strict release receipt must be
durable and verified before the active marker is removed. Final closure then
requires an independent read-only proof that the exact lane has returned to its
verified manifest-declared idle topology, is clean and detached at the current
authoritative ref, and matches the complete registered-worktree topology.

Only an exact duplicate for the same Issue, lane, tested ref, and generation
may succeed as a read-only no-op after every relevant artifact and ownership
fact is reverified. Near matches, stale or malformed artifacts, interruption,
or uncertain process ownership fail closed. Recovery must use a separately
approved exact-generation procedure with fresh snapshots; never repair state
automatically, infer a generation from a receipt, retry an unsafe mutation, or
remove foreign files or processes. No competing checkout ownership is allowed
at any point.

These native requirements do not change the existing legacy closure order
`cleanup -> e2e-release -> closure-check` or remove its `SAY-N` release gates.
Manual E2E judgment and execution semantics remain owned by
[`MANUAL-E2E.md`](./MANUAL-E2E.md).

## Human terminal and fail-closed boundary

Use [Human terminal instructions](../../shared/skills/human-terminal-instructions/SKILL.md)
for Mac commands; keep read-only inspection separate from mutation and do
not terminate the Human's shell. Commands must establish the exact checkout,
identity and expected state, recheck mutation preconditions, and explain
`BLOCKED` instead of guessing or destructively repairing state. Lost
terminal output is not proof that mutation failed: inspect actual state and
the responsible helper's recorded result before any retry.

No reset, stash, force-switch, forced history rewrite, unexplained cleanup,
metadata deletion, ownership adoption or extra worktree may be used to make
a lane look free. Product fixes never run in the Human-test checkout.
CI reproduction follows [`CI-INCIDENTS.md`](./CI-INCIDENTS.md); active D1
slice integration/drift follows
[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md).

## Compatible pre-existing SAY `nuinui` operations — historical reference

**Do not start a new SAY/Linear Work or route a new GitHub-native Issue
through the old helper.** The legacy executable, source, tests, persistent
metadata, receipts and historical Issue/Linear evidence are preserved. An
already admitted, unresolved SAY claim, release tombstone/lock, audit
reservation or E2E marker still blocks conflicting native admission.

For an actually existing pre-admitted SAY generation, retain its original
strict schema, claim/Issue/Base/checkpoint identity, lifecycle and exact
recovery rules. The [frozen pre-reduction CHECKOUTS.md](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md)
is the complete compatible SAY-only operational reference, including:

- [Phase B exception, historical only](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md#L33-L47);
- [SAY audit reservation](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md#L450-L474);
- [Human exact source-fix, preflight and legacy E2E handoff](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md#L475-L590);
- [legacy integration and durable ownership/start/resume/release/recover](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md#L604-L860);
- [legacy E2E marker/cleanup/release and failure paths](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md#L861-L928);
- [one-time native checkout registration and recovery record](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md#L1002-L1064).

These links preserve the **existing** compatible legacy contract for
finishing/recovering an admitted generation; they are not an activation,
independent permission to invoke legacy commands, or a second current route.
Follow the applicable original helper and
[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) and
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) with exact read-only
identity/ownership proof. Never infer an owner from checkout appearance,
automatically clear ambiguous locks or markers, or apply a legacy
`FREE` result to override an unresolved GitHub-native audit checkpoint.
