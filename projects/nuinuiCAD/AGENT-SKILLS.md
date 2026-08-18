# nuinuiCAD-specific Agent Skills

nuinuiCAD 固有の Agents custom skill。
共通 skill は [`../../shared/AGENT-SKILLS.md`](../../shared/AGENT-SKILLS.md) を参照する。

## Make DSL Changes Safely

`make-dsl-changes-safely`

nuinuiCAD DSL 変更専用の impact-check skill。

DSL 変更時に、変更内容に応じて次の surface を確認する。

- tokenizer / scanner
- parser / AST
- semantic analysis / resolution
- typecheck
- lowering / compilation
- runtime / evaluation
- serializer / canonical formatting
- completion
- rename
- navigation
- diagnostics
- source spans / ranges
- statement identity
- editor integration
- tests / fixtures

各 surface を次のいずれかに分類する。

- affected
- intentionally unchanged
- deferred
- not applicable

目的は「毎回すべて変更する」ことではなく、parser だけ新仕様になって他の affected layer が旧仕様のまま残る事故を防ぐこと。

特に source span、replacement range、`@`、`::`、property access、日本語 identifier、relative/absolute offset、stable statement identity を壊さないよう注意する。

後続 Task に割り当てられた DSL surface は先取りしない。

## Skill selection

nuinuiCAD の一般的な Task 実装:

- `keep-task-scope-tight`
- `reuse-existing-architecture`
- 必要なら `keep-code-context-small`

DSL 変更:

- 上記に加えて `make-dsl-changes-safely`

required gate failure 修正:

- `fix-precommit-errors`

実装後 blocking review:

- `review-against-contract`

すべての skill は parent task、repository の `AGENTS.md`、repository 固有の plan / instructions を上書きしない。
