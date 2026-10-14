# nuinuiCAD GitHub Issues — Work and contract policy

この文書は `sayosomi/nuinuiCAD` のGitHub Issue authoring、current Work contract、readiness、completionをownerする。移行全体の承認と履歴は [dev-context #268](https://github.com/sayosomi/dev-context/issues/268)、入口は [nuinuiCAD Project Context](./README.md) がownerする。

## Activation boundary

C1 GitHub Issues Work authority is active after its coordinated owner PR was
merged and authoritative GitHub `main` was read back. The Worker disabled mode
alone is not an authority-transfer signal.

The separate D1 general Git-only route becomes effective only after its
coordinated policy PR is independently reviewed, merged, read back on
authoritative dev-context `main`, and recorded as the activation checkpoint in
[dev-context #268](https://github.com/sayosomi/dev-context/issues/268). The
completed #1374 pilot was one-off operational proof under a Human-waived
policy-amendment prerequisite, not strict compliance with the unchanged
pre-activation policy and not general activation. Until the general checkpoint
is recorded, do not start ordinary GitHub-native implementation. After it, use
the Git-only route without a separate per-Task approval or activation step.

Reservation-free fixed-SHA audits are the normal route for new GitHub-native
Research/Improvement evaluator Work only after the D2-C policy PR is
independently reviewed and merged, its changes are read back on authoritative
dev-context `main`, and a separate explicit activation checkpoint is recorded
in #268. The D2-B pilot supplied historical operational proof, but neither its
completion nor D1 implementation activation activates the evaluator route.
Until all D2-C activation conditions are met, do not start a new
reservation-free evaluator audit. The D2-B SHA remains historical evidence,
not a fixed revision for later audits.

## Authority and identity

- **Current Work scope / acceptance / implementation contract:** `sayosomi/nuinuiCAD#N` のGitHub Issue body。
- **Material evidence / decisions / historical checkpoints:** 対応するIssue comments。commentはcurrent body contractの代替ではない。
- **Implementation facts:** latest remote `sayosomi/nuinuiCAD` repositoryとそのnormative source / specifications。
- **Execution / review / merge facts:** GitHub branches、commits、PRs、Actions checks、authoritative merge read-back。
- **Durable engineering / DSL specifications:** 対応するrepository-owned normative Markdown owner。
- **Linear Issues / Documents:** identity、URL、provenanceを保持する歴史的参照。例外として、既存のSAY taskが従来の `nuinui` lifecycleを実行中の場合だけ、既存flowが要求する最低限のLinear execution/status checkpointを記録できる。

GitHub Issue numberとSAY identifierは別のidentityであり、相互に置き換えない。dev-context自身のIssueは [root ISSUES.md](../../ISSUES.md) がownerする。このproject policyへdev-contextのpersistent worktree routingを持ち込まない。

## Evaluator audit checkpoints

Current evaluator Research/Improvement Work is tracked in a canonical GitHub
Issue. The Issue body owns its current bounded semantic scope, acceptance, and
non-goals. Comments retain material decisions, fixed-revision evidence,
residual dispositions, and operational checkpoints.

Use explicit comment headings and record:

- `Evaluator audit start`: canonical Issue, existing checkout identity,
  branch, exact fixed SHA, bounded scope, absolute evidence location outside the
  checkout, executor, and explicit confirmation that the checkout is
  available with no unfinished implementation or competing audit.
- `Evaluator audit progress`: fixed SHA, current scope, absolute evidence location,
  retained findings, residual dispositions, and any remote-main drift. The
  audit SHA and scope remain fixed for that run; a required change stops it and
  requires a new admission.
- `Evaluator audit stop`: stop reason/outcome, confirmation that all audit
  execution using the checkout has stopped, and retained evidence/residuals.
- `Evaluator audit final checkout proof`: unchanged repository/worktree
  identity, branch `main`, HEAD equal to the original fixed SHA, clean tracked
  and untracked state, complete declared/registered two-checkout topology,
  unchanged detached Human E2E checkout and idle state, unchanged legacy
  ownership metadata, and retained evidence/residuals. Record remote-main
  drift without incorporating it. This is Sol's executor proof, not
  independent verification and not a release checkpoint.
- `Independent final checkout verification PASS`: ChatGPT posts this
  checkpoint on the canonical product evaluator Research/Improvement Issue
  immediately in the same continuation after independently accepting the
  Human's complete output from the one read-only verification block. The block
  is prepared after Sol's final audit report and executor checkout proof, uses
  the current run's external evidence directory and original fixed SHA, and is
  executed once by the Human without a separate approval round. No additional
  verifier agent is required. ChatGPT assesses the returned output itself and
  does not claim to have run the local checker.

  Record, without exposing secrets: the current run identity, evidence
  directory, and original fixed SHA; the complete `LANES.conf` / registered
  topology result; each checkout's lane, absolute path, canonical repository
  identity, declared role and idle policy, and verified state (`main` at the
  exact fixed SHA and clean; `human-e2e` detached at its unchanged admission
  HEAD and clean/idle); the recursive legacy
  metadata path/type/content-fingerprint match and validation against the
  actual baseline schema; the retained report, evidence, and matching start,
  any progress, stop, and executor-proof checkpoints; and the process/occupancy
  conclusion that audit-owned processes stopped and no conflicting or
  unexplained activity involves either checkout. State explicitly that this
  PASS ends the audit-specific exclusion for both checkouts.

  This checkpoint establishes physical checkout reuse eligibility only. It
  does not close the Research Issue or admit a later implementation, evaluator
  audit, or Manual E2E operation. Keep the Research Issue open while residual
  scope remains; any later operation requires its own separate fresh
  admission. On `BLOCKED`, error, incomplete output, or ambiguity, do not post
  this PASS and do not lift the exclusion.

Issue comments are operational checkpoints, not atomic or machine-enforced
locks. An unmatched audit-start comment, missing executor proof, missing
independent PASS, or ambiguous execution state blocks implementation, another
audit, Manual E2E, and checkout transition until explicit investigation and
complete independent post-audit verification resolve it. A stop or executor
proof comment alone is not proof that either checkout is safe to reuse.
Detailed physical admission and recovery remain owned by
[`CHECKOUTS.md`](./CHECKOUTS.md).

## Native Issue authoring

新しいWorkはGitHubの `sayosomi/nuinuiCAD#N` をcanonical IDとしてauthorする。Issue bodyにはcurrent problem、scope、required direction、dependencies、executable acceptance / verification、non-goalsを記録する。Materialな調査evidence、decision rationale、PR / audit checkpointはcommentsへ残す。

Issue作成・変更前にlatest product repository、関連するrepository owner / specification、target Issueとmaterial comments、関連Issue / PRをfreshに読む。作成・変更が明示的に承認されたscopeに限る。Linearの枠不足を理由にBug報告を止めず、Linearへduplicate Workを作らない。

## Contract state and Work completion

GitHub Issueの `open` は未完了Work、`closed` はfull acceptanceを独立に確認した完了Workを表す。PR、branch、checkの存在だけでIssueを完了と判断しない。

Readinessが必要な場合の語彙は `contract:pending` / `contract:ready` / `contract:blocked` とする。これらはC1で実際のGitHub labelを作成したり、既存Issueを一括relabelする要求ではない。readinessをlabelで管理する場合、open Work Issueは通常このうち1つだけを持ち、Issue bodyと一致させる。

- `contract:pending`: investigation、contract、acceptance、またはHumanが決めるべき選択が未完了。
- `contract:ready`: current authority、scope、dependencies、verification routeを確認済みで、implementation前のfresh re-auditが可能。
- `contract:blocked`: 必須prerequisiteまたはexternal capabilityがなく、executable contractを確定できない。単なる実装待ちはblockedではない。

Issue bodyはcurrent meaningだけを持ち、obsoleteなcontract historyは積み重ねない。Close前にlatest remote repository / main、Issue bodyとcomments、required independent exact-head review、protected CI / verification、必要なHuman Manual E2Eをfreshに再確認する。Required Manual E2Eが残るIssueをcloseしない。PR linking / merge / closing keywordの詳細は [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) がownerする。

## Freshness and concurrent-write protection

Issue作成、contract更新、readiness変更、completionの直前に、対象Issue body / material commentsとlatest repository stateをread backする。related Issue / PRやnormative ownerがcontractに影響する場合もfreshに確認する。

Humanまたは別chatのwriteをstale snapshotから消さない。独立した追記はreconcileし、scope / acceptance / decisionが競合して一意に統合できない場合はwriteを止めてHuman判断を求める。write後もIssueを再取得して内容・stateを確認する。

`contract:ready`はimplementation開始許可ではない。implementation直前にcurrent owner、dependencies、acceptance、latest repository、execution routeを再auditする。fact driftだけでcontract choiceが変わらなければReadyを保ってrefreshする。Materialな選択が発生すればPendingへ戻し、必須prerequisiteを失えばBlockedにする。一般activation checkpoint後のimplementation startupは、current Issue contractと既存Git-only safety policyに従う。contract readinessはWorkの状態であり、D1に追加のper-Task approval / activationを要求しない。

## Existing mirror history and Linear compatibility

既存のLinear由来GitHub Issues / Documentsをrecreate、renumber、bulk rewrite、deleteしない。SAY URL、hidden `linear-issue-id` / `linear-document-id` / `linear-comment-id` markers、comments、close reason、attachment mappingを保持する。mirror由来の古いacceptanceをcurrent contractとして使う前に、そのIssueを個別にre-auditしてcurrent repository / specと照合する。履歴を現在のcontractに見せるため機械的に本文やlabelを書き換えない。

Linearは新しいWorkやDocumentの作成先ではなく、既存SAY taskの旧 `nuinui` lifecycleが必要とする最小限のexecution/status checkpointにだけ一時的に使える。このcheckpointはGitHub Issue contractやGitHub execution evidenceをsupersedeしない。新規Linear Work / Documents、bulk Linear update、reverse sync、mirroring再開は許可しない。Phase BでverifiedされたCloudflare Worker disabled production modeを維持し、8件のhistorical DLQ messageを未変更のまま保つ。

## Maintenance boundary

本documentはGitHub Issueのauthoring、current contract、readiness、freshness、completion、history preservationをownerする。Cutover checkpointは[#268](https://github.com/sayosomi/dev-context/issues/268)、GitHub PR linking / mergeは[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)、checkout / implementation lifecycleは[`CHECKOUTS.md`](./CHECKOUTS.md)、[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md)、および各role ownerが定める。個別TaskのSHA、branch、progressをこのdurable policyへ保存しない。

## Native GitHub Manual E2E checkpoints (activation pending)

This section defines Issue evidence for the native route. It does not activate
native E2E or change the current Work-contract authority: the Issue body continues to
own current scope, acceptance, and Manual E2E eligibility; comments retain
operational evidence and decisions. A merge, even a reviewed and verified
merge, is never a Manual E2E PASS.

### Native identity

The canonical GitHub Work identity is `sayosomi/nuinuiCAD#<N>`, with canonical
URL `https://github.com/sayosomi/nuinuiCAD/issues/<N>`. `<N>` is a positive
canonical decimal GitHub Issue number with no sign, whitespace, or leading
zeroes.

The native helper serializes the Issue locally as
`GH-sayosomi-nuinuiCAD-<N>` and maps it one-to-one back to the canonical
GitHub Issue. This token is distinct from legacy `SAY-<N>` and is accepted
only by `nuinui-e2e --production`; the old `nuinui` and
`nuinui-e2e-prepare` executables do not accept it. This implementation change
does not write live metadata, equate GitHub Issue number N with SAY-N, modify
the legacy marker schema, or reinterpret an existing SAY record as native Work.

### Operational comment checkpoints

After native tooling is independently reviewed, merged, read back, and
activated, retain these
checkpoints in the canonical GitHub Issue comments. Comments are durable
evidence, not an atomic lane lock or a substitute for checkout proof.

- **Manual E2E plan and required acceptance:** record the current Issue
  acceptance and Required status, the plan and eligibility decision, and the
  relevant owner links. Keep the
  Human-only execution, oracle, classification, stabilization, actual-host
  evidence, and post-merge verification rules in
  [`MANUAL-E2E.md`](./MANUAL-E2E.md).
- **Tested implementation:** record the reviewed merge, authoritative tested
  commit and exact tested ref, and evidence mapping the required units to the
  production path. For post-merge reverse-map evidence, follow
  [`MANUAL-E2E.md`](./MANUAL-E2E.md#post-merge-implementation-backed-reverse-map-re-audit).
- **E2E start:** record the canonical Issue, its exact reserved local token
  mapping if used, manifest lane and checkout identity, exact tested ref, and
  unique generation / marker / session identity with the admission evidence.
- **E2E progress and stop:** record material progress, any interruption or
  stop reason, what execution is known to have stopped, retained evidence, and
  unresolved process, ownership, or recovery facts.
- **Human result:** record `PASS`, `FAIL`, or `BLOCKED` with the applicable
  oracle observations and actual-host evidence. Apply classification and
  judgment only under [`MANUAL-E2E.md`](./MANUAL-E2E.md).
- **Closure and final checkout proof:** record exact-generation cleanup and
  release evidence, marker/session state, and the independent final proof of
  repository/worktree identity, safe idle return, clean state, and complete
  registered-worktree topology.
- **Recovery and rerun:** retain every unresolved recovery condition and the
  evidence required before an exact recovery or a separately admitted rerun.
  An unmatched start, missing closure proof, ambiguous owner, or unresolved
  interruption blocks reuse and rerun.

These checkpoints do not create lane metadata or synthetic receipts. The
manifest declares one Human-test lane, but its checkout is unregistered and
remains a hard block under
[`CHECKOUTS.md`](./CHECKOUTS.md#native-github-manual-e2e-checkout-contract-activation-pending).
Native Manual E2E cannot be invoked until the implementation is merged and
verified, the checkout is separately registered after activation, and the
explicit activation checkpoint is recorded.
