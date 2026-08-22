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

## nuinuiCAD Luna MCP-backed Manual E2E

`nuinuicad-luna-mcp-e2e`

repository-owned skill: `sayosomi/nuinuiCAD/.agents/skills/nuinuicad-luna-mcp-e2e/SKILL.md`

predeclaredされた`Executor: Luna`のobjective Manual E2E unitを、isolated VS Code production host上で実行するためのnuinuiCAD固有skill。

実行モデル:

```text
Playwright/CDP = deterministic VS Code UI operation / DOM-accessibility observation
nuinuiCAD MCP = exact-current structured product state / evidence
Computer Use = required GUI / pixel-only gapだけのbounded fallback
Luna = operate -> observe -> compare with predeclared oracle -> record evidence
Human = Sol HighとLuna session間のmanual prompt/result copy-paste transport
```

このHuman transportは`Judgment: Human`でも`Executor: Human`でもない。自動ChatGPT↔Luna session relayを導入・要求しない。

このskillはexecution procedureを提供するが、authorityを置き換えない。

- classification / executor / PASS-FAIL-BLOCKED: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- isolated VS Code host setup: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- Luna prompt / tested-state / evidence / retry / pitfall / result handling: [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md)
- current fixture / action / oracle / acceptance: current Linear IssueのManual E2E plan

Lunaへimplementation fix、root-cause investigation、test-plan redesign、missing oracleの発明、Human judgmentをさせない。

result受領後のreusable lesson判定はSol Highが行う。runが再利用可能なoperation / evidence lessonを示した場合だけ、責務に応じてskill / `LUNA-E2E-PLAYBOOK.md` / 他のauthorityを更新する。一般化可能なMCP observation deficiencyは、恒久的なvisual inferenceへ逃がさずfocused MCP follow-up workとして扱う。何も再利用可能なlessonがなければ更新しない。

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

`Executor: Luna` のnuinuiCAD Manual E2E execution:

- `nuinuicad-luna-mcp-e2e`
- `MANUAL-E2E.md`に従い`Judgment: Objective`としてpredeclared oracleが確定しているunitだけを対象にする
- VS Code production-host unitでは`VS-CODE-E2E.md`と`LUNA-E2E-PLAYBOOK.md`のcurrent ruleをSol High promptへ反映する
- `Judgment: Human` / `Executor: Human` unit、implementation、blocking-fix、open-ended investigationには選択しない

すべての skill は parent task、repository の `AGENTS.md`、repository 固有の plan / instructions を上書きしない。
