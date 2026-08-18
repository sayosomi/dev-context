# nuinuiCAD Notion運用ルール（移行期間用）

## Source of truth

Notionは原則として以下の2DBだけをsource of truthとして使う。

- Work: 作業・進捗管理
- Specs: 長期参照する仕様・設計

実装済みの事実についてNotionとlatest repositoryが矛盾する場合は、repositoryをauthoritativeとする。

## Work

- アイデア、Feature、Task、Bug、Research、Verification、InitiativeをWorkで管理する。
- 同じ機能・Taskについて別の進捗ページを作らない。原則として同じWork itemを着想から完了まで更新する。
- implementation plan / implementation contract / 調査結果 / review結果 / verification結果のためだけに別ページを作らない。対応するWork item本文へ追記する。
- Manual E2Eなど、独立して進捗管理する必要がある確認作業だけ、種類=VerificationのWorkとして作成してよい。
- 複数Taskを束ねる計画は、種類=InitiativeのWorkと親/子relationで表す。
- 完了したWorkは削除・移動せずDoneにする。
- 不要・重複・不採用はDroppedにする。

## Workの状態

- Inbox: とりあえず登録した未整理の項目。
- Backlog: やる候補として整理済みだが、まだ着手順には入っていない。
- Ready: 仕様・前提・依存関係が十分に固まり、次に着手できる。
- In progress: 調査・設計・実装など実際の作業中。
- Review: 実装後のblocking review / PR review / CI確認などの待ち。
- Verify: 実装とreviewは通ったが、Manual E2Eなど人間による最終確認が残っている。
- Done: そのWorkに必要な実装・review・verificationが完了した。
- Dropped: 不採用、不要化、重複、別案への置き換えなどで進めない。

すべてのWorkが全状態を通る必要はない。不要な段階は飛ばしてよい。

## Specs

- Specsは長期的に参照する仕様・設計だけを管理する。
- 一時的なimplementation contractや調査メモはSpecsにしない。
- Draft: 仕様策定中。
- Ready: 仕様確定済み・実装待ち。
- Current: 現在有効な仕様。
- Superseded: 旧仕様。
- 実装済みかどうかはSpecsの状態に含めない。実装進捗はWorkで管理する。

## Notion更新時のルール

1. 新しいページを作る前に、必ずWork / Specsを検索して既存ページがないか確認する。
2. 既存ページがある場合は新規作成より更新を優先する。
3. WorkとSpecs以外の新しいDBを勝手に作らない。
4. 新しい分類・状態・領域・観点を勝手に追加しない。既存値で表現できない場合は追加前にユーザーへ確認する。
5. Work itemに長期仕様が必要な場合だけ、仕様relationでSpecsへ結ぶ。
6. 旧資料や重複資料を整理する場合はArchiveへ退避し、履歴を勝手に削除しない。
7. Notionの記録内容とrepositoryのactual implementationが矛盾する場合、実装事実についてはlatest repositoryをauthoritativeとし、必要ならNotionを更新する。

## 迷ったとき

何か記録したい
→ Work / Specsを検索
→ 既存あり: 更新
→ 既存なし:
  - 作業・進捗: Work
  - 長期仕様: Specs
  - どちらでもない: 原則として新規ページを作らない
