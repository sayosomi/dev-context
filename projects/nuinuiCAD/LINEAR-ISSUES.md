# nuinuiCAD Linear Issue workflow

## Purpose

Linear Issueのstatus、readiness、labels、metadata、recording、checkpoint synchronizationを定義する。

- execution ownership: [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md)
- Manual E2E classification / execution semantics: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- implementation contract判断: [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)
- implementation slicing / sequential PR: [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)
- Free plan capacity: [`LINEAR-CAPACITY.md`](./LINEAR-CAPACITY.md)

## Issue lifecycle

Feature / Task / Bug / Research / Verificationなど、実際に開始して完了する作業はIssueで管理する。

1つのWork itemは開始から完了まで同じIssueを更新し、進捗段階ごとに別Issueを増やさない。途中で見つかった追加作業をsame Issueに残すかnew Issueへ分けるかは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) をauthorityとする。

1つのIssueは複数のsequential implementation PR / execution trackを持ってよい。intermediate PRのmergeはIssue completionを意味せず、remaining acceptanceがある間は同じIssueを継続する。same Issue内のsafe merge checkpoint、next PR、pause / resume時の実装slice判断は [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) をauthorityとする。

通常の実装Issue:

```text
Backlog → Todo → In Progress → Done
                         ↘ In Review → Done
```

`In Review`は通常のPR review段階ではない。実装はmerge済みだが必要なManual E2Eが未完了のWorkを追跡するために使う。

Research / ReviewなどPRを伴わないIssueは、そのWork自体が完了した時点で`Done`へ進める。

### Decomposition and tracking parents

Issueを複数の独立leaf Issueへ完全に分解し、original scope / acceptanceをすべてleafへ移した場合、元Issueをpure tracking parentとして維持しない。

- original Work自体がresearch / decompositionで、そのacceptanceが完了したなら`Done`にしてよい。
- feature delivery Issueを分解しただけなら、分解した事実だけでfeatureを`Done`にしない。元Issueがremaining acceptanceを一切ownerしなくなったなら、child identifiersを記録したうえでsuperseded / no-longer-active tracking workとして`Canceled`へ進める。
- parentを残すのは、integrated Manual E2E、cross-child aggregate acceptance、final cutover / migration / cleanup等、leaf完了だけでは満たせないreal aggregate workを親自身がownerする場合だけ。

retained parentのexecution-ownership label ruleは [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) がauthority。

## Status

### Backlog

**まだ実装開始可能ではないWork**。

実装Issueでは主に次の間はBacklog:

- `Contract: Pending` または `Contract: Blocked`
- Manual E2E planが必要なのに `Manual E2E: Plan Pending`
- 未完了の`blockedBy` relationが1つ以上ある

Contract / E2E planが揃っていても未完了blockerがある間はBacklog。blocker relationが存在しても、そのblockerが`Done`ならReady判定上はblockingではない。

### Todo

**Ready Queueそのもの**。

実装Issueで次をすべて満たしたら原則Todoへ同期する。

- `Contract: Ready`
- Manual E2E planが確定済み、またはManual E2E不要
- 未完了blockerなし

通常の未着手IssueではManual E2Eは`Ready to Run`または`Not Required`になる。

既に検証履歴があるIssueでは`Failed` / `Deferred`等でも、実装再開可能で未blockedならTodoへ戻り得る。

Contract / E2E planが揃ったとき、または最後のblockerがDoneになったときはTodoへの同期を忘れない。Todoに新しい未完了blockerが追加された場合はBacklogへ戻す。

### In Progress

**ユーザーがチャットで明示的に開始した実作業**に使う。既に開始済みのexecution trackを継続する例外は、専用execution-ownership ruleが明示する場合だけ従う。

contract調査、候補比較、Issue本文更新、E2E plan策定だけではIn Progressにしない。

local Coding Agent / local execution Taskの同時実行は固定numeric limitで管理しない。既存checkoutのreuseを優先し、安全に必要なlocal isolationだけを追加する。詳細は [`CHECKOUTS.md`](./CHECKOUTS.md) をauthorityとする。

`only_chatgpt`はlocal worktree capacityの対象外。local checkoutが埋まっていることを理由に独立した`only_chatgpt` workを止めない。並行開始可否は [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) のinterference gateをauthorityとする。

Taskを中止・保留する場合、再開可能で未blockedならTodo、未readyまたはblockedならBacklogへ戻す。

### In Review

**実装はmerge済みだが、必要なManual E2Eが未完了のWork**。

主な形:

```text
In Review + Manual E2E: Ready to Run
In Review + Manual E2E: Deferred
```

PR open、review activity、blocking review、ready for mergeだけを理由にIn Reviewへ移さない。

Required Manual E2Eはmerge後実行がdefault。Manual E2Eを開始したら`Running`、確定FAILなら`Failed`、全required unit PASS後は`Passed`へ更新する。pre-merge E2EはTask contractが明示した例外だけ。

### Done

**Workの最終完了**。

実装Issueでは原則:

- implementationがintended baseへmerge済み
- required Manual E2Eが`Passed`または`Not Required`
- Done-before Ready contract freshness check完了

Manual E2Eが`Deferred` / `Running` / `Failed`のままDoneにしない。

## Done-before Ready contract freshness check

Issueを`Done`へ進める直前に、今回完了するWorkによって前提が変わり得る未完了Issueのうち`Contract: Ready`のものを確認する。

優先対象:

- direct dependent
- same subsystem / surface
- same owner / API / command / DSL surface

latest remote `main`とactual implementationを基準に、Ready contract内の次のようなcurrent factを確認する。

- file / API / type / subsystem owner名
- command ID、menu、surface、current UI behavior
- source model / DSL syntax / semantics
- dependency / blocker関係
- runtime / data-flow ownership、freshness boundary
- automated test fixture、Manual E2E手順、launch command
- capabilityの存在 / 非存在前提

今回の完了でReady contractが古くなった場合は、現在IssueをDoneにする前、または同じcompletion checkpoint内でactual stateへrefreshする。

`Contract: Ready`を維持してrefreshできるか、`Pending` / `Blocked`へ戻す必要があるかの判定は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) がauthority。既決定のsemantics / scope / acceptanceを変えずlatest authorityから一意に追従できるfact driftだけならReadyを維持する。

別チャットが担当中の`In Progress` / `In Review` Issue本文をfreshness checkだけを理由に直接書き換えない。必要ならそのTask側へdriftを引き継ぐ。

影響対象がなければ形式的な更新は不要。

## Ready Queue synchronization

Todoはreadiness + dependencyから導出されるmaterialized stateとして扱う。Linear自体にcomputed statusはないため、ChatGPTがcheckpointで同期する。

次のcheckpointで対象Issueと直接dependent IssueのReady判定を再確認する。

1. Contractが`Ready`になった
2. Manual E2Eが`Ready to Run`または`Not Required`になった
3. blocker relationを追加 / 削除した
4. blocker IssueがDoneになった
5. In Progressを終了 / 中止した
6. IssueをDoneへ進める

Ready条件を満たす未着手IssueはTodo、満たさない未着手IssueはBacklog。

## Required metadata on create

正式Issue作成時はLinear defaultに任せず次を明示する。

1. `state`
2. `Contract` labelを1つ
3. `Manual E2E` labelを1つ
4. 必要なtype label
5. 既に確定しているdependency relation

標準例:

- contract / E2E plan未確定
  - `Backlog + Contract: Pending + Manual E2E: Plan Pending`
- prerequisite待ち
  - `Backlog + Contract: Blocked + Manual E2E: Plan Pending`
- contract + E2E plan ready、未完了blockerなし
  - `Todo + Contract: Ready + Manual E2E: Ready to Run`
- Manual E2E不要、未完了blockerなし
  - `Todo + Contract: Ready + Manual E2E: Not Required`
- contract / E2E plan readyだが未完了blockerあり
  - `Backlog + Contract: Ready + Manual E2E: Ready to Run` または `Not Required`

本文の`Draft` / `contract pending` / `blocked`等とmetadataを一致させる。自由記述だけで状態を表さない。

Sayosomi Teamのdefault statusは防御策としてBacklogを推奨するが、ChatGPTはdefaultへ依存せず作成時に`state`を指定する。

## Idea Inbox

軽い思いつきだけでIssue数を増やさないため、常設Issue `SAY-55 — Idea Inbox — future work / 思いつきメモ` を使う。

- まだ調査・仕様策定・実装へ進めると決めていない案は原則新規Issueにせず`Ideas`へ追記する。
- ChatGPTは軽い思いつきを受け取ったとき、既存Issue化が明らかに必要でなければまずIdea Inboxへの追記を優先する。
- 独立したResearch / spec / implementation / Bug / Verificationとして扱う段階で既存Issue重複を検索し、正式Issueへ切り出す。
- 切り出した元項目は削除せず`→ SAY-xx`等で履歴を残す。
- 不要案は取り消し線または`Dropped`で残してよい。
- Idea Inbox自体はProjectなし、`Contract: N/A`、`Manual E2E: Not Required`。
- Inbox入りはimplementation予定・priority・contract確定を意味しない。
- capacityに余裕があるだけで全項目をIssue化しない。

## State label groups

正式なnuinuiCAD Work Issueにはtype labelとは別に、`Contract`から必ず1つ、`Manual E2E`から必ず1つを付ける。

### Contract

- `Pending`
  - implementation contractに必要なrepository調査、architecture判断、product decision、scope確定等が残る。
  - Coding Agentへそのままimplementation指示を渡せる状態ではない。
- `Blocked`
  - prerequisite、external capability、durable foundation等がなく、現時点ではimplementation contractを完成できない。
  - 条件が変わるまでactionableなcontract作業を期待しないIssueを通常の`Pending`と分離する。
- `Ready`
  - scope / product semantics / architecture / safety boundary等、implementation contractの本質的内容が確定済み。
  - Task開始時のlatest remote / actual owner refreshは引き続き行う。それだけでは`Pending`へ戻さない。
  - current fact / implementation pathを、既決定のsemantics / scope / acceptanceを変えず一意にrefreshできるdriftは`Ready`のまま追従する。
  - product / UX / scope / compatibility / acceptanceの再選択が必要なら`Pending`へ戻す。prerequisite自体がなくcontractを成立させられない場合は`Blocked`。
- `N/A`
  - Research / Review / specification discussion等、implementation contract自体を作るWorkではない。

implementation contractがcheckpointで確定したら`Pending → Ready`へ更新する。詳細判定は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) がauthority。

### Manual E2E

Aggregate Linear stateとして次を使う。

- `Plan Pending`
  - Manual E2Eが必要だが、concreteなtest plan / fixture / expected resultがまだ確定していない。
- `Ready to Run`
  - concreteなManual E2E planがあり、対象implementationが利用可能になればそのplanで検証できる。
- `Deferred`
  - Manual E2Eを意図的に後回しにしている。merge後に通常`In Review + Deferred`。
- `Running`
  - Manual E2Eを現在実施中。
- `Failed`
  - provisionalな違和感ではなく、Manual E2Eでconfirmed FAILが現在存在する。
- `Passed`
  - 必要なManual E2Eが完了し、current verification resultがPASS。
- `Not Required`
  - automated testsだけで全acceptanceを十分に証明でき、actual production execution environmentでしか確認できないrequired acceptanceやHuman quality judgmentがない。判定は [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。

代表遷移:

```text
Plan Pending → Ready to Run → Running → Passed
Ready to Run → Deferred → Running → Passed
Running → Failed
```

fix後は状況に応じて`Ready to Run`または`Running`へ戻し、rerun完了後に`Passed`へ進める。

unitごとのJudgment / Executor / PASS / FAIL / BLOCKED semanticsは [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。

Labelはcurrent stateのindexであり、過去のFAIL / fix / rerun履歴はCommentに残す。

## Saved views

### Now

Status `Todo` / `In Progress` / `In Review`。

- Todo = Ready Queue
- In Progress = active work
- In Review = merge済み・Manual E2E待ち

Todo自体をReady Queueとして同期するため、Now viewで同じContract / Manual E2E filterを重ねない。

### Ready Queue

Status `Todo`を見る。

Saved view側でreadiness条件を重複実装せず、status同期をsource of truthにする。

### Contract Pending

通常のcontract調査対象は`Contract: Pending`。

prerequisite待ちでactionableでないものは`Contract: Blocked`としPending viewへ混ぜない。

## Issue description and comments

Issue descriptionにはcurrentで有効な情報を置く。

- purpose
- scope
- non-goals
- implementation contract
- current important assumptions
- 必要に応じてManual E2E plan

Manual E2E planが長大、またはCommentで策定済みならcurrent planを示すCommentに置いてよい。Labelから`Ready to Run`か判断できる状態を維持する。

Commentには確定した作業記録を置く。

- research result
- Coding Agent implementation result
- implementation / merge checkpoint
- blocking review result
- Manual E2E result
- important decision record

Issueを閉じた後もcurrent authorityとして残し、複数future Taskで再利用する仕様・設計だけを [`LINEAR-DOCUMENTS.md`](./LINEAR-DOCUMENTS.md) のpromotion ruleに従って長期ownerへ移す。単に長いIssue本文を機械的にDocument化しない。

## Checkpoint-based updates

Linearをリアルタイム逐次ログとして使わない。チャット中の細かな進捗、仮説、見間違い、途中訂正をその都度反映しない。

主なcheckpoint:

1. repository調査とimplementation contract確定
2. Manual E2E plan確定
3. blocker relation / blocker completionでReady判定変更
4. userがTask開始 / 中止を明示
5. Coding Agent implementation完了
6. same Issue内のsafe merge / handoff checkpoint、またはnext sequential PRへの移行
7. blocking review完了
8. PR merge
9. Manual E2E開始 / 延期 / FAIL確定 / 完了
10. 例外的Project assignment / Project cleanup
11. decompositionで元tracking Issueのownershipがなくなった

same Issue内のintermediate merge checkpointでは [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) のrecord shapeに従い、completed acceptance / remaining acceptance / next intended slice / next baseを記録する。intermediate mergeをIssue completionとして扱わない。

各checkpointでReady状態が変わり得るdirect dependentも確認する。

担当外チャットから`In Progress` / `In Review` Issue本文・status・progress recordを不用意に変更しない。dependency解消等の全体metadata同期だけは実態を確認して行ってよい。

必要なければ更新を増やさず、複数の確定事項を1回の更新へまとめる。

## Manual E2E recording in Linear

Manual E2E中のユーザー / Luna報告は、確定するまではprovisional observationとして扱う。

- `FAILかもしれない`
- 表示がおかしい
- 見間違い
- rerunでPASS

等を1件ずつ恒久記録しない。結果が落ち着いたまとまりごとにCommentへ記録する。

単なる違和感や未確認の疑いだけで`Failed`へ変更しない。confirmed failureが残るときだけ`Failed`。

aggregate stateは [`MANUAL-E2E.md`](./MANUAL-E2E.md) と [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) に従って同期する。

Manual E2Eを意図的に後回しへDeferredする場合は通常:

```text
In Review + Manual E2E: Deferred
```

all required units PASS後:

```text
Manual E2E: Passed
→ Done-before Ready contract freshness check
→ Done
```

Manual E2E failure後のimplementation ownershipは [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md)、same-Issue fix / separate Issue判断は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) をauthorityとする。test-environment mistakeやLuna capability limitationをimplementation failureとして記録しない。

## Post-write verification

Issueを作成または重要metadataを更新した直後は、そのIssueを再取得して少なくとも確認する。

- intended status
- Ready条件とBacklog / Todoの一致
- `Contract` labelが1つ
- `Manual E2E` labelが1つ
- descriptionのDraft / Ready / Blocked等とmetadataの整合
- intended dependency relation

不一致があれば操作完了扱いにする前に修正する。