# dev-context Issues

この document は、`sayosomi/dev-context` の GitHub Issue authoring、current contract、contract lifecycle、contract re-audit の canonical owner である。

実装のcheckout / persistent worktree / branch / commit / push / review / PR / merge / sync lifecycleは [root `DEVELOPMENT.md`](./DEVELOPMENT.md) と shared Git ownerへrouteする。この document はその全文を複製せず、Issueの作成・契約・監査境界を定める。

## Authority and ownership

dev-context Workでは、責務ごとに次のauthorityを使う。

```text
actual dev-context repository state
  -> latest sayosomi/dev-context remote

durable development / Issue governance
  -> repository owner documents

current Work scope / implementation contract
  -> GitHub Issue body

important investigation evidence / rationale / contract history
  -> GitHub Issue comments

implementation / review state
  -> GitHub branch / commits / PR / checks
```

GitHub Issuesはdev-contextのprimary Work / current-contract authorityである。Issue本文と実際のrepository stateが食い違う場合、実装済み事実はlatest remote repositoryで確認する。ただし、Issueがnormative policyの変更を意図している場合、現在の実装やdocumentがそうなっているというだけでIssueのintended contractを黙って上書きしない。

dev-context documentが`/Users/yosomi/Code/nuinuiCAD`などexternal repositoryの実装事実、API、architectureを扱う場合は、そのexternal repositoryのlatest remote stateをfreshに確認する。dev-context、local copy、過去chatをexternal repositoryのimplementation authorityにしない。

責務の詳細なownerは次のとおりである。

- dev-context自身の実装 lifecycle、persistent worktree、Git mechanics: [root `DEVELOPMENT.md`](./DEVELOPMENT.md) と shared owner
- dev-context GitHub Issue authoring、current contract、contract label、contract update、re-audit、Issue completion: この document
- shared mechanics: [shared development router](./shared/DEVELOPMENT.md) とそこからrouteされる owner document
- nuinuiCAD固有のpolicy: [`projects/nuinuiCAD/`](./projects/nuinuiCAD) 配下の owner document

## Fresh authoring and audit startup

新しいIssueをauthorする場合、またはexisting Issueのcontractをaudit / updateする場合は、過去chat、handoff text、local clone、過去に取得したSHAをcurrent authorityとして扱わない。Taskに関係する範囲で、freshに次を確認する。

1. latest `sayosomi/dev-context` remote `main`
2. root `README.md`
3. root `DEVELOPMENT.md`
4. root `ISSUES.md`
5. relevant shared / project owner documents
6. current target Issue body and relevant current comments
7. related Issues and PRs
8. external implementation factsが関係する場合の、該当external repositoryのlatest remote state

すべてのrepository documentを毎回読む必要はない。owner documentのloading ruleとcurrent Taskの責務に必要な範囲を読む。

## Issue creation approval

ChatGPTが新しいdev-context GitHub Issueを作成する前に、HumanへIssue plan / draftを提示し、明示的な承認を得る。plan / draftには最低限、次を含める。

- problem / motivation
- proposed scope
- intended contract direction
- related or overlapping Issues
- proposed priority
- unresolved Human decisions

read-only investigationには承認を要しない。調査でfollow-up Workの候補を見つけても、それだけではIssue作成をauthorizeしない。Humanの「起票して」など、提示したscopeに対する明示的な指示がある場合に限り、そのscopeで作成する。

## Issue Authoring boundary

Issue Authoringはrepository implementationではない。Authoring中は次を行わない。

- `/Users/yosomi/Code/dev-context-dev` を新しいimplementation Taskへrepurposeしない
- implementation topic branchを開始しない
- repository fileを変更しない
- contractが`contract:ready`になっただけでimplementationを開始しない
- implementation PRを作成しない

Issue Authoringではread-onlyなrepository / GitHub investigationだけを行ってよい。Authoring conversationの数はdev-contextのsingle implementation-track capacityで制限しない。

`/Users/yosomi/Code/dev-context-dev` はdev-contextのsingle-track persistent development worktreeであり、Issue Authoringのために新しいworktreeを作らない。implementationを開始するときだけ、[root `DEVELOPMENT.md`](./DEVELOPMENT.md) のcurrent persistent-worktree policyに従って安全にrepurposeする。

Issue AuthoringはnuinuiCADのmain / sub / e2e fixed laneをclaimせず、そのcapacityを消費しない。nuinuiCAD lane occupancyだけを理由にdev-context Issue Authoringまたはdev-context implementationを`contract:blocked`とは分類しない。

## Contract state labels

Contract stateは次の3つだけを使う。

```text
contract:pending
contract:ready
contract:blocked
```

open dev-context Work Issueは、通常このうちexactly oneのlabelを持つ。labelとIssue本文のcontract meaningを一致させ、obsoleteなstateを本文に履歴として積み重ねない。

### `contract:pending`

investigationまたはcontractが未完了で、実行可能なcurrent contractがまだ成立していない状態。

- current authorityの調査が未完了
- 複数の合理的なdurable choiceが残っている
- realなHuman decisionが残っている
- Issue boundary、acceptance、またはverification routeがexecutably定まっていない

### `contract:ready`

current authorityの調査が完了し、executorへ渡せるcontractが成立している状態。

- current authorityを確認済み
- scopeとsemantic ownerが明確
- acceptanceがexecutable
- dependencyが解決済み、またはcontract上明示されている
- unresolvedなHuman decisionがない
- verification routeを定義できる

`contract:ready`はfile name、symbol、またはinternal implementation pathを永久に固定する意味ではない。

### `contract:blocked`

required prerequisite、external capability、またはupstream decisionが利用できず、現時点でexecutable contractを完成できない状態。

単なるimplementation開始待ち、Humanの空き時間待ち、またはnuinuiCAD main / sub / e2e lane occupancyは`contract:blocked`の理由にしない。

## Ask Human only for real decision branches

current authorityから一意に決まるdetailは、mechanicalなA/B質問にせず、ChatGPTがcurrent contractへ反映する。

Humanへ判断を求めるのは、authorityをfreshに確認しても複数の合理的な選択肢が残り、その選択が次のいずれかをmaterially変える場合に限る。

- durable workflow semantics
- source-of-truth / ownership hierarchy
- safety boundary
- compatibility
- scope / acceptance
- future developmentを拘束するarchitecture
- Human workflow

authority同士が衝突する、またはauthorityが不明な場合も、arbitraryに選択しない。選択肢と影響を説明してHumanへ戻す。

## Same Issue vs new Issue

Workをnew Issueへ分離するのは、次のすべてを満たす独立した責務として説明できる場合に限る。

1. **Independently explainable scope** — scopeを単独で説明できる
2. **Independent semantic owner** — primary responsibilityが独立している
3. **Independent acceptance / verification oracle** — 単独のacceptanceとverification oracleがある
4. **Safe standalone completion** — 先に完了してもrepository stateが一貫する
5. **Durable tracking value** — review、failure、rollback、ownershipを別Issueで追う durable valueがある

単にPRを小さくする、parallelismを増やす、または管理上分割しやすくするだけではnew Issueを作成しない。一つのIssueを複数のsequential PRで実装することは、このIssue boundaryとは別に判断できる。

## Issue body and comments

Issue bodyがcurrent effective contractをownerする。通常は次の構成を使う。

- Summary / Purpose
- Scope
- Required direction / implementation contract
- Dependencies
- Acceptance criteria
- Non-goals

contractが更新されたら本文をcurrent meaningへ更新し、obsolete contractを本文へ履歴として蓄積しない。

Issue commentsには、current contractを置き換えないmaterialな記録を残してよい。

- investigation evidence
- architecture rationale
- contract-change summary
- audit result
- blocker evidence
- superseded assumptionの説明
- implementation / PR checkpoint

chat transcript全体をcommentsへコピーしない。

## Contract update and concurrent-write safety

existing Issueを変更する直前に、次をfreshに実行する。

1. current Issue bodyを再取得する
2. relevant current commentsを再取得する
3. materialなrelated Issue / PR stateをrefreshする
4. working snapshot取得後のconcurrent updateを検出する

独立した追加はreconcileしてよい。別chatまたはHumanが追加したcurrent decisionをstale snapshotから消さない。

scope、acceptance、またはdurable decisionが競合する場合はlast-write-winsで上書きしない。current authoritative recordを保持し、reconciliationが一意でなければHumanへ判断を戻す。

### Ready refresh

`contract:ready`後にcurrent factsが変わった場合、次を判定する。

> 既決定のscope、semantics、acceptanceを変えずに、current facts / owner / symbol / path / implementation routeを一意にrefreshできるか。

- **Yes:** `contract:ready`を維持し、current factsをrefreshする
- **No — real durable choiceが発生:** `contract:pending`へ戻し、Human decisionまたは追加調査を行う
- **Required prerequisiteが利用不能:** `contract:blocked`へ変更する

labelとIssue本文の意味を食い違わせない。

## Implementation-start re-audit

`contract:ready`はimplementation開始の十分条件ではない。implementation開始直前に、freshなcurrent stateで次を再確認する。

- latest remote authority
- current semantic owner
- relevant policy
- related merged PRs
- dependencies
- acceptance oracle
- intended implementation route

fact driftがscope、semantics、acceptanceを一意に保つ場合はReadyのままrefreshしてよい。新しいmaterialなcontract choiceが生じたらimplementationを開始せず`contract:pending`へ戻す。executable contractを妨げるprerequisiteが失われたら`contract:blocked`へ戻す。

dev-contextのimplementation startとは、[root `DEVELOPMENT.md`](./DEVELOPMENT.md) のsingle-track policyに従い、次のTask用に `/Users/yosomi/Code/dev-context-dev` を安全にrepurposeして、freshに検証したintended mainからtopic branchへ移ることを指す。Taskごとの新しいworktree作成を意味しない。

Issue Authoringからimplementationを開始する場合も、Authoringのread-only boundaryを越える前にこのre-auditを完了する。

## Self-modification re-audit

dev-context自身のgovernanceを変えるIssueは、自分のcontract assumptionsを変更し得るため、通常のfreshness checkより強いre-auditを要する。対象には次を含む。

- root `README.md`
- root `DEVELOPMENT.md`
- root `ISSUES.md`
- loading rules
- source-of-truth hierarchy
- owner / responsibility routing
- approval / review / PR lifecycle
- Issue contract semantics
- execution capacity / worktree governance

merge前に、次を比較する。

1. current base authority
2. proposed new authority
3. original Issue contract
4. materially affected related Issues

「implementation now says so」だけでoriginal contractを黙って置き換えない。新しいgovernanceを適用するとmaterialなcontract decisionが発生し、それがoriginal Issueで承認されていなかった場合は、merge前にHumanへ戻す。

governance、loading、authorityの変更がmergeされた後は、新しいruleにmaterially影響される既存open Issueだけをtargeted auditする。すべてのIssueを機械的にrewriteしない。

## PR relationship

implementation PRは対応するGitHub Issueを明示的にreferenceする。

```text
Refs #N
```

post-merge verification、follow-up audit、またはその他のacceptanceが残る場合は`Refs #N`を使う。

PR mergeと、すでに完了したrequired verificationだけでIssueのfull acceptanceを満たす場合に限り、次を使ってよい。

```text
Closes #N
```

acceptanceが未検証のまま、PRがmergeされたという理由だけでIssueを自動closeしない。

## Issue completion

Issueをcloseする前に、fresh stateで次を確認する。

- intended implementation / policyがremote `main`に存在する
- required reviewとverificationがpassしている
- acceptance criteriaが満たされている
- required self-modification re-auditが完了している
- unresolved blockerまたは誤って残ったfollow-up scopeがない

独立したfollow-up Workは、通常のIssue creation approval ruleに従ってnew Issueへ切り出してよい。closed Issueにfinal contract labelをhistoryとして残すことは許容する。

## Priority

GitHub priority-label taxonomyは導入しない。当面はIssue bodyに次のようなtextを置く。

```text
Priority: High
Priority: P0
```

priority taxonomyの標準化は別のfuture Workとして扱う。

## Relationship to nuinuiCAD policy

nuinuiCADの既存policyから再利用するのは、次の原則だけである。

- Authoringとimplementationの分離
- authorityから一意に決まるdetailをHumanへ機械的に戻さない
- realなdurable product / workflow decisionはHumanへ戻す
- concurrent Issue write guard
- current contractをIssue bodyへ置く
- material evidence / rationaleをcommentsへ残す
- same Issue / new Issue boundary
- Ready contract freshness re-audit

dev-contextへ次を持ち込まない。

- Linear lifecycle / status
- Linear Project / Document semantics
- GitHub Issues mirror semantics
- `contract_reaudit` campaign marker
- nuinuiCAD fixed-lane routing
- Manual E2E classification

dev-contextではGitHub Issuesを直接primary Work / current-contract authorityとして扱う。Linearの導入、Linear mirror、Linear Project / Document、またはnuinuiCADのlane semanticsをdev-context Issue governanceへ追加しない。

## Maintenance boundary

この documentはGitHub Issueのauthoring、contract、re-audit、PR relationship、completionだけをownerする。persistent worktree governance、single-track execution、standard clone boundary、merge/read-back/sync lifecycle、nuinuiCAD separation、Human repository-file write approval gateの詳細は [root `DEVELOPMENT.md`](./DEVELOPMENT.md) とshared ownerに残す。

current TaskのSHA、branch、progress、temporary implementation planをこのdurable documentへ書き込まない。
