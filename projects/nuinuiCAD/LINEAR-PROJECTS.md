# nuinuiCAD Linear Project policy

## Purpose

Linear Projectの粒度、lifecycle、Project label運用を定義する。

Workspace / Team / Initiative全体の入口は [`LINEAR.md`](./LINEAR.md) を参照する。

## Projects are exception-only

nuinuiCADではLinear Free planのcapacityを明示的な制約として扱うため、**Projectは原則作らない**。

通常のWork管理はleaf Issue + dependency / relationで行う。複数Issueが同じfeature goalを持つことだけではProject作成理由にならない。

Projectを例外的に使ってよいのは、現在進行中の複数Issueを極短期だけaggregate trackingする実益が明確で、Issue relationだけではその短期executionを追う負担が大きい場合に限る。

Projectを作らない代表例:

- 単に同じsurface / subsystem / categoryのIssueが複数ある
- 同じ週に着手するだけで共通completion gateがない
- future workの分類箱が欲しい
- parent / tracking Issueの代替として常設したい
- 共通goalはあるがIssue relationだけで十分追える

Projectを作る場合も、長期roadmapや履歴保存の器ではなく、一時的なexecution aidとして扱う。

## Assignment at Task start

ProjectなしIssueへ着手するとき、Project assignmentを既定作業にしない。

- 既存Projectが現在も有効な極短期aggregate trackingを行っており、そのscopeへ明確に入るなら所属させてよい。
- 新しいProjectは、複数Issueを今まさに並行・連続して進めるうえで一時的aggregate trackingの実益が明確な場合だけ作る。
- Issue relationで十分ならProjectを作らない。
- 単発Work、future work、カテゴリ分類、履歴保存のためにはProjectを使わない。

Projectを作るか迷う場合は「Projectなし」を既定とする。

## Completion and cleanup

Projectを使った場合は、aggregate trackingの役目が終わり次第すみやかにCompletedへ進める。

Done Issueを未完了Projectへ長期間残してauto-archiveを妨げない。

Completed Projectを履歴保存だけのために長期間保持することを目的にしない。Linear Free plan capacityと利用可能な管理操作を確認し、不要なProjectは早期に整理する。

旧カテゴリProjectは新規Workの分類箱として再利用しない。既存Projectについても、現在のaggregate trackingに不要なら解体・整理候補として扱う。

## Project labels

Project labelは、例外的にProjectを使う場合だけ「何の分野のProjectか」を表す。statusや進捗段階をProject labelで重複表現しない。

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

新しいProject label / label groupを勝手に増やさない。既存分類で表現できない場合はユーザーと決めてから追加する。
