# nuinuiCAD Linear運用ルール

## 目的

LinearをnuinuiCADの正式なWork管理・長期仕様管理の場所として使う。

ユーザー自身が管理画面を細かく操作することより、ChatGPTが安定して検索・作成・更新できることを優先する。

Notionはlegacy archiveとして残し、新規Work / Specの管理先には使わない。

## 基本構造

- Workspace: Sayosomi
- Team: Sayosomi
- Initiative: nuinuiCAD
- Project: 数日〜数週間で完了できるexecution phase
- Project label: Projectの分野分類
- Issue: 実際に着手・完了する作業
- Document: 長期的に残す仕様・設計文書

Taskや個別開発テーマをInitiativeにしない。
製品ごとにTeamを増やさず、当面はSayosomi Team 1つで運用する。

## 新規作成前の検索

Initiative / Project / Issue / Documentを新規作成する前に、必ず既存項目を検索する。

同じものがある場合は新規作成せず更新する。

Canceledになっている移行試験用Issueや旧カテゴリProjectなどが残っている場合があるため、タイトルだけで判断せず内容とstatusも確認する。

まだ独立Workとして扱うほど固まっていない軽い思いつきは、新規Issueを起票せず、後述の `Idea Inbox — future work / 思いつきメモ` へ追記する。

## Project

Projectは**終わる単位**として使う。

複数Issueをまとめて進め、数日〜数週間程度でCompletedにできるexecution phaseを基本とする。

例:

- Canvas Selection / Navigation v1
- Geometry Editing / Bake v1
- Modifier Editor Integration v1
- Print Layout v1

`Language / Editor Integration`、`Module`、`DSL / Geometry`、`Automation / MCP`のような長期カテゴリをProjectとして常設しない。

まだ着手時期が決まっていない将来Issueは、原則としてProjectなしのBacklogで保持する。
一連の作業として着手する段階で、完了可能な短期Projectを作成し、対象Issueを移す。

Project内の必要Issueが完了したら、ProjectもCompletedにする。
Done Issueを未完了Projectへ長期間残してauto-archiveを妨げない。

旧カテゴリProjectは履歴としてCanceledのまま残してよいが、新規Workの分類箱として再利用しない。

個々の単発実装Taskを機械的に1 Issue = 1 Projectにはしない。複数Issueをまとめて完了条件を持てる開発phaseだけをProject化する。

## Project labels

Project labelは「何の分野のProjectか」を表す。
statusや進捗段階をProject labelで重複表現しない。

現在は2つのProject label groupを使う。

### Surface

1 Projectにつき必要なものを1つ選ぶ。

- `VS Code / Editor`
- `Canvas`
- `Print Layout`

### Domain

必要なProjectだけ1つ選ぶ。

- `DSL / Geometry`
- `Module`
- `Automation / MCP`

SurfaceとDomainは異なる観点なので、1 Projectにそれぞれ1つずつ付けてよい。

現在の代表例:

- Canvas Selection / Navigation v1
  - Surface: `Canvas`
- Modifier Editor Integration v1
  - Surface: `VS Code / Editor`
- Geometry Editing / Bake v1
  - Surface: `Canvas`
  - Domain: `DSL / Geometry`
- Print Layout v1
  - Surface: `Print Layout`

新しいProject label / label groupを勝手に増やさない。
既存分類で表現できない場合はユーザーと決めてから追加する。

## Issue

Feature / Task / Bug / Research / Verificationなど、実際に開始して完了する作業はIssueで管理する。

1つのWork itemは、開始から完了まで同じIssueを更新する。
進捗段階ごとに別Issueを増やさない。

通常の実装Issueは次のflowを使う。

```text
Backlog → Todo → In Progress → Done
                         ↘ In Review → Done
```

`In Review`は通常のPR review段階を表すstatusではない。実装をmergeしたが、必要なManual E2Eを後回しにしてまだ完了判定できない場合に使う。

Issue statusは現在のWork状態を表す。ContractとManual E2Eの準備・検証状態は後述のLabel Groupで独立管理する。

Research / ReviewなどPRを伴わないIssueでは、そのWork自体が完了した時点で`Done`へ進める。

### Statusの意味

- `Backlog`
  - **まだ実装開始可能ではないWork**を置く。
  - 実装Issueでは、次のいずれかに該当する間は原則Backlogとする。
    - `Contract: Pending` または `Contract: Blocked`
    - Manual E2E planが必要なのに `Manual E2E: Plan Pending`
    - 未完了の`blockedBy` relationが1つ以上ある
  - Contract / E2E planが揃っていても、未完了blockerがある間はBacklog。
  - blocker relationが存在しても、そのblockerが`Done`ならReady判定上はblockingではない。

- `Todo`
  - **Ready Queueそのもの**。
  - Todoへ入れるかどうかをreadinessとは別の人間判断にしない。
  - 実装Issueで次をすべて満たしたら、ChatGPTは原則として機械的にTodoへ同期する。
    - `Contract: Ready`
    - Manual E2E手順が確定済み、またはManual E2E不要
    - 未完了のblockerがない
  - 通常の未着手IssueではManual E2Eは`Ready to Run`または`Not Required`になる。
  - 既に検証履歴があるIssueでは`Failed` / `Deferred`等でも、実装再開可能で未blockedならTodoへ戻り得る。
  - Contract/E2E planが揃った時、または最後のblockerがDoneになった時は、Todoへ上げ忘れない。
  - Todoに新しい未完了blockerが追加された場合はBacklogへ戻す。

- `In Progress`
  - **ユーザーがチャットで明示的に「始める」としたIssueだけ**に使う。
  - contract調査、候補比較、Issue本文更新、E2E plan策定だけではIn Progressにしない。
  - nuinuiCADの通常運用では、primary worktreeとpersistent sub worktreeの実装Taskに対応するため、同時In Progressは原則最大2件。
  - primary / subのどちらかでTaskを明示的に開始した時点で、対象TodoをIn Progressへ移す。
  - Taskを中止・保留してworktreeを空ける場合、再開可能で未blockedならTodo、未readyまたはblockedならBacklogへ戻す。

- `In Review`
  - **実装はmerge済みだが、必要なManual E2Eが未完了のWork**に使う。
  - 主な形は `In Review + Manual E2E: Deferred`。
  - PRを開いた、review activityがあった、blocking review中、ready for mergeになった、という理由だけではIn Reviewへ移さない。
  - merge後にManual E2Eをすぐ実施できず後回しにする場合、IssueをIn Reviewに残して未完了Workとして追跡する。
  - 後回しにしたManual E2Eを開始したら`Running`、確定FAILなら`Failed`、全てPASSしたら`Passed`へ更新する。
  - 必要なManual E2Eが最終的にPASSした時点でDoneへ進める。

- `Done`
  - **Workの最終完了**。
  - 実装Issueでは原則、実装がmerge済みで、必要なManual E2Eが`Passed`または`Not Required`になった時点でDone。
  - Manual E2Eが必要なのに`Deferred` / `Running` / `Failed`のままDoneにしない。
  - Manual E2Eをmerge前に完了済みなら、merge時点でDoneへ進めてよい。

### Ready Queue同期ルール

Todoはreadinessとdependencyから導出されるmaterialized stateとして扱う。Linear自体にcomputed statusはないため、ChatGPTがcheckpointで同期する。

次のcheckpointでは必ず対象Issueと直接dependentなIssueのReady判定を再確認する。

1. Contractが`Ready`になった時
2. Manual E2Eが`Ready to Run`または`Not Required`になった時
3. blocker relationを追加・削除した時
4. blocker IssueがDoneになった時
5. In Progressを終了・中止してactive slotを空けた時

Ready条件を満たす未着手IssueはTodo、満たさない未着手IssueはBacklogにする。

## Issue作成時の必須metadata

正式Issueを作成するときは、Linearのdefaultに任せず次を**明示的に指定**する。

1. `state`
2. `Contract` labelを1つ
3. `Manual E2E` labelを1つ
4. 必要なtype label
5. 既に確定しているdependency relation

`state`を省略してLinear teamのdefault statusへフォールバックさせない。

実装Issueの標準的な作成状態:

- contract / E2E planが未確定
  - `Backlog + Contract: Pending + Manual E2E: Plan Pending`
- prerequisite待ちで現時点ではcontractを完成できない
  - `Backlog + Contract: Blocked + Manual E2E: Plan Pending`
- contractとE2E planが確定済み、かつ未完了blockerなし
  - `Todo + Contract: Ready + Manual E2E: Ready to Run`
- Manual E2E不要、かつ未完了blockerなし
  - `Todo + Contract: Ready + Manual E2E: Not Required`
- contract / E2E planは確定済みだが未完了blockerあり
  - `Backlog + Contract: Ready + Manual E2E: Ready to Run` または `Not Required`

Issue本文に`Draft` / `contract pending` / `blocked`などと書いた場合、その文言とmetadataを一致させる。本文の自由記述だけで状態を表し、status / labelを未設定のままにしない。

Sayosomi Teamのdefault issue statusは防御策として`Backlog`を推奨する。ただしdefault設定に依存せず、ChatGPTは作成時に必ず`state`を明示する。

## Idea Inbox

軽い思いつきだけでIssue数を増やさないため、常設Issue `SAY-55 — Idea Inbox — future work / 思いつきメモ` を使う。

Idea Inboxは**実装対象Issueではなく、独立Workへ昇格する前の一時保管場所**とする。

運用:

- まだ調査・仕様策定・実装へ進めると決めていない思いつきは、原則として新規Issueを作らずIdea Inboxの`Ideas`へ箇条書きで追記する。
- ChatGPTはユーザーから軽い思いつきを受け取ったとき、既存Issue化が明らかに必要でなければまずIdea Inboxへの追記を優先する。
- 独立した調査、仕様策定、実装、Bug修正、Verificationなどとして扱う段階になったら、既存Issueとの重複を検索したうえで正式Issueへ切り出す。
- 切り出した元項目は削除せず、`→ SAY-xx`のように切り出し先を記録して履歴を残す。
- 不要になった案は取り消し線または`Dropped`で残してよい。
- Idea Inbox自体はProjectに所属させない。
- Idea Inbox自体は`Contract: N/A` / `Manual E2E: Not Required`とする。
- Idea Inboxへ入っているだけの項目は、実装予定・優先順位確定・implementation contract確定を意味しない。
- Issue枠に余裕が出たことだけを理由に機械的に全項目をIssue化しない。

## Issue state labels

Issue一覧だけでimplementation contractとManual E2Eの現在状態を判断できるよう、type labelとは別に2つのLabel Groupを使う。

正式なnuinuiCAD Work Issueには、`Contract`から**必ず1つ**、`Manual E2E`から**必ず1つ**を付ける。

既存の`Feature` / `Improvement` / `Bug`等はWorkの種類を表すlabelとして併用する。

### Contract

- `Pending`
  - implementation contractに必要なrepository調査、architecture判断、product decision、scope確定などがまだ残っている。
  - Coding Agentへそのまま実装指示を渡せる状態ではない。
- `Blocked`
  - prerequisite、external capability、durable foundationなどが存在せず、現時点ではimplementation contractを完成できない。
  - 条件が変わるまでactionableなcontract作業を期待しないIssueを通常の`Pending`と分離する。
- `Ready`
  - scope / product semantics / architecture / safety boundaryなど、implementation contractの本質的な内容が確定済み。
  - Task開始時のlatest remote確認、actual owner / symbol / file pathのrefreshは引き続き行う。それだけでは`Pending`へ戻さない。
  - latest repositoryで実質的なcontract contradictionが見つかった場合だけ再調査する。
- `N/A`
  - Research / Review / specification discussionなど、implementation contract自体を作るWorkではない。

implementation contractがcheckpointで確定したら`Pending → Ready`へ更新する。

### Manual E2E

- `Plan Pending`
  - Manual E2Eが必要だが、具体的なtest plan / fixture /期待結果がまだ確定していない。
- `Ready to Run`
  - concreteなManual E2E planがあり、対象実装が利用可能になればそのplanで検証できる。
- `Deferred`
  - Manual E2Eを意図的に後回しにしている。
  - mergeを先に行った場合は通常`In Review + Deferred`で保持する。
- `Running`
  - Manual E2Eを現在実施中。
- `Failed`
  - provisionalな違和感ではなく、Manual E2Eで確定したFAILが現在存在する。
- `Passed`
  - 必要なManual E2Eが完了し、現在のverification resultがPASS。
- `Not Required`
  - このIssueではManual E2Eを必要としない。

代表的な遷移:

`Plan Pending → Ready to Run → Running → Passed`

後回しにする場合:

`Ready to Run → Deferred → Running → Passed`

FAIL時:

`Running → Failed`

修正後は状況に応じて`Ready to Run`または`Running`へ戻し、再検証完了後に`Passed`へ進める。

Labelは**現在状態のindex**であり、過去のFAIL /修正 /再検証履歴はCommentに残す。

## Saved views

### Now

`Now`は、次に開始できるReady Queueと現在未完了の実作業をまとめて見るviewとする。

条件:

- Status: `Todo` / `In Progress` / `In Review`

意味:

- `Todo` = Ready Queue
- `In Progress` = primary / persistent subで現在実装中
- `In Review` = merge済み・Manual E2E待ち

Todo自体をReady Queueとして同期するため、Nowでは追加のContract / Manual E2E filterを重ねない。

### Ready Queue

`Ready Queue`はStatus `Todo`を見るviewとする。

Todoは次のreadiness条件から同期される。

- `Contract: Ready`
- Manual E2E planが確定済み、または`Not Required`
- 未完了blockerなし

Saved view側で同じreadiness条件を重複実装せず、status同期をsource of truthにする。

### Contract Pending

通常のcontract調査対象は `Contract: Pending` で見る。

prerequisite待ちでactionableでないものは `Contract: Blocked` とし、`Pending` viewへ混ぜない。

## GitHub Pull Request連携

LinearのGitHub integrationを使い、Linear IssueとGitHub Pull Requestをリンクする。

PRとIssueの標準的な紐付けは、PR descriptionにclosing magic wordとIssue identifierを記載する方式とする。

例:

`Fixes SAY-38`

`Linear: SAY-38`のような単なるラベルだけを標準の紐付け方法にはしない。
branch名へLinear Issue identifierを入れることも必須にしない。

### Pull request automations

Sayosomi TeamのLinear `Workflows & automations > Pull request automations` は、**5項目すべて `No action` を維持する**。

- On draft PR open → `No action`
- On PR open → `No action`
- On PR review request or activity → `No action`
- On PR ready for merge → `No action`
- On PR merge → `No action`

GitHub integrationはPRとIssueのリンクには使うが、Issue statusの決定には使わない。PRイベントだけでは`In Progress` / `In Review` / `Done`の意味を判定できないため、status automationを有効化しない。

### PRとstatusの関係

PR lifecycleだけでIssue statusを決めない。

- draft PR open → status変更なし
- PR open → status変更なし
- PR review request / activity → status変更なし
- PR ready for merge → status変更なし
- PR merge → Manual E2E状態を確認してChatGPTが最終statusを同期する

通常、実装開始済みTaskはPR作成・blocking review・merge直前まで`In Progress`のまま。

PR merge時:

- Manual E2Eが`Passed` → `Done`
- Manual E2Eが`Not Required` → `Done`
- Manual E2Eが必要だが後回し → `In Review + Deferred`
- Manual E2Eがmerge前から`Failed`で未解決 → 原則mergeしない

Pull request automationsはすべて`No action`なので、PRイベントによる自動status変更は前提にしない。merge後のstatus / Manual E2E labelはChatGPTが実態を確認して更新する。

## Issue descriptionとComment

Issue descriptionには、現在も有効な情報を置く。

- 目的
- scope
- non-goals
- implementation contract
- 現在も有効な重要前提
- 必要に応じてManual E2E plan

Manual E2E planが長大な場合や既にCommentで策定済みの場合は、current planを示すCommentに置いてもよい。Labelで`Ready to Run`かどうかを一覧から判断できる状態を維持する。

Commentには、確定した作業記録を置く。

- 調査結果
- Coding Agent実装結果
- blocking review結果
- Manual E2E結果
- 重要な判断記録

長期仕様はIssue本文へ埋め込まずDocumentへ置く。

## Linear更新はcheckpoint-basedにする

Linearをリアルタイムの逐次ログとして使わない。

チャット中の細かな進捗、仮説、見間違い、途中訂正をその都度Linearへ反映しない。

原則として、次のようなまとまったcheckpointで更新する。

1. repository調査とimplementation contractが確定したとき
2. Manual E2E planが確定したとき
3. blocker relationまたはblocker完了でReady判定が変わったとき
4. ユーザーが明示的にTask開始・中止を宣言したとき
5. Coding Agentの実装が完了したとき
6. blocking reviewが完了したとき
7. PRをmergeしたとき
8. Manual E2Eを開始・延期・FAIL確定・完了したとき
9. ProjectへIssueをまとめる、ProjectをCompletedにするなどexecution phaseの境界が確定したとき

各checkpointで、対象IssueだけでなくReady状態が変わり得る直接dependent Issueも確認する。

In Progress / In ReviewのIssueについて、直接そのTaskを担当していない別チャットからIssue本文・status・進捗記録を不用意に変更しない。dependency解消など全体管理上必要なmetadata同期だけは、実態を確認したうえで行ってよい。

必要がなければ各checkpointでも更新を増やさず、複数の確定事項を1回の更新にまとめる。

## Manual E2E中の扱い

Manual E2E中のユーザー報告は、その場ではprovisionalな観測として扱う。

例:

- PASS
- FAILかもしれない
- 表示がおかしい
- 見間違いだった
- 再確認したらPASSだった

これらを1件ずつLinearへ記録しない。

チャット上で確認・訂正を続け、結果が落ち着いたまとまりごとにLinearへ反映する。

E2E結果は、可能なら複数testをまとめて1 Commentに記録する。

例:

- Tests 1–6: PASS
- Tests 7–9: PASS
- Test 10: FAIL — 修正対象として確定
- Tests 11–12: PASS

単なる違和感や未確認の疑いは、修正対象と確定するまで`Failed`へ変更したり恒久記録したりしない。

Manual E2E開始時は必要に応じて`Running`へ更新する。まとまったFAILが確定したら`Failed`、最終的に必要な検証がすべて通ったら`Passed`へ更新する。

## Manual E2Eをmerge後に実施する場合

Manual E2Eをすぐ実施できない場合、blocking reviewとrequired automated verificationが十分なら、Manual E2Eを`Deferred`として先にmergeしてよい。

この場合:

1. PRをmergeする。
2. 元Issueを`In Review + Manual E2E: Deferred`にする。
3. worktreeは次Taskへ使ってよい。
4. 後日Manual E2Eを開始するとき`Running`へ更新する。
5. 全必要checkがPASSしたら`Passed + Done`へ進める。

`In Review`は未完了Workなので、Deferred E2Eが残っている間はDoneにしない。

### merge後E2Eで問題が見つかった場合

merge後のManual E2Eで実装不備が確定した場合:

1. 元Issueは`In Review`のまま維持する。
2. 元IssueのManual E2E labelを`Failed`へ変更する。
3. 元Issueへ確定したE2E結果をCommentで記録する。
4. 修正用の新しい`Bug` Issueを作成し、元Issueとrelated relationで紐付ける。
5. Bug Issue側で修正・mergeを行う。
6. 元Issueで該当Manual E2Eを再実施する。
7. 問題解消を確認できたら元Issueを`Passed + Done`へ更新する。

一方、**merge前**のManual E2Eで見つかったscope内の不具合は、原則として新Bugへ切り出さず、元Issueを`In Progress`のまま同じTask内で修正する。

ただしE2E中に見つかった問題が明確に別scope /既存問題である場合は、merge前でも独立Bug Issueへ切り出してよい。

## Documents

Linear Documentsを長期仕様・設計文書の正式な保存先とする。

Spec Document冒頭には、必要に応じてmetadataをテキストで持たせる。

例:

```text
Status: Ready
Area: Typed Expression / Evaluation / Module
Category: DSL
Source: ...
```

Spec statusとして必要に応じて以下を使う。

- Draft
- Ready
- Current
- Superseded

一時的なimplementation contract、調査ログ、Manual E2E plan、完了済みTask planを長期SpecとしてDocument化しない。

## Source of truth

- 実装済み事実 / actual code: latest repository
- 作業予定・進捗・調査結果: Linear Issue / Project
- 長期仕様・設計: Linear Document
- 移行前の履歴: Notion legacy archive

実装事実についてLinear / Notion / 過去チャットとrepositoryが矛盾する場合は、latest repositoryをauthoritativeとする。

移行前から進行中のTaskが特定の未移行Notion Specを明示的なsource of truthとして開始済みの場合だけ、そのTaskの次の明確なcheckpointまではNotion参照を継続してよい。checkpoint後にSpecをLinear Documentへ移行し、Issue側の参照先を更新する。

## 新Task開始時

ChatGPTは新規開発Task開始前に:

1. GitHub remote stateを確認する
2. Linearで既存Issue / Projectを検索する
3. Linear Documentsから必要なSpecを確認する
4. 対象Issueの`Contract` / `Manual E2E` label、dependency、本文・Commentを確認する
5. 対象IssueがReady条件を満たすならTodoになっていることを確認する
6. ProjectなしIssueを着手する場合、既存の短期execution Projectへ属するWorkか確認し、必要なら新しい短期Projectを作成する
7. Projectへ所属させる場合、適切な`Surface` / `Domain` Project labelを付ける
8. ユーザーがそのTaskを明示的に「始める」とした時点でIn Progressへ更新する
9. `Contract: Ready`でもlatest remote / actual ownerを再確認してからCoding Agentへの実装指示を作る

`Contract: Pending`の調査を進めること自体はIn Progressへの変更理由にしない。

新規TaskでNotionを通常のSpec検索先として使わない。
必要なSpecがLinearに見つからず、legacy Notionにのみ存在する場合は、内容と現在性を確認したうえでLinear Documentへ移行してから正式な参照先にする。

開始時以外の進捗更新はcheckpoint-basedで行う。

## ChatGPTが管理操作を担当する

ユーザーにLinearの手動更新を要求しない。

Issue作成、状態変更、Label更新、Project紐付け、Project label付与、Comment追加、Document更新などは原則ChatGPTが行う。

Linear APIで未対応の管理操作のみ、必要な最小限のUI操作をユーザーに依頼してよい。

新しい分類・status・label groupを勝手に追加しない。必要な場合はユーザーと運用を決めてから追加する。

Issueを作成または重要metadataを更新した直後は、そのIssueを再取得し、少なくとも次を確認する。

- intended statusになっている
- Ready条件とBacklog / Todoが一致している
- `Contract` labelが1つだけ付いている
- `Manual E2E` labelが1つだけ付いている
- 本文のDraft / Ready / Blocked等の記述とmetadataが矛盾していない
- 指定したdependency relationが反映されている

不一致があれば、その操作を完了扱いにする前に修正する。

Linear管理自体が開発作業の主目的にならないよう、必要な記録だけをまとめて更新する。

## Coding Agentとの役割分担

Linear運用によってChatGPT / Coding Agentの役割分担は変更しない。

ChatGPTがrepository調査・architecture把握・implementation contract・blocking review・Manual E2E plan策定・Linear管理を担当する。

Coding Agentは確定済みcontractに従い、実装・test・commit・pushを行う。

Coding Agent開始前の `git fetch origin --prune` とremote state確認は引き続き必須。