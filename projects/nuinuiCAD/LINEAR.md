# nuinuiCAD Linear policy router

## Purpose

LinearをnuinuiCADの正式なWork管理・長期仕様管理の場所として使う。

ユーザー自身が管理画面を細かく操作することより、ChatGPTが安定して検索・作成・更新できることを優先する。

この文書はLinear運用の**入口 / router**。詳細ruleはowner documentへ分離する。

## Structure

- Workspace: Sayosomi
- Team: Sayosomi
- Initiative: nuinuiCAD
- Project: exception-onlyの極短期aggregate tracking
- Project label: 例外的にProjectを使う場合の分野分類
- Issue: 実際に着手・完了するWork
- Document: repositoryに既存ownerがない長期的な仕様・設計

Taskや個別開発テーマをInitiativeにしない。製品ごとにTeamを増やさず、当面はSayosomi Team 1つで運用する。

Projectは通常の分類・roadmap単位にしない。通常のWork管理はIssue + relationを基本とし、Project利用条件は [`LINEAR-PROJECTS.md`](./LINEAR-PROJECTS.md) をauthorityとする。

## Policy map

| Topic | Owner |
| --- | --- |
| Project粒度 / lifecycle / Project labels | [Linear Project policy](./LINEAR-PROJECTS.md) |
| Issue status / Ready Queue / labels / checkpoints / Done freshness | [Linear Issue workflow](./LINEAR-ISSUES.md) |
| GitHub PR linking / PR automations / merge status sync | [Linear / GitHub integration](./LINEAR-GITHUB.md) |
| long-term specification / Linear Documents / Notion migration | [Linear Document policy](./LINEAR-DOCUMENTS.md) |
| `only_chatgpt` / `manual_e2e_only` execution ownership | [Execution ownership labels](./ONLY-CHATGPT.md) |
| Manual E2E classification / executor / PASS-FAIL-BLOCKED | [Manual E2E execution rules](./MANUAL-E2E.md) |
| implementation contract judgment | [Implementation contract decision rule](./CONTRACT-DECISIONS.md) |
| Linear Free plan capacity | [Linear free-plan capacity policy](./LINEAR-CAPACITY.md) |
| GitHub Issues public mirror | [GitHub Issues sync](./GITHUB-ISSUES-SYNC.md) |
| legacy Notion browsing | [Legacy Notion archive](./NOTION-LEGACY.md) |

## Search before create

Initiative / Project / Issue / Documentを新規作成する前に、必ず既存項目を検索する。

同じWork / Specがある場合は新規作成せず更新する。

Canceledの移行試験Issueや旧カテゴリProject等が残っている場合があるため、タイトルだけで判断せず内容とstatusも確認する。

軽い思いつきは新規Issueを乱造せず、 [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のIdea Inbox ruleに従う。

## Source of truth

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- repository-owned normative contract: repositoryの該当spec / policy owner
- work plan / progress / research result: Linear Issue / Project
- repositoryにownerがない長期仕様・設計: Linear Document
- pre-migration history: Notion legacy archive

実装事実についてLinear / Notion / 過去チャットとrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。actual behaviorとnormative contractの衝突判断は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) に従う。

## New Task startup

新規開発Task開始前に:

1. latest GitHub remote stateを確認する。
2. Linearで既存Issueを検索する。Projectは現在のTaskに関係する例外的な短期Projectが存在する場合だけ確認する。
3. 必要なlong-term Specをrepository ownerまたはLinear Documentsから確認する。
4. 対象IssueのContract / Manual E2E label、dependency、description、current Commentを確認する。
5. [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) に従いReady条件とBacklog / Todoが一致していることを確認する。
6. Project assignmentを例外的に行う必要がある場合だけ [`LINEAR-PROJECTS.md`](./LINEAR-PROJECTS.md) に従う。
7. `Contract: Ready`でもlatest repositoryのactual owner / symbol / file pathを再確認する。
8. ユーザーがTaskを明示的に開始した時点で、Issue workflowとexecution ownership ruleに従ってactive statusへ同期する。

`Contract: Pending`の調査を進めること自体はIn Progressへの変更理由にしない。

Notionを新Taskの通常Spec検索先にしない。legacy exception / migrationは [`LINEAR-DOCUMENTS.md`](./LINEAR-DOCUMENTS.md) と [`NOTION-LEGACY.md`](./NOTION-LEGACY.md) に従う。

## ChatGPT manages Linear operations

ユーザーにLinearの手動更新を要求しない。

Issue作成、status変更、label更新、Project紐付け、Project label、Comment、Document更新等は原則ChatGPTが行う。

Linear APIで未対応の管理操作だけ、必要最小限のUI操作をユーザーへ依頼してよい。

新しい分類・status・label groupを勝手に追加しない。必要ならユーザーと運用を決めてから追加する。

Linear管理自体を開発作業の主目的にせず、checkpointで必要なrecordだけをまとめて更新する。Issue checkpointとpost-write verificationは [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) がauthority。

## Coding Agent boundary

Linear運用によってChatGPT / Coding Agentの役割分担を変更しない。

- ChatGPT: repository調査、architecture把握、implementation contract、blocking review、Manual E2E plan、Linear管理
- Coding Agent: 確定済みcontractに従うimplementation / test / commit / push

local worktree運用は [`CHECKOUTS.md`](./CHECKOUTS.md)、direct GitHub execution ownershipは [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) をauthorityとする。

remote-state verification、prompt順序、Git safetyは [`shared/DEVELOPMENT.md`](../../shared/DEVELOPMENT.md) をauthorityとする。

## Loading rule

Linearを扱うときも全owner documentを毎回読む必要はない。

1. Linear操作・参照ではこの`LINEAR.md`を読む。
2. Issueの作成 / status / labels / dependency / readiness / Doneでは`LINEAR-ISSUES.md`を読む。
3. Project作成 / assignment / label / completionでは`LINEAR-PROJECTS.md`を読む。
4. PR linking / PR automation / merge checkpointでは`LINEAR-GITHUB.md`を読む。
5. Linear Document / long-term Spec / Notion移行では`LINEAR-DOCUMENTS.md`を読む。
6. execution ownership、Manual E2E、contract、capacity、public mirrorが関係するときはPolicy mapの専用ownerも読む。

## Maintenance rule

新しいLinear詳細ruleをこのrouterへ積み上げない。

既存ownerへ置き、ここにはroute / shared boundary / loading conditionだけを残す。
