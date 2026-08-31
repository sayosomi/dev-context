# nuinuiCAD Chat workflow

## Purpose

ChatGPT Project内のchat sessionを、Work / repository / execution stateそのものから分離して運用する。

chatは作業UIでありsource of truthではない。chatが長大化、遅延、文脈劣化、判断品質低下などで使いづらくなった場合、同じWorkの途中でも安全に新しいchatへrotationできることを前提とする。

current stateのauthorityは次の通り。

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- Work / contract / progress / checkpoint: Linear Issue / Comment / Document
- local execution occupancy: actual fixed checkout state + current Linear checkpoint
- durable project policy: latest `sayosomi/dev-context` owner documents

過去chat、chat summary、project conversation historyはcurrent stateのauthorityにしない。

## Human terminal-loss recovery

Lost Human terminal output is an external-state recovery case, not permission to retry a mutation. The first official recovery surface is the read-only `nuinui last-result` command. The durable result store and its verified canonical output are the evidence; chat history is not the authority. A later mutation is never automatically retried merely because the terminal disappeared.

## Chat roles

Chat roleは会話整理のための分類であり、Issue status、execution ownership、lane occupancyそのものではない。

| Role | Purpose | Owner |
| --- | --- | --- |
| Coordinator | Project全体のstatus整理、Work選択、routing | [`CHAT-COORDINATOR.md`](./CHAT-COORDINATOR.md) |
| Issue Authoring | Issue作成・調査・仕様・contract・dependency整理 | [`CHAT-AUTHORING.md`](./CHAT-AUTHORING.md) |
| Implementation | Ready Issueのimplementation / fix / verification / integration / review / merge | [`CHAT-IMPLEMENTATION.md`](./CHAT-IMPLEMENTATION.md) |
| E2E | required Manual E2Eの実行・再開 | [`CHAT-E2E.md`](./CHAT-E2E.md) |

chatを新しく作っただけではIssue statusやexecution laneを変更しない。各role固有のstartup / handoffはそのowner documentに従う。

## Chat role and Work identity are separate

`1 Issue = 1 chat`を要求しない。

同じIssueは必要に応じて複数chatへrotationしてよい。

```text
SAY-123 authoring #1
-> SAY-123 authoring #2
-> SAY-123 implementation #1
-> SAY-123 implementation #2
-> SAY-123 E2E
```

このchat分割自体はIssue decompositionではない。Issue boundaryは`CONTRACT-DECISIONS.md`、implementation sliceは`IMPLEMENTATION-SLICING.md`がauthority。

chatとlaneも固定対応させない。`main chat` / `sub chat`のような恒久対応を作らず、Issueのcurrent execution時点でFREEなlaneを割り当てる。

## Rotation is always allowed

Humanがchatを重い、遅い、混乱している、判断品質が落ちた、または単に切り替えたいと感じた場合、同じWorkの途中でも新chatへrotationしてよい。rotation自体を正当化する必要はない。

### Normal rotation

旧chatがまだ信頼できる場合、Humanは例えば次のように指示できる。

```text
このチャット重い。checkpointして切り替える
```

ChatGPTはrotation前に、**chatにしか存在せず外部stateから復元できない重要情報だけ**を必要に応じて外部化する。

典型:

- Human Manual E2E observation / result
- 未記録のproduct / UX decision
- Luna handoffのうちremote / Linearへまだ保存されていないcurrent checkpoint
- 唯一のscreenshot / evidenceへの必要な参照情報
- next chatがrepository / Linear / local stateだけでは復元できない一時情報

GitHub / Linear / dev-contextから再取得できる情報を長大なhandoff summaryとして複製しない。

### Emergency rotation

旧chatの判断をすでに信用できない、またはcheckpoint作業自体を任せたくない場合は、そのchatをそのまま捨ててよい。

新chatでは例えば次だけでよい。

```text
SAY-123を外部状態から復元して続ける。前チャットは信用しない
```

その場合、外部保存されていないchat-only stateは失われ得る。必要なHuman observation / decisionが外部化されていなければ、再確認が必要になることは許容する。

## Recovery order in a new chat

Issue / Workを新chatで開始・再開するとき、過去chatの要約からcurrent stateを組み立てない。

必要なscopeに応じて次から再構築する。

1. latest Project Context `README.md`
2. loading ruleが要求するlatest dev-context owner documents
3. current Linear Issue / Comments / relevant Document
4. latest GitHub remote repository / branch / PR / CI state
5. local executionが関係する場合だけactual fixed lane state

current implementation factはlatest repositoryをauthoritativeとする。

通常の開始文は短くてよい。

```text
SAY-123を続ける
```

またはfresh reconstructionを明示するなら:

```text
SAY-123を最新の外部状態から再開
```

## Rotation is not Task pause

**chat session rotation alone is not a Task pause.**

同じWorkを継続するためにchatだけを交換する場合、rotationだけを理由に次を行わない。

- Linear status変更
- implementation / E2E lane release
- Base checkpoint更新
- branch変更
- active slice変更
- tested commit変更

Work自体をpauseしてlaneを解放する場合だけ、`LINEAR-ISSUES.md` / `CHECKOUTS.md`のpause / release ruleを使う。

## Parallelism model

chatの数とexecution parallelismを混同しない。

```text
Coordinator chat     -> execution capacityを消費しない
Issue Authoring chat -> unlimited; execution capacityを消費しない
Implementation       -> main/subで最大2 track
Manual E2E           -> e2eで最大1 track
```

Issue Authoringを多数並行することは許可するが、Ready Workが増えたことを理由にimplementation laneを追加しない。

## Handoff between chat roles

典型flow:

```text
Human report / idea
-> Issue Authoring chat
-> Issue / contract Ready
-> Todo
-> Coordinator or direct request selects Work
-> Implementation chat + FREE main/sub lane
-> merge
-> requiredなら E2E chat + e2e lane
-> PASS
-> Done
```

roleを切り替える際も、destination roleのstartup gateを省略しない。同じchatを継続するか新chatへ切り替えるかはWork identityとは別判断。

## Loading rule

1. Chat role判断、rotation、handoff、external-state recoveryではこのdocumentを読む。
2. Coordinator workでは`CHAT-COORDINATOR.md`。
3. Issue Authoringでは`CHAT-AUTHORING.md`。
4. Implementationでは`CHAT-IMPLEMENTATION.md`。
5. E2Eでは`CHAT-E2E.md`。
6. 各role ownerを読んだ後、READMEのtopic-specific loading ruleに従う。

## Maintenance rule

このdocumentはchat共通lifecycle / role routing / rotation / recoveryだけをownerする。role固有の動作は各`CHAT-*.md`へ置き、Issue lifecycle、contract semantics、implementation executor、checkout、Manual E2Eの詳細はそれぞれのowner documentへ置く。
