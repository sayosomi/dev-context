# nuinuiCAD execution lane / checkout policy

## Purpose

nuinuiCADのlocal execution capacityを、常設3 checkoutに固定して管理する。

この3 checkoutは単なる再利用候補ではなく、**存在を許可するexecution laneそのもの**である。Issue数、Ready数、worker数を理由に追加worktree / clone / checkoutを作らない。

## Fixed lanes

| Lane | Checkout | Role |
| --- | --- | --- |
| `main` | `/Users/yosomi/Code/nuinuiCAD` | Luna implementation / blocking fix / implementation-side diagnosis |
| `sub` | `/Users/yosomi/Code/nuinuiCAD-sub` | Luna implementation / blocking fix / implementation-side diagnosis |
| `e2e` | `/Users/yosomi/Code/nuinuiCAD-e2e` | Manual E2E only |

`main` laneという呼称はGit branch `main`とは別概念。`main` / `sub` implementation laneはそれぞれTask branchをcheckoutしてよい。

Hard limits:

- implementationは同時に最大2 track。`main`と`sub`を各1 trackだけ使う。
- Manual E2Eは同時に最大1 track。`e2e`だけを使う。
- 4つ目のworktree / clone / CI-repro checkoutを作らない。
- `e2e`をimplementationへ転用しない。
- `main` / `sub`が両方BUSYなら、新しいimplementationは開始しない。

## Human terminal operations

Humanがterminalでlocal checkoutへ対して行う**mechanical / deterministic operation**はlane ownershipそのものではなく、Luna implementation routeとは別の操作補助として扱う。

ChatGPTがlocal状態の確認や単純な環境準備を必要とするときは、Luna sessionを起動する前に、Humanが安全にcopy/paste実行できるcommandで済むかを優先して判断する。

Humanへ任せてよい典型:

- read-only audit: `git status`, `git rev-parse`, `git worktree list`, branch / HEAD / upstream / path確認;
- safety conditionが確定した後の単純な`git fetch`, fast-forward, exact checkout / detached checkout;
- cleanで不要と証明済みのworktree整理;
- E2E markerの作成 / 読み取り / 削除;
- dev host / test hostの起動・停止など、implementationを含まない環境操作。

Human向けterminal instructionを生成する場合はshared `human-terminal-instructions` skillを必ず使い、少なくとも次を守る。

- absolute pathで対象checkoutを固定する;
- auditとmutationを分ける;
- mutation直前にsafety-critical factsを再確認する;
- precondition mismatchでは`BLOCKED:`等で具体的理由を表示して停止する;
- current directoryや以前のshell変数へ暗黙依存しない。

同じmechanical operationがversioned helperとして[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に登録済みで、current local clone上のhelperが利用可能なら、Human handoffではそのhelperを優先してよい。helperは上記safety requirementを省略するものではなく、確認とmutationをversioned implementationへ移すだけである。

helper commandの存在はlaneのcurrent利用許可ではない。executor / lane選択はREADME routerとActive overrideがauthorityであり、helperは許可済みoperationのmechanical preconditionとmutationだけを担う。

### Mandatory preflight handoff rule

implementation start / resume等でmandatory 3-lane preflightが必要なのに、ChatGPT側からactual local checkout stateを直接確認できない場合、`preflightが必要`、`lane状態がblocker`、`audit結果待ち`等とだけ述べて停止してはならない。

versioned `nuinui` helperがcurrentで利用可能なら、その応答内でHumanがそのままcopy/paste実行できる**exact helper invocation**を提示する。標準path:

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui preflight
```

helperが未install、stale / broken、またはcurrent operationをsupportしていない場合は、その応答内でHumanがそのままcopy/paste実行できる**完全なread-only 3-lane audit block**をfallbackとして提示する。

helper outputまたはinline auditは、少なくとも`main` / `sub` / `e2e`の全3 laneについて次を一度に確認できること。

- checkout path存在;
- branch名またはdetached HEAD;
- actual HEAD SHA;
- `git status --porcelain`相当のcleanliness;
- `git worktree list`からのcurrent worktree state;
- implementation laneでcurrent branch / stateから読めるIssue ownership情報;
- `e2e` laneのmarker有無と、存在する場合は内容。

handoff生成時の追加原則:

- path、Issue key、commit SHA等、ChatGPTが確定できる値をHumanに手入力・置換させない。
- auditはread-onlyに限定し、`fetch`、checkout、switch、reset、stash、clean、marker作成/削除等のmutationを混ぜない。
- 実際には提示していないcommandを`上のaudit`、`先ほどのpreflight`等として参照しない。
- command生成自体を妨げるconcrete blockerがある場合だけ`BLOCKED`とし、その理由と次に必要なactionを明示する。
- Humanからaudit出力が返ったら、それをfresh evidenceとしてlane stateを判定し、結果がまだfreshでmaterial state changeのsignalがない限り同じpreflightを機械的に要求し直さない。

このruleはlane safety checkを省略するものではなく、**必要なcheckをHumanへ依頼するときのhandoffを不完全なまま終わらせない**ためのruleである。

Humanへ任せないもの:

- product code implementation / blocking fix;
- implementation-side failure diagnosisがcode changeや広いlocal iterationを伴う作業;
- merge / rebase conflict resolutionやintegration fix;
- 状態不明のcheckoutに対する`reset`, `stash`, force-switch, force-push;
- dirty / untracked workの保存判断を伴うworktree削除やcleanup;
- unrelated Human workを破棄・上書きする操作。

Human terminal assistanceはimplementation executorの変更ではない。repository implementation / blocking fixは引き続き[`CODING-AGENT.md`](./CODING-AGENT.md)に従いLuna xhighが担当する。

## Lane isolation rule

implementation laneはTask / current implementation slice開始時に**Base checkpoint SHA**を固定する。

active sliceの途中では、次を行わない。

- remote `main` advanceのmerge / rebase / cherry-pick;
- もう一方のimplementation laneのunfinished change取り込み;
- unrelated PR branchの取り込み;
- 「最新にしておく」ことだけを目的としたbase refresh。

remote `main`が進んだ事実は観測してよい。contract / ownershipを無効化する重大な変更が見つかった場合は、現在の変更を安全に保存してcheckpointで停止する。**途中同期して継続することはしない。**

## Integration checkpoint

他line / latest `main`の変更を取り込めるのは、current sliceが明確なintegration checkpointへ到達したときだけ。

典型的には:

1. current sliceの実装とfocused verificationを完了する。
2. branchへcommit / pushし、現在のstateをremoteに保存する。
3. current laneのBase checkpoint以降にremote `main`へ入ったchangeを確認する。
4. Lunaが必要なmerge / rebase / conflict resolution / integration fixをそのlaneで行う。
5. integration後のrequired verificationを行う。
6. blocking review / merge gateへ進む。

integration checkpoint前に相手laneの進行中branchへ依存しない。必要なdependencyがあるなら、依存先がmergeされるまでcurrent sliceをcheckpointで止める。

## Occupancy model

current occupancyはdev-contextへ保存しない。actual local checkout stateとLinear checkpointから判断する。

新しいlocal executionを始める前に3 laneすべてについて最低限確認する。

- path存在
- branch / detached HEAD
- HEAD SHA
- `git status --porcelain`
- implementation laneならbranchから読めるIssue key
- e2e laneならtested Issue / exact ref marker

state:

- `FREE`: cleanでlaneのidle state。新しいexecutionへ割当可能。
- `BUSY`: current Issue / tested refのownershipを一意に確認でき、executionが現在進行中。
- `RELEASE-PENDING`: implementation自体はremote保存済みまたはmerge済みで終了しているが、cleanなcheckoutをidle stateへ戻すdeterministic local cleanupだけが残る。新しいIssueへはまだ割り当てない。
- `BLOCKED / UNKNOWN`: dirty、unexpected HEAD、ownership不明、marker mismatch、missing checkout等。

`BUSY` / `RELEASE-PENDING` / `BLOCKED` laneを空けるためにreset / stash / force-switch / unrelated work破棄をしない。

`RELEASE-PENDING`はWork lifecycle statusではない。前Issueを`In Progress`へ保持する理由にせず、Linear statusはactual implementation / merge / Manual E2E stateに従う。

## E2E marker

`e2e` laneはdetached HEADを使えるため、実行中だけGit local metadataへmarkerを持つ。

```bash
$(git -C /Users/yosomi/Code/nuinuiCAD-e2e rev-parse --git-dir)/nuinui-slot
```

format:

```text
issue=SAY-123
ref=<exact tested commit or stable ref>
```

markerはworking treeへ置かない。E2E releaseの最後に削除する。

## Lane start

### main / sub implementation

1. mandatory 3-lane preflightを行う。
2. `FREE`なimplementation laneを選ぶ。
3. `git fetch origin --prune`でremote stateを確認する。
4. start時点のintended baseを確定し、Base checkpoint SHAとして記録する。
5. Task branchを作成 / checkoutする。
6. Linearへlane / Base checkpoint / branch / current sliceをcheckpointする。
7. 以降はintegration checkpointまでbaseを固定する。

新しいTask開始時点で`main`と`sub`が両方FREEなら通常`main`を優先する。`main`がBUSYなら`sub`を使う。並列化自体を目的にTaskを増やさない。

### implementation resume

remote保存済みactive implementation branchをfixed laneへ戻して同じsliceを再開する場合は、新しい`start`として扱わない。mandatory 3-lane preflightのfresh evidenceと、再開対象のIssue / branch / exact pushed checkpointを確定してからresumeする。

versioned helperがcurrentなら次の形を使う。

```text
nuinui resume <main|sub> <SAY-123> <expected-checkpoint-sha> <branch>
```

resumeがworking tree / branchへ行うmutationは、安全条件を満たしたexisting branchへのswitchだけである。authoritative remote mainをfreshに確認するため`git fetch origin main`で`origin/main`を更新してよいが、`--prune`や他remote-tracking refのcleanupは行わない。local / authoritative remote branchがexact checkpointと一致し、laneがcleanなsafe idle stateで、対象branchが他worktreeにcheckoutされていないことを確認する。既に対象branch / exact checkpointならそのstateをそのまま成功として扱う。

resume時にlatest `main`を取り込まない。active sliceのBase checkpointはintegration checkpointまで固定したままとし、reset / stash / force-switch / merge / rebaseによるrepairを行わない。条件が一致しなければ`BLOCKED / UNKNOWN`として停止し、状態を推測して復旧しない。

### e2e

1. `e2e`がFREEであることを確認する。
2. exact tested commit / stable refを決める。
3. detached checkoutし、actual HEADを確認する。
4. markerへIssue / refを書く。
5. Manual E2Eをその固定stateで実行する。

E2E中にremote `main`が進んでもtested stateを途中更新しない。

## E2E failure

confirmed product implementation failureが出ても`e2e` laneでは修正しない。

```text
e2e FAIL
-> failure classification / fix contract
-> FREEな main または sub implementation lane
-> Luna fix / verification / merge
-> new exact tested commit
-> e2e laneでaffected unitをrerun
```

両implementation laneがBUSYならfixは開始可能なcheckpointまで待つ。E2E laneを4つ目の実装lineにしない。

## Lane release

### main / sub

release条件:

- uncommitted changeなし;
- current workがremote branch / merged commitへ保存済み;
- Linear checkpointから再開可能;
- branch ownershipを失わず安全にidleへ戻せる。

Task完了だけでなく、remote保存済みの明確なpause / handoff checkpointでもreleaseしてよい。

implementation / mergeが終了した時点でlocal checkoutがまだTask branch等に残っている場合、そのlaneは`RELEASE-PENDING`とする。これはimplementation executionの継続ではなく、idleへ戻すdeterministic cleanup待ちである。

#### Post-merge release authority

PR merge後のimplementation lane releaseでは、merge済みtopic branchのremote refが残っていることを要求しない。GitHub設定やmerge操作でtopic branchが削除され、`git fetch --prune`後にremote-tracking refが消えるのは正常系になり得る。

post-merge releaseのauthoritative evidenceは少なくとも:

- local working treeがclean;
- merge前に保存したexact integration / pushed checkpoint SHAが判明している;
- current authoritative `origin/main`がそのcheckpoint SHAをancestorとして含む;
- local idle stateへの移動がnon-destructiveに行える。

この条件を満たすなら、remote topic branch missingだけを理由に`BLOCKED`へしない。

また、merge直後に記録した`main` SHAとの完全一致もrelease条件にしない。別のsafe mergeによって`origin/main`がさらにadvanceしていても、保存済みcheckpointがcurrent `origin/main`に含まれ、local idle branchをsafeにfast-forwardできるならlatest `origin/main`へreleaseしてよい。

`git fetch --prune`で証拠refを消してからそのrefの存在を後段conditionに使わない。Human向けcommand生成はshared `human-terminal-instructions` skillのremote-pruning ruleにも従う。

idle state:

- `main`: cleanなlocal `main`。release時点で安全ならlatest `origin/main`へfast-forward。
- `sub`: cleanなlatest `origin/main` detached HEAD。

#### Release checkpoint synchronization

`main` / `sub` releaseが成功してactual local laneが`FREE`になったら、そのfresh release evidenceをcurrent IssueのLinear Commentへ`Lane release checkpoint`として同期する。標準recordの内容は[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)をauthorityとする。

少なくとも、release対象lane、release前に保存済みのexact checkpoint、release結果、release後のidle branch / detached state、release後HEAD、lane state `FREE`を復元できるように記録する。

このcheckpointはIssueが既に`Done`でも記録する。physical laneが`FREE`かどうかはactual local checkout stateで決まり、Linear writeの成否によってrelease自体を巻き戻さない。一方、Implementation chatがexecution lifecycle全体をfinal closureとして宣言する条件には、このLinear synchronizationとpost-write read-backを含める。

pause / handoffでreleaseした場合も、current Issueから次のexecutorがlane release済みstateを復元する必要があるため同じcheckpoint semanticsを使う。

### e2e

host / fixture cleanupを完了し、cleanを確認してlatest `origin/main` detached HEADへ戻し、最後にmarkerを削除する。

`nuinui-e2e-prepare prepare`でhostを起動した場合は、先に`nuinui-e2e-prepare cleanup`でexact session metadata、E2E root、handoff、同rootに属するprocessをcleanupする。session metadataが残る間はe2e releaseを行わない。

## CI reproduction

CI reproductionも4つ目のcheckoutを作らない。

local reproductionが必要なら、`FREE`な`main`または`sub` implementation laneを一時的に使用し、そのincidentのexact failing SHA / workflowをauthorityとしてLunaが診断する。両laneがBUSYなら、既存Taskを壊してslotを作らず、先にどちらかのsafe checkpointを完了する。

詳細はshared CI incident時だけ [`CI-INCIDENTS.md`](./CI-INCIDENTS.md) を読む。

## Prohibited patterns

- Issueごとのdisposable worktree
- persistent 4th checkout
- `/Users/yosomi/Code/nuinuiCAD-ci-repro`
- active slice途中のroutine merge-main / rebase-main
- unfinished parallel branch同士の取り込み
- E2E checkoutでのproduct fix
- checkout capacity不足をworktree追加で解消すること

並列性は**main / subの2 implementation lane**で表現する。それ以上の並列ismは作らない。
