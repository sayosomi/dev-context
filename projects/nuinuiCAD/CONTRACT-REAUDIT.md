# nuinuiCAD individual GitHub Issue contract re-audit

## Purpose and authority

個別のGitHub Issue contractを、latest repositoryとcurrent nuinuiCAD rulesに照らして再調査する手順を定める。C1後のnormal routeはIssueごとのtargeted re-auditであり、Linear campaignやbulk relabelではない。

Current Issue body / comments / freshness / completionは[`ISSUES.md`](./ISSUES.md)、product decisionとdecompositionは[`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、chat routingは[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)、implementation slicingは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)がownerする。Pre-existing SAY execution checkpointだけがLinear status compatibilityを必要とする場合、その既存ownerを読む。

## Individual re-audit

古い`contract:ready` text / labelがあることだけを根拠にcontractを維持しない。対象Issueを一件ずつfreshに読み、関係する範囲で次を再確認する。

- latest Project Contextとcurrent durable rules;
- latest remote `sayosomi/nuinuiCAD`のactual implementation、owner、API、data flow、supported surface;
- repository normative specification / policyとIssueのcurrent semantics / acceptance;
- current Issue body / material comments / related Issues / PRsにある過去decisionと、今も有効なもの;
- recently merged foundationやrelated workによって実装済み・一部実装済み・duplicate・superseded・不要となったscope;
- dependency / blocker / parent-child / same-Issue decomposition boundary;
- Manual E2Eの必要性、oracle、fixture、Human executor;
- current executable sliceとexecution route。ordinary GitHub-native startupは一般D1 activation checkpoint後にGit-only routeを使う。それ以前のstartupは保留する。

古いcontractを正当化するためではなく、current authorityから新たに判断する。旧decisionが整合する箇所は維持し、stale / contradictory / over-specified / under-specifiedな箇所を明示する。current authorityが複数の合理的な選択を残す場合は`contract:pending`にし、durable product decisionをChatGPTが代わりに決めない。必須prerequisiteが欠ける場合は`contract:blocked`にする。

## Freshness and concurrent-write guard

Issueを変更する直前に、target Issue body / material comments、latest repository / relevant normative owner、関係するIssue / PRをfreshに再取得する。調査snapshot後にHumanまたは別chatが追加したcontract updateを消さない。

Independentな追記はreconcileする。scope、acceptance、またはdurable decisionが競合し一意に解決できない場合はstale writeを行わずHumanへ戻す。write後はIssueを再取得し、body、comments、readiness、open / closed stateが意図したcurrent recordになったことを確認する。

個別re-auditではIssue固有のsubstantiveな結果を記録する。必要に応じて、current implementation / primary owner、残すdecisionと更新するassumption / acceptance、code・normative spec・Issueの不一致と根拠、別Workへ移管またはsupersedeされたscope、dependency / decomposition、未解決のHuman decisionとその理由、Manual E2E / automated verificationのcurrent shapeを含める。Current contractはIssue bodyへ反映し、material evidence / rationale / audit resultはcommentsへ残す。Issue本文へobsolete historyを積み重ねず、chat transcriptを複製しない。

## Completion

個別re-auditが完了したら、同じcheckpointで次を行う。

1. Issue bodyをcurrent valid contractへ更新し、必要なevidence / rationaleをcommentへ残す。
2. readiness labelをすでに運用している場合だけ、`contract:ready` / `contract:pending` / `contract:blocked`のうち正しい状態へ合わせる。C1はlabel作成またはbulk updateを要求しない。
3. Manual E2E、dependency、Issue boundaryを再評価する。
4. current executable sliceがある場合はimplementation slicing / execution routeを確認する。GitHub-native Workのstartupは一般D1 activation checkpoint前なら保留し、checkpoint後はGit-only policyに従う。
5. Close前にはlatest repository `main`、Issue body / comments、required review / verification、全acceptance、Required Human Manual E2Eを独立に確認する。mergeだけで未完了Issueをcloseしない。
6. write後のIssue read-backを確認する。

re-audit自体は完了したがproduct decision待ちなら`contract:pending`を残す。再調査の結果、Workが不要・duplicate・scope移管済みと判明した場合はGitHub Issue lifecycleに従い整理し、Readyに戻すことを目的にしない。

## Historical Linear campaign

過去にはLinear `contract_reaudit` marker、Linear Contract status、Ready Queue statusをbulk更新するre-audit campaignが存在した。そのmarker / cutoff / concurrent-update記録と当時の手順はmigration historyとしてだけ参照する。C1後のnormal Work、GitHub-native Issue、または個別re-auditのために、そのcampaign markerを作成・適用したり、Linear label / status / descriptionを一括変更したりしない。

既存SAY taskが従来の`nuinui` execution lifecycle上にあり、そのlifecycle自身がcheckpointを要求する場合だけ、current Issue contractを書き換えず最低限のLinear execution/status checkpointを残せる。これをre-audit campaignやLinear authorityの復帰に拡張しない。
