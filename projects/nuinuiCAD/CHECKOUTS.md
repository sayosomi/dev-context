# nuinuiCAD execution lane / checkout policy

## Purpose

nuinuiCADのlocal execution capacityとlane ownershipを、versioned `LANES.conf`に宣言されたcheckoutから導出して管理する。

宣言されたcheckoutは再利用候補ではなく、**存在を許可するexecution laneそのもの**である。Issue数、Ready数、worker数を理由に動的なlane / worktree / clone / checkoutを作らない。

再利用可能なexecution semantics（role、capacity、FREE/BUSY/RELEASE-PENDING/BLOCKED、durable claim/Base/checkpoint、lock、release tombstone/receipt）は shared [`DECLARED-LANE-EXECUTION.md`](../../shared/DECLARED-LANE-EXECUTION.md) がsole ownerする。この文書はnuinuiCAD固有のmanifest、Luna implementation policy、Human-only Manual E2E policyをownerする。

Evaluator auditのexecutor selection、finding threshold、Sol-first / Astra-escalation handoffは[`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md)がownerする。この文書は、既存checkoutを一時的なread-only / execution-only探索に使う場合のlane境界をownerする。

## Declared lanes

The checked-in manifest declares one implementation lane and one Human-test lane; the names and paths are data, not the capacity model. Both declared checkouts are registered. Registration does not activate the native Manual E2E lifecycle, which remains behind its separate activation gate.

| Lane | Checkout | Role |
| --- | --- | --- |
| `main` | `/Users/yosomi/Code/nuinuiCAD` | Luna implementation / blocking fix / implementation-side diagnosis |
| `human-e2e` | `/Users/yosomi/Code/nuinuiCAD-e2e` | Human-only native Manual E2E |

Lane names are identifiers from `LANES.conf`; they are not special aliases. An implementation lane may checkout a task branch when its declared idle policy and lifecycle proof permit it.

Capacity and routing rules:

- implementation capacity is the number of declared `role=implementation` lanes.
- Human-test capacity is the number of declared `role=human-test` lanes.
- A declared Human-test lane supplies capacity only when its exact real checkout is registered and passes complete topology / idle-state admission. `/Users/yosomi/Code/nuinuiCAD-e2e` is registered; native Manual E2E startup remains blocked until its separate activation gate is complete. A Required Manual E2E remains required and must not be waived, marked PASS, or treated as Done.
- a lane is never reassigned across roles, and declared paths are not inferred from lane names.
- the one authorized forensic worktree exception below is inventory-only and adds no execution capacity.
- capacity is an upper bound, not a utilization target; leave a safe lane FREE when no admitted Work needs it.

## Historical Phase B Cloudflare mirror shutdown and repair exception — #268 only

このsectionは歴史的なPhase B exceptionを記録する。declared-lane Linear ownershipと`nuinui begin` / implementation-agent `nuinui handoff` / `nuinui release`は、すでにそのlifecycleへadmitされたcompatible pre-existing SAY taskだけに適用する。一般activation checkpoint後のordinary GitHub-native implementationは下記Git-only routeを使い、legacy lifecycleへ入らない。Phase Bで認められたのは、`sayosomi/dev-context#268` の既存Cloudflare mirror Worker write-barrier / shutdown実装、ならびにcutover前に必要な既存Linear→GitHub mirrorのlossless reconciliation / history repair（Linear-to-GitHub identity mapping、status drift、Issue / Document comments、Linear Document reconciliation）と、その範囲を証明するfocused tests / configurationだけであり、既存のnuinuiCAD checkoutを使うsequential Git workflowで実施した。repairは既存mirror recordに限り、GitHub Issueのidentityや既存historyを保持する。Issueのdelete / recreate、historyの欠落・重複、reverse sync、または一般的なnuinuiCAD implementationを許可しない。新しいlane、worktree、clone、SAY Issue、またはdurable implementation generationは作らない。

Phase B当時、このexceptional workflowの開始前には、read-onlyなcheckout auditで次をすべて確認する必要があった。

- 対象は既存manifest-declared nuinuiCAD checkoutであり、repository / registered-worktree identityとfresh remote `main`が明確である。
- active implementation claim、audit reservation、mutation lock、release-pending / tombstone、または未解決のdurable ownership stateがない。
- checkoutがcleanで、current branch / HEADが説明可能であり、unrelated tracked / untracked workがない。
- 他のimplementationまたはevaluator auditが同じproduct checkoutを使用中でなく、このsliceを別作業と並行させない。

1つでも確認できない、またはstateがambiguousなら開始を止める。existing durable metadataを削除、書換え、初期化、またはexceptionのために解放してはならず、既存claim / reservationがある場合はそのownerの通常lifecycleが結論するまで待つ。

Phase Bでは上記auditの後、fresh verified `main`からordinary topic branchを使い、`nuinui begin` / `nuinui handoff` / `nuinui release`を要求しない1つのsequential sliceを許可した。durable claim/checkpoint metadataは作成・変更せず、既存のGitHub CI、pushed-head independent blocking review、PR protection、safe merge gateを維持した。この例外はPhase Bに限られ、一般activation checkpoint後のGitHub-native implementationは上記Git-only routeを使う。compatible pre-existing SAY implementationはlegacy lifecycleを継続する。Evaluator auditとHuman Manual E2Eはそれぞれ別の既存policyに従う。

## GitHub-native single-checkout Git-only workflow — general activation gate

This D1 workflow is the normal startup and continuation route for ordinary
future GitHub-native nuinuiCAD implementation Tasks. It becomes effective only
after the coordinated policy PR is independently reviewed, merged, read back on
authoritative dev-context `main`, and recorded as the activation checkpoint in
[dev-context #268](https://github.com/sayosomi/dev-context/issues/268). Until
that global checkpoint is recorded, GitHub-native implementation startup stays
blocked. Once recorded, this policy requires no separate per-Task approval or
activation step.

The completed [pilot #1374](https://github.com/sayosomi/nuinuiCAD/issues/1374)
proved the Git-only operational cycle under the one-run policy-amendment waiver
recorded in [#268 comment 6125057400](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6125057400).
It was successful one-off operational proof, not strict compliance with the
unchanged pre-activation policy and not general activation. This coordinated
policy change is the separate general-activation step.

The route uses only the existing product checkout at
`/Users/yosomi/Code/nuinuiCAD`. It does not change the manifest, declared-lane
classification, or existing claim, lock, reservation, initialization, or
release algorithms. Compatible pre-existing SAY tasks already admitted to the
legacy lifecycle continue there until a separate retirement checkpoint.
Evaluator audits follow the reservation-free GitHub-native route below only
after its separate D2-C activation checkpoint; D1 implementation activation
does not activate reservation-free audits.
Manual E2E policy is unchanged.

### Startup admission

Before a new GitHub-native Task, ChatGPT and the implementation agent must
independently re-establish the following from current GitHub and local state:

- Resolve the canonical nuinuiCAD Issue URL or repository-qualified issue
  number. Read the current Issue body and material comments, latest product
  main, applicable current policy owners, and relevant normative specifications.
  Confirm the Issue remains open and its approved scope, acceptance,
  verification, and non-goals remain executable.
- Prove the repository identity and exact registered product worktree at
  /Users/yosomi/Code/nuinuiCAD. Inspect the complete registered-worktree
  inventory, current branch and HEAD, and tracked and untracked status.
- Validate the current `LANES.conf` against its existing manifest schema
  before deriving the expected checkout set. Reject missing, malformed,
  duplicate, or ambiguous declarations, repository/path mismatches, and any
  registered-worktree set that differs from the authorized declared paths.
  This is a read-only check; do not change the manifest or create a checkout.
- Confirm there is no other active product implementation or evaluator audit.
  GitHub branches or PRs alone do not prove local execution is idle; if current
  execution occupancy cannot be established, stop.
- For a new Task, prove the checkout is in the declared idle `main` form using
  the independent read-only admission checks below. A `FREE` / `preflight=PASS`
  result from legacy `nuinui preflight` is not required and does not grant
  admission; that command may be used for optional diagnostics only. For a
  same-Task native continuation on its expected topic branch, do not require
  legacy preflight to classify the checkout as `FREE` or return `PASS`. A clean
  topic branch without a legacy slot may be `BLOCKED` under the old classifier;
  that classification proves neither capacity nor permission to proceed. If
  any reason for `BLOCKED`, or any other execution state, is ambiguous, stop.
- For a native continuation, independently verify that the current Issue
  checkpoint names this exact Issue and slice, topic branch, and pushed SHA;
  the local topic branch and HEAD and freshly fetched remote topic ref must all
  equal that SHA. The checkout must be clean, and no competing implementation
  or evaluator audit may be active. This exact continuation proof does not
  require or assign a legacy `FREE` / `BUSY` classification.
- For either entry type, inspect the exact Git directory from
  `git rev-parse --absolute-git-dir` and inventory the existing legacy
  ownership/audit metadata using read-only operations. This includes the
  `nuinui-implementation-v1` initialization state,
  `nuinui-implementation-slot/state`,
  `nuinui-implementation-lock/state`, every
  `nuinui-implementation-slot.releasing.<claim>/state` and `checkpoint`, and
  `nuinui-audit-reservation-v1`. Validate present and required records under
  their existing schemas and reject symlinks. A missing required record, or a
  malformed, symlinked, inconsistent, or ambiguous record, is a hard stop. Any
  active legacy claim, mutation lock, release-pending tombstone, or audit
  reservation is also a hard stop; do not silently ignore it or infer
  execution capacity from its absence or from a generic preflight `BLOCKED`
  result. This inventory does not require a SAY identifier or begin, handoff,
  or release command. Do not create, initialize, release, rewrite, or replace
  legacy metadata for the proposed route, and do not add a second ownership
  state machine or alter the existing classifier.
- Fetch origin with prune and verify the authoritative GitHub main SHA and
  target branch state. The expected repository, remote, branch, and exact
  checkpoint must match the approved startup contract.
- Require a clean checkout before a new Task. For a new Task, the current
  branch must be local main at the exact fresh intended base or at a clean
  ancestor eligible for the ordinary fast-forward below. After synchronization,
  main must equal that exact base. For a same-Task continuation, branch and
  HEAD must equal the exact pushed checkpoint named by the current Issue.
- After all admission checks pass, a clean local main that is behind current
  origin/main may be advanced only by ordinary fast-forward. Recheck remote
  main and ancestry immediately before the operation. If fast-forward is not
  possible, stop.
- For a new Task, re-read remote main immediately before creating a fresh topic
  branch from the verified intended base. If main advanced, re-audit and
  establish the new exact base first. Use the existing product checkout only.
  Do not create another worktree, dynamic lane, SAY-number requirement, or new
  durable nuinui claim.
- Use ordinary commits and non-force pushes. Do not reset, stash, force-switch,
  force-push, clean, overwrite, or destructively remove checkout or branch data.

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

### D1 pilot record and general activation boundary

The controlled [pilot #1374](https://github.com/sayosomi/nuinuiCAD/issues/1374)
completed the one-off Git-only operational cycle: [PR #1375](https://github.com/sayosomi/nuinuiCAD/pull/1375)
passed independent exact-pushed-head review and required CI run
[38256280538](https://github.com/sayosomi/nuinuiCAD/actions/runs/38256280538),
was merged, and authoritative product `main` was read back. The final clean,
reset-free local return was reported by the Human in
[#1374 comment 6125424675](https://github.com/sayosomi/nuinuiCAD/issues/1374#issuecomment-6125424675).

The Human expressly waived the pilot's prior policy-owner amendment
prerequisite for that single run in
[#268 comment 6125057400](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6125057400).
The pilot therefore records successful one-off operational proof under that
waiver; it must not be described as strict compliance with the unchanged
pre-activation policy or as general activation.

General GitHub-native startup becomes effective only after this coordinated
policy PR is independently reviewed, merged, read back on authoritative
dev-context `main`, and recorded as the activation checkpoint in
[#268](https://github.com/sayosomi/dev-context/issues/268). Before that
checkpoint, native implementation startup remains blocked. After it, the
Git-only workflow above is the ordinary route and requires no additional
per-Task approval or activation mechanism. Evaluator-audit replacement,
product legacy-helper retirement, and Human Manual E2E policy remain separate
work and are not activated by this checkpoint.

## Human-authorized forensic worktree exception

通常policyは`LANES.conf`に宣言されたlaneだけを許可する。現在の1 implementation lane / 1 Human-test laneはmanifestの現行構成であり、別の有効な宣言数・名前・pathも同じgeneric policyで扱う。

forensic checkoutの作成・利用には、事前の明示的なHuman authorizationが必要である。`--forensic-worktree <absolute-path>` flagは、既にHumanがauthorizedしたcheckoutをcurrent invocationのinventory exceptionとして認識するだけであり、作成・利用をauthorizeしない。

current `preflight` / `begin` / `start` invocationで認識できるsupplied registered forensic worktreeは正確に1つだけである。persistent allowlist、marker、config、receipt、environment settingは存在せず、directory nameやbranch nameのnaming conventionもexceptionを付与しない。forensic worktreeは宣言laneにならず、execution capacity・implementation capacity・Human-test capacityを消費も追加もしない。また、durable implementation metadataをownerできない。

exceptionを使う場合も、supplied pathはcanonical absolute directoryであり、同じnuinuiCAD repositoryにregisteredされた唯一のextra worktreeでなければならない。standalone clone、別repositoryのworktree、alias path、declared lane path、追加のunknown worktreeはBLOCKする。forensic checkoutのdirty state、branch、HEADはinventory validationの対象外だが、宣言laneに対する通常のlane safety checkはすべて引き続き適用される。

## Reservation-free GitHub-native evaluator audits — D2-C

After general activation, every new GitHub-native Research/Improvement
evaluator audit uses this reservation-free fixed-SHA route. Activation is
effective only after the D2-C policy PR is independently reviewed and merged,
the change is read back on authoritative dev-context `main`, and a separate
explicit activation checkpoint is recorded in dev-context #268. Before that
checkpoint, do not start a new reservation-free audit. The D2-B run is
historical operational proof; its product SHA is not the fixed revision for
future runs. Evaluator role, semantic scope, evidence, budgets, and escalation
are owned by [`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md); GitHub Issue checkpoint
fields are owned by [`ISSUES.md`](./ISSUES.md).

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
- Existing required legacy ownership and audit metadata has been inspected
  read-only using the complete metadata inventory and schema requirements
  listed in Startup admission above. Validate present and required records
  against their existing schemas; reject missing required records, symlinks,
  malformed or inconsistent records, or ambiguous ownership. There is no
  active implementation claim, mutation lock, release-pending state, audit
  reservation, or other unresolved ownership state. Record a read-only,
  non-secret baseline fingerprint outside the checkout so final proof can show
  that this metadata was not mutated. Do not create, initialize, rewrite,
  release, or replace legacy metadata or reservations.
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

The existing read-only `nuinui preflight` may be used as a supplementary safety
check, but it is not sufficient evidence of audit admission. A `FREE` result
does not override an active or ambiguous GitHub audit checkpoint. Do not run
`nuinui audit-begin` or `nuinui audit-release` for a new GitHub-native audit. Do
not create, initialize, rewrite, or automatically release legacy metadata or
reservations.
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
implementation admission must check for an unfinished evaluator audit even
when an optional legacy preflight diagnostic reports `FREE`.

If remote product `main` advances during an active audit, record the new SHA
as drift in the Issue comments. Keep the local checkout and audit evidence at
the admitted fixed SHA; the remote advance does not invalidate historical
evidence. Defer any synchronization until the audit has safely completed.

### Completion and interruption recovery

After audit execution stops, prove and record that all audit processes have
fully stopped; `/Users/yosomi/Code/nuinuiCAD` remains on branch `main` at the
original fixed SHA with tracked and untracked state clean; and the complete
two-checkout registered topology, paths, repository identities, roles, and
idle policies match admission. Prove that `/Users/yosomi/Code/nuinuiCAD-e2e`
is still registered, clean, detached, idle, and unchanged from its admission
HEAD and state; that no competing E2E generation, host session, process,
cleanup, or release operation exists; and that legacy ownership metadata is
identical to its admission fingerprint. Retain external evidence and residual
findings. A newer remote `main` is allowed and must not be incorporated during
completion. The next implementation Task uses the existing D1 freshness and
safe fast-forward procedure.

An independent verifier must compare the final Issue checkpoint with both
actual checkouts, the complete registered-worktree inventory and occupancy,
stopped-process evidence, the legacy metadata baseline, and retained external
evidence. No implementation, Manual E2E, other audit, or checkout transition
may begin until this independent final checkout verification passes. An
audit-stop checkpoint alone does not release either checkout.

If execution is interrupted, final state is ambiguous, or any required proof
is missing, preserve both checkouts and report `BLOCKED`. An unmatched audit
start is not proof of safe release. Investigate it explicitly and require the
complete post-audit proof above before permitting another execution. Never
reset, clean, stash, delete, auto-release, or repair ambiguous state.

Compatible pre-existing SAY audit reservations remain governed by the
existing lifecycle in [`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md) and
[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md); the GitHub-native route does not alter
that lifecycle.
Any forensic worktree use remains subject to its separate explicit Human
authorization and inventory rule.

### Compatible pre-existing SAY audit reservations

This physical reservation lifecycle applies only to evaluator audits already
admitted through the compatible legacy SAY flow. It does not apply to new
GitHub-native evaluator audits using the reservation-free D2-C route.

The legacy owner selects the Research/Improvement Issue, declared lane, exact
authoritative `main` revision, and bounded scope, then uses the existing
`nuinui audit-begin` command. That command validates the manifest, full
registered-worktree inventory, clean canonical idle form, durable ownership,
and live remote `main`; when allowed, it records a generation-bound durable
reservation before detaching at the exact audit SHA. A valid legacy
reservation is `BLOCKED reason=audit-reservation` for implementation
`begin`/`start` admission. Do not infer this reservation from detached HEAD.

The legacy executor stays on that fixed revision with tracked source
read-only and all harnesses, reducers, logs, evidence, outputs, and caches
outside the checkout. Dirty, malformed, interrupted, or ambiguous state
retains the reservation and fails closed. After execution stops, the legacy
owner uses the matching `nuinui audit-release` command to verify the exact
reservation and restore the recorded canonical checkout form and post-
fast-forward base. A newer remote `main` may leave the released lane
`FREE / STALE`; release does not incorporate that newer commit. Never reset,
stash, clean, force-recover, or automatically release an existing reservation.

## Human terminal operations

Humanがterminalでlocal checkoutへ行うmechanical / deterministic operationはlane ownershipそのものではなく、Luna implementation routeとは別の操作補助として扱う。

Human terminal disappearance is an external-state recovery case. If terminal output disappears or is lost after a Human mutation command, do not blindly rerun that mutation. Run the official read-only command `nuinui last-result` first. An exact recovered terminal SUCCESS can continue through normal next-stage verification; a recovered BLOCKED or ERROR continues from that exact outcome. `NONE`, `INVALID`, or `INCOMPLETE` routes to the existing lane-specific diagnosis/preflight path. Do not reset, stash, force-switch, or otherwise repair state while recovering the lost output.

Humanへ任せてよい典型:

- read-only audit: `git status`, `git rev-parse`, `git worktree list`, branch / HEAD / upstream / path確認;
- safety conditionが確定した後の単純な`git fetch`, fast-forward, exact checkout / detached checkout;
- cleanで不要と証明済みのworktree整理;
- E2E markerの作成 / 読み取り / 削除;
- dev host / test hostの起動・停止など、implementationを含まない環境操作。

Human向けterminal instructionを生成する場合はshared `human-terminal-instructions` skillを使い、absolute path、audit/mutation分離、mutation直前の再検証、mismatch時のfail-closed、current directoryや過去shell stateへの暗黙依存禁止を守る。

versioned helperが[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に登録済みでcurrent local clone上で利用可能なら、Human handoffではhelperを優先してよい。helper commandの存在はlane利用許可を意味しない。executor / lane選択はREADME routerとcurrent policyがauthorityである。

## Human-authorized exact source-fix exception

通常のsource-code implementation / blocking-fix executorはLuna xhighのままである。ただし、ChatGPTがcurrent implementation contract内の単一で自明なmechanical repairを特定し、Humanがその1回のexact-fix invocationを明示的にauthorizeした場合だけ、専用のexact-fix boundaryを使える。このexceptionは一般的なsource implementation、debug loop、design判断、conflict resolution、または任意のlane mutationを許可しない。

exact-fixのeligibility / identity / Base / checkpoint / lock / release-pending / remote freshness semanticsはこのsectionがownerする。active durable implementation generationがIssueに対して一意であり、resolved checkoutがそのgenerationのbranch / Base / current remote topicへ一致し、expected authoritative mainがfreshであることを証明する。callerはlane、claim、Base、checkpoint、ticket、またはauthorization tokenを渡さず、helperが既存のhandoff / manifest / ownership primitiveから一意に解決する。zero / multiple / malformed generation、near-match、stale remote、dirty startup、または曖昧なidentityはmutation前にBLOCKEDとする。

許可されるpatchは、resolved checkoutの既存tracked regular fileだけに対するexact textual modificationで、file declarationの集合と完全一致しなければならない。add / delete / rename / copy / binary / submodule / symlink ambiguity / outside-repository input / unknown tracked・untracked・ignored changeは受理しない。absolute patch fileとabsolute executable verifierをsnapshotして、patch applicability、deterministic diff、verifier、post-verifier diff、fresh pre-commit proofを同じresolved checkoutで確認した後、helperが宣言fileだけをstageし、supplied messageでordinary one-commitを作り、normal non-force pushを行う。

commit前の失敗は、authorized pathsだけが触られ、original HEAD / branch / lock / generation identityが変わっていないことを証明できる場合に限りexact restorationする。証明できない場合は状態を保持してmutation=unknownで停止し、reset / stash / clean / rebase / force操作はしない。push failure後はlocal commitを保持してlast-resultで復旧する。success envelopeはverification=PASS、file_set=VERIFIED、mutation=yes、clean=yes、lane / Issue / claim / branch / Base / prior topic / new HEAD / expected mainを返す。tracked exact-fix resultは既存のcommand-result storeへ記録し、別registryを作らない。

canonical interface:

~~~
nuinui exact-fix --issue <SAY-N> --expected-topic <40-sha> --expected-main <40-sha> --patch <absolute-patch-file> --verify <absolute-verifier-file> --message <commit-message> --file <repo-relative-path> [--file <repo-relative-path> ...]
~~~

### Legacy SAY preflight diagnostic / routing rule

このlegacy preflight / routing手順はcompatible pre-existing SAY taskだけに適用し、その既存startupで必要なpreflightを維持する。Native GitHub new Taskは上記のindependent read-only Git-only admissionを使う。`nuinui preflight`はnative Taskに対するoptional diagnosticであり、admission prerequisiteではない。Same-Task continuationはGitHub Issueに記録されたexact pushed checkpointを検証し、native Taskをlegacy `begin` / `handoff`へrouteしない。

`nuinui preflight`はread-onlyのinventory / routing commandであり、known-Issueの通常startやsame-generation continuationに対する別のHuman handoffではない。通常のknown-Issue implementation startは、ChatGPTがWork、target implementation lane、caller-supplied Base、branchを確定した後、Humanが同じterminalでnamed-argument startup mutationを実行する。same-generation Luna handoffでは、ChatGPTがfresh audit済みのIssueとexpected authoritative main SHAをpromptへ渡し、実装Agentがassigned checkoutでcanonical handoffを実行する。Manual E2E startupには、下記の`e2e-start-command` façadeを使う。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui begin-command --lane <implementation-lane> --issue <SAY-123> --base <expected-base-sha> --branch <branch> [--forensic-worktree <absolute-path>]
```

このhelperはnormal runtime manifestをread-onlyで解決し、global topology / registered-worktree proof、implementation-scoped admission、canonical declaration-order inventory、target `FREE`、existing read-only verifyを行って、copy/paste-readyな次の既存positional commandを出力する。strictな`nuinui preflight`は引き続き全roleのdiagnostic commandであり、Human-test role-local runtime failureがあってもこのimplementation capacityのproofとは混同しない。

```text
BEGIN COMMAND READY
<absolute-helper> begin <lane> <issue> <base> <branch> <canonical-inventory> [--forensic-worktree <absolute-path>]
```

Humanはその出力行をChatGPTへ戻さず、同じterminalでverbatimに実行する。既存`begin`が同じimplementation-scoped admissionと通常のmutation-time revalidationを行い、成功後に`IMPLEMENTATION STARTED`、normal checkpoint / continuationへ進む。generated lineはargumentをreorderせず、positional commandをreconstructせず、inventoryを再serializeせず、forensic optionを移動せず、older syntaxへ変換しない。

### Canonical Manual E2E startup handoff

通常のManual E2E startupは、ChatGPTがsemanticなIssue、tested ref、executor、fixture、locale、portを確定し、Humanが次の短いnamed generator commandを同じterminalで1回実行する。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui e2e-start-command \
  --issue SAY-123 \
  --tested-ref <full-tested-sha> \
  --executor <human|luna> \
  --fixture <absolute-fixture-path> \
  [--lane <human-test-lane>] \
  [--locale <default|ja>] \
  [--port <port>]
```

このgeneratorはread-onlyで、runtime manifest、全laneの既存preflight、選択Human-test laneの`lane_execution_nuinui_human_test_classify`をfreshに読む。selected laneが`FREE`なら生成を許可し、exact same Issue/refの`BUSY`だけは既存duplicate/no-op ownerへ委譲する候補として許可する。別Issue/refの`BUSY`、malformed marker/session、dirty/named/wrong-ref/ambiguous/blocked stateはfail closedする。複数のHuman-test laneで`--lane`を省略した場合もlaneを推測しない。

成功時はterminalが次のbounded continuationのformatting authorityになる。

```text
E2E START COMMAND READY
'<absolute-nuinui>' 'e2e-start' '<lane>' '<Issue>' '<tested-ref>' && '<absolute-prepare>' 'prepare' '<lane>' '<Issue>' '<tested-ref>' '<fixture>' [<port>] [--locale ja]
```

Humanはこの1行をChatGPTへ戻さず、同じterminalでverbatimに実行する。`&&`により`e2e-start`失敗時はprepareを実行しない。生成された値はshell-quoted済みであり、ChatGPTがlane/ref/prepareの順序を再構成しない。generatorはcheckout、marker、session、host、GUI、test oracleを変更せず、既存`nuinui e2e-start`と`nuinui-e2e-prepare prepare`がexecution-time revalidation、race protection、duplicate/no-op、host readiness、cleanup safetyを引き続きownerする。

`--executor`はChatGPTが決めるsemantic metadataであり、generatorはHumanとLunaを分類しない。`human`ではprepare後のsetupをHuman E2E unitへ渡し、`luna`では既存prepare outputのshort `handoff=` path / session identityをcurrent Luna playbookへ渡す。大きなLuna promptはterminal outputから生成しない。現行の`e2e-start-local-main`はinactive interim workflowの互換commandとして残るが、通常のこのgeneratorは標準`e2e-start`だけを出力する。

generatorが`BLOCKED`、ambiguous、stale、または利用不能な場合だけ、下記のread-only preflightと既存diagnosis / recovery pathへ戻る。preflight outputをpasteしてChatGPTに通常commandを再構成させる流れは標準startupではない。

これはChatGPT/Humanのunconditionalなround-tripではない。以下の別diagnostic preflight / recovery条件はそのまま維持する。

ChatGPTがactual local inventoryを知らず、begin / resume / releaseがBLOCKEDを返した、またはexplicit diagnosis / recoveryが必要な場合は、current helperが利用可能ならその応答内でcopy/paste-readyなexact preflight invocationを提示する。実装Agentの`nuinui handoff` identity / safety failureはHuman preflightや再実行へ変換せず、Agentを停止してorchestratorへ返す。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui preflight
```

helperが未install、stale / broken、またはunsupportedなら、同じ応答内で全宣言laneを含むread-only inventory audit blockを提示する。

preflight evidenceは少なくとも全宣言laneのrole、path、branch/detached HEAD、HEAD SHA、cleanliness、registered worktree state、durable ownership state、Human-test marker stateを一度に確認できること。auditへfetch、checkout、switch、reset、stash、clean、marker mutationを混ぜない。

Humanからfresh audit outputが返ったら、それをcurrent evidenceとして扱う。material state changeのsignalがない限り同じpreflightを機械的に要求し直さない。

Separate preflightを使う条件は次に限定する。

- Coordinatorがcurrent lane occupancyを知らず、Workのselect / route前にinventoryが必要;
- current execution identityを一意に再構成できない;
- `begin`、`resume`、`release`、またはIssue #84 exception外の`nuinui handoff`が`BLOCKED`を返した;
- crash / interrupted lifecycle operationが疑われる;
- unexpected checkout、branch、dirty stateが報告された;
- explicit recovery / diagnosisが必要。

same Issue、same lane、same durable claim generation、Luna commit / push、blocking reviewからblocking fix、implementationからintegration、新しいLuna session、ChatGPT chat rotation、unrelated remote `main` advanceだけではpreflight invalidationにならない。remote `main` freshnessはChatGPT側でfreshに確認し、Issueとexpected-main SHAだけをimplementation promptへ渡す。`nuinui handoff <SAY-N> <expected-main-sha>`はそのIssueに一致するdurable generationをcanonical dev-context cloneから解決し、full startup literalsをpromptへ手作業転記しない。

Humanへ任せないもの:

- product code implementation / blocking fix;
- code changeや広いiterationを伴うimplementation-side diagnosis;
- merge / rebase conflict resolutionやintegration fix;
- 状態不明checkoutへのreset / stash / force-switch / force-push;
- unrelated Human workを破棄・上書きするcleanup。

## Lane isolation rule

implementation laneはTask / current slice開始時に**Base checkpoint SHA**を固定する。

active slice途中では次を行わない。

- remote `main` advanceのroutine merge / rebase / cherry-pick;
- もう一方のimplementation laneのunfinished change取り込み;
- unrelated PR branchの取り込み;
- 「最新にしておく」ことだけを目的としたbase refresh。

remote `main` advanceは観測してよい。contract / ownershipを無効化する重大な変更が見つかった場合はcurrent workを安全にremote保存してcheckpointで停止し、途中同期して継続しない。

## Legacy SAY integration checkpoint

他line / latest `main`を取り込めるのはcurrent sliceが明確なintegration checkpointへ到達したときだけ。

1. current sliceの実装とfocused verificationを完了する。
2. branchへcommit / pushしcurrent stateをremote保存する。
3. Base checkpoint以降のremote `main` changeを確認する。
4. ChatGPTがBase checkpointとcurrent `main`のdriftおよびcurrent contractをauditする。conflict-free merge-only operationとsettled verificationだけで完了するeligibleなIntegration checkpointはHuman `nuinui integrate-clean`を使い、それ以外のintegration / conflict fixはそのlaneのLunaが行う。
5. integration後のrequired verificationを行う。
6. blocking review / merge gateへ進む。

integration checkpoint前に相手laneの進行中branchへ依存しない。dependencyが必要なら依存先mergeまでsafe checkpointで止める。Post-integration Driftの扱いは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)をauthorityとする。

### Conflict-free merge-only Human integration exception

first / routine Integration checkpointで、ChatGPTがBase checkpointとcurrent `main`のdriftおよびcurrent contractをauditし、conflict-free merge-only operationとsettled verificationだけで完了するとfreshに判定した場合は、prior Integration WatermarkまたはReview Headなしで`nuinui integrate-clean`をsame active durable generationでHumanが実行してよい。既存のpost-review refreshでは、Integration Watermark到達後のalready-reviewed topic、freshな`NON-INTERFERING` drift判定、およびcurrent-base freshnessだけを要求するmerge gateを引き続き要求する。

このhelperはnew lane claim / Base refresh / source implementation routeではない。current durable slotをconsumeし、exact Issue / claim / branch / Base / local topic / remote topic / current main / clean stateをmutation boundaryで再検証する。conflict resolutionやintegration fixは行わず、conflictまたはpre-commit failureではoriginal topic checkpointへのexact rollbackを証明する。push failure後はverified local merge commitを保持してfresh diagnosisへ戻す。

## Compatible pre-existing SAY durable implementation ownership

以下のdurable lane ownership、lane start / resume / release、Linear checkpoint手順は、compatible pre-existing SAY taskがすでにadmittedされたlegacy lifecycleだけに適用する。Native GitHub Workは上記D1 Git-only routeを使い、legacy slotをclaimせずLinear checkpointを記録しない。

### Authority

宣言されたimplementation laneのprimary ownership evidenceはcheckout appearanceやLinear statusではなく、そのlane固有Git directoryに保存するdurable metadataである。

- durable metadata: physical ownership / generation authority;
- Linear checkpoint: restart / handoff identityの外部evidence;
- checkout: durable identityとのconsistency evidence。

chat rotation、past prompt、branch名だけ、Linear `In Progress`だけからownershipを再構成しない。

metadata root:

```text
$(git -C <lane> rev-parse --absolute-git-dir)
```

permanent v1 files:

```text
nuinui-implementation-v1
nuinui-implementation-slot/
  state
nuinui-implementation-lock/
  state
nuinui-implementation-slot.releasing.<claim>/
  state
  checkpoint
```

active slot `state`:

```text
version=1
issue=SAY-123
branch=<exact Task branch>
base=<exact durable Base checkpoint SHA>
claim=<unique generation token>
```

`claim`はlane取得generationのidentity。同じIssue / branch / Baseを後で再取得してもnew claimを使い、stale resume / releaseを別generationとして拒否する。

mutation lockは`version`, `operation`, `issue`, `branch`, `base`, `checkpoint`, `claim`をexactly once保持する。v1で許可するoperationは`start | resume | release | init`。release tombstoneはactive slot identityとexact checkpointを保持する。

`version=1`はhelper versionとは独立したpermanent ownership metadata schemaである。helper releaseだけを理由にversionを上げない。

v1 stateはstrict schema。required key missing / duplicate、unknown key、unsupported version、invalid Issue / branch / SHA / claimは`BLOCKED / UNKNOWN`。malformed / incomplete metadataを推測して自動削除しない。

### Classification priority

`nuinui preflight`は各宣言laneを次の優先順位で分類する。

1. mutation lockあり → `BLOCKED`。validならoperation / claimを表示し、invalidならinvalid lockとしてBLOCK。
2. active slotあり → releasing stateがなく、slot valid、checkout branch=slot.branch、slot.baseがcurrent HEAD ancestorなら`BUSY`。working treeのdirtyだけでは`BUSY`を`BLOCKED`にしない。branch / Base / metadata identityの不一致は`BLOCKED`。
3. releasing tombstoneあり → single valid stateなら`RELEASE-PENDING`。multiple / malformed / suffix-claim mismatchは`BLOCKED`。
4. ownership stateなし → valid initialization marker + declared clean/form idle stateなら`FREE`。それ以外は`BLOCKED`。

`clean main`、`slotなし`、branch名だけをFREE根拠にしない。topic branchなのにslotがない状態もFREEではない。

active implementation laneがvalidなdurable ownershipを保持している場合、working treeのdirtyは診断上`clean=no`として表示するが、ownership identityが有効なら`state=BUSY`である。`FREE`のexact idle stateと`start` / `resume` / `release`のmutation preconditionでは、既存どおりworking tree cleanが必須である。

implementation occupancy is derived from each lane's declared `idle` policy: the checkout must be initialized and clean, have valid checkout/HEAD evidence, have no ownership/lock/release-pending state, and satisfy the declared branch or detached form. A clean correctly formed unowned checkout that is behind the authoritative default is still `FREE`; preflight may report that separate freshness evidence as `freshness=STALE` and never normalizes the checkout. `begin` / `start` retain the stronger mutation-boundary proof that the authoritative default equals the caller-supplied exact Base and then create the topic at that exact Base. Release and other canonical-idle contracts retain their existing exact-current-default proof.

### Mutation lock and crash safety

start / resume / release / explicit recovery / initializationのlane mutationはper-lane atomic lockで直列化する。lock取得後にsafety-critical factsを再確認する。

lockは時間でexpireしない。ageを理由に削除しない。crashでlockが残った場合はlaneをBLOCKし、known operation / claim / metadata / checkout状態を一意に証明できるときだけ`recover`する。

startはTask branch switchより先にownership slotをdurable化する。外部processが後で別branchへswitchしてもslotは残り、claim-checkout mismatchとしてBLOCKする。

releaseはactive slotをclaim固有`releasing.<claim>`へatomic renameしてからidle transitionを行う。cleanupはtombstoneを先、mutation lockを最後に削除する。古いrelease cleanupがnew claimを削除してはならない。

## Ownership schema initialization

宣言されたimplementation laneを新規作成 / 正当に再作成し、まだv1 initialization markerが存在しない場合だけ:

```text
nuinui lane-init <implementation-lane>
```

を使う。

`lane-init`はownershipの推測・adoption commandではない。slot / lock / releasing stateが存在せず、fresh authoritative `origin/main`に対するexact safe idleを再証明できる場合だけmarkerを書く。

active-looking checkoutやclaimless legacy checkpointからownershipを生成するpublic adoption pathは持たない。ownershipをcurrent durable metadataから一意に証明できないlaneは`BLOCKED / UNKNOWN`のまま扱い、Human reviewなしにcheckout appearanceからreseedしない。

## Lane start

### Declared implementation lane

Canonical normal Human handoff:

```text
nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory>
```

`begin` performs the full read-only declared-lane safety audit inside the same Human command, including registered worktree inventory, role validation, target FREE, and exact complete implementation occupancy. It then revalidates target start conditions immediately before delegating to the existing start mutation semantics. An inventory mismatch never starts the target lane. A successful result includes the complete verified `IMPLEMENTATION STARTED` envelope.

成功時のstable envelope:

```text
IMPLEMENTATION STARTED
lane=<implementation-lane>
issue=<SAY-N>
branch=<exact branch>
base=<exact base>
checkpoint=<actual HEAD>
claim=<durable generation claim>
clean=yes
state=BUSY
implementation_inventory=<declaration-order lane=FREE|SAY-N entries>
preflight=PASS
```

Lower-level lifecycle primitive retained for self-test / explicit routing:

```text
nuinui start <implementation-lane> <SAY-123> <expected-base-sha> <branch>
```

`start` is not the normal separate first half of a known-Issue Human start. It keeps the existing low-level mutation and recovery semantics; its output identifies the local transition and does not replace ChatGPT's external occupancy / parallel-admission decision. Use `begin` for the normal Human handoff.

helperはnew claim generationを作成し、mutation lockとdurable slotをbranch switchより先に取得する。その後fresh remote / exact Base / branch absence / safe idleを再確認し、必要なsafe normalization後にTask branchをcreate/switchする。final checkout / Base / cleanlinessを再確認してlockを削除し、成功outputへclaimを返す。

`begin` / `start` successはlane、Issue、branch、Base、actual checkpoint、claim、cleanliness、BUSY stateを返す。`begin`はさらにcaller expectationと照合済みのdeclaration-order implementation inventoryと`preflight=PASS`を返す。canonical normal startupでは`begin`を使い、成功した`begin`のclaimを既存のIssue checkpointへ同じcontinuationで保存する。

branch作成前にcrashしてもslot / lockがlaneを保持する。precondition failureでexact pre-start stateを一意に証明できる場合だけ自分が作ったmetadataをrollbackしてよい。判定不能なら保持してBLOCKする。

### implementation resume

remote保存済みactive branchをsame durable generationへ戻す場合はnew startにしない。

```text
nuinui resume <implementation-lane> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>
```

callerはcurrent external checkpointからLane / Issue / durable Base / exact checkpoint / branch / claimを復元する。通常のpushed checkpointではremote topicも同じcheckpointであることを要求する。`begin`直後の初回push前に限り、remote topicの成功したabsence、local topic = Base = expected checkpoint、cleanな既存topic、safeなidle identityをすべて証明できた場合だけ、そのlocal topicへ復帰できる。Baseをancestryだけから再推定したり、local slotのclaimをcaller expectationの代わりに採用しない。

slot identityがexact一致し、working tree、local branch checkpoint、authoritative remote branch、worktree occupancyがsafe-resume条件を満たす場合だけexisting branchへswitchする。authoritative main確認はactive Baseを更新するためではない。latest mainのmerge / rebase / reset / stash / force-switchを行わない。

already target branch / exact checkpointならidempotent successとしてよい。slotがownershipを保持しているのにcheckoutが別branchへ変わっている場合はpreflightのBLOCKEDを維持し、explicit resumeで安全にrestoreできた後だけBUSYへ戻す。

same active durable generationのresume / continuationでは、fresh local preflightを別途要求しない。ChatGPTがcurrent Issueとexpected authoritative main SHAをpromptへ含め、implementation Agentの最初の`nuinui handoff <SAY-N> <expected-main-sha>`がdurable slot、checkout、remote topic、remote mainを再検証する。matchなら継続し、mismatchなら`BLOCKED / STALE_EXECUTION_CONTEXT`としてAgentを停止してorchestratorへ戻す。

resume success envelope:

```text
IMPLEMENTATION RESUMED
lane=<implementation-lane>
issue=<SAY-N>
branch=<exact branch>
base=<exact base>
checkpoint=<actual HEAD>
claim=<durable generation claim>
clean=yes
state=BUSY
```

## Lane release

### Declared implementation lane

通常のHuman handoffは、ChatGPTがcheckpoint SHAを再構成せず、同じterminalで次のread-only generatorを実行する。

```text
nuinui release-command --lane <implementation-lane> --issue <SAY-123> --claim <durable-claim>
```

成功時は次の行がterminal formatting authorityになる。

```text
RELEASE COMMAND READY
'<absolute-nuinui>' 'release' '<lane>' '<topic-checkpoint>' '<claim>'
```

generatorはexact lane / Issue / durable claimを検証し、active generationのtopic checkpoint `T`をcurrent release authorityから導出する。current authoritative main `M`はcontainment authorityだけであり、`T != M`でも`T`が`M`にcontainedなら`T`を生成する。active ownershipがない場合はarbitrary `FREE`をrelease evidenceにせず、exact completed-release receiptだけを既存#108 duplicate-release proofへ渡す。Humanは生成されたrelease行をChatGPTへ戻さず、同じterminalでverbatimに実行する。

generatorはcheckout、durable slot、receipt、lock、tombstone、working treeを変更しない。実行後のmutation-time revalidation、release tombstone / receipt、duplicate no-op、recovery boundary、idle transitionは下記の既存positional `release` state machineがsole authorityする。このgeneratorは下記 mechanicsを再定義せず、checkpointを別のmain / merge SHAへ書き換えない。

underlying post-merge helper / mutation-time primitive:

```text
nuinui release <implementation-lane> <merged-checkpoint-sha> <expected-claim>
```

`lane + checkpoint`だけではgenerationを区別できないためclaimは必須。

releaseはvalid active slotがexpected claimを所有し、caller checkpoint / claimがvalidで、durable Issue / branch / Base / claim identityがunchangedであることを確認してからlocal branch relationを分類する。claimed local topic branch refがcaller指定checkpointにexact一致する場合は通常のrelease pathであり、missing refはcheckpoint mismatchではなくbranch identity failureとして診断する。fresh `origin/main`がcheckpointをancestorとして含むことを再証明し、slotへcheckpointをpersistしてclaim固有tombstoneへrenameした後、安全なidle transitionを行う。

PR merge後にremote topic refが自動削除されていても、それ自体をBLOCK条件にしない。authoritative evidenceはsaved exact checkpointとcurrent `origin/main` ancestryである。別のsafe mergeで`origin/main`がさらにadvanceしていてもcheckpointがancestorならlatest `origin/main`へreleaseしてよい。

post-mergeに実装laneのcheckoutだけがdriftした場合、release自身が次の狭い条件をすべて満たすときだけ復旧して続行できる。active slotがdurable Issue / branch / Base / claimとexact一致し、lock / tombstoneがなく、checkpoint / caller claimもexact一致することを先に確認する。claimed local refがcheckpointにある場合は、manifest-declared `idle=branch` laneのcleanなdefault-branch checkout、または`idle=detached` laneのcleanなdetached checkoutを、そのlaneの宣言されたidle policyどおり復旧でき、cleanなexact-checkpoint differently named branchからもexisting local claimed topicへexact `git switch`できる。current HEAD / checkpointがfresh authoritative default branchに含まれ、topicが別worktreeでcheckoutされていないことを再証明する。remote topicはabsentでもよいが、存在する場合は同じcheckpointのexact refでなければならない。

この復旧はreleaseの既存mutation lock取得後、slotをreleasing tombstoneへrenameする前に行う。claimed local refがmissingでも、current checkoutがcleanなnamed non-default branch、current branch refがcheckpoint、HEADがcheckpoint、fresh authoritative default branch / Base ancestry、remote topic、別worktree不存在、lock / tombstone不存在をすべてexactに証明できる場合だけ、switch直前にcritical factsを再取得・再検証して`git branch -m <durable-claimed-branch>`を一度だけ行う。existing claimed refのpathでは`git switch <durable-claimed-branch>`だけを使い、missing-ref pathではそのexact renameだけを使う。Issue textやstring similarityからbranchを推測せず、durable slotのbranchを唯一の意図されたidentityとする。branch生成、reset、stash、merge、rebase、cherry-pick、force操作、durable metadata rewriteは行わない。wrong checkpoint / claim / ref SHA、dirty、別named branch、別worktree、remote / ancestry / metadata ambiguity、lock / tombstone conflictは`BLOCKED: release claimed branch mismatch`または既存の厳密なmismatchとしてactive slotを保持する。repair後に完了を証明できない場合はrelease lockを残してrecoverへ渡し、`resume` / `recover` / generic claim-checkout mismatchの意味はこのrelease-only recoveryで変更しない。

idle state:

- declared `idle=branch`: clean local default-branch form at latest authoritative default;
- declared `idle=detached`: clean detached HEAD at latest authoritative default.

release開始時にlane自身がclaimed topic branchをcheckoutしていた場合だけ、idle transition後にそのlocal branchをcleanup candidateとする。local refがsaved checkpointのまま、checkpointがcurrent mainに含まれ、他worktreeにcheckoutされていないことを再確認し、expected-old SHA付きexact deletionを行う。

すでにidle stateからrelease continuationを行う場合、release開始時に使っていなかったlocal branchesを探索・一括削除しない。unmerged pause branch、別Issue / slice、`main`、他worktree使用中branchは保持する。

slot rename前のknown failureでcheckout / slot不変を証明できる場合はreleaseが取得した自分のlockだけrollbackしてよい。rename後のfailure / crashはtombstoneとlockを保持してexplicit recoveryへ渡す。

release成功後はcurrent Issueへ`Lane release checkpoint`を記録し、[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)に従ってread-backする。physical FREEのauthorityはactual local stateであり、Linear write failureでsuccessful releaseを巻き戻さない。

successful release outputはIssue、saved checkpoint、released claim / branch、idle branch、idle HEAD、authoritative origin main、`clean=yes`、`state=FREE`をself-containedに返す。fresh successful release envelopeを得た後、release checkpointのためだけに別preflightを行わない。

```text
IMPLEMENTATION RELEASED
lane=<implementation-lane>
issue=<released Issue>
saved_checkpoint=<exact checkpoint>
released_claim=<claim>
released_branch=<topic branch>
idle_branch=<default-branch|DETACHED>
idle_head=<actual final HEAD>
origin_main=<authoritative main used for release>
clean=yes
state=FREE
```

### Explicit recovery

```text
nuinui recover <implementation-lane> <expected-claim>
```

recoverは一般repair commandではない。valid lock / tombstoneとexpected claimをexact照合し、known interrupted `init | start | resume | release` stateだけを継続またはlock-only cleanupする。

multiple tombstones、claim mismatch、dirty、malformed state、wrong Base/history、wrong branch/HEAD等はrecoverしない。reset / stash / force-switch / broad cleanupへのfallbackは禁止。

## E2E marker

Human-test lanes are normally detached and hold a Git-local marker only while an exact test generation is active.

```bash
$(git -C <human-test-lane-path> rev-parse --git-dir)/nuinui-slot
```

format:

```text
issue=SAY-123
ref=<40-character tested commit SHA>
```

markerはworking treeへ置かない。E2E releaseの最後に削除する。

active markerがある間は、そのIssue/ref generationがauthorityであり、古いcompleted receiptから別callerが新しいmarkerを採用・releaseしてはならない。exact duplicate startはstrict marker、caller identity、clean checkout、HEAD、optional sessionをread-onlyで証明した場合だけno-op成功する。receiptはmarkerとsessionがないidle stateで、caller identityとcurrent authoritative default branch HEADが完全一致するときだけcompleted-release authorityになる。

### e2e start

1. selected Human-test laneがmanifest上FREEであることを確認する。
2. exact tested commit / stable refを決める。
3. detached checkoutしactual HEADを確認する。
4. markerへIssue / refを書く。
5. Manual E2Eを宣言されたtested stateでHumanが実行する。

E2E中にremote `main`が進んでもtested stateを途中更新しない。

### e2e release

Canonicalなsuccessful Human E2E closure handoffは、Sol High / ChatGPTが成功後のclosureを承認したうえで、Humanが同じterminalから次の短いnamed handoffを1回実行する。

```bash
nuinui-e2e-prepare closure-command --issue <Issue> [--lane <human-test-lane>]
```

`closure-command`はfreshなlocal authorityからtested ref、E2E root、current Human-test lane、active / cleanup-complete / released generationをread-onlyで解決し、terminal outputをcanonicalな実行記録として`cleanup -> e2e-release -> closure-check`の順に既存public commandへ渡す。Humanはlane、ref、rootを手で置換・再構成しない。`--lane`はcaller constraintであり、複数laneでは省略可能なのはrequested Issueのmatching generationが1つだけfreshに証明できる場合だけである。

Exact duplicate cleanup / releaseは既存authorityのsuccess envelopeのまま直ちに次stageへ進む。release後はcleanupのexact duplicateがcheckout/marker lifecycle上有効でないため、strict cleanup receiptで過去のcleanupを証明できる場合に限り、既存release duplicateからclosure-checkへ進む。このprojectionは新しいclosure stateやreceipt解釈を作らない。

`cleanup <Issue> <tested-ref> <e2e-root>`はIssue/refに加えてexact rootをsession-generation identityとして照合し、prepared sessionのowned process、temporary root、handoff、session metadataを削除するが、tested same-Issue markerは意図的に保持する。完了時はGit dirへstrictな`version=1 / issue / ref / root`の`nuinui-e2e-cleanup-receipt`を先に保存する。したがってcleanup成功後にmarkerが残り、session metadataがない状態がnormalなrelease-ready stateである。markerの削除は`e2e-release`だけがownerする。

`e2e-release <Issue> <tested-ref>`はcaller identityをmarkerと照合し、session metadataの不在、valid repository/origin、clean detached checkout、tested HEADをmutation前に要求する。fetch/prune後に同じproofを再検証し、current authoritative `origin/main`を取得する。Git dirへstrictな`version=1 / issue / ref`の`nuinui-e2e-release-receipt`をatomically write/replaceしてから安全に`origin/main`へdetachし、最後にmarkerを削除する。receipt writeに失敗した場合はmarkerを保持してBLOCKEDで停止する。

markerがない場合、同じcaller Issue/ref、strict receipt、session metadata不在、clean detached checkout、current authoritative `origin/main` HEADをread-onlyで完全一致証明できる場合だけ、`E2E ALREADY RELEASED` / `mutation=no-op`として受理する。active markerはreceiptより常に優先され、staleなreceiptから別Issueのreleaseを推測しない。

`nuinui-e2e-prepare closure-check [<human-test-lane>] <Issue>`はrelease後にだけ実行するfinal read-only closure proofである。通常のrelease前validationとしてcleanupとe2e-releaseの間に実行しない。同一Issueのmarkerが残っている場合、closure-checkは引き続き`BLOCKED`でなければならない。

各stageの実行時再検証、cleanup receipt、release receipt、marker、session/root/process cleanup、release mutation、final closure proofはそれぞれ従来のownerが保持する。どのstageでも`BLOCKED` / `ERROR`なら後続stageを実行せず、HumanはChatGPTへbounded diagnosisを返す。Manual E2EのPASS / FAIL judgmentとHumanのstop / pause semanticsは変更しない。

`nuinui-e2e-prepare prepare`でhostを起動した場合は、先に`nuinui-e2e-prepare cleanup [<human-test-lane>] <Issue> <tested-ref> <e2e-root>`でsession metadata / temporary root / handoff / owned processesをcleanupする。session metadataが残る間はe2e releaseしない。

## E2E failure

confirmed product implementation failureが出てもHuman-test laneでは修正しない。

```text
e2e FAIL
-> failure classification / fix contract
-> FREE declared implementation lane
-> Luna fix / verification / merge
-> new exact tested commit
-> selected Human-test laneでaffected unit rerun
```

すべてのdeclared implementation laneがBUSYなら既存Taskを壊してslotを作らない。

## CI reproduction

CI reproductionも追加のexecution laneを作らない。必要ならFREEなdeclared implementation laneを一時利用し、exact failing SHA / workflowをauthorityとしてLunaが診断する。全implementation laneがBUSYならsafe checkpointまで待つ。詳細は[`CI-INCIDENTS.md`](./CI-INCIDENTS.md)。

## Prohibited patterns

- Issueごとのdisposable worktree;
- persistent unregistered extra checkout;
- `/Users/yosomi/Code/nuinuiCAD-ci-repro`;
- active slice途中のroutine merge-main / rebase-main;
- unfinished parallel branch同士の取り込み;
- `NON-INTERFERING`なPost-integration Driftだけを理由にroutine integrationを繰り返すこと;
- FREE laneを埋めるためだけのparallel start;
- E2E checkoutでのproduct fix;
- checkout capacity不足をworktree追加で解消すること;
- checkout appearanceからclaimを推測生成すること;
- malformed / stale durable metadataのage-based deletion。

並列性はmanifestに宣言されたimplementation lane数で表現する。それ以上のdynamic laneを作らず、全laneを同時に使うこと自体も目的にしない。

## Native GitHub Manual E2E checkout contract (activation pending)

The native `nuinui-e2e` production lifecycle is implemented in this policy change, but is not yet active and does not authorize creating or registering the Human-test checkout. Before any live generation, this change must be independently reviewed and merged, read back from authoritative `main`, and separately activated after safe checkout registration. The compatible legacy SAY lifecycle above keeps its current helper, marker/session/receipt authority, and exact recovery behavior.

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

### Admission and checkout identity

The current [`LANES.conf`](./LANES.conf) declares exactly one `role=human-test`
lane named `human-e2e`, with `idle=detached` at
`/Users/yosomi/Code/nuinuiCAD-e2e`. This checkout was authorized and registered
under dev-context #286. Registration does not activate native Manual E2E; the
separate activation checkpoint remains pending. Do not register or recreate
the existing checkout again, reuse the implementation lane, invent another
checkout, or start a native E2E generation before activation. A Required
Manual E2E cannot be waived or reported PASS while native startup is blocked.

### Historical one-time Human-test checkout registration and recovery

The one-time Human-authorized registration was completed under dev-context
#286. This procedure is retained as historical context only. The destination
is already registered: do not run `worktree add` again, re-register it, or
remove and recreate it. Registration did not activate native E2E; its separate
activation checkpoint remains pending.

At the historical registration boundary, the complete registered-worktree
list, both declared paths, destination path, and Git-local ownership records
were inspected read-only. The implementation checkout was the only registered
lane, the destination path was absent, and no operation or ownership state was
active or pending. The full authoritative `main` SHA was used as the idle
commit:

```bash
git -C /Users/yosomi/Code/nuinuiCAD worktree add --detach \
  /Users/yosomi/Code/nuinuiCAD-e2e <authoritative-main-sha>
```

After the historical `worktree add`, `git worktree list --porcelain`, the
Human-test checkout's origin / Git directory / detached HEAD / clean status,
and the full manifest-to-worktree topology were independently re-read. Do not
overwrite an existing path or use reset, force, prune, or cleanup to make
registration appear successful.

The historical recovery rule for an interrupted registration was to leave the
destination and Git metadata untouched. Any uncertain state required
read-only inspection of the complete worktree list, destination, `.git`
pointer, checkout origin, HEAD, status, and ownership records. An unknown,
partial, or conflicting state remained `BLOCKED`; repeating `worktree add`,
removing the path, or running `worktree repair` / `prune` did not resolve it.

For each native generation, the selected checkout must be a manifest-
declared `role=human-test` lane with the required `idle=detached` topology. At
the admission boundary, verify all of the following from fresh Git and manifest
state:

- the exact repository is `sayosomi/nuinuiCAD`, with the expected canonical
  remote and Git directory;
- the exact checkout path, registered worktree identity, lane name, and role
  match the manifest;
- the complete registered-worktree topology for the repository is inventoried
  and reconciled with declared lanes; no checkout has an unknown or competing
  owner;
- the authoritative tested commit and exact tested ref are fixed before
  startup. For a new generation, require an independently proven FREE,
  clean, detached Human-test checkout in its manifest-declared idle form.
  Do not require that idle checkout to already be at the tested ref: only
  the separately approved guarded start mutation may detach it to that
  exact ref, verify the clean tested-ref HEAD, and establish the active
  generation marker. Throughout the active generation, keep HEAD fixed
  at the tested ref. An exact duplicate start instead proves the existing
  marker and tested-ref checkout without changing either;
- the product implementation checkout has a separately verified safe return
  to its idle state, with no competing implementation or evaluator audit;
- the current Issue acceptance, Manual E2E eligibility, Human-only executor,
  and exact generation identity agree with the Issue record.

Do not advance the tested ref or move the detached HEAD during a generation.
Any mismatch, dirty or named checkout, incomplete topology, stale authority,
or foreign ownership fails closed before mutation.

### Generation and recovery evidence

The native Work identity is the canonical GitHub identity in
[`ISSUES.md`](./ISSUES.md#native-github-manual-e2e-checkpoints-activation-pending).
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
