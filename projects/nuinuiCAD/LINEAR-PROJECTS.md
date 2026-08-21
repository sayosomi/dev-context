# nuinuiCAD Linear Project policy

## Purpose

Linear Projectの粒度、lifecycle、Project label運用を定義する。

Workspace / Team / Initiative全体の入口は [`LINEAR.md`](./LINEAR.md) を参照する。

## Project is an execution phase

Projectは**終わる単位**として使う。

複数Issueをまとめて進め、数日〜数週間程度でCompletedにできるexecution phaseを基本とする。

例:

- Canvas Selection / Navigation v1
- Geometry Editing / Bake v1
- Modifier Editor Integration v1
- Print Layout v1

`Language / Editor Integration`、`Module`、`DSL / Geometry`、`Automation / MCP`のような長期カテゴリをProjectとして常設しない。

まだ着手時期が決まっていない将来Issueは、原則ProjectなしのBacklogで保持する。一連の作業として着手する段階で、完了可能な短期Projectを作成し、対象Issueを移す。

個々の単発実装Taskを機械的に1 Issue = 1 Projectにはしない。複数Issueをまとめて完了条件を持てる開発phaseだけをProject化する。

## Completion

Project内の必要Issueが完了したらProjectもCompletedにする。

Done Issueを未完了Projectへ長期間残してauto-archiveを妨げない。

旧カテゴリProjectは履歴としてCanceledのまま残してよいが、新規Workの分類箱として再利用しない。

## Project labels

Project labelは「何の分野のProjectか」を表す。statusや進捗段階をProject labelで重複表現しない。

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

新しいProject label / label groupを勝手に増やさない。既存分類で表現できない場合はユーザーと決めてから追加する。

## Assignment at Task start

ProjectなしIssueへ着手するときは、既存の短期execution Projectへ属するWorkか確認する。

- 既存Projectの明確なscopeならそこへ所属させる。
- 新しいまとまりとして複数Issueを進めるexecution phaseなら、必要に応じて短期Projectを作成する。
- 単発Workや着手時期未定のfuture workを、分類目的だけでProjectへ押し込まない。

Projectへ所属させる場合、適切な`Surface` / `Domain` Project labelを付ける。