# nuinuiCAD GitHub Issues — Work and contract policy

この文書は `sayosomi/nuinuiCAD` のGitHub Issue authoring、current Work contract、readiness、completionをownerする。移行全体の承認と履歴は [dev-context #268](https://github.com/sayosomi/dev-context/issues/268)、入口は [nuinuiCAD Project Context](./README.md) がownerする。

## Activation boundary

このpolicyは、承認済みC1 owner一式を含むPRがmergeされ、authoritative GitHub `main`をread backして変更が存在することを確認した後にだけ有効になる。C1 PRの作成・review中やmerge前にcutover済みと扱わない。Workerのdisabled状態だけでもauthorityは移らない。

有効化後、新しいWorkのauthoringにはGitHub Issuesを使える。ただし、GitHub-native Issueのimplementation startupはD1でGit-only safety workflowが実証されるまで開始しない。C1は既存の `nuinui begin` / `handoff` / `release` lifecycleを置き換えない。

## Authority and identity

- **Current Work scope / acceptance / implementation contract:** `sayosomi/nuinuiCAD#N` のGitHub Issue body。
- **Material evidence / decisions / historical checkpoints:** 対応するIssue comments。commentはcurrent body contractの代替ではない。
- **Implementation facts:** latest remote `sayosomi/nuinuiCAD` repositoryとそのnormative source / specifications。
- **Execution / review / merge facts:** GitHub branches、commits、PRs、Actions checks、authoritative merge read-back。
- **Durable engineering / DSL specifications:** 対応するrepository-owned normative Markdown owner。
- **Linear Issues / Documents:** identity、URL、provenanceを保持する歴史的参照。例外として、既存のSAY taskが従来の `nuinui` lifecycleを実行中の場合だけ、既存flowが要求する最低限のLinear execution/status checkpointを記録できる。

GitHub Issue numberとSAY identifierは別のidentityであり、相互に置き換えない。dev-context自身のIssueは [root ISSUES.md](../../ISSUES.md) がownerする。このproject policyへdev-contextのpersistent worktree routingを持ち込まない。

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

`contract:ready`はimplementation開始許可ではない。implementation直前にcurrent owner、dependencies、acceptance、latest repository、execution routeを再auditする。fact driftだけでcontract choiceが変わらなければReadyを保ってrefreshする。Materialな選択が発生すればPendingへ戻し、必須prerequisiteを失えばBlockedにする。GitHub-native implementation自体はD1の実証完了まで開始しない。

## Existing mirror history and Linear compatibility

既存のLinear由来GitHub Issues / Documentsをrecreate、renumber、bulk rewrite、deleteしない。SAY URL、hidden `linear-issue-id` / `linear-document-id` / `linear-comment-id` markers、comments、close reason、attachment mappingを保持する。mirror由来の古いacceptanceをcurrent contractとして使う前に、そのIssueを個別にre-auditしてcurrent repository / specと照合する。履歴を現在のcontractに見せるため機械的に本文やlabelを書き換えない。

Linearは新しいWorkやDocumentの作成先ではなく、既存SAY taskの旧 `nuinui` lifecycleが必要とする最小限のexecution/status checkpointにだけ一時的に使える。このcheckpointはGitHub Issue contractやGitHub execution evidenceをsupersedeしない。新規Linear Work / Documents、bulk Linear update、reverse sync、mirroring再開は許可しない。Phase BでverifiedされたCloudflare Worker disabled production modeを維持し、8件のhistorical DLQ messageを未変更のまま保つ。

## Maintenance boundary

本documentはGitHub Issueのauthoring、current contract、readiness、freshness、completion、history preservationをownerする。Cutover checkpointは[#268](https://github.com/sayosomi/dev-context/issues/268)、GitHub PR linking / mergeは[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)、checkout / implementation lifecycleはlegacy互換の各ownerと後続D1 policyがownerする。個別TaskのSHA、branch、progressをこのdurable policyへ保存しない。
