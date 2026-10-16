# nuinuiCAD Implementation Coding Agent Policy

## Purpose

nuinuiCADのimplementation / blocking-fix executionを定義する。

### GitHub-native and legacy startup boundary

このdocument内の`SAY-N` / `nuinui handoff` startup proceduresは、すでに
そのlifecycleへ入ったcompatible pre-existing SAY taskにだけ適用する。新しい
GitHub-native IssueをSAY identifierへ変換したり、legacy helperへ渡したり
しない。普通のnative implementationは、D1一般activation checkpointが
[dev-context #268](https://github.com/sayosomi/dev-context/issues/268)に記録
された後、[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)と
[CHECKOUTS.md](./CHECKOUTS.md)のGit-only routeを使う。checkpoint前はstartupを
止め、checkpoint後にper-Task approvalを追加しない。

以下にあるlane / Base / Linear checkpointと`nuinui handoff`のstartup手順は、
すべて上記legacy SAY route専用である。native GitHub Workは、開始・続行ともに
[`CHECKOUTS.md`](./CHECKOUTS.md)と[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md)
のindependent read-only safety checksを通す。native Taskで`nuinui begin`、
`nuinui handoff`、`nuinui release`を実行したり、Linear checkpointを書いたり
しない。current contractとmaterial checkpointはGitHub Issue body/commentsへ、
execution evidenceはGitHub commits / PRs / checksから確認する。

Shared role boundary / prompt content / Git handoffは [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) に従う。Prompt language / formattingは [`../../shared/AGENT-PROMPT-STYLE.md`](../../shared/AGENT-PROMPT-STYLE.md) に従い、prompt publicationのmachine-checkable gateは [`../../shared/AGENT-PROMPT-PREFLIGHT.md`](../../shared/AGENT-PROMPT-PREFLIGHT.md) に従う。

Project-specific ruleとして、nuinuiCADの**source-code implementation / blocking fix**はmanifest-declared `role=implementation` laneを担当する**implementation Coding Agent**が実行する。Coding Agent product / model / effortの選択はHumanがprompt / handoffの外側で行う。ChatGPTはimplementation promptへ特定product / model / effortをrequired executor identityとして埋め込まず、implementation agentもself-reported model nameをauthorization / safety gateとして扱わない。web ChatGPTがdirect GitHub editingでsource-code implementationを代替するexecution routeは持たない。

GPT-6 Astraのevaluator explorationは、source implementationとは別のnon-implementation roleであり、その唯一のproject ownerは[`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md)である。この探索役割は、本書が定める通常のimplementation Coding Agent ownershipを弱めず、競合もしない。

### GitHub-native Work agent contract — after general activation

This route applies to ordinary future GitHub-native implementation after the
coordinated policy PR is independently reviewed, merged, read back on
authoritative dev-context `main`, and the activation checkpoint is recorded in
[dev-context #268](https://github.com/sayosomi/dev-context/issues/268). Until
then, native startup is blocked. The completed #1374 pilot was successful
one-off operational proof under the separately recorded Human waiver of its
policy-amendment prerequisite; it was not strict compliance with the unchanged
pre-activation policy and did not itself activate general startup. After the
checkpoint, no separate per-Task approval or activation mechanism applies.

Agent responsibilities:

- Fetch and verify current GitHub remote state, including authoritative main
  and the assigned topic ref where applicable.
- Validate the assigned existing nuinuiCAD product checkout and its registered
  worktree identity. Do not create a worktree or another checkout.
- Match the exact expected new-Task start checkpoint or explicitly authorized
  same-Task pushed continuation checkpoint.
- Re-read the current Issue contract and material comments, and stop if the
  approved scope, acceptance, verification, or non-goals changed.
- Work only on the authorized topic branch and preserve unrelated local
  branches and user data.
- Run only the authorized focused tests and verification, commit only
  intended Task changes, and use ordinary non-force push.
- Return the exact branch, base SHA, pushed HEAD SHA, changed files,
  verification commands and results, acceptance coverage, deviations, and
  blockers or residual risks.

An unexpected dirty or untracked checkout, remote mismatch, unexpected active
branch, legacy claim, audit reservation, unresolved lock, release-pending
state, conflicting implementation, evaluator audit, or policy ambiguity is a
stop condition. Preserve state and report it. Never silently repair it with
reset, stash, rebase, force, branch overwrite, cleanup, a new worktree, or
durable legacy metadata mutation.

The agent does not choose product behavior, architecture, slice boundaries,
or new dependencies. ChatGPT owns those decisions. Shared requirements for
prompt completeness, freshness, exact-head review, direct English style, and
completion reporting continue to apply.

Once the global activation checkpoint above is recorded, this is the normal GitHub-native implementation-agent route.

### Autonomous conformance discovery and repair — explicit implementation-Issue opt-in

Ordinary source implementation and blocking fixes continue to use Luna as the
default implementation Coding Agent. After D1 is active, one canonical,
open GitHub implementation Issue may instead explicitly authorize
**autonomous conformance discovery and repair**. This is a per-Issue scope
choice within the existing D1 route, not a new activation, approval round,
label, lane, reservation, or metadata system. Compatible pre-existing SAY
tasks remain under their existing legacy executor and lifecycle contract.
For an opted-in native Issue, this section owns executor selection over
generic Luna-default wording in implementation chat, issue-boundary, or
skill-selection guidance; apply any relevant skill procedures without treating
those ordinary-default references as an executor restriction.

The current implementation Issue body must contain the explicit field
`Autonomous conformance discovery and repair: authorized` and define every
item below before the mode can start. This is plain Issue-body text, not a new
label or metadata authority. Do not infer authorization from words such as
“audit,” “debug,” “test,” or “conformance,” from a linked read-only audit, or
from historical audit findings.

- **Settled semantic oracle:** cite the current normative nui1 contract and
  state the exact expected semantics needed to judge the cases. If expected
  behavior is ambiguous or requires a product/spec decision, do not opt in.
- **Closed exploration matrix:** enumerate the allowed inputs, transformations,
  endpoints, and other dimensions precisely enough to establish when every
  cell is complete. Do not authorize repo-wide or otherwise open-ended search.
- **Semantic owners and boundaries:** identify the primary compiler,
  evaluator, transport, or language-service owners in scope, plus any relevant
  reference and production paths. Do not delegate new owner or architecture
  choices to the Coding Agent.
- **Bounded distinct exploration:** provide a numeric ceiling on distinct
  compiler-accepted exploratory programs, or an equally explicit countable
  exploration-unit ceiling appropriate to the closed matrix. A distinct new
  exploratory input consumes capacity once; reruns of the same input and
  existing or unrelated suite fixtures run for verification do not consume
  additional exploratory capacity. The ceiling constrains *new exploration*,
  not the number of times authorized cases may be verified. There is no
  automatic defect-family-count stop.
- **Verification is not a cumulative count budget:** do not require hard
  numerical ceilings for canonical compiler invocation attempts, production
  persistent-Rust stdio requests, or repeats of focused regression, parity,
  build, CI, and full-suite verification. These executions may be counted and
  reported for diagnostics and cost awareness, but their totals alone must
  never stop required retesting, independent review, or completion. Human-run
  and agent-run verification obey the same scope and safety contract; changing
  the executor does not bypass or expand the exploration boundary.
- **Execution guardrails:** retain per-test and per-process timeouts, bounded
  individual harness runs, resource and memory safety, detection of
  non-progressing or repeating failures, and explicit process cleanup. On
  actual hangs, resource exhaustion, or other safety failures, preserve a
  safe pushed checkpoint and stop for diagnosis. Prefer existing runner
  controls; do not add a new quota or ledger, promise endless execution, or
  waive platform limits. D2-C read-only evaluator audits retain their own
  separate per-run accepted-program and Rust-request budgets unchanged.
- **Acceptance and verification:** define expected results, required controls,
  reproduction and regression evidence, and the criteria for matrix
  completion. State which production/reference parity checks apply.
- **Exclusions and stop conditions:** name out-of-scope semantics, owners,
  surfaces, resources, and decisions. Require a safe checkpoint if the oracle,
  matrix, owner, checkout, or contract becomes ambiguous, if work would exceed
  the authorized exploration-unit ceiling, or if a process hangs, resources
  are exhausted, required execution cannot progress safely, or a
  product/architecture decision is needed.

One Human-selected implementation Coding Agent owns the complete in-scope
loop for the Issue: generate discriminating compiler-valid cases and calculate
expected results; run the applicable reference/production checks; independently
reproduce and reduce each suspected defect with nearby passing controls; locate
the useful incorrect boundary; add deterministic regressions; make the smallest
owner-correct fix; and reverify the affected cells against the corrected
candidate. Continue across multiple distinct defect families until the closed
matrix is complete or a real stop condition applies. Exhausting the distinct
exploration ceiling stops *new exploratory inputs*, not required re-execution
of already authorized cases or necessary regression and full-suite checks.
If completing the matrix would require new exploration beyond that ceiling,
preserve a safe pushed checkpoint and return the contract decision to ChatGPT.
A defect-family count or accumulated compiler/Rust/test invocation count
alone never stops verification. Do not report cells contaminated by a known
defect as evidence; rerun affected cells on the corrected candidate.
One Issue may cover multiple in-scope defects; do not automatically create a
separate Bug Issue for each family.

Keep the source edits and tests inside the Issue's stated semantic owners and
authorized paths. Do not change the product specification speculatively,
redesign architecture, broaden the matrix, use external resources, or claim a
Human-only GUI result. If scope or ownership must change, preserve a safe
checkpoint and return the decision to ChatGPT. Record each distinct family,
test seed, expected and actual result, exact candidate revision, completed and
residual matrix cells, source changes, verification, and Git checkpoints in
the existing Issue/PR surfaces.

This mode remains an implementation Task: use the ordinary D1 Git-only
admission, single registered implementation checkout, GitHub-native branch and
checkpoint lifecycle, independent pushed-HEAD review, protected PR/CI, and
Human Manual E2E requirements. It does not use D2-C audit admission,
fixed-SHA read-only execution, audit reservations, or audit final-checkout
closeout. Manual E2E remains Human-only. Human chooses the actual
implementation-agent product, model, and effort in the Codex UI outside the
prompt. Do not name, prescribe, or verify those selections in the prompt.

### Documentation / policy direct execution exception

Repository-owned documentation / specification / policy workはsource-code implementationとは別のexecution classとする。

次の条件をすべて満たすdocumentation/policy Taskは、implementation Coding Agentを使わずChatGPTがremote repository上で直接実行してよい。

- 変更対象が`docs/**`、`AGENTS.md`、repository/project `README.md`、`ARCHITECTURE.md`、CHANGELOG等のrepository-owned documentation / specification / policy fileに限定される;
- source code、test code、fixtures、build設定、CI、runtime behavior、generated artifactを変更しない;
- target file、current problem、change purpose、intended change summaryをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- 文面修正だけでなく、新しいproduct / UX / architecture / engineering / operational ruleを決定する変更も、この明示的なplanのscope内であれば対象にできる;
- latest remote repository、current management/spec state、関連するpolicy ownerを確認してから編集する;
- verificationがdocumentation/policy consistencyを確認するread-only / focused checkで足り、source-code implementation-side test-debug loopを必要としない;
- scopeがdocumentation / specification / policy workからsource-code implementationへmaterially拡大しない。

この例外ではimplementation lane、Base checkpoint、implementation-agent sessionを要求しない。ChatGPTが編集、必要なfocused verification、blocking review、commit / push / mergeまで担当してよい。Native GitHub Workのcontract / material checkpointはGitHub Issue body/commentsへ、execution evidenceはGitHub commits / PRs / checksから確認する。Linearへ記録できるのは、compatible pre-existing SAY taskがすでにadmittedされたlifecycle自身から要求するminimum checkpointだけである。

ユーザーの許可なしに新しいrepository policy / product ruleをChatGPT判断だけで直接commitしてはならない。許可済みplanの意味上のscopeを越える場合はwrite前にplanを更新して再承認を得る。

途中でsource code / test / generated outputの変更、broad implementation-side debugging、または許可済みplanを越える変更が必要になった場合は例外を解除し、通常のimplementation Coding Agent lifecycleへ戻す。

### Narrow CI/tooling direct execution exception

CI / repository tooling / automation workのうち、product implementationから独立した**狭く一意なCI/tooling-only変更**は、source-code implementationとは別のexecution classとする。

次の条件をすべて満たすTaskは、implementation Coding Agentを使わずChatGPTが直接実行してよい。

- targetがCI workflow / CI config、repository-only automation / tooling、またはrepository checkの狭い配線変更に限定される;
- product source implementation、runtime semantics、DSL semantics、fixtures、generated artifacts、product build output / packaging semanticsを変更しない;
- latest remote repositoryからintended changeが一意に決まり、implementation scopeが狭い;
- target file、current problem、change purpose、intended change summaryをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- verificationがread-onlyまたはfocusedなCI/tooling checkで完結し、broad test-debug loopを必要としない;
- Manual E2Eを必要としない;
- conflict resolution、integration-heavy work、またはambiguous failure diagnosisを必要としない。

典型例は、既存CI jobへrepository内にすでに存在するcheck commandを1 step追加するだけで、上記条件をすべて満たす変更である。

この例外ではdeclared execution lane、Base checkpoint、implementation-agent sessionをclaimしない。ChatGPTがbranch、edit、focused verification、blocking review、commit / push、PR、mergeを担当してよい。Work記録はcurrent authorityに従い、native GitHub WorkではGitHub Issue / repository evidenceを使う。minimum Linear compatibility checkpointはcompatible pre-existing SAY taskに限る。

write直前にlatest remote SHAとtarget file freshnessを再確認する。freshness driftによってintended change、scope、またはverification routeが一意でなくなった場合はwriteせず再評価する。

途中でproduct source / runtime behavior / DSL semantics側の変更、broad debugging、conflict resolution、integration-heavy work、またはその他の除外scopeが必要になった場合はdirect executionを停止し、通常のimplementation Coding Agent + declared implementation lane lifecycleへ戻す。

このexceptionは旧 `only_chatgpt` execution model全体を復活させるものではない。

### Transitional Cloudflare mirror shutdown and repair implementation exception — #268 only

`sayosomi/dev-context#268` のPhase Bで承認された、既存Cloudflare Linear-to-GitHub mirror Workerのwrite-barrier / shutdown実装、およびcutover前に必要な既存mirror history / reconciliationのlossless repair（Linear-to-GitHub identity mapping、status drift、Issue / Document comments、Linear Document reconciliationを含む）と、それを証明するfocused tests / configurationに限り、new SAY Linear Issueを作らずGitHub Issue `sayosomi/dev-context#268` をtask contractとして実装Coding Agentへ渡せる。repairは既存recordのhistoryとGitHub Issue identityを保持し、Issueのdelete / recreate、historyの欠落・重複、reverse sync、または一般的なnuinuiCAD implementationを含めない。これはdocumentation direct-editやChatGPT source-code implementationの許可ではない。source / test implementationのexecutorは引き続きimplementation Coding Agentである。

開始前に[`CHECKOUTS.md`](./CHECKOUTS.md)のtransitional exception admission proofを満たし、既存product checkoutがcleanで、active implementation claim / audit reservationがなく、unrelated workがないことを確認する。exceptional sliceでは`nuinui begin`、`nuinui handoff`、`nuinui release`を要求せず、Linear checkpoint/statusやdurable claim/checkpoint metadataを作らない。既存metadataを変更・削除せず、別implementation / auditとの並行実行も認めない。実装AgentのGit-only startup境界は[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md)がownerする。

PR descriptionには[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)のexact cross-repository referenceを使う。通常のGitHub CI、independent pushed-head blocking review、protected PR / safe merge conditionsはすべて維持し、この例外ではparent migration Issueをcloseしない。production authority transferは、production Cloudflare write barrierのdeployとread-back verification後に限る。このPhase B exceptionはhistoricalである。C1後はGitHub Issue bodyがcurrent Work contractをownerする。compatible pre-existing SAY tasksだけがlegacy lifecycleを継続し、一般activation checkpoint後の新しいnative IssueはGit-only routeを使う。

Manual E2E executorはこのpolicyではなく [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。

### Human-authorized exact source-fix exception

通常のsource-code implementation / blocking fixは引き続きimplementation Coding Agentが標準かつ唯一のexecutorである。例外として、ChatGPTがcurrent contract内の単一で自明なtextual repairを特定し、Humanがその1回のexact-fix invocationを明示的にauthorizeした場合だけ、専用helperを使ったmechanical executionを許可する。このexceptionは一般的なimplementation、design、debugging、test-driven iteration、conflict resolution、またはambiguous fixをHumanへ移さない。

eligibilityとcheckout safetyのauthorityはCHECKOUTS.mdのHuman-authorized exact source-fix exception sectionであり、helperは既存handoff / manifest / ownership primitiveを再利用する。callerはlane、claim、Base、checkpoint、ticket、authorization tokenを渡さず、Issueとexpected remote refs、absolute patch / verifier、commit message、repo-relative declared filesだけを渡す。patchは既存tracked regular fileへのexact textual modificationに限り、verifierとpost-verifier diff、freshness、ordinary commit、normal non-force pushを含む全boundaryがpassしなければ停止する。failure pathではsafe restoreが証明できる場合だけ復元し、それ以外は状態を保持してmutation=unknownとする。

exact-fixが適用できない場合、source implementation ownershipはHumanへ移らない。fixが自明でない、複数の意味解釈がある、複数surfaceに広がる、verifierが失敗する、freshness / identity / file-set proofが成立しない、またはdebug loopが必要な場合はimplementation Coding Agentへ戻す。normal implementation branchでは通常どおりimplementation Coding Agentがimplementation / test / commit / pushを担当する。

## Role boundary

ChatGPT owns:

- latest Project Context / remote repository / current Work authorityの取得（native GitHub WorkではIssue body/comments、compatible pre-existing SAY taskでは必要な既存Linear checkpointも確認）;
- repository / architecture / semantic owner調査;
- product / architecture / implementation contract決定;
- implementation slicingとrouteごとのsafe checkpoint決定;
- execution lane選択;
- Human terminal assistanceとimplementation-agent handoffの使い分け;
- implementation-agent prompt生成;
- blocking review / merge判断;
- GitHub management、およびcompatible pre-existing SAY taskでlifecycleが要求するminimum Linear compatibility checkpointの記録 / read-back;
- documentation / specification / policy direct execution exceptionとnarrow CI/tooling direct execution exceptionのplan策定、承認取得、remote edit、focused verification、review、merge判断。

Implementation Coding Agent owns:

- current executable source-code implementation sliceの具体的implementation;
- focused / required test execution;
- implementation-side failure diagnosis and fix within the settled contract;
- branch commit / push;
- integration checkpointで必要なlatest-main integration reasoning / conflict resolution / integration fix。ただし上記のeligible deterministic merge-only Human integrationは除く。

implementation Coding Agentへopen-ended product designやarchitecture選択を委ねない。

## Human terminal assistance vs implementation Coding Agent

Humanがcopy/pasteできる単純なlocal terminal operationはimplementation executorではない。

ChatGPTがlocal checkoutの観測・準備・cleanupを必要とするときは、まず[`CHECKOUTS.md`](./CHECKOUTS.md)のHuman terminal operations ruleに照らし、**mechanical / deterministicで安全条件をcommand内に固定できるならHuman terminal assistanceを優先**する。

典型例:

- checkout / branch / HEAD / status / worktree inventory;
- exact ref確認;
- safety条件が確定した単純なfetch / fast-forward / checkout;
- cleanで不要と証明済みのworktree整理;
- E2E markerやhost起動などimplementationを伴わないlocal preparation。

Human terminal assistanceを使う場合、ChatGPTはshared `human-terminal-instructions` skillに従ったcopy/paste-ready commandを生成する。

### Conflict-free merge-only Human integration exception

ChatGPTがIntegration checkpointでBase checkpointとcurrent `main`のdriftおよびcurrent contractをauditし、conflict-free merge-only operationとsettled verificationだけで完了するとfreshに判定した場合は、[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)の`nuinui integrate-clean`をHuman terminal assistanceとして使ってよい。first / routine checkpointではprior Integration Watermarkまたはblocking Review Headを要求しない。既存のpost-review merge-gate refreshでは、already-reviewed Review Head、Integration Watermark、freshな`NON-INTERFERING` drift判定、およびcurrent-base freshnessだけを要求するmerge gateを引き続き要求する。

このexceptionはsource implementation ownershipをHumanへ移さない。Human/helperが許可されるmutationは、exact durable identity / claim generation、exact topic / main、clean checkoutを再検証した上でのconflict-free merge-only operation、settled verifier、optional file manifest、race checks、verified exact merge commit、normal non-force topic pushだけ。

stale / mechanical precondition failureがsource reasoningなしに一意にrefreshできる場合は、fresh ChatGPT evaluation後もHuman routeへ残してよい。conflict、integration fix、source edit、relevant / ambiguous semantic drift、verification failureのdiagnosis、test-debug loop、ambiguous repository state、post-commit ambiguous stateは通常のimplementation Coding Agent lifecycleへ戻す。helper成功後もfresh required PR CIとChatGPT blocking reviewを省略しない。

一方、次はHuman terminal assistanceへ委譲せずimplementation Coding Agentへ渡す。

- product codeのimplementation;
- blocking fix;
- code changeを伴うimplementation-side failure diagnosis;
- broad local iteration / test-debug loop;
- merge / rebase conflict resolution;
- integration checkpointのintegration reasoning / conflict resolution / integration fix。ただし上記のeligible deterministic merge-only Human integrationは除く;
- branch commit / pushを含むsource-code implementation execution。

Documentation / policy direct execution exceptionのdocumentation / policy editingと、narrow CI/tooling direct execution exceptionのCI/tooling editing / focused verification / review / mergeは、この一覧のsource-code implementationには含めない。

Default routing:

The one-shot Human-authorized exact source-fix route is selected only after
the CHECKOUTS.md eligibility proof; it invokes exact-fix and does not replace
the normal implementation-agent source-implementation route.

```text
ChatGPT determines the operation
-> documentation / policy direct-execution exception? YES -> ChatGPT direct execution after explicit user plan approval
-> narrow CI/tooling direct-execution exception? YES -> ChatGPT direct execution after explicit user plan approval
-> eligible one-shot Human-authorized exact source-fix? YES -> Human `nuinui exact-fix`
-> eligible deterministic conflict-free merge-only Integration checkpoint? YES -> Human `nuinui integrate-clean`
-> simple deterministic local operation? YES -> Human terminal assistance
-> NO / source-code implementation work -> implementation Coding Agent
```

Humanがterminal commandを実行したことを理由にsource-code implementation ownershipをHumanへ移さない。source-code implementation contract、lane、Base checkpoint、implementation Coding Agent ownershipはそのまま維持する。

## Declared execution lanes

Source-code implementation executionは [`LANES.conf`](./LANES.conf) に宣言された`role=implementation` laneだけを使う。

The checked-in manifest currently provides the following implementation-lane
example; names and paths are data, not the topology model.

- `main`: `/Users/yosomi/Code/nuinuiCAD`
- `sub`: `/Users/yosomi/Code/nuinuiCAD-sub`

各laneは同時に1つのsource-code implementation generationだけを保持する。動的なimplementation checkout / worktree / cloneを作らない。

`role=human-test` laneはManual E2E専用で、source-code implementationへ転用しない。

Documentation / policy direct execution exceptionとnarrow CI/tooling direct execution exceptionでは、これらのimplementation laneをclaimしない。

### Codex project / initial cwd is not lane ownership

Coding Agent workspace / project root、implementation-agent processのinitial working directory、またはsession開始時の`pwd`はimplementation laneを定義しない。

compatible pre-existing SAY taskでは、implementation laneのauthorityはChatGPTがcurrent sliceへ割り当て、legacy Linear checkpointへ記録したmanifest-declared checkout pathである。GitHub-native Workはlegacy lane claim / Linear checkpointを使わず、[CHECKOUTS.md](./CHECKOUTS.md)と[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)が定める単一checkout Git-only admissionを使う。

具体的なlane nameとpathはcurrent `LANES.conf`から読む。lane nameからpathやroleを推測しない。

compatible pre-existing SAY taskのimplementation Coding Agentは別のcwdから開始してよい。Git safety check、repository file read、test、edit、commit、pushの対象としてassigned declared checkoutを明示的にtargetする。そのlegacy startupでは、pathをtargetした後の最初のauthority operationはexactな`nuinui handoff <SAY-N> <expected-main-sha>`であり、その前にhelper-ownedなrepository identity、branch、HEAD、clean state、remote stateを手作業で再構成・検証しない。Native GitHub Workは上記Git-only routeを使う。

session開始時の`pwd`がassigned laneと違うことだけを理由に`LANE_MISMATCH`として停止してはならない。`LANE_MISMATCH`はassigned checkoutをtargetした後のcanonical handoffまたは後続operationがrequired lane conditionの不一致を報告した場合だけ使う。

declared laneを使うために別Codex Project、別VS Code window、extra checkout/worktreeを作る必要はない。同じCodex Projectからmanifest-declared checkoutをtargetしてよい。

compatible pre-existing SAY taskのimplementation-agent promptを生成するときは、initial `pwd`一致をpreconditionにせず、prompt-visibleなassigned checkout pathをrouting targetとして保持し、`assigned checkoutをtargetする -> exactな nuinui handoff <SAY-N> <expected-main-sha>を最初に実行する`順序で書く。pathはsecond identity proofにしない。Native GitHub Workのpromptにはlegacy handoff commandを含めない。

## Base checkpoint semantics

この節のlane / Base checkpoint / Linear checkpoint手順は、compatible pre-existing SAY taskのlegacy executionにだけ適用する。Native GitHub WorkはlaneやLinear checkpointを作らず、ordinary startup / continuationの独立したGit-only proofとIssue記録について[`CHECKOUTS.md`](./CHECKOUTS.md)および[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md)に従う。

新しいlegacy source-code implementation sliceをlaneへ載せる直前にChatGPTがlatest remote stateを確認し、**Base checkpoint SHA**を固定する。

Documentation / policy direct execution exceptionとnarrow CI/tooling direct execution exceptionには、このBase checkpoint requirementを適用しない。ただしwrite直前にlatest remote SHA、対象fileのfreshness、許可済みplanとのscope一致を確認する。

Shared Coding Agent Workflowのpre-prompt freshness gateは、nuinuiCADでは次のように適用する。

### New lane / new slice

- prompt生成直前にlatest remote `main`を確認する;
- relevant driftを判断する;
- current sliceのbaseを確定する;
- compatible pre-existing SAY taskに限り、既存lifecycleが要求するminimum Linear checkpointとしてlane / Base checkpoint / branchをrecordする。

### Same active slice continuation

active slice中にremote `main`が進んでもroutine merge / rebaseはしない。

ChatGPTはremote advanceを観測し、次だけ判断する。

- unrelated / non-invalidating drift → Base checkpointを変えずcurrent slice継続;
- contract / ownershipをmaterially invalidateするdrift → current workをremoteへ保存し、safe checkpointで停止して再評価。

remote advanceを理由にactive slice途中でbaseをrefreshしない。

### Legacy SAY integration checkpoint

current source-code sliceの実装とfocused verificationが完了し、remoteへ保存された時点でlatest remote `main`を再確認する。

compatible pre-existing SAY executionでChatGPTがBase checkpointとcurrent `main`のdriftおよびcurrent contractをauditした結果、conflict-free merge-only operationとsettled verificationだけで完了するeligibleなIntegration checkpointはHuman `nuinui integrate-clean`を使う。その他のintegration、またはconflict / source edit / integration fix / debuggingを必要とする場合はそのlaneのimplementation Coding Agentが担当する。Native GitHub Workのintegration / continuationはGit-only routeのordinary Git operationsを使い、このlegacy helperやLinear checkpointへrouteしない。

```text
slice implementation complete
-> push checkpoint
-> inspect latest main
-> ChatGPT drift / contract audit
-> eligible deterministic merge-only? YES -> Human `nuinui integrate-clean`
-> otherwise implementation-agent integration reasoning / conflict resolution / integration fix
-> required verification
-> Integration Watermark
-> blocking review
-> merge
```

相手implementation laneのunfinished branchを直接取り込まない。必要なdependencyは先にintended baseへmergeされること。

## Legacy SAY implementation-agent run — ChatGPT preparation

以下のlane / Base / handoff prompt preparationはcompatible pre-existing SAY taskにだけ適用する。Native GitHub implementation promptはcurrent GitHub Issue contractと[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) / [`CHECKOUTS.md`](./CHECKOUTS.md)のGit-only admission routeから作り、SAY identity、legacy lane、Linear checkpoint、`nuinui handoff`を含めない。

compatible pre-existing SAY taskをimplementation Coding Agentへ渡す前にChatGPTがcurrent Project Contextとlatest relevant repository stateを使って次を確定する。

- current Issue / current slice;
- selected lane;
- Base checkpoint SHA;
- branch;
- fresh-audited authoritative default-branch SHA for the implementation run;
- concrete change owner / files / symbols / API boundary;
- settled acceptance;
- required verification;
- explicit non-goals;
- blocking / stop conditions。

compatible pre-existing SAY taskのimplementation promptでは、freshなauthoritative `main` SHAをexpected remote stateとして示し、実装Issueとともに`nuinui handoff <SAY-N> <expected-main-sha>`を渡す。handoff façadeはmanifestとdurable implementation slotからlane、claim、branch、Base、current HEADを導出するため、これらをtransport artifactとしてpromptへ重複転記しない。

implementation Coding Agentへrepository全体のarchitecture探索やscope決定を依頼しない。

## Compatible pre-existing SAY implementation-agent prompt contract

このprompt contractのlane / handoff要件はcompatible pre-existing SAY task専用である。Native GitHub Workではcurrent Issue body/commentsからscopeとacceptanceを取り込み、Git-only admission/safety routeを[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md)と[`CHECKOUTS.md`](./CHECKOUTS.md)に従って実施する。native promptからSAY identifier、Linear checkpoint、`nuinui handoff`を除く。

Promptにはcurrent executable source-code sliceだけを書く。nuinuiCADでは、prompt publication checkerやexpected-context fileを作成せず、semantic completeness、scope、verification、Git safety、prompt styleをこのdocumentとshared Coding Agent Workflowのauthorityに従って確認する。

必須:

- repository
- lane checkout path
- one exact prefilled `nuinui handoff <SAY-N> <expected-main-sha>` command; the façade resolves the full execution identity from durable lane state
- current slice / change target
- concrete required changes
- required tests / verification
- commit / push requirement
- no-mid-slice-main-sync rule
- blocking conditions

Implementation-agent start時の`git fetch origin --prune`はrace検出に使ってよいが、active sliceのbaseを自動更新する指示にはしない。

compatible pre-existing SAY taskのPrompt startup sequenceでは、implementation-agent processのinitial cwdをauthorityに使わない。assigned lane checkout pathをtargetした後、exactな`nuinui handoff <SAY-N> <expected-main-sha>`を最初に実行する。repository identity、実行identity、branch、HEAD、clean state、remote stateはhandoff façadeとstandalone proofが検証するため、implementation Coding Agentはhandoff前に独立したhelper-owned precheckを再構成しない。

Expected lane state、dirty work、ownership、Base checkpointとの差異は、下記 `implementation-agent startup handoff gate` のhelper-owned proof結果として扱う。handoffが失敗した場合は、変更せず停止して報告させる。

For compatible pre-existing SAY startup, project-specific canonical `nuinui handoff` is the terminal startup façade for its helper-owned facts when it returns `HANDOFF VERIFIED`. It delegates proof to `nuinui-handoff-check`. Do not append another lane / topic / main verification after that success merely to re-prove those facts; a later fetch required for genuinely new implementation work is allowed, but it must not override the successful handoff evidence. For the legacy ownership contract and exact race-sensitive topic authority, route to [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md).

### implementation-agent startup handoff gate

compatible pre-existing SAY taskでは、repository operation前にimplementation Coding Agentがassigned checkout pathをtargetした後、promptにあるexact `nuinui handoff <SAY-N> <expected-main-sha>` commandをargument変更なしで最初に実行する。

```text
handoff succeeds
-> continue

anything else
-> stop
```

The façade obtains Issue from the public command and lane, Claim, Branch, Base, and current checkpoint from the unique matching durable implementation generation. It derives remote topic mode from exact authoritative remote state and passes the resolved values to the retained standalone proof. The implementation agent must not infer or regenerate identity from retained session context or repository history. Any identity or safety failure is a hard-stop with no resume, retry, repair, push, or recovery decision tree; return control to the orchestrator.

## Scope control

implementation Coding Agentが次に当たったら広域探索・redesignへ進ませない。

- settled contractから一意に決められないproduct / architecture decision;
- current slice外のsemantic owner変更が必要;
- unrelated user changes;
- required dependencyが未merge;
- current implementationがnatural safe boundaryを越えて拡大する。

その場合はcurrent workを安全に保存できるならcheckpointし、ChatGPTが再調査 / re-sliceする。

## Rerun minimization

失敗runを同じ曖昧promptで繰り返さない。

1. ChatGPTがimplementation-agent result / failure evidenceを読む。
2. failure classとownerを特定する。
3. contract / slice / verificationを必要範囲だけ更新する。
4. same active sliceのnarrow blocking fixなら同lane / same session reuseを検討する。
5. new slice / checkpoint後なら原則new implementation-agent session。

## Implementation-agent selection and session recommendation

Coding Agent product / model / effortと実際のUI上のexecutor選択はHuman-owned orchestrationであり、implementation prompt / handoff contractには含めない。ChatGPTはprompt外で推奨を示してよいが、特定product / model / effortをrequired identityとして指定・検証しない。implementation agentは内部のmodel identifierやself-reported model familyだけを理由に実行を拒否しない。

Default session recommendation: **New session**。実際のsession選択はHumanが行う。

Reuse current sessionを推奨するのは次をすべて満たすときだけ。

- same lane;
- same current executable slice;
- same branch;
- narrow blocking-fix / direct continuation;
- retained contextがreconstruction costを明確に下げる。

New sessionを使う典型:

- new Issue / new slice;
- integration checkpoint後;
- execution lane変更;
- semantic owner / contract変更;
- major remote drift後;
- previous sessionにstale / broad explorationが多い。

ユーザーへimplementation-agent promptを提示するとき、必要ならprompt外側に次だけを示す。

```text
Implementation lane: <manifest-declared implementation lane>
Session recommendation: New session | Reuse current session
```

product / model / effortはpromptへ転記しない。HumanがUI上で選択する。Reuse推奨時だけ短い理由を添える。

## E2E failure fix

Manual E2Eでconfirmed implementation failureが出たら、Human-test checkoutでは修正しない。

ChatGPTがfailureをclassify / sliceし、`FREE`なmanifest-declared implementation laneへfixを割り当て、implementation Coding Agentが実装する。fix merge後、new exact tested commitでselected Human-test laneへ戻す。

## Cross-chat continuity and task records

別ChatGPT conversationへ継続するために長いhandoff proseを標準化しない。

Native GitHub Workではcurrent contractをIssue bodyに保ち、material decisionsとexact pushed continuation checkpointをIssue commentsに記録する。実行結果はGitHub commits / PRs / checksから確認し、LinearへWork stateやcheckpointを複製しない。

compatible pre-existing SAY taskが旧lifecycle上にある場合だけ、そのcurrent Linear Issueへ既存flowが要求するminimum checkpointを記録する。

- lane;
- Base checkpoint;
- branch / PR / pushed head;
- completed acceptance;
- remaining acceptance;
- current verification / blocker;
- next safe checkpoint。

Native GitHub documentation / policy direct execution exceptionではlane / Base checkpointを作らず、対象file、latest remote file SHA、commit SHA、verification outcome、remaining acceptanceをcurrent GitHub Issue commentへ記録する。Compatible pre-existing SAY taskで既存lifecycleが必要とする場合に限り、対応するminimum Linear checkpointも残す。

次conversationはlatest Project Contextとremote repository、およびnative Workならcurrent GitHub Issueから再構成する。Legacy SAY continuationだけは、これに既存Linear checkpointのread-backを加える。
