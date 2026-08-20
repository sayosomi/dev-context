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

基本status:

Backlog → Todo → In Progress → In Review → Done

すべてのIssueが全statusを通る必要はない。

Issue statusは作業進行を表す。Manual E2Eの準備・実施状態はstatusへ混ぜず、後述のLabel Groupで独立管理する。

実装Issueでは、PR mergeで`Done`になったこととManual E2Eが完了したことを同義にしない。`Done + Manual E2E: Deferred`や、後日問題が確認された`Done + Manual E2E: Failed`も正当な状態として扱う。

Research / ReviewなどPRを伴わないIssueでは、そのWork自体が完了した時点で`Done`へ進める。

### Statusの意味

- `Backlog`
  - 将来Work、contract調査待ち、dependency待ち、またはreadyではあるが現在の着手queueへまだ入れないIssueを置く。
  - `Contract: Pending` / `Contract: Blocked` / `Manual E2E: Plan Pending` の実装Issueは原則ここに置く。
  - `Contract: Ready`かつManual E2E準備済みでも、ユーザーがまだ次の着手候補へ上げていないIssueはBacklogのままでよい。readiness labelは準備状態、statusは着手予定を表す。
- `Todo`
  - **実際に開始可能で、次の着手候補として明示的にqueueへ入れたWork**に使う。単なる「未着手」や「Issueを作った」ことを意味しない。
  - 実装Issueを`Todo`へ置くには、原則 `Contract: Ready` かつ Manual E2Eが `Ready to Run` または `Not Required` であること。
  - readiness labelが揃ったことだけを理由にBacklogからTodoへ自動的に移さない。Todoへの移動はqueueへ入れるという独立した判断とする。
- `In Progress`
  - ChatGPTによるcontract調査を含め、そのIssueの作業を実際に開始したときに使う。
- `In Review`
  - 実装・blocking review・merge前確認の段階。
- `Done`
  - Work自体が完了した状態。Manual E2Eの最終状態とは独立する。

### Issue作成時の必須metadata

正式Issueを作成するときは、Linearのdefaultに任せず次を**明示的に指定**する。

1. `state`
2. `Contract` labelを1つ
3. `Manual E2E` labelを1つ
4. 必要なtype label
5. 既に確定しているdependency relation

`state`を省略してLinear teamのdefault statusへフォールバックさせない。

実装Issueの標準的な作成状態:

- contract / E2E planが未確定のdraft
  - `Backlog + Contract: Pending + Manual E2E: Plan Pending`
- prerequisite待ちで、現時点でactionableなcontract作業がない
  - `Backlog + Contract: Blocked + Manual E2E: Plan Pending`
- contractとE2E planが確定済みで、次の着手queueへ入れるWork
  - `Todo + Contract: Ready + Manual E2E: Ready to Run`
- Manual E2E不要で、次の着手queueへ入れるWork
  - `Todo + Contract: Ready + Manual E2E: Not Required`
- contractとE2E planが確定済みだが、まだqueueへ入れないWork
  - `Backlog + Contract: Ready + Manual E2E: Ready to Run` または `Not Required`

Issue本文に `Draft` / `contract pending` / `blocked` などと書いた場合、その文言とmetadataを一致させる。本文の自由記述だけで状態を表し、status / labelを未設定のままにしない。

Sayosomi Teamのdefault issue statusは防御策として`Backlog`を推奨する。ただしdefault設定に依存せず、ChatGPTは作成時に必ず`state`を明示する。

## Idea Inbox

軽い思いつきだけでIssue数を増やさないため、常設Issue `SAY-55 — Idea Inbox — future work / 思いつきメモ` を使う。

Idea Inboxは**実装対象Issueではなく、独立Workへ昇格する前の一時保管場所**とする。

運用:

- まだ調査・仕様策定・実装へ進めると決めていない思いつきは、原則として新規Issueを作らずIdea Inboxの`Ideas`へ箇条書きで追記する。
- ChatGPTはユーザーから軽い思いつきを受け取ったとき、既存Issue化が明らかに必要でなければまずIdea Inboxへの追記を優先する。
- 独立した調査、仕様策定、実装、Bug修正、Verificationなどとして扱う段階になったら、既存Issueとの重複を検索したうえで正式Issueへ切り出す。
- 切り出した元項目は削除せず、`→ SAY-xx` のように切り出し先を記録して履歴を残す。
- 不要になった案は取り消し線または`Dropped`で残してよい。
- Idea Inbox自体はProjectに所属させない。
- Idea Inbox自体は`Contract: N/A` / `Manual E2E: Not Required`とする。
- Idea Inboxへ入っているだけの項目は、実装予定・優先順位確定・implementation contract確定を意味しない。
- Issue枠に余裕が出たことだけを理由に機械的に全項目をIssue化しない。実際に独立管理する価値が出た項目から切り出す。

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
  - 条件が変わるまでactionableなcontract作業を期待しないIssueを、通常の`Pending`と分離する。
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
  - timing / environment /開発順の都合で先にmergeしてよい状態を明示するために使う。
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

Saved viewでは、**現在実行中のWork**と**次に開始できるWork**を分離する。

### Now

`Now`は「実際に現在作業中、またはreview中のWork」だけを見るviewとする。

条件:

- Status: `In Progress` または `In Review`

`Todo`は含めない。Contract / Manual E2Eのreadiness labelも`Now`のgateにはしない。
contract調査中の`In Progress + Contract: Pending`なども、実際にそのWorkを進めているなら`Now`へ含める。

primary worktreeとpersistent sub worktreeで並列作業している場合は、それぞれで実際に進行中のIssueが`Now`へ並ぶ。片方がidleならplaceholderを作らない。

### Ready Queue

`Ready Queue`は「実装準備が完了し、次の着手候補として明示的にqueueへ入っているWork」を見るviewとする。

実装Issueについては次をAND条件にする。

- Status: `Todo`
- Contract: `Ready`
- Manual E2E: `Ready to Run` / `Running` / `Failed` / `Deferred` / `Passed` / `Not Required` のいずれか

`Contract: Pending` / `Contract: Blocked` / `Manual E2E: Plan Pending`、またはContract / Manual E2E labelが欠けているIssueは含めない。

`Contract: Ready`かつManual E2E準備済みでも、Statusが`Backlog`なら`Ready Queue`へ含めない。ReadyなBacklog IssueをTodoへ移すことは、readiness更新ではなく「次の着手候補へ上げる」という明示的なqueue判断とする。

### Contract Pending

通常のcontract調査対象は `Contract: Pending` で見る。

prerequisite待ちでactionableでないものは `Contract: Blocked` とし、`Pending` viewへ混ぜない。

## GitHub Pull Request連携

LinearのGitHub integrationを使い、Linear IssueとGitHub Pull Requestをリンクしてstatus更新を自動化する。

PRとIssueの標準的な紐付けは、PR descriptionにclosing magic wordとIssue identifierを記載する方式とする。

例:

`Fixes SAY-38`

`Linear: SAY-38`のような単なるラベルだけを標準の紐付け方法にはしない。
branch名へLinear Issue identifierを入れることも必須にしない。

Sayosomi TeamのPull request automationsは次を標準設定とする。

- On draft PR open → `In Progress`
- On PR open → `In Progress`
- On PR review request or activity → `In Review`
- On PR ready for merge → `In Review`
- On PR merge → `Done`

nuinuiCADは個人開発を前提とするため、別レビュアーによるreview requestを`In Review`への必須条件にしない。
通常はPRがready for mergeになった時点で`In Review`へ進み、blocking review、required automated verification、実施可能なManual E2E、最終確認を行う。

Manual E2Eをその時点で実施できない、または後回しにして次の開発を進める方が合理的な場合は、Manual E2Eを`Deferred`と明示したうえでmergeしてよい。Manual E2Eの`Passed`を一律のmerge条件にはしない。

review request or activityのautomationは、将来reviewerやreview automationを使う場合にも自然に`In Review`へ進める互換的なtriggerとして維持する。

PRをmergeしたら、closing magic wordでリンクされたIssueはLinear automationにより`Done`へ進める。
通常の開発Taskでは、GitHub側のPR状態から自動で反映できるstatusをChatGPTが重複して手動更新しない。
ただしautomationが発火しなかった、PRとIssueが正しくリンクされていない、または実際のTask状態と自動statusが一致しない場合は、原因を確認して必要な修正を行う。

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
3. Coding Agentの実装が完了したとき
4. blocking reviewが完了したとき
5. Manual E2Eを開始・延期・FAIL確定・完了したとき
6. Taskのstatusを変更すべき明確な節目
7. ProjectへIssueをまとめる、ProjectをCompletedにするなどexecution phaseの境界が確定したとき

このcheckpointで必要に応じて`Contract` / `Manual E2E` labelも現在状態へ更新する。

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

途中でユーザーが報告を訂正しても、Linearの記録を何度も書き換える必要がない運用を優先する。

E2E結果は、可能なら複数testをまとめて1 Commentに記録する。

例:

- Tests 1–6: PASS
- Tests 7–9: PASS
- Test 10: FAIL — 修正対象として確定
- Tests 11–12: PASS

単なる違和感や未確認の疑いは、修正対象と確定するまで`Failed`へ変更したり恒久記録したりしない。

Manual E2E開始時は必要に応じて`Running`へ更新する。まとまったFAILが確定したら`Failed`、最終的に必要な検証がすべて通ったら`Passed`へ更新する。

## Manual E2Eをmerge後に実施する場合

Manual E2Eをすぐ実施できない場合、blocking reviewとrequired automated verificationが十分なら`Deferred`を付けて先にmergeしてよい。

この場合、元IssueはPR mergeによって`Done`になってもよい。Manual E2Eは後日そのsame Issueに対して実施する。

### merge後E2Eで問題が見つかった場合

merge後のManual E2Eで実装不備が確定した場合:

1. 元Issueは`Done`のまま維持する。
2. 元IssueのManual E2E labelを`Failed`へ変更する。
3. 元Issueへ確定したE2E結果をCommentで記録する。
4. 修正用の新しい`Bug` Issueを作成し、元Issueとrelated relationで紐付ける。
5. Bug Issue側で修正・review・mergeを行う。
6. 元Issueで該当Manual E2Eを再実施する。
7. 問題解消を確認できたら元Issueを`Passed`へ更新する。

元Issueの`Done`をreopenして履歴を揺らすことを標準運用にはしない。

一方、**merge前**のManual E2Eで見つかったscope内の不具合は、原則として新Bugへ切り出さず、元Issueを`In Progress`へ戻して同じTask内で修正する。

ただしE2E中に見つかった問題が明確に別scope /既存問題である場合は、merge前でも独立Bug Issueへ切り出してよい。

## Documents

Linear Documentsを長期仕様・設計文書の正式な保存先とする。

Spec Document冒頭には、必要に応じてmetadataをテキストで持たせる。

例:

Status: Ready
Area: Typed Expression / Evaluation / Module
Category: DSL
Source: ...

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
4. 対象Issueの`Contract` / `Manual E2E` labelと本文・Commentを確認する
5. ProjectなしBacklog Issueを着手する場合、既存の短期execution Projectへ属するWorkか確認し、必要なら新しい短期Projectを作成する
6. Projectへ所属させる場合、適切な`Surface` / `Domain` Project labelを付ける
7. 対象IssueをIn Progressへ更新する
8. `Contract: Ready`でなければrepository調査とimplementation contract策定を進める
9. `Contract: Ready`でもlatest remote / actual ownerを再確認してからCoding Agentへの実装指示を作る

新規TaskでNotionを通常のSpec検索先として使わない。
必要なSpecがLinearに見つからず、legacy Notionにのみ存在する場合は、内容と現在性を確認したうえでLinear Documentへ移行してから正式な参照先にする。

ただしLinear更新のために作業テンポを落とさない。
開始時以外の進捗更新はcheckpoint-basedで行う。

## ChatGPTが管理操作を担当する

ユーザーにLinearの手動更新を要求しない。

Issue作成、状態変更、Label更新、Project紐付け、Project label付与、Comment追加、Document更新などは原則ChatGPTが行う。

Linear APIで未対応の管理操作のみ、必要な最小限のUI操作をユーザーに依頼してよい。

新しい分類・status・label groupを勝手に追加しない。必要な場合はユーザーと運用を決めてから追加する。

Issueを作成または重要metadataを更新した直後は、そのIssueを再取得し、少なくとも次を確認する。

- intended statusになっている
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