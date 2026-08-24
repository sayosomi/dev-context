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

## Chat roles

Chat roleは会話整理のための分類であり、Issue status、execution ownership、lane occupancyそのものではない。

### Coordinator chat

Project全体の整理とroutingを行う。

主な用途:

- current status / Ready Queue / blockersの確認
- 次に進めるWorkの選択
- lane / remote / Linearの整合確認
- project運用ruleの検討
- 個別Issue / E2E chatへの振り分け

Coordinator chat自体はimplementation laneやManual E2E laneを占有しない。

### Issue Authoring chat

Issueを**作る / 育てる / 編集する**ためのchat。

主な用途:

- Humanが報告したBugを調査してIssue化する
- 要望 / アイデアを正式Workへ育てる
- existing Issueの仕様をHumanと相談して決める
- product / UX / compatibility / scope decisionを確定する
- latest repositoryを調査して細かなimplementation contractを策定する
- same Issue / new Issueのboundaryを決める
- dependency / parent-child / relationを整理する
- acceptance criteria / Manual E2E planを策定する
- `Contract: Pending | Blocked`を`Ready`へ進める
- current fact driftに合わせてReady contractをrefreshする

Issue Authoringはrepository implementationではない。

- `main` / `sub` / `e2e` laneをclaimしない。
- implementation branch / worktreeを作らない。
- product code implementation / blocking fixを開始しない。
- Readyになっただけでは`In Progress`へ進めない。
- implementation待ちのReady Workは原則`Todo`に置く。

**Issue Authoring chatの同時実行数に上限を設けない。**

複数IssueのAuthoringを別chatで並行してよい。これはfixed implementation capacityとは無関係であり、3つ目以降のimplementation trackを許可する意味ではない。

同じIssueを複数Authoring chatが扱うことも禁止しない。ただしLinear write前にcurrent Issue / relevant commentsを再取得し、別chatの新しい変更を失わないこと。競合するproduct decisionをlast-write-winsで上書きしない。一意に統合できない場合はHumanへ判断を戻す。

Issue contractの判断詳細は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、Linear lifecycleは [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) をauthorityとする。

### Implementation chat

`Contract: Ready`なIssueのrepository implementation / blocking fix / verification / integration / blocking review / mergeを進めるchat。

実行capacityはchat数ではなく [`CHECKOUTS.md`](./CHECKOUTS.md) のfixed implementation laneで決まる。

- `main`: at most 1 implementation track
- `sub`: at most 1 implementation track
- 合計最大2 implementation track

Implementation chatを新しく作っただけではlaneをclaimしない。実際のstartup gate / lane assignment / Base checkpoint記録が完了した時点でexecutionが開始する。

repository implementation / blocking fixは [`CODING-AGENT.md`](./CODING-AGENT.md) に従いLuna xhighが担当する。

### E2E chat

required Manual E2Eを実行するchat。

実行capacityは [`CHECKOUTS.md`](./CHECKOUTS.md) の`e2e` lane最大1 track。Judgment / Executor / PASS-FAIL-BLOCKEDは [`MANUAL-E2E.md`](./MANUAL-E2E.md) をauthorityとする。

E2E chatを新しく作っただけでは`e2e` laneをclaimしない。tested commit / marker / Issue checkpointを固定した時点でexecutionが開始する。

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

Humanがchatを重い、遅い、混乱している、判断品質が落ちた、または単に切り替えたいと感じた場合、同じWorkの途中でも新chatへrotationしてよい。

rotation自体を正当化する必要はない。

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

## Linear write safety for concurrent Authoring

Issue Authoringは多数並行できるため、Linear writeではcurrent stateを再確認する。

原則:

1. write直前にtarget Issue / relevant current commentsを取得する。
2. 自分のchat開始時点より新しい変更があれば意味を確認する。
3. independentな追加は統合する。
4. descriptionを更新する場合、別chatのcurrent decision / acceptanceを消さない。
5. incompatibleなproduct decision、scope、acceptance変更が競合した場合は勝手に上書きしない。
6. write後は`LINEAR-ISSUES.md`のpost-write verificationに従う。

細かなchat transcriptや議論履歴をLinearへ複製しない。current Work state / decision / checkpointだけを残す。

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

Issue AuthoringからImplementationへ移る際、同じchatを継続することも技術的には禁止しないが、chat roleとexecution boundaryを明確にするため新chatへ切り替えてよい。どちらの場合もimplementation startup gateを省略しない。

## Loading rule

1. Chat role判断、chat開始 / 再開、rotation、handoff、外部state recoveryではこの文書を読む。
2. Issue Authoringでは`LINEAR.md`、`LINEAR-ISSUES.md`、`CONTRACT-DECISIONS.md`と、READMEが要求するrelevant authorityを読む。
3. Implementation chatではREADMEのimplementation loading ruleに従う。
4. E2E chatではREADMEのManual E2E loading ruleに従う。
5. local lane操作が必要な場合だけ`CHECKOUTS.md`を読む。

## Maintenance rule

Issue lifecycle、contract semantics、implementation executor、checkout、Manual E2Eの詳細をこの文書へ複製しない。それぞれのowner documentを参照し、この文書はchat session lifecycle / role / rotation / recoveryのboundaryだけをownerする。
