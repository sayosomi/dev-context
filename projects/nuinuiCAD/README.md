# nuinuiCAD Project Context

Repository: `sayosomi/nuinuiCAD`

このREADMEはChatGPT Projectから参照する**固定入口 / router**。

Current taskのSHA、branch、進捗、個別implementation planはここに書かない。詳細policyも可能な限りowner documentへ分離し、このREADMEは「何をいつ読むか」を中心に保つ。

## Always load for development work

開発作業では最初に次を読む。

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- repositoryのcurrent [`AGENTS.md`](https://github.com/sayosomi/nuinuiCAD/blob/main/AGENTS.md)

実装済みの事実、owner、API、surface、architecture、DSLについて判断するときは、必ずlatest remote `sayosomi/nuinuiCAD` repositoryを確認する。dev-context、Linear、過去チャット、local copyをactual implementationのsource of truthにしない。

## Project-specific policy map

必要な作業に応じてowner documentを読む。

| Topic | Owner |
| --- | --- |
| checkout / persistent sub worktree | [Checkout / worktree policy](./CHECKOUTS.md) |
| execution-agent prompt language / formatting | [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md) |
| implementation Coding Agent workflow | [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md) |
| Coding Agent skill選択 | [Shared Agent Skills](../../shared/AGENT-SKILLS.md) + [nuinuiCAD Agent Skills](./AGENT-SKILLS.md) |
| Linear overview / routing | [Linear policy router](./LINEAR.md) |
| Linear Project / Project labels | [Linear Project policy](./LINEAR-PROJECTS.md) |
| Linear Issue status / Ready Queue / Done freshness | [Linear Issue workflow](./LINEAR-ISSUES.md) |
| Linear ↔ GitHub PR integration | [Linear / GitHub integration](./LINEAR-GITHUB.md) |
| Linear Documents / long-term Spec | [Linear Document policy](./LINEAR-DOCUMENTS.md) |
| `only_chatgpt` / `manual_e2e_only` ownership | [Execution ownership labels](./ONLY-CHATGPT.md) |
| shared CI incident / human-terminal Mac reproduction | [Shared CI incident escalation](./CI-INCIDENTS.md) |
| Manual E2EのJudgment / Executor / PASS-FAIL-BLOCKED | [Manual E2E execution rules](./MANUAL-E2E.md) |
| VS Code isolated Manual E2E host | [VS Code Manual E2E environment](./VS-CODE-E2E.md) |
| Luna Manual E2E prompt / evidence / pitfalls | [Luna Manual E2E playbook](./LUNA-E2E-PLAYBOOK.md) |
| implementation contract判断 | [Implementation contract decision rule](./CONTRACT-DECISIONS.md) |
| user-facing command contract | [Command contract policy](./COMMAND-CONTRACTS.md) |
| Linear Free plan capacity | [Linear free-plan capacity policy](./LINEAR-CAPACITY.md) |
| GitHub Issues public mirror | [GitHub Issues sync](./GITHUB-ISSUES-SYNC.md) |
| legacy Notion | [Legacy Notion archive](./NOTION-LEGACY.md) |

## Standard local checkouts

標準配置だけここに保持する。運用ruleは [`CHECKOUTS.md`](./CHECKOUTS.md) がauthority。

- primary: `/Users/yosomi/Code/nuinuiCAD`
- persistent sub: `/Users/yosomi/Code/nuinuiCAD-sub`

## Repository-owned sources of truth

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- repository engineering policy: `AGENTS.md`
- current architecture / navigation index: `ARCHITECTURE.md`
- normative nui4 language contract: `docs/nui4/spec.md`
- implemented user-facing DSL documentation: `docs/dsl.md`

実装事実について管理文書・過去チャット・work-management systemとrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。

## Work / specification management

現在のWork / specification管理はLinearを正式な管理先とする。LinearはFree plan前提で運用し、closed itemの早期archiveによるIssue枠管理を明示的な制約とする。

- 作業予定・進捗・調査結果: Linear Issue / Project
- 長期的に参照する仕様・設計: Linear Document

Notionは新規Work / Specの管理先には使わない。

移行前から進行中のTaskが特定の未移行Notion Specを明示的source of truthとして開始済みの場合だけ、そのTaskの次の明確なcheckpointまでは参照を継続してよい。checkpoint後はLinear Documentへ移行し、Task側の参照先も更新する。

新しい開発Taskの開始時は、GitHub remote stateと既存Linear Issue / Project / Documentを確認してからimplementation contractを策定する。

## Consecutive Task merge checkpoint

連続Taskで前TaskにPull Requestがある場合、次TaskのCoding Agentへ実装指示を出す前に、そのPRがGitHub上でmerge済みか確認する。

- 未merge: repository調査、Linear確認、implementation contract策定までは進めてよいが、Coding Agentへ実装開始を指示しない。
- merge済み: merge後のlatest remote `main`を再確認し、それを次Taskのimplementation baseとする。

## Loading rule

毎回すべてのlinked documentを読む必要はない。

1. **Always:** このREADMEを読む。
2. **Development work:** `shared/DEVELOPMENT.md` とrepositoryのcurrent `AGENTS.md`を読む。
3. **Checkout / branch / worktree / local execution:** `CHECKOUTS.md`を読む。
4. **Execution-agent prompt generation:** roleにかかわらず`shared/AGENT-PROMPT-STYLE.md`を読む。
5. **Implementation / blocking-fix Coding Agent:** `shared/CODING-AGENT-WORKFLOW.md`を読む。skill選択が必要なときだけShared / nuinuiCAD Agent Skillsを追加で読む。
6. **Linear操作・参照、またはimplementation contract策定:** `LINEAR.md`、`CONTRACT-DECISIONS.md`、`LINEAR-CAPACITY.md`、`GITHUB-ISSUES-SYNC.md`を読む。Issue / Project / PR integration / Documentの詳細は`LINEAR.md`のloading ruleに従って該当ownerを追加で読む。
7. **`only_chatgpt` / `manual_e2e_only`:** 6に加えて`ONLY-CHATGPT.md`を読む。
8. **Shared CI incident suspicion / human-terminal CI reproduction:** `ONLY-CHATGPT.md`のshared CI incident routeに該当した場合だけ`CI-INCIDENTS.md`を読む。通常の`only_chatgpt`開始時やordinary issue-local CI failureでは読まない。
9. **Manual E2E plan / classification / execution / result handling:** `MANUAL-E2E.md`を読む。VS Code production-host testなら`VS-CODE-E2E.md`も読む。`Executor: Luna`のprompt生成・retry・environment/evidence切り分けなら`shared/AGENT-PROMPT-STYLE.md`と`LUNA-E2E-PLAYBOOK.md`を読む。Manual E2E test-operator promptであるという理由だけで`shared/CODING-AGENT-WORKFLOW.md`を読まない。別途implementation / blocking-fixを依頼するときだけ5を適用する。
10. **User-facing commandの追加・surface変更:** `COMMAND-CONTRACTS.md`を読む。allowed Palette scope等のdurable enumはcurrent repository `AGENTS.md`をauthorityとする。
11. **Legacy履歴または明示的な移行中例外:** 必要なときだけ`NOTION-LEGACY.md`を読む。
12. **Current implementation / architecture / DSL判断:** 必ずlatest repositoryから取得する。

## Maintenance rule

このREADMEへ新しい詳細ruleを直接積み上げない。

新しいdurable policyが既存ownerに収まらない場合は、まず適切なowner documentを決め、このREADMEにはrouteとloading conditionだけを追加する。
