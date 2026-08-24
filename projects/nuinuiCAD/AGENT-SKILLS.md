# nuinuiCAD-specific Agent Skills

nuinuiCAD固有のAgents custom skill。共通skillは [`../../shared/AGENT-SKILLS.md`](../../shared/AGENT-SKILLS.md) を参照する。

## Make DSL Changes Safely

`make-dsl-changes-safely`

nuinuiCAD DSL変更専用のimpact-check skill。

DSL変更時に、変更内容に応じて次のsurfaceを確認する。

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

各surfaceを`affected | intentionally unchanged | deferred | not applicable`に分類する。

目的は毎回すべて変更することではなく、affected layerが旧仕様のまま残る事故を防ぐこと。

特にsource span、replacement range、`@`、`::`、property access、日本語identifier、relative/absolute offset、stable statement identityを壊さない。

後続Taskに割り当てたsurfaceを先取りしない。

## nuinuiCAD Luna MCP-backed Manual E2E

`nuinuicad-luna-mcp-e2e`

repository-owned skill: `sayosomi/nuinuiCAD/.agents/skills/nuinuicad-luna-mcp-e2e/SKILL.md`

predeclaredされた`Executor: Luna`のObjective Manual E2E unitを、fixed `e2e` laneのisolated VS Code production host上で実行するためのskill。

実行モデル:

```text
Playwright/CDP = deterministic VS Code UI operation / DOM-accessibility observation
nuinuiCAD MCP = exact-current structured product state / evidence
Computer Use = required GUI / pixel-only gapだけのbounded fallback
Luna = operate -> observe -> compare with predeclared oracle -> record evidence
Human = transport or Human-judgment executor when required
```

このskillはexecution procedureを提供するがauthorityを置き換えない。

- classification / executor / PASS-FAIL-BLOCKED: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- fixed checkout / lane: [`CHECKOUTS.md`](./CHECKOUTS.md)
- isolated VS Code host: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- Luna prompt / tested-state / evidence / retry: [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md)
- current fixture / oracle: current Linear Issue Manual E2E plan

LunaへManual E2E operator roleの中でimplementation fix、root-cause redesign、test-plan redesign、missing oracleの発明、Human judgmentをさせない。

## Implementation skill selection

nuinuiCADのrepository implementation / blocking fixはLuna xhighが実行する。ChatGPTはcurrent Taskに必要なskillを選び、implementation promptへconstraint / procedureとして反映する。

一般的なimplementation:

- `keep-task-scope-tight`
- `reuse-existing-architecture`
- 必要なら`keep-code-context-small`

DSL変更:

- 上記に加えて`make-dsl-changes-safely`

required gate failure修正:

- `fix-precommit-errors`

implementation後blocking review:

- ChatGPTが`review-against-contract`を適用する。

## Lane-aware use

skill selectionは`main` / `sub`のどちらでも同じ。

- laneのBase checkpointは [`CHECKOUTS.md`](./CHECKOUTS.md) / [`CODING-AGENT.md`](./CODING-AGENT.md) に従う;
- skillを理由にactive slice途中でlatest mainをmerge / rebaseしない;
- skillがscope expansionを要求しそうならcurrent workをcheckpointし、ChatGPTへ戻す;
- `e2e` laneでimplementation skillを使わない。

## Manual E2E selection

`Executor: Luna`のVS Code Manual E2E:

- `nuinuicad-luna-mcp-e2e`
- `MANUAL-E2E.md`
- `VS-CODE-E2E.md`
- `LUNA-E2E-PLAYBOOK.md`

`Judgment: Human` / `Executor: Human` unit、implementation、blocking-fix、open-ended investigationにはE2E skillを使わない。

すべてのskillはparent task、repository `AGENTS.md`、current Linear contract、fixed lane policyを上書きしない。
