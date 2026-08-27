# nuinuiCAD Project Context

Repository: `sayosomi/nuinuiCAD`

このREADMEはChatGPT Projectから参照する**固定入口 / router**。

Current taskのSHA、branch、進捗、個別implementation planはここに書かない。詳細policyはowner documentへ置き、このREADMEは「何をいつ読むか」を中心に保つ。

## Always load for development work

開発作業では最初に次を読む。

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- repositoryのcurrent [`AGENTS.md`](https://github.com/sayosomi/nuinuiCAD/blob/main/AGENTS.md)

実装済みの事実、owner、API、surface、architecture、DSLについて判断するときは必ずlatest remote `sayosomi/nuinuiCAD` repositoryを確認する。dev-context、Linear、過去chat、local copyをactual implementationのsource of truthにしない。

## Project-specific policy map

| Topic | Owner |
| --- | --- |
| inactive contingency workflow for ChatGPT availability / token constraints | [Codex-only interim workflow](./CODEX-ONLY-INTERIM.md) — **Inactive; load only when reactivation is being considered** |
| Chat common lifecycle / role routing / rotation / external-state recovery | [Chat workflow](./CHAT-WORKFLOW.md) |
| Coordinator status / Work selection / routing handoff | [Coordinator chat](./CHAT-COORDINATOR.md) |
| Issue Authoring / contract investigation chat behavior | [Issue Authoring chat](./CHAT-AUTHORING.md) |
| Implementation chat start / resume / continuation handoff | [Implementation chat](./CHAT-IMPLEMENTATION.md) |
| E2E chat lifecycle | [E2E chat](./CHAT-E2E.md) |
| fixed execution lanes / checkout occupancy / checkpoint isolation | [Execution lane policy](./CHECKOUTS.md) |
| local versioned helper / local dev-context sync / tool promotion | [Local tools](./LOCAL-TOOLS.md) |
| execution-agent prompt language / formatting | [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md) |
| implementation / blocking-fix Luna workflow | [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md) + [nuinuiCAD Implementation Coding Agent Policy](./CODING-AGENT.md) |
| implementation slicing / integration checkpoint / sequential PR | [Implementation slicing policy](./IMPLEMENTATION-SLICING.md) |
| implementation / review skill selection | [Shared Agent Skills](../../shared/AGENT-SKILLS.md) + [nuinuiCAD Agent Skills](./AGENT-SKILLS.md) |
| Linear overview / routing | [Linear policy router](./LINEAR.md) |
| Linear Issue status / Ready Queue / lane checkpoint / Done freshness | [Linear Issue workflow](./LINEAR-ISSUES.md) |
| Linear Project / Project labels | [Linear Project policy](./LINEAR-PROJECTS.md) |
| Linear ↔ GitHub PR integration | [Linear / GitHub integration](./LINEAR-GITHUB.md) |
| Linear Documents / long-term Spec | [Linear Document policy](./LINEAR-DOCUMENTS.md) |
| shared CI incident / fixed-lane reproduction | [Shared CI incident escalation](./CI-INCIDENTS.md) |
| Manual E2E Judgment / Executor / PASS-FAIL-BLOCKED | [Manual E2E execution rules](./MANUAL-E2E.md) |
| VS Code isolated Manual E2E host | [VS Code Manual E2E environment](./VS-CODE-E2E.md) |
| Luna Manual E2E prompt / evidence / pitfalls | [Luna Manual E2E playbook](./LUNA-E2E-PLAYBOOK.md) |
| implementation contract judgment | [Implementation contract decision rule](./CONTRACT-DECISIONS.md) |
| user-facing command contract | [Command contract policy](./COMMAND-CONTRACTS.md) |
| explicit contract re-audit | [Contract re-audit policy](./CONTRACT-REAUDIT.md) |
| Linear Free plan capacity | [Linear free-plan capacity policy](./LINEAR-CAPACITY.md) |
| GitHub Issues public mirror | [GitHub Issues sync](./GITHUB-ISSUES-SYNC.md) |
| legacy Notion | [Legacy Notion archive](./NOTION-LEGACY.md) |

## Fixed execution lanes

nuinuiCADのlocal executionは次の3 laneだけを使う。詳細は [`CHECKOUTS.md`](./CHECKOUTS.md)。

- `main` implementation lane: `/Users/yosomi/Code/nuinuiCAD`
- `sub` implementation lane: `/Users/yosomi/Code/nuinuiCAD-sub`
- `e2e` Manual E2E lane: `/Users/yosomi/Code/nuinuiCAD-e2e`

Hard rule:

- implementationはLuna xhighでmain/sub最大2 track;
- Manual E2Eはe2e最大1 track;
- 4つ目のworktree / clone / checkoutを作らない;
- active implementation sliceはBase checkpoint SHAを固定し、integration checkpointまで他lane / remote mainの変更を取り込まない;
- E2Eでimplementation failureが出たらmain/subのFREE laneへfixを戻し、e2e checkoutでは修正しない。

## Repository-owned sources of truth

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- repository engineering policy: `AGENTS.md`
- current architecture / navigation index: `ARCHITECTURE.md`
- normative nui4 language contract: `docs/nui4/spec.md`
- implemented user-facing DSL documentation: `docs/dsl.md`

実装事実について管理文書・過去chat・work-management systemとrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。

## Work / specification management

現在のWork / specification管理はLinearを正式な管理先とする。

- 作業予定・進捗・調査結果・lane checkpoint: Linear Issue / Comment
- 長期的に参照する仕様・設計: Linear Document

Notionは新規Work / Specの管理先には使わない。

新しい開発Task開始時はlatest remote stateとexisting Linear Issue / Documentを確認してからimplementation contractを策定する。

## Parallel execution rule

Parallelismはunbounded worker / reservation modelではなく、物理laneで表現する。

```text
main implementation lane -> at most one current implementation Issue
sub implementation lane  -> at most one current implementation Issue
e2e lane                 -> at most one current Manual E2E Issue
```

main/subは互いの途中変更を取り込まない。

一方のPRが先にmainへmergeされても、もう一方はactive slice途中でmerge-main / rebase-mainしない。自身のintegration checkpointへ到達したときだけlatest intended baseをLunaが統合し、必要なconflict / integration fixとverificationを行う。

同じlaneで次Taskへ進むときは、前Taskをmergeまたはremote保存済みsafe checkpointでreleaseした後、新Task startとしてlatest remote stateからnew Base checkpointを固定する。

## Loading rule

毎回すべてのlinked documentを読む必要はない。

1. **Always:** このREADMEを読む。`CODEX-ONLY-INTERIM.md`はInactiveな間は通常loadしない。Humanが明示的に再有効化を検討・指示した場合だけ読み、Active化された場合はlisted override topicで同documentを優先する。
2. **Chat role / start / resume / rotation / handoff / recovery:** `CHAT-WORKFLOW.md` + current role owner (`CHAT-COORDINATOR.md` / `CHAT-AUTHORING.md` / `CHAT-IMPLEMENTATION.md` / `CHAT-E2E.md`)。
3. **Development work:** `shared/DEVELOPMENT.md`とcurrent repository `AGENTS.md`。
4. **Checkout / branch / local execution / concurrency:** `CHECKOUTS.md`。
5. **Local versioned helper / local dev-context sync / tool trial-promotion-repair:** `LOCAL-TOOLS.md`。
6. **Execution-agent prompt generation:** `shared/AGENT-PROMPT-STYLE.md`。
7. **Implementation / blocking fix:** `shared/CODING-AGENT-WORKFLOW.md` + `CODING-AGENT.md`。該当する場合Shared / nuinuiCAD Agent Skillsも読む。
8. **Implementation start / pause-resume / sequential PR / integration checkpoint / scope expansion:** `IMPLEMENTATION-SLICING.md`。
9. **Linear操作・参照、またはimplementation contract策定:** `LINEAR.md`、`CONTRACT-DECISIONS.md`、`LINEAR-CAPACITY.md`、`GITHUB-ISSUES-SYNC.md`。詳細は`LINEAR.md`のroutingに従う。
10. **Manual E2E:** `MANUAL-E2E.md`。VS Code hostなら`VS-CODE-E2E.md`。Executor: Lunaならprompt style + `LUNA-E2E-PLAYBOOK.md`。
11. **Shared CI incident suspicion / local reproduction:** strong signalがある場合だけ`CI-INCIDENTS.md`。reproductionにもFREEなmain/sub laneだけを使う。
12. **User-facing command追加・surface変更:** `COMMAND-CONTRACTS.md`。
13. **Legacy履歴または移行中例外:** 必要なときだけ`NOTION-LEGACY.md`。
14. **Current implementation / architecture / DSL判断:** 必ずlatest repositoryから取得する。

## Maintenance rule

このREADMEへ新しい詳細ruleを直接積み上げない。

新しいdurable policyが既存ownerに収まらない場合は適切なowner documentを決め、このREADMEにはrouteとloading conditionだけを追加する。
