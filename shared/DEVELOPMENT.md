# Shared Development Workflow

複数projectで共通利用するChatGPT / Coding Agent開発運用の**入口 / router**。

Project固有のrepository policy、task contract、specification、work-management ruleがある場合はそちらを優先する。

この `dev-context` repository 自身が変更対象の場合は、root [`../DEVELOPMENT.md`](../DEVELOPMENT.md) が self-development lifecycle の canonical owner である。
checkout / worktree / branch / review / merge / sync lifecycleはroot documentに従い、このshared routerをそのlifecycleの第二の全文コピーにしない。

## Core responsibility

ChatGPTがrepository調査、architecture把握、actual owner / change location特定、implementation contract決定、blocking reviewを担当する。

Coding Agentをimplementation / blocking-fixに使う場合は、確定済みcontractに従い具体的なimplementation / test / git作業を行わせ、open-ended architecture / design判断を委ねない。

Agent promptのlanguage / formattingは [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) がauthority。Implementation Coding Agentのrole / prompt content / handoffは [`CODING-AGENT-WORKFLOW.md`](./CODING-AGENT-WORKFLOW.md) がauthority。

## dev-context write approval

この`dev-context` repositoryへのcreate / update / deleteは、ChatGPTが実際のwriteを行う前にユーザーへ変更planを提示し、明示的な承認を得てから実行する。

これはcross-cuttingなshared safety requirementとして維持する。dev-context自身のself-development lifecycle全体のownerはroot [`../DEVELOPMENT.md`](../DEVELOPMENT.md)であり、このgateを弱めたり、別のapproval ruleへ置き換えたりしない。

変更planには最低限、次を含める。

- current state / problem
- change purpose
- target file(s)
- intended change summary

read-onlyな調査・fetch・比較には承認を要求しない。

承認は提示したplanの範囲に対して有効とする。対象file、責務、意味上のscopeがmaterially拡大する場合は、write前に更新planを再提示して承認を取り直す。

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
| execution-agent prompt language / formatting | [Shared Agent Prompt Style](./AGENT-PROMPT-STYLE.md) |
| implementation Coding Agent role / prompt content / management ordering / handoff | [Shared Implementation Coding Agent Workflow](./CODING-AGENT-WORKFLOW.md) |
| reusable implementation/review skills and Human terminal instruction skill routing | [Shared Agent Skills](./AGENT-SKILLS.md) |

## Task lifecycle

標準的なimplementation flow:

1. current remote / work-management / spec stateを確認する。
2. ChatGPTがrepositoryを調査し、implementation contractを確定する。
3. Implementation Coding Agentが必要なら、確定済みcontractからnarrow implementation promptを作る。
4. implementation / test / git作業を実行する。
5. pushed stateに対してrequired blocking review / verificationを行う。
6. blocking fix、PR / merge、次Taskへの継続はcurrent track / project planに従う。

current Task scope外のcleanup / future workを先取りしない。

TaskごとにPR / mergeを機械的に要求しない。review済みcommitから連続Taskへ進むtrackも、project / current planが許す場合はあり得る。

Manual E2E test operatorなどimplementation以外のexecution roleは、このimplementation lifecycleへ機械的に当てはめない。Project-specific role authorityに従う。

## Loading rule

1. Development workではこの`DEVELOPMENT.md`を読む。dev-context自身が変更対象なら、root [`../DEVELOPMENT.md`](../DEVELOPMENT.md)も読み、そのself-development lifecycleを優先する。
2. Git remote state、branch / checkout / worktree、commit / push / reviewが関係する場合は`GIT-WORKFLOW.md`を読む。dev-context自身のlifecycleの詳細なownerはroot documentである。
3. Execution agent向けpromptを生成する場合は、roleにかかわらず`AGENT-PROMPT-STYLE.md`を読む。
4. Implementation / blocking-fix Coding Agent向けprompt、implementation role boundary、implementation handoffが関係する場合だけ`CODING-AGENT-WORKFLOW.md`を読む。
5. Agent skill選択が必要な場合は`AGENT-SKILLS.md`とproject固有skill policyを読む。Humanがcopy/pasteして実行するterminal command / shell scriptをChatGPTが生成する場合も`AGENT-SKILLS.md`を読み、そこに登録されたHuman terminal instruction skillのactivation ruleに従う。
6. Project固有ruleが同じtopicを上書き / 追加する場合はproject policyを優先する。

Manual E2E test-operator promptであるという理由だけで`CODING-AGENT-WORKFLOW.md`を読まない。Manual E2Eのallowed operationsはproject-specific Manual E2E authorityを読む。

## Maintenance rule

Git mechanics / safetyの詳細をこのrouterへ積み上げない。Agent prompt styleやimplementation Coding Agent promptの詳細もこのrouterへ積み上げない。

新しいshared development ruleは責務に応じて`GIT-WORKFLOW.md`、`AGENT-PROMPT-STYLE.md`、`CODING-AGENT-WORKFLOW.md`、`AGENT-SKILLS.md`のownerへ置き、この文書にはshared principle / route / loading conditionだけを残す。
