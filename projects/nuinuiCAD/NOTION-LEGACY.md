# nuinuiCAD Notion legacy archive

## 位置づけ

NotionはLinear移行前のWork / Specs履歴を残すlegacy archiveとして扱う。

現在のWork管理・進捗管理・長期仕様管理のsource of truthではない。
新しいWork / SpecをNotionへ作成しない。

実装済みの事実についてNotionとlatest repositoryが矛盾する場合は、repositoryをauthoritativeとする。

## 残すもの

Notionには移行前の履歴として以下を残す。

- 過去のWork item
- 完了済みimplementation plan / Manual E2E plan
- 移行前のBacklog / investigation記録
- Linearへ移行済みSpecの旧版
- Superseded Spec
- migration以前の判断履歴

履歴保存のため、通常は削除しない。

## 通常の参照方法

過去の判断や移行前の経緯を確認する必要がある場合だけNotionを検索・参照する。

Notionの内容をそのままcurrent factとして採用しない。
必要に応じてlatest repository、Linear Issue / Project / Documentと照合する。

Notion内で今後も有効な未移行Workを見つけた場合は、Notion側を再開せずLinear Issueへ移行または既存Issueへ統合する。

Notion内で今後も有効な未移行Specを見つけた場合は、内容と現在性を確認し、Linear Documentへ移行してから正式な参照先にする。

## 移行中の例外

移行前から進行中のTaskが、特定の未移行Notion Specを明示的なsource of truthとして開始済みの場合だけ、そのTaskの次の明確なcheckpointまではそのNotion Specを参照し続けてよい。

checkpoint後は:

1. current repository / Task contractと照合する
2. 必要ならSpecを最新化する
3. Linear Documentへ移行する
4. Linear Issue側のsource of truth参照をLinear Documentへ切り替える
5. Notion側はlegacy archiveとして残す

この例外を新しいTaskへ引き継がない。

## 更新しないもの

原則としてNotionでは以下を行わない。

- 新規Work作成
- 新規Spec作成
- Work status更新
- current implementation contract追記
- blocking review結果追記
- Manual E2E進捗の逐次更新
- Backlog追加
- roadmap更新

これらはLinearで管理する。

ユーザーがlegacy archive自体の誤記修正や整理を明示的に依頼した場合だけ、Notionを直接更新してよい。

## Source of truth

現在の管理先は以下。

- 実装済み事実 / actual code: latest repository
- 作業予定・進捗・調査結果: Linear Issue / Project
- 長期仕様・設計: Linear Document
- 移行前の履歴: Notion legacy archive

迷った場合はNotionへ新規記録せず、まずLinearを検索する。
