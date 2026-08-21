# Shared Development Workflow

複数projectで共通利用するChatGPT / Coding Agent開発運用の**入口 / router**。

Project固有のrepository policy、task contract、specification、work-management ruleがある場合はそちらを優先する。

## Core responsibility

ChatGPTがrepository調査、architecture把握、actual owner / change location特定、implementation contract決定、blocking reviewを担当する。

Coding Agentは確定済みcontractに従い、具体的なimplementation / test / git作業を行う。open-ended architecture / design判断を委ねない。

詳細なrole / prompt / handoffは [`CODING-AGENT-WORKFLOW.md`](./CODING-AGENT-WORKFLOW.md) がauthority。

## New development Task

過去チャットやpromptに書かれたcommit hashを現在値として無条件に信用しない。

implementation contract確定前にGitHub上のremote stateを確認する。必要に応じて:

- latest remote main
- target branch remote HEAD
- related PR state
- projectが利用するwork-management / spec source

実装済みの事実について、過去チャットやmanagement documentとrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。

remote/local照合、checkout / worktree、commit / push / reviewの詳細は [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) に従う。

## Shared policy map

| Topic | Owner |
| --- | --- |
| remote/local verification | [Shared Git Workflow](./GIT-WORKFLOW.md) |
| checkout / worktree / Git safety | [Shared Git Workflow](./GIT-WORKFLOW.md) |
| commit / push / pushed-state review | [Shared Git Workflow](./GIT-WORKFLOW.md) |
| ChatGPT / Coding Agent role boundary | [Shared Coding Agent Workflow](./CODING-AGENT-WORKFLOW.md) |
| Coding Agent prompt / management ordering / handoff | [Shared Coding Agent Workflow](./CODING-AGENT-WORKFLOW.md) |
| reusable implementation/review skills | [Shared Agent Skills](./AGENT-SKILLS.md) |

## Task lifecycle

標準的な流れ:

1. current remote / work-management / spec stateを確認する。
2. ChatGPTがrepositoryを調査し、implementation contractを確定する。
3. Coding Agentが必要なら、確定済みcontractからnarrow implementation promptを作る。
4. implementation / test / git作業を実行する。
5. pushed stateに対してrequired blocking review / verificationを行う。
6. blocking fix、PR / merge、次Taskへの継続はcurrent track / project planに従う。

current Task scope外のcleanup / future workを先取りしない。

TaskごとにPR / mergeを機械的に要求しない。review済みcommitから連続Taskへ進むtrackも、project / current planが許す場合はあり得る。

## Loading rule

1. Development workではこの`DEVELOPMENT.md`を読む。
2. Git remote state、branch / checkout / worktree、commit / push / reviewが関係する場合は`GIT-WORKFLOW.md`を読む。
3. Coding Agent向けprompt、role boundary、implementation handoffが関係する場合は`CODING-AGENT-WORKFLOW.md`を読む。
4. Agent skill選択が必要な場合だけ`AGENT-SKILLS.md`とproject固有skill policyを読む。
5. Project固有ruleが同じtopicを上書き / 追加する場合はproject policyを優先する。

## Maintenance rule

Git mechanics / safetyの詳細をこのrouterへ積み上げない。Coding Agent prompt作法もこのrouterへ積み上げない。

新しいshared development ruleは責務に応じて`GIT-WORKFLOW.md`、`CODING-AGENT-WORKFLOW.md`、`AGENT-SKILLS.md`のownerへ置き、この文書にはshared principle / route / loading conditionだけを残す。
