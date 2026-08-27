# nuinuiCAD contract re-audit policy

## Purpose

既存のimplementation contractを、latest repositoryとcurrent nuinuiCAD rulesに基づいてIssueごとに全面再調査するcampaignを管理する。

通常のstart-time freshness checkより広く、過去に`Contract: Ready`だったこと自体を前提にせず、current implementation / architecture / product contract / dependency / verification / execution shapeを改めて確認する。

通常のcontract判断は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、status / label / checkpoint同期は [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)、chat role / handoffは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)、execution sliceは [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) がauthority。

## Marker

Linear Issue label `contract_reaudit` を一時的なcampaign markerとして使う。

意味は:

> このIssueの旧Ready contractは再調査未完了であり、current implementation routeとして信用しない。

`contract_reaudit`はContract stateそのものではない。再調査完了後もproduct decision待ちで`Contract: Pending`が残る場合があるため、両者を分離する。

残っている`contract_reaudit`件数をcampaignの未完了件数として扱えるようにする。

## Initial campaign marking

明示的な一斉再調査campaignを開始するとき、対象は原則としてunfinishedかつunstartedの既存`Contract: Ready` Issueとする。

対象Issueは一括で:

- `contract_reaudit`を追加する。
- `Contract: Ready`を`Contract: Pending`へ戻す。
- `Todo`なら`Backlog`へ戻す。
- 廃止済み`only_chatgpt`、およびReady contractを前提とする`manual_e2e_only`等のexecution-state labelは外す。
- Manual E2E labelは機械的に消去・再分類せず、旧判断として保持し、個別re-audit時に再評価する。

旧description内に`Contract Ready`、古いbaseline、旧owner等が書かれていても、campaign markingだけのために全Issue本文を機械的に書き換えない。`contract_reaudit + Contract: Pending`が「旧contractは現在未承認」を明示する。個別re-audit完了時にcurrent descriptionへ整合させる。

`Done` / `Canceled` / `Duplicate`は通常campaign対象外。

別チャットで`In Progress` / `In Review`のactive workを進めているIssueは、一斉resetでcurrent execution stateを壊さない。必要ならcurrent Taskのsafe checkpointで個別に扱う。

既に個別re-auditを開始して`Contract: Pending`へ戻っているIssueは、current stateを巻き戻さず`contract_reaudit`だけ追加してcampaign集合へ含めてよい。

## Concurrent update guard

一斉markingは、別チャット / runner / active Taskが同じIssueを同時にrefreshし得る前提で行う。

- campaign対象を列挙した時点のbaseline / cutoffを保持する。
- 各Issueを機械的にresetする直前にcurrent Linear state / labels / `updatedAt`相当のfreshnessを再確認する。
- baseline選定後に別作業でIssueが更新されていた場合、古いsnapshotから`Pending` / `Backlog` / markerを上書きしない。
- concurrentな個別re-auditが完了してcurrent `Ready`へ戻っているなら、そのfresh resultを維持しcampaign markerを付けない。
- concurrentな個別re-auditが進行中なら、current stateを読んでreconcileする。必要ならmarkerだけを追加してよいが、既に確定したfresh contract / route / statusを機械的に巻き戻さない。
- 誤ってstale bulk writeを行ったことに気づいた場合は、fresh concurrent recordをauthorityとして即座に復元し、そのIssueを以後のbulk対象から外す。

campaign markerを完全に揃えることより、freshな個別re-audit結果を壊さないことを優先する。

## Individual re-audit

個別re-auditは旧contractの単なる文面校正やfile-path refreshではない。

最低限、current Issueに関係する範囲で次を再確認する。

- latest Project Contextとcurrent durable rules;
- latest remote `sayosomi/nuinuiCAD`のactual implementation、owner、API、data flow、supported surface;
- repository normative spec / policyとcurrent Issueのproduct semantics / acceptance;
- current Issue description / comments / related Issues / Documentsにある過去decisionと、そのうち今も有効なもの;
- recently merged foundationやrelated workによって、既に実装済み・一部実装済み・重複・superseded・不要になったscopeがないか;
- dependency / blocker / parent-child boundary / same-Issue vs decompositionがcurrent architectureに合うか;
- Manual E2Eの必要性、oracle、fixture、executor classificationがcurrent stateに合うか;
- implementation slicingとexecution routeを、current executable sliceに対して改めて選べるか。

古いcontractを正当化するために調査しない。旧decisionがcurrent authorityと整合する部分は維持し、stale / contradictory / over-specified / under-specifiedな部分は明示して直す。

## Re-audit record

固定テンプレートへの穴埋めを目的にしない。Issueごとに拾える情報量と重要点が違うため、調査結果は**substantiveなissue-specific record**として残す。

特にmaterialなら次を記録する。

- current repositoryで確認した実装状況とprimary owner;
- 旧contractから残すdecision、捨てるassumption、変更するacceptance;
- code / normative contract / Issue記録の食い違いと、その解決根拠;
- 既に別Issueで実装されたscope、duplicate / superseded / missing scope;
- dependency / decomposition / sequencingの変更;
- unresolvedなreal product decisionと、ユーザー判断が必要な理由;
- Manual E2E / automated verificationのcurrent shape;
- current executable sliceとexecution routeを決められる場合、その根拠。

情報があるのに短い定型文へ圧縮しない。一方、関係のないrepository全体の調査結果や一般ruleをIssueへコピーしない。

Issue descriptionには再調査後のcurrent有効contractを置き、調査で得た重要なevidence / rationale / change summaryはCommentへ残してよい。

## Completion

個別re-auditが完了したら同じcheckpointで:

1. Issue descriptionをcurrent有効情報へ更新する。
2. `Contract`を`Ready` / `Pending` / `Blocked`の正しい状態へ同期する。
3. Manual E2E label / plan、dependency、Issue boundaryを再評価して同期する。
4. current executable sliceが存在する場合だけimplementation slicing / execution routeを再分類する。
5. execution ownerは廃止済みlabelではなく、current chat role、fixed lane、Luna policyから再判定する。
6. `contract_reaudit`を外す。
7. Issueのcurrent lifecycle phaseを先に判定し、[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のstatus synchronization precedenceに従ってstatusを同期する。
   - implementationがintended baseへmerge済みでrequired Manual E2Eだけが未完了なら`In Review`。
   - implementation前またはimplementation再開待ちのWorkだけ、readiness条件により`Todo` / `Backlog`。
   - re-audit完了や`Contract: Ready`への復帰だけを理由に`In Review`を`Todo` / `Backlog`へ戻さない。

re-audit自体は完了したがuser product decision待ちになった場合、`contract_reaudit`は外して`Contract: Pending`を残す。markerは「再調査が必要」ではなく「今回の再調査が未完了」を表す。

再調査の結果、Issue自体が不要・重複・完全にscope移管済みと判明した場合は、通常のIssue lifecycle / decomposition ruleに従って整理し、`Ready`へ戻すことを目的化しない。
