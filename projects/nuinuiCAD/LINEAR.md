# nuinuiCAD Linear policy router

## Purpose

LinearをnuinuiCADの正式なWork管理・長期仕様管理の場所として使う。

この文書はLinear運用の入口 / router。実装済み事実はlatest `sayosomi/nuinuiCAD` repository、execution capacityは [`CHECKOUTS.md`](./CHECKOUTS.md) がauthority。

## Structure

- Workspace: Sayosomi
- Team: Sayosomi
- Initiative: nuinuiCAD
- Project: exception-onlyの極短期aggregate tracking
- Issue: 実際に着手・完了するWork
- Document: repositoryにownerがない長期仕様・設計

Projectは通常の分類・roadmap単位にしない。通常のWork管理はIssue + relationを基本とする。

## Policy map

| Topic | Owner |
| --- | --- |
| Project粒度 / lifecycle | [Linear Project policy](./LINEAR-PROJECTS.md) |
| Issue status / Ready Queue / lane checkpoints / Done freshness | [Linear Issue workflow](./LINEAR-ISSUES.md) |
| execution lane / checkout capacity | [Execution lane policy](./CHECKOUTS.md) |
| implementation slicing / integration checkpoint | [Implementation slicing policy](./IMPLEMENTATION-SLICING.md) |
| implementation Coding Agent | [nuinuiCAD Coding Agent policy](./CODING-AGENT.md) |
| explicit contract re-audit campaign | [Contract re-audit policy](./CONTRACT-REAUDIT.md) |
| GitHub PR linking / merge sync | [Linear / GitHub integration](./LINEAR-GITHUB.md) |
| long-term specification / Linear Documents | [Linear Document policy](./LINEAR-DOCUMENTS.md) |
| Manual E2E classification / executor / result | [Manual E2E execution rules](./MANUAL-E2E.md) |
| implementation contract judgment | [Implementation contract decision rule](./CONTRACT-DECISIONS.md) |
| Linear Free plan capacity | [Linear free-plan capacity policy](./LINEAR-CAPACITY.md) |
| GitHub Issues public mirror | [GitHub Issues sync](./GITHUB-ISSUES-SYNC.md) |
| legacy Notion | [Legacy Notion archive](./NOTION-LEGACY.md) |

## Search before create

Initiative / Project / Issue / Documentを新規作成する前に既存項目を検索する。

同じWork / Specがある場合は新規作成せず更新する。軽い思いつきは [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のIdea Inboxへ置く。

## Source of truth

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- repository-owned normative contract: repositoryの該当spec / policy owner
- work plan / progress / current execution checkpoint: Linear Issue / Comment
- repositoryにownerがない長期仕様・設計: Linear Document
- local lane occupancy: actual checkout state + current Linear checkpoint

実装事実についてLinear / Notion / 過去チャットとrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。

## New Task startup

新規開発Task開始前に:

1. latest Project Contextを読む。
2. latest GitHub remote stateを確認する。
3. Linearでexisting Issue / relevant specを確認する。
4. Contract / Manual E2E / dependency / current commentsを確認する。
5. current lifecycle phaseを判定しstatusを同期する。
6. [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) でcurrent executable sliceを決める。
7. [`CHECKOUTS.md`](./CHECKOUTS.md) の3-lane preflightを行う。
8. `FREE`な`main` / `sub` implementation laneがある場合だけimplementationを開始する。
9. lane start時点のlatest remote mainからBase checkpoint SHAを固定する。
10. Issueを`In Progress`へ進め、lane / Base checkpoint / branch / current sliceを同じstartup checkpointでrecordする。

`Contract: Pending`の調査だけではIn Progressにしない。

implementation laneが2つともBUSYならReady IssueはTodoのまま待つ。3つ目のparallel implementation trackをIssue / branch / worktreeで作らない。

## ChatGPT manages Linear operations

ユーザーにLinearの手動更新を要求しない。

Issue作成、status変更、label更新、relations、Comment、Document更新等は原則ChatGPTが行う。

Linear管理はcheckpointで必要なcurrent-state recordだけをまとめて更新する。細かなcommit logや過去チャットの複製をIssueへ積まない。

## Coding Agent boundary

- ChatGPT: repository調査、contract、slicing、lane assignment、blocking review、merge判断、Manual E2E plan、Linear管理
- Luna xhigh: implementation / blocking fix / tests / git / integration checkpoint work

local executionは [`CHECKOUTS.md`](./CHECKOUTS.md)、prompt / executor detailは [`CODING-AGENT.md`](./CODING-AGENT.md) をauthorityとする。

web ChatGPTによるdirect GitHub implementationを別execution routeとして管理しない。

## Parallel work model

ParallelismはLinear reservation labelやworker-specific execution labelではなく、**固定2 implementation lane**で管理する。

```text
main lane -> at most 1 implementation track
sub lane  -> at most 1 implementation track
e2e lane  -> at most 1 Manual E2E track
```

same file / subsystem overlapは開始判断のsignalにはなるが、active lane同士を途中同期して解決しない。real dependency / owner conflictが判明した場合はdependent laneをsafe checkpointで止め、prerequisite merge後のnext integration / restart checkpointで解決する。

## Loading rule

1. Linear操作・参照ではこの`LINEAR.md`を読む。
2. Issue作成 / status / labels / readiness / Done / lane checkpointでは`LINEAR-ISSUES.md`を読む。
3. implementation開始 / pause-resume / sequential PR / integration checkpointでは`IMPLEMENTATION-SLICING.md`を読む。
4. local execution start / lane capacityでは`CHECKOUTS.md`を読む。
5. Contract re-auditでは`CONTRACT-REAUDIT.md`。
6. Projectでは`LINEAR-PROJECTS.md`。
7. PR linking / merge checkpointでは`LINEAR-GITHUB.md`。
8. Linear Documentでは`LINEAR-DOCUMENTS.md`。
9. Manual E2E / contract / capacity / public mirrorはPolicy mapのownerを読む。

## Maintenance rule

新しいLinear詳細ruleをこのrouterへ積み上げない。既存ownerへ置き、ここにはroute / shared boundary / loading conditionだけを残す。
