# nuinuiCAD Linear運用ルール

## 目的

Linearは、nuinuiCADのWork管理と長期仕様管理の移行先として試験運用する。

ユーザー自身が管理画面を細かく操作することより、ChatGPTが安定して検索・作成・更新できることを優先する。

移行試験が完了するまでは、既存Notion Work / Specsを削除・アーカイブしない。

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

試験用Issueや過去の移行確認用データが存在する可能性があるため、タイトルだけで判断せず内容も確認する。

## Project

Projectはまとまった開発トラックに使う。

例:

- Language / Editor Integration
- Automation / MCP
- DSL / Geometry

個々の実装TaskをProjectにしない。

長期間継続するProjectがDone Issueのarchiveを妨げる場合は、必要になった時点でProjectの区切り方を見直す。

## Issue

Feature / Task / Bug / Research / Verificationなど、実際に開始して完了する作業はIssueで管理する。

1つのWork itemは、開始から完了まで同じIssueを更新する。
進捗段階ごとに別Issueを増やさない。

基本status:

Backlog → Todo → In Progress → In Review → Done

すべてのIssueが全statusを通る必要はない。

Manual E2EなどのVerify相当statusは未確定。
必要になっても勝手に新しいStatusを追加せず、ユーザーと決める。

## Issue descriptionとComment

Issue descriptionには、現在も有効な情報を置く。

- 目的
- scope
- non-goals
- implementation contract
- 現在も有効な重要前提

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
2. Coding Agentの実装が完了したとき
3. blocking reviewが完了したとき
4. Manual E2Eのまとまった区切り、またはE2E全体が完了したとき
5. Taskのstatusを変更すべき明確な節目

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

単なる違和感や未確認の疑いは、修正対象と確定するまでLinearへ恒久記録しない。

## Documents

Linear Documentsは長期仕様・設計文書の保存先として試験する。

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

Linear DocumentsにはNotion DBのような構造化プロパティがないため、この点が実運用上問題になるかを試験する。

## Source of truth — 移行試験中

- 実装済み事実 / actual code: latest repository
- 既存長期仕様: Notion Specs
- Linearへ移した新規Spec: Linear Document
- 移行試験開始前から進行中の既存Work: Notion
- 移行試験開始後に新規開始するWork: Linear

実装事実についてLinear / Notion / 過去チャットとrepositoryが矛盾する場合は、latest repositoryをauthoritativeとする。

移行完了をユーザーが承認するまでは、Notionを削除・アーカイブしない。

## 新Task開始時

ChatGPTは新規開発Task開始前に:

1. GitHub remote stateを確認する
2. Linearで既存Issue / Projectを検索する
3. 必要なSpecをLinear DocumentまたはNotion Specsから取得する
4. 対象IssueをIn Progressへ更新する
5. repository調査とimplementation contract策定を開始する

ただしLinear更新のために作業テンポを落とさない。
開始時以外の進捗更新はcheckpoint-basedで行う。

## ChatGPTが管理操作を担当する

ユーザーにLinearの手動更新を要求しない。

Issue作成、状態変更、Project紐付け、Comment追加、Document更新などは原則ChatGPTが行う。

Linear管理自体が開発作業の主目的にならないよう、必要な記録だけをまとめて更新する。

## Coding Agentとの役割分担

Linear移行によってChatGPT / Coding Agentの役割分担は変更しない。

ChatGPTがrepository調査・architecture把握・implementation contract・blocking review・Linear管理を担当する。

Coding Agentは確定済みcontractに従い、実装・test・commit・pushを行う。

Coding Agent開始前の `git fetch origin --prune` とremote state確認は引き続き必須。
