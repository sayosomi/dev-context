# nuinuiCAD execution lane / checkout policy

## Purpose

nuinuiCADのlocal execution capacityとimplementation lane ownershipを、常設3 checkoutに固定して管理する。

この3 checkoutは再利用候補ではなく、**存在を許可するexecution laneそのもの**である。Issue数、Ready数、worker数を理由に追加worktree / clone / checkoutを作らない。

## Fixed lanes

| Lane | Checkout | Role |
| --- | --- | --- |
| `main` | `/Users/yosomi/Code/nuinuiCAD` | Luna implementation / blocking fix / implementation-side diagnosis |
| `sub` | `/Users/yosomi/Code/nuinuiCAD-sub` | Luna implementation / blocking fix / implementation-side diagnosis |
| `e2e` | `/Users/yosomi/Code/nuinuiCAD-e2e` | Manual E2E only |

`main` laneという呼称はGit branch `main`とは別概念。`main` / `sub` implementation laneはTask branchをcheckoutしてよい。

Hard limits:

- implementationは同時に最大2 track。`main`と`sub`を各1 trackだけ使う。
- Manual E2Eは同時に最大1 track。`e2e`だけを使う。
- 4つ目のworktree / clone / CI-repro checkoutを作らない。
- `e2e`をimplementationへ転用しない。
- `main` / `sub`が両方BUSYなら、新しいimplementationは開始しない。
- implementation lane数はcapacity上限でありutilization targetではない。parallel admissionを満たすWorkがなければFREE laneをidleのまま残す。

## Human terminal operations

Humanがterminalでlocal checkoutへ行うmechanical / deterministic operationはlane ownershipそのものではなく、Luna implementation routeとは別の操作補助として扱う。

Humanへ任せてよい典型:

- read-only audit: `git status`, `git rev-parse`, `git worktree list`, branch / HEAD / upstream / path確認;
- safety conditionが確定した後の単純な`git fetch`, fast-forward, exact checkout / detached checkout;
- cleanで不要と証明済みのworktree整理;
- E2E markerの作成 / 読み取り / 削除;
- dev host / test hostの起動・停止など、implementationを含まない環境操作。

Human向けterminal instructionを生成する場合はshared `human-terminal-instructions` skillを使い、absolute path、audit/mutation分離、mutation直前の再検証、mismatch時のfail-closed、current directoryや過去shell stateへの暗黙依存禁止を守る。

versioned helperが[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に登録済みでcurrent local clone上で利用可能なら、Human handoffではhelperを優先してよい。helper commandの存在はlane利用許可を意味しない。executor / lane選択はREADME routerとcurrent policyがauthorityである。

### Mandatory preflight handoff rule

implementation start / resume等でmandatory 3-lane preflightが必要なのに、ChatGPT側からactual local checkout stateを直接確認できない場合、audit結果待ちとだけ述べて停止しない。

current helperが利用可能なら、その応答内でcopy/paste-readyなexact invocationを提示する。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui preflight
```

helperが未install、stale / broken、またはunsupportedなら、同じ応答内で完全なread-only 3-lane audit blockを提示する。

preflight evidenceは少なくとも全3 laneのpath、branch/detached HEAD、HEAD SHA、cleanliness、registered worktree state、main/sub durable ownership state、e2e marker stateを一度に確認できること。auditへfetch、checkout、switch、reset、stash、clean、marker mutationを混ぜない。

Humanからfresh audit outputが返ったら、それをcurrent evidenceとして扱う。material state changeのsignalがない限り同じpreflightを機械的に要求し直さない。

Humanへ任せないもの:

- product code implementation / blocking fix;
- code changeや広いiterationを伴うimplementation-side diagnosis;
- merge / rebase conflict resolutionやintegration fix;
- 状態不明checkoutへのreset / stash / force-switch / force-push;
- unrelated Human workを破棄・上書きするcleanup。

## Lane isolation rule

implementation laneはTask / current slice開始時に**Base checkpoint SHA**を固定する。

active slice途中では次を行わない。

- remote `main` advanceのroutine merge / rebase / cherry-pick;
- もう一方のimplementation laneのunfinished change取り込み;
- unrelated PR branchの取り込み;
- 「最新にしておく」ことだけを目的としたbase refresh。

remote `main` advanceは観測してよい。contract / ownershipを無効化する重大な変更が見つかった場合はcurrent workを安全にremote保存してcheckpointで停止し、途中同期して継続しない。

## Integration checkpoint

他line / latest `main`を取り込めるのはcurrent sliceが明確なintegration checkpointへ到達したときだけ。

1. current sliceの実装とfocused verificationを完了する。
2. branchへcommit / pushしcurrent stateをremote保存する。
3. Base checkpoint以降のremote `main` changeを確認する。
4. Lunaが必要なintegration / conflict fixをそのlaneで行う。
5. integration後のrequired verificationを行う。
6. blocking review / merge gateへ進む。

integration checkpoint前に相手laneの進行中branchへ依存しない。dependencyが必要なら依存先mergeまでsafe checkpointで止める。Post-integration Driftの扱いは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)をauthorityとする。

## Durable implementation ownership

### Authority

`main` / `sub` implementation laneのprimary ownership evidenceはcheckout appearanceやLinear statusではなく、そのworktree固有Git directoryに保存するdurable metadataである。

- durable metadata: physical ownership / generation authority;
- Linear checkpoint: restart / handoff identityの外部evidence;
- checkout: durable identityとのconsistency evidence。

chat rotation、past prompt、branch名だけ、Linear `In Progress`だけからownershipを再構成しない。

metadata root:

```text
$(git -C <lane> rev-parse --absolute-git-dir)
```

permanent v1 files:

```text
nuinui-implementation-v1
nuinui-implementation-slot/
  state
nuinui-implementation-lock/
  state
nuinui-implementation-slot.releasing.<claim>/
  state
  checkpoint
```

active slot `state`:

```text
version=1
issue=SAY-123
branch=<exact Task branch>
base=<exact fixed Base checkpoint SHA>
claim=<unique generation token>
```

`claim`はlane取得generationのidentity。同じIssue / branch / Baseを後で再取得してもnew claimを使い、stale resume / releaseを別generationとして拒否する。

mutation lockは`version`, `operation`, `issue`, `branch`, `base`, `checkpoint`, `claim`をexactly once保持する。v1で許可するoperationは`start | resume | release | init`。release tombstoneはactive slot identityとexact checkpointを保持する。

`version=1`はhelper versionとは独立したpermanent ownership metadata schemaである。helper releaseだけを理由にversionを上げない。

v1 stateはstrict schema。required key missing / duplicate、unknown key、unsupported version、invalid Issue / branch / SHA / claimは`BLOCKED / UNKNOWN`。malformed / incomplete metadataを推測して自動削除しない。

### Classification priority

`nuinui preflight`はmain/subを次の優先順位で分類する。

1. mutation lockあり → `BLOCKED`。validならoperation / claimを表示し、invalidならinvalid lockとしてBLOCK。
2. active slotあり → releasing stateがなく、slot valid、working tree clean、checkout branch=slot.branch、slot.baseがcurrent HEAD ancestorなら`BUSY`。不一致は`BLOCKED`。
3. releasing tombstoneあり → single valid stateなら`RELEASE-PENDING`。multiple / malformed / suffix-claim mismatchは`BLOCKED`。
4. ownership stateなし → valid initialization marker + exact idle stateなら`FREE`。それ以外は`BLOCKED`。

`clean main`、`slotなし`、branch名だけをFREE根拠にしない。topic branchなのにslotがない状態もFREEではない。

exact idle state:

- `main`: clean、branch=`main`、HEAD=fresh authoritative `origin/main`。
- `sub`: clean、detached HEAD、HEAD=fresh authoritative `origin/main`。

clean local `main`でもauthoritative `origin/main`よりbehindならFREEではない。preflightはread-onlyでcheckoutを自動normalizationしない。

### Mutation lock and crash safety

start / resume / release / explicit recovery / initializationのlane mutationはper-lane atomic lockで直列化する。lock取得後にsafety-critical factsを再確認する。

lockは時間でexpireしない。ageを理由に削除しない。crashでlockが残った場合はlaneをBLOCKし、known operation / claim / metadata / checkout状態を一意に証明できるときだけ`recover`する。

startはTask branch switchより先にownership slotをdurable化する。外部processが後で別branchへswitchしてもslotは残り、claim-checkout mismatchとしてBLOCKする。

releaseはactive slotをclaim固有`releasing.<claim>`へatomic renameしてからidle transitionを行う。cleanupはtombstoneを先、mutation lockを最後に削除する。古いrelease cleanupがnew claimを削除してはならない。

## Ownership schema initialization

固定implementation laneを新規作成 / 正当に再作成し、まだv1 initialization markerが存在しない場合だけ:

```text
nuinui lane-init <main|sub>
```

を使う。

`lane-init`はownershipの推測・adoption commandではない。slot / lock / releasing stateが存在せず、fresh authoritative `origin/main`に対するexact safe idleを再証明できる場合だけmarkerを書く。

active-looking checkoutやclaimless legacy checkpointからownershipを生成するpublic adoption pathは持たない。ownershipをcurrent durable metadataから一意に証明できないlaneは`BLOCKED / UNKNOWN`のまま扱い、Human reviewなしにcheckout appearanceからreseedしない。

## Lane start

### main / sub implementation

current helper:

```text
nuinui start <main|sub> <SAY-123> <expected-base-sha> <branch>
```

実行前にmandatory 3-lane preflightとLinear occupancy reconciliationを行い、FREE laneを選ぶ。もう一方がBUSYなら[`CHAT-COORDINATOR.md`](./CHAT-COORDINATOR.md)のParallel admission gateを満たすことを確認する。

helperはnew claim generationを作成し、mutation lockとdurable slotをbranch switchより先に取得する。その後fresh remote / exact Base / branch absence / safe idleを再確認し、必要なsafe normalization後にTask branchをcreate/switchする。final checkout / Base / cleanlinessを再確認してlockを削除し、成功outputへclaimを返す。

start成功のclaimは[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)のImplementation checkpointへ同じcontinuationで保存する。

branch作成前にcrashしてもslot / lockがlaneを保持する。precondition failureでexact pre-start stateを一意に証明できる場合だけ自分が作ったmetadataをrollbackしてよい。判定不能なら保持してBLOCKする。

### implementation resume

remote保存済みactive branchをsame durable generationへ戻す場合はnew startにしない。

```text
nuinui resume <main|sub> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>
```

callerはcurrent external checkpointからLane / Issue / fixed Base / exact pushed checkpoint / branch / claimを復元する。Baseをancestryだけから再推定したり、local slotのclaimをcaller expectationの代わりに採用しない。

slot identityがexact一致し、working tree、local branch checkpoint、authoritative remote branch、worktree occupancyがsafe-resume条件を満たす場合だけexisting branchへswitchする。authoritative main確認はactive Baseを更新するためではない。latest mainのmerge / rebase / reset / stash / force-switchを行わない。

already target branch / exact checkpointならidempotent successとしてよい。slotがownershipを保持しているのにcheckoutが別branchへ変わっている場合はpreflightのBLOCKEDを維持し、explicit resumeで安全にrestoreできた後だけBUSYへ戻す。

## Lane release

### main / sub

post-merge helper:

```text
nuinui release <main|sub> <merged-checkpoint-sha> <expected-claim>
```

`lane + checkpoint`だけではgenerationを区別できないためclaimは必須。

releaseはvalid active slotがexpected claimを所有し、claimed local topic branch refがcaller指定checkpointにexact一致することを確認してlockを取得する。fresh `origin/main`がcheckpointをancestorとして含むことを再証明し、slotへcheckpointをpersistしてclaim固有tombstoneへrenameした後、安全なidle transitionを行う。

PR merge後にremote topic refが自動削除されていても、それ自体をBLOCK条件にしない。authoritative evidenceはsaved exact checkpointとcurrent `origin/main` ancestryである。別のsafe mergeで`origin/main`がさらにadvanceしていてもcheckpointがancestorならlatest `origin/main`へreleaseしてよい。

idle state:

- `main`: clean local `main` at latest `origin/main`;
- `sub`: clean detached HEAD at latest `origin/main`。

release開始時にlane自身がclaimed topic branchをcheckoutしていた場合だけ、idle transition後にそのlocal branchをcleanup candidateとする。local refがsaved checkpointのまま、checkpointがcurrent mainに含まれ、他worktreeにcheckoutされていないことを再確認し、expected-old SHA付きexact deletionを行う。

すでにidle stateからrelease continuationを行う場合、release開始時に使っていなかったlocal branchesを探索・一括削除しない。unmerged pause branch、別Issue / slice、`main`、他worktree使用中branchは保持する。

slot rename前のknown failureでcheckout / slot不変を証明できる場合はreleaseが取得した自分のlockだけrollbackしてよい。rename後のfailure / crashはtombstoneとlockを保持してexplicit recoveryへ渡す。

release成功後はcurrent Issueへ`Lane release checkpoint`を記録し、[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)に従ってread-backする。physical FREEのauthorityはactual local stateであり、Linear write failureでsuccessful releaseを巻き戻さない。

### Explicit recovery

```text
nuinui recover <main|sub> <expected-claim>
```

recoverは一般repair commandではない。valid lock / tombstoneとexpected claimをexact照合し、known interrupted `init | start | resume | release` stateだけを継続またはlock-only cleanupする。

multiple tombstones、claim mismatch、dirty、malformed state、wrong Base/history、wrong branch/HEAD等はrecoverしない。reset / stash / force-switch / broad cleanupへのfallbackは禁止。

## E2E marker

`e2e` laneはdetached HEADのため、実行中だけGit-local markerを持つ。

```bash
$(git -C /Users/yosomi/Code/nuinuiCAD-e2e rev-parse --git-dir)/nuinui-slot
```

format:

```text
issue=SAY-123
ref=<exact tested commit or stable ref>
```

markerはworking treeへ置かない。E2E releaseの最後に削除する。

### e2e start

1. `e2e`がFREEであることを確認する。
2. exact tested commit / stable refを決める。
3. detached checkoutしactual HEADを確認する。
4. markerへIssue / refを書く。
5. Manual E2Eをfixed stateでHumanが実行する。

E2E中にremote `main`が進んでもtested stateを途中更新しない。

### e2e release

host / fixture cleanupを完了し、cleanを確認してlatest `origin/main` detached HEADへ戻し、最後にmarkerを削除する。

`nuinui-e2e-prepare prepare`でhostを起動した場合は、先に`nuinui-e2e-prepare cleanup`でsession metadata / temporary root / handoff / owned processesをcleanupする。session metadataが残る間はe2e releaseしない。

## E2E failure

confirmed product implementation failureが出てもe2e laneでは修正しない。

```text
e2e FAIL
-> failure classification / fix contract
-> FREE main/sub implementation lane
-> Luna fix / verification / merge
-> new exact tested commit
-> e2e laneでaffected unit rerun
```

両implementation laneがBUSYなら既存Taskを壊してslotを作らない。

## CI reproduction

CI reproductionも4つ目のcheckoutを作らない。必要ならFREEなmain/sub implementation laneを一時利用し、exact failing SHA / workflowをauthorityとしてLunaが診断する。両laneがBUSYならsafe checkpointまで待つ。詳細は[`CI-INCIDENTS.md`](./CI-INCIDENTS.md)。

## Prohibited patterns

- Issueごとのdisposable worktree;
- persistent 4th checkout;
- `/Users/yosomi/Code/nuinuiCAD-ci-repro`;
- active slice途中のroutine merge-main / rebase-main;
- unfinished parallel branch同士の取り込み;
- `NON-INTERFERING`なPost-integration Driftだけを理由にroutine integrationを繰り返すこと;
- FREE laneを埋めるためだけのparallel start;
- E2E checkoutでのproduct fix;
- checkout capacity不足をworktree追加で解消すること;
- checkout appearanceからclaimを推測生成すること;
- malformed / stale durable metadataのage-based deletion。

並列性はmain/subの2 implementation laneで表現する。それ以上のparallelismを作らず、2 laneを同時に使うこと自体も目的にしない。
