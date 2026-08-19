# nuinuiCAD Linear運用ルール

## 目的

LinearをnuinuiCADの正式なWork管理・長期仕様管理の場所として使う。

ユーザー自身が管理画面を細かく操作することより、ChatGPTが安定して検索・作成・更新できることを優先する。

Notionはlegacy archiveとして残し、新規Work / Specの管理先には使わない。

## 基本構造

- Workspace: Sayosomi
- Team: Sayosomi
- Initiative: nuinuiCAD
- Project: まとまった開発トラック
- Issue: 実際に着手・完了する作業
- Document: 長期的に残す仕様・設計文書

Taskや個別開発テーマをInitiativeにしない。
製品ごとにTeamを増やさず、当面はSayosomi Team 1つで運用する。

## 新規作成前の検索

Initiative / Project / Issue / Documentを新規作成する前に、必ず既存項目を検索する。

同じものがある場合は新規作成せず更新する。

Canceledになっている移行試験用Issueなどが残っている場合があるため、タイトルだけで判断せず内容とstatusも確認する。

## Project

Projectはまとまった開発トラックに使う。

例:

- Language / Editor Integration
- Automation / MCP
- DSL / Geometry
- Print Layout

個々の実装TaskをProjectにしない。

長期間継続するProjectがDone Issueのarchiveを妨げる場合は、必要になった時点でProjectの区切り方を見直す。

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

## Issue state labels

Issue一覧だけでimplementation contractとManual E2Eの現在状態を判断できるよう、type labelとは別に2つのLabel Groupを使う。

原則として正式なnuinuiCAD Work Issueには、`Contract`から1つ、`Manual E2E`から1つを付ける。

既存の`Feature` / `Improvement` / `Bug`等はWorkの種類を表すlabelとして併用する。

### Contract

- `Pending`
  - implementation contractに必要なrepository調査、architecture判断、product decision、scope確定などがまだ残っている。
  - Coding Agentへそのまま実装指示を渡せる状態ではない。
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
5. 対象IssueをIn Progressへ更新する
6. `Contract: Ready`でなければrepository調査とimplementation contract策定を進める
7. `Contract: Ready`でもlatest remote / actual ownerを再確認してからCoding Agentへの実装指示を作る

新規TaskでNotionを通常のSpec検索先として使わない。
必要なSpecがLinearに見つからず、legacy Notionにのみ存在する場合は、内容と現在性を確認したうえでLinear Documentへ移行してから正式な参照先にする。

ただしLinear更新のために作業テンポを落とさない。
開始時以外の進捗更新はcheckpoint-basedで行う。

## ChatGPTが管理操作を担当する

ユーザーにLinearの手動更新を要求しない。

Issue作成、状態変更、Label更新、Project紐付け、Comment追加、Document更新などは原則ChatGPTが行う。

Linear管理自体が開発作業の主目的にならないよう、必要な記録だけをまとめて更新する。

## Coding Agentとの役割分担

Linear運用によってChatGPT / Coding Agentの役割分担は変更しない。

ChatGPTがrepository調査・architecture把握・implementation contract・blocking review・Manual E2E plan策定・Linear管理を担当する。

Coding Agentは確定済みcontractに従い、実装・test・commit・pushを行う。

Coding Agent開始前の `git fetch origin --prune` とremote state確認は引き続き必須。
