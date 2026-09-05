# nuinuiCAD execution lane / checkout policy

## Purpose

nuinuiCADのlocal execution capacityとlane ownershipを、versioned `LANES.conf`に宣言されたcheckoutから導出して管理する。

宣言されたcheckoutは再利用候補ではなく、**存在を許可するexecution laneそのもの**である。Issue数、Ready数、worker数を理由に動的なlane / worktree / clone / checkoutを作らない。

再利用可能なexecution semantics（role、capacity、FREE/BUSY/RELEASE-PENDING/BLOCKED、durable claim/Base/checkpoint、lock、release tombstone/receipt）は shared [`DECLARED-LANE-EXECUTION.md`](../../shared/DECLARED-LANE-EXECUTION.md) がsole ownerする。この文書はnuinuiCAD固有のmanifest、Luna implementation policy、Human-only Manual E2E policyをownerする。

## Declared lanes

The checked-in manifest currently declares these example lanes; the names and paths are data, not the capacity model.

| Lane | Checkout | Role |
| --- | --- | --- |
| `main` | `/Users/yosomi/Code/nuinuiCAD` | Luna implementation / blocking fix / implementation-side diagnosis |
| `sub` | `/Users/yosomi/Code/nuinuiCAD-sub` | Luna implementation / blocking fix / implementation-side diagnosis |
| `e2e` | `/Users/yosomi/Code/nuinuiCAD-e2e` | Manual E2E only |
| `e2e2` | `/Users/yosomi/Code/nuinuiCAD-e2e2` | Manual E2E only |

Lane names are identifiers from `LANES.conf`; they are not special aliases. An implementation lane may checkout a task branch when its declared idle policy and lifecycle proof permit it.

Capacity and routing rules:

- implementation capacity is the number of declared `role=implementation` lanes.
- Human-test capacity is the number of declared `role=human-test` lanes.
- a lane is never reassigned across roles, and declared paths are not inferred from lane names.
- the one authorized forensic worktree exception below is inventory-only and adds no execution capacity.
- capacity is an upper bound, not a utilization target; leave a safe lane FREE when no admitted Work needs it.

## Human-authorized forensic worktree exception

通常policyは`LANES.conf`に宣言されたlaneだけを許可する。現在の4 laneは上記manifestの例であり、別の有効な宣言数・名前・pathも同じgeneric policyで扱う。

forensic checkoutの作成・利用には、事前の明示的なHuman authorizationが必要である。`--forensic-worktree <absolute-path>` flagは、既にHumanがauthorizedしたcheckoutをcurrent invocationのinventory exceptionとして認識するだけであり、作成・利用をauthorizeしない。

current `preflight` / `begin` / `start` invocationで認識できるsupplied registered forensic worktreeは正確に1つだけである。persistent allowlist、marker、config、receipt、environment settingは存在せず、directory nameやbranch nameのnaming conventionもexceptionを付与しない。forensic worktreeは宣言laneにならず、execution capacity・implementation capacity・Human-test capacityを消費も追加もしない。また、durable implementation metadataをownerできない。

exceptionを使う場合も、supplied pathはcanonical absolute directoryであり、同じnuinuiCAD repositoryにregisteredされた唯一のextra worktreeでなければならない。standalone clone、別repositoryのworktree、alias path、declared lane path、追加のunknown worktreeはBLOCKする。forensic checkoutのdirty state、branch、HEADはinventory validationの対象外だが、宣言laneに対する通常のlane safety checkはすべて引き続き適用される。

## Human terminal operations

Humanがterminalでlocal checkoutへ行うmechanical / deterministic operationはlane ownershipそのものではなく、Luna implementation routeとは別の操作補助として扱う。

Human terminal disappearance is an external-state recovery case. If terminal output disappears or is lost after a Human mutation command, do not blindly rerun that mutation. Run the official read-only command `nuinui last-result` first. An exact recovered terminal SUCCESS can continue through normal next-stage verification; a recovered BLOCKED or ERROR continues from that exact outcome. `NONE`, `INVALID`, or `INCOMPLETE` routes to the existing lane-specific diagnosis/preflight path. Do not reset, stash, force-switch, or otherwise repair state while recovering the lost output.

Humanへ任せてよい典型:

- read-only audit: `git status`, `git rev-parse`, `git worktree list`, branch / HEAD / upstream / path確認;
- safety conditionが確定した後の単純な`git fetch`, fast-forward, exact checkout / detached checkout;
- cleanで不要と証明済みのworktree整理;
- E2E markerの作成 / 読み取り / 削除;
- dev host / test hostの起動・停止など、implementationを含まない環境操作。

Human向けterminal instructionを生成する場合はshared `human-terminal-instructions` skillを使い、absolute path、audit/mutation分離、mutation直前の再検証、mismatch時のfail-closed、current directoryや過去shell stateへの暗黙依存禁止を守る。

versioned helperが[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に登録済みでcurrent local clone上で利用可能なら、Human handoffではhelperを優先してよい。helper commandの存在はlane利用許可を意味しない。executor / lane選択はREADME routerとcurrent policyがauthorityである。

### Preflight diagnostic / routing rule

`nuinui preflight`はread-onlyのinventory / routing commandであり、known-Issueの通常startやsame-generation continuationに対する別のHuman handoffではない。通常のknown-Issue implementation startは、ChatGPTがWork、target implementation lane、caller-supplied Base、branchを確定した後、Humanが同じterminalでnamed-argument handoffを実行する。Manual E2E startupには、下記の`e2e-start-command` façadeを使う。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui begin-command --lane <implementation-lane> --issue <SAY-123> --base <expected-base-sha> --branch <branch> [--forensic-worktree <absolute-path>]
```

このhelperはnormal runtime manifestをread-onlyで解決し、fresh full preflight、canonical declaration-order inventory、target `FREE`、existing read-only verifyを行って、copy/paste-readyな次の既存positional commandを出力する。

```text
BEGIN COMMAND READY
<absolute-helper> begin <lane> <issue> <base> <branch> <canonical-inventory> [--forensic-worktree <absolute-path>]
```

Humanはその出力行をChatGPTへ戻さず、同じterminalでverbatimに実行する。既存`begin`が通常のmutation-time revalidationを行い、成功後に`IMPLEMENTATION STARTED`、normal checkpoint / continuationへ進む。generated lineはargumentをreorderせず、positional commandをreconstructせず、inventoryを再serializeせず、forensic optionを移動せず、older syntaxへ変換しない。

### Canonical Manual E2E startup handoff

通常のManual E2E startupは、ChatGPTがsemanticなIssue、tested ref、executor、fixture、locale、portを確定し、Humanが次の短いnamed generator commandを同じterminalで1回実行する。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui e2e-start-command \
  --issue SAY-123 \
  --tested-ref <full-tested-sha> \
  --executor <human|luna> \
  --fixture <absolute-fixture-path> \
  [--lane <human-test-lane>] \
  [--locale <default|ja>] \
  [--port <port>]
```

このgeneratorはread-onlyで、runtime manifest、全laneの既存preflight、選択Human-test laneの`lane_execution_nuinui_human_test_classify`をfreshに読む。selected laneが`FREE`なら生成を許可し、exact same Issue/refの`BUSY`だけは既存duplicate/no-op ownerへ委譲する候補として許可する。別Issue/refの`BUSY`、malformed marker/session、dirty/named/wrong-ref/ambiguous/blocked stateはfail closedする。複数のHuman-test laneで`--lane`を省略した場合もlaneを推測しない。

成功時はterminalが次のbounded continuationのformatting authorityになる。

```text
E2E START COMMAND READY
'<absolute-nuinui>' 'e2e-start' '<lane>' '<Issue>' '<tested-ref>' && '<absolute-prepare>' 'prepare' '<lane>' '<Issue>' '<tested-ref>' '<fixture>' [<port>] [--locale ja]
```

Humanはこの1行をChatGPTへ戻さず、同じterminalでverbatimに実行する。`&&`により`e2e-start`失敗時はprepareを実行しない。生成された値はshell-quoted済みであり、ChatGPTがlane/ref/prepareの順序を再構成しない。generatorはcheckout、marker、session、host、GUI、test oracleを変更せず、既存`nuinui e2e-start`と`nuinui-e2e-prepare prepare`がexecution-time revalidation、race protection、duplicate/no-op、host readiness、cleanup safetyを引き続きownerする。

`--executor`はChatGPTが決めるsemantic metadataであり、generatorはHumanとLunaを分類しない。`human`ではprepare後のsetupをHuman E2E unitへ渡し、`luna`では既存prepare outputのshort `handoff=` path / session identityをcurrent Luna playbookへ渡す。大きなLuna promptはterminal outputから生成しない。現行の`e2e-start-local-main`はinactive interim workflowの互換commandとして残るが、通常のこのgeneratorは標準`e2e-start`だけを出力する。

generatorが`BLOCKED`、ambiguous、stale、または利用不能な場合だけ、下記のread-only preflightと既存diagnosis / recovery pathへ戻る。preflight outputをpasteしてChatGPTに通常commandを再構成させる流れは標準startupではない。

これはChatGPT/Humanのunconditionalなround-tripではない。以下の別diagnostic preflight / recovery条件はそのまま維持する。

ChatGPTがactual local inventoryを知らず、begin / resume / release / handoff-checkがBLOCKEDを返した、またはexplicit diagnosis / recoveryが必要な場合は、current helperが利用可能ならその応答内でcopy/paste-readyなexact preflight invocationを提示する。ただし、exact pushed-checkpoint Luna handoffのinitial failureのfirst lineがexactly`BLOCKED: handoff claimed branch mismatch`の場合は、EXECUTION-HANDOFF.mdのone-attempt exact resume recoveryを先に実行する。

```bash
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui preflight
```

helperが未install、stale / broken、またはunsupportedなら、同じ応答内で全宣言laneを含むread-only inventory audit blockを提示する。

preflight evidenceは少なくとも全宣言laneのrole、path、branch/detached HEAD、HEAD SHA、cleanliness、registered worktree state、durable ownership state、Human-test marker stateを一度に確認できること。auditへfetch、checkout、switch、reset、stash、clean、marker mutationを混ぜない。

Humanからfresh audit outputが返ったら、それをcurrent evidenceとして扱う。material state changeのsignalがない限り同じpreflightを機械的に要求し直さない。

Separate preflightを使う条件は次に限定する。

- Coordinatorがcurrent lane occupancyを知らず、Workのselect / route前にinventoryが必要;
- current execution identityを一意に再構成できない;
- `begin`、`resume`、`release`、またはIssue #84 exception外の`nuinui-handoff-check`が`BLOCKED`を返した;
- crash / interrupted lifecycle operationが疑われる;
- unexpected checkout、branch、dirty stateが報告された。ただし、exact pushed-checkpoint Luna handoffのinitial failureがIssue #84のexact `claimed branch mismatch` classifierである場合だけは、下記one-attempt recoveryを先に適用する;
- explicit recovery / diagnosisが必要。

For an exact pushed-checkpoint Luna handoff whose first handoff failure is exactly
`BLOCKED: handoff claimed branch mismatch`, EXECUTION-HANDOFF.md's one-attempt exact resume recovery runs first.

Human preflight is not required if resume returns the canonical `IMPLEMENTATION RESUMED` envelope and the exact original handoff-check rerun returns `HANDOFF VERIFIED`. Route to the normal BLOCKED / preflight path if the initial failure has any other classification, the one recovery attempt fails or returns ambiguous evidence, or the second handoff-check fails. This exception does not apply to `absent` topic mode.

same Issue、same lane、same durable claim generation、Luna commit / push、blocking reviewからblocking fix、implementationからintegration、新しいLuna session、ChatGPT chat rotation、unrelated remote `main` advanceだけではpreflight invalidationにならない。remote `main` freshnessはChatGPT側のGitHub checkとLuna handoff-check inputとして別に扱う。

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
4. 原則Lunaが必要なintegration / conflict fixをそのlaneで行う。semantic driftが`NON-INTERFERING`でcurrent-base freshnessだけがmerge gateとなるexact narrow caseは`nuinui integrate-clean`を使ってよい。
5. integration後のrequired verificationを行う。
6. blocking review / merge gateへ進む。

integration checkpoint前に相手laneの進行中branchへ依存しない。dependencyが必要なら依存先mergeまでsafe checkpointで止める。Post-integration Driftの扱いは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)をauthorityとする。

### Conflict-free merge-only refresh exception

Integration Watermark到達後のalready-reviewed topicについて、ChatGPTがpost-integration semantic driftを`NON-INTERFERING`とfresh判定し、repository merge gateがcurrent-base freshnessだけを要求する場合は、`nuinui integrate-clean`をsame active durable generationでHumanが実行してよい。

このhelperはnew lane claim / Base refresh / source implementation routeではない。current durable slotをconsumeし、exact Issue / claim / branch / Base / local topic / remote topic / current main / clean stateをmutation boundaryで再検証する。conflict resolutionやintegration fixは行わず、conflictまたはpre-commit failureではoriginal topic checkpointへのexact rollbackを証明する。push failure後はverified local merge commitを保持してfresh diagnosisへ戻す。

## Durable implementation ownership

### Authority

宣言されたimplementation laneのprimary ownership evidenceはcheckout appearanceやLinear statusではなく、そのlane固有Git directoryに保存するdurable metadataである。

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
base=<exact durable Base checkpoint SHA>
claim=<unique generation token>
```

`claim`はlane取得generationのidentity。同じIssue / branch / Baseを後で再取得してもnew claimを使い、stale resume / releaseを別generationとして拒否する。

mutation lockは`version`, `operation`, `issue`, `branch`, `base`, `checkpoint`, `claim`をexactly once保持する。v1で許可するoperationは`start | resume | release | init`。release tombstoneはactive slot identityとexact checkpointを保持する。

`version=1`はhelper versionとは独立したpermanent ownership metadata schemaである。helper releaseだけを理由にversionを上げない。

v1 stateはstrict schema。required key missing / duplicate、unknown key、unsupported version、invalid Issue / branch / SHA / claimは`BLOCKED / UNKNOWN`。malformed / incomplete metadataを推測して自動削除しない。

### Classification priority

`nuinui preflight`は各宣言laneを次の優先順位で分類する。

1. mutation lockあり → `BLOCKED`。validならoperation / claimを表示し、invalidならinvalid lockとしてBLOCK。
2. active slotあり → releasing stateがなく、slot valid、checkout branch=slot.branch、slot.baseがcurrent HEAD ancestorなら`BUSY`。working treeのdirtyだけでは`BUSY`を`BLOCKED`にしない。branch / Base / metadata identityの不一致は`BLOCKED`。
3. releasing tombstoneあり → single valid stateなら`RELEASE-PENDING`。multiple / malformed / suffix-claim mismatchは`BLOCKED`。
4. ownership stateなし → valid initialization marker + exact idle stateなら`FREE`。それ以外は`BLOCKED`。

`clean main`、`slotなし`、branch名だけをFREE根拠にしない。topic branchなのにslotがない状態もFREEではない。

active implementation laneがvalidなdurable ownershipを保持している場合、working treeのdirtyは診断上`clean=no`として表示するが、ownership identityが有効なら`state=BUSY`である。`FREE`のexact idle stateと`start` / `resume` / `release`のmutation preconditionでは、既存どおりworking tree cleanが必須である。

exact idle state is derived from each lane's declared `idle` policy: the checkout must be clean, at a fresh authoritative default-branch commit, and must satisfy the declared branch or detached form. A clean checkout that is behind the authoritative default is not FREE. Preflight is read-only and does not normalize checkout state.

### Mutation lock and crash safety

start / resume / release / explicit recovery / initializationのlane mutationはper-lane atomic lockで直列化する。lock取得後にsafety-critical factsを再確認する。

lockは時間でexpireしない。ageを理由に削除しない。crashでlockが残った場合はlaneをBLOCKし、known operation / claim / metadata / checkout状態を一意に証明できるときだけ`recover`する。

startはTask branch switchより先にownership slotをdurable化する。外部processが後で別branchへswitchしてもslotは残り、claim-checkout mismatchとしてBLOCKする。

releaseはactive slotをclaim固有`releasing.<claim>`へatomic renameしてからidle transitionを行う。cleanupはtombstoneを先、mutation lockを最後に削除する。古いrelease cleanupがnew claimを削除してはならない。

## Ownership schema initialization

宣言されたimplementation laneを新規作成 / 正当に再作成し、まだv1 initialization markerが存在しない場合だけ:

```text
nuinui lane-init <implementation-lane>
```

を使う。

`lane-init`はownershipの推測・adoption commandではない。slot / lock / releasing stateが存在せず、fresh authoritative `origin/main`に対するexact safe idleを再証明できる場合だけmarkerを書く。

active-looking checkoutやclaimless legacy checkpointからownershipを生成するpublic adoption pathは持たない。ownershipをcurrent durable metadataから一意に証明できないlaneは`BLOCKED / UNKNOWN`のまま扱い、Human reviewなしにcheckout appearanceからreseedしない。

## Lane start

### Declared implementation lane

Canonical normal Human handoff:

```text
nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory>
```

`begin` performs the full read-only declared-lane safety audit inside the same Human command, including registered worktree inventory, role validation, target FREE, and exact complete implementation occupancy. It then revalidates target start conditions immediately before delegating to the existing start mutation semantics. An inventory mismatch never starts the target lane. A successful result includes the complete verified `IMPLEMENTATION STARTED` envelope.

成功時のstable envelope:

```text
IMPLEMENTATION STARTED
lane=<implementation-lane>
issue=<SAY-N>
branch=<exact branch>
base=<exact base>
checkpoint=<actual HEAD>
claim=<durable generation claim>
clean=yes
state=BUSY
implementation_inventory=<declaration-order lane=FREE|SAY-N entries>
preflight=PASS
```

Lower-level lifecycle primitive retained for self-test / explicit routing:

```text
nuinui start <implementation-lane> <SAY-123> <expected-base-sha> <branch>
```

`start` is not the normal separate first half of a known-Issue Human start. It keeps the existing low-level mutation and recovery semantics; its output identifies the local transition and does not replace ChatGPT's external occupancy / parallel-admission decision. Use `begin` for the normal Human handoff.

helperはnew claim generationを作成し、mutation lockとdurable slotをbranch switchより先に取得する。その後fresh remote / exact Base / branch absence / safe idleを再確認し、必要なsafe normalization後にTask branchをcreate/switchする。final checkout / Base / cleanlinessを再確認してlockを削除し、成功outputへclaimを返す。

`begin` / `start` successはlane、Issue、branch、Base、actual checkpoint、claim、cleanliness、BUSY stateを返す。`begin`はさらにcaller expectationと照合済みのdeclaration-order implementation inventoryと`preflight=PASS`を返す。canonical normal startupでは`begin`を使い、成功した`begin`のclaimを既存のIssue checkpointへ同じcontinuationで保存する。

branch作成前にcrashしてもslot / lockがlaneを保持する。precondition failureでexact pre-start stateを一意に証明できる場合だけ自分が作ったmetadataをrollbackしてよい。判定不能なら保持してBLOCKする。

### implementation resume

remote保存済みactive branchをsame durable generationへ戻す場合はnew startにしない。

```text
nuinui resume <implementation-lane> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>
```

callerはcurrent external checkpointからLane / Issue / durable Base / exact checkpoint / branch / claimを復元する。通常のpushed checkpointではremote topicも同じcheckpointであることを要求する。`begin`直後の初回push前に限り、remote topicの成功したabsence、local topic = Base = expected checkpoint、cleanな既存topic、safeなidle identityをすべて証明できた場合だけ、そのlocal topicへ復帰できる。Baseをancestryだけから再推定したり、local slotのclaimをcaller expectationの代わりに採用しない。

slot identityがexact一致し、working tree、local branch checkpoint、authoritative remote branch、worktree occupancyがsafe-resume条件を満たす場合だけexisting branchへswitchする。authoritative main確認はactive Baseを更新するためではない。latest mainのmerge / rebase / reset / stash / force-switchを行わない。

already target branch / exact checkpointならidempotent successとしてよい。slotがownershipを保持しているのにcheckoutが別branchへ変わっている場合はpreflightのBLOCKEDを維持し、explicit resumeで安全にrestoreできた後だけBUSYへ戻す。

same active durable generationのresume / continuationでは、fresh local preflightを別途要求しない。last verified lifecycle envelopeまたはcurrent Linear checkpointのclaim / checkpointはcaller expectationとして渡してよいが、authorityではない。Lunaの最初の`nuinui-handoff-check`がactual durable slot、checkout、remote topic、remote mainを再検証し、matchなら継続、mismatchなら`BLOCKED / STALE_EXECUTION_CONTEXT`としてdiagnosis / recoveryへ戻す。

resume success envelope:

```text
IMPLEMENTATION RESUMED
lane=<implementation-lane>
issue=<SAY-N>
branch=<exact branch>
base=<exact base>
checkpoint=<actual HEAD>
claim=<durable generation claim>
clean=yes
state=BUSY
```

## Lane release

### Declared implementation lane

post-merge helper:

```text
nuinui release <implementation-lane> <merged-checkpoint-sha> <expected-claim>
```

`lane + checkpoint`だけではgenerationを区別できないためclaimは必須。

releaseはvalid active slotがexpected claimを所有し、caller checkpoint / claimがvalidで、durable Issue / branch / Base / claim identityがunchangedであることを確認してからlocal branch relationを分類する。claimed local topic branch refがcaller指定checkpointにexact一致する場合は通常のrelease pathであり、missing refはcheckpoint mismatchではなくbranch identity failureとして診断する。fresh `origin/main`がcheckpointをancestorとして含むことを再証明し、slotへcheckpointをpersistしてclaim固有tombstoneへrenameした後、安全なidle transitionを行う。

PR merge後にremote topic refが自動削除されていても、それ自体をBLOCK条件にしない。authoritative evidenceはsaved exact checkpointとcurrent `origin/main` ancestryである。別のsafe mergeで`origin/main`がさらにadvanceしていてもcheckpointがancestorならlatest `origin/main`へreleaseしてよい。

post-mergeに実装laneのcheckoutだけがdriftした場合、release自身が次の狭い条件をすべて満たすときだけ復旧して続行できる。active slotがdurable Issue / branch / Base / claimとexact一致し、lock / tombstoneがなく、checkpoint / caller claimもexact一致することを先に確認する。claimed local refがcheckpointにある場合は、manifest-declared `idle=branch` laneのcleanなdefault-branch checkout、または`idle=detached` laneのcleanなdetached checkoutを、そのlaneの宣言されたidle policyどおり復旧でき、cleanなexact-checkpoint differently named branchからもexisting local claimed topicへexact `git switch`できる。current HEAD / checkpointがfresh authoritative default branchに含まれ、topicが別worktreeでcheckoutされていないことを再証明する。remote topicはabsentでもよいが、存在する場合は同じcheckpointのexact refでなければならない。

この復旧はreleaseの既存mutation lock取得後、slotをreleasing tombstoneへrenameする前に行う。claimed local refがmissingでも、current checkoutがcleanなnamed non-default branch、current branch refがcheckpoint、HEADがcheckpoint、fresh authoritative default branch / Base ancestry、remote topic、別worktree不存在、lock / tombstone不存在をすべてexactに証明できる場合だけ、switch直前にcritical factsを再取得・再検証して`git branch -m <durable-claimed-branch>`を一度だけ行う。existing claimed refのpathでは`git switch <durable-claimed-branch>`だけを使い、missing-ref pathではそのexact renameだけを使う。Issue textやstring similarityからbranchを推測せず、durable slotのbranchを唯一の意図されたidentityとする。branch生成、reset、stash、merge、rebase、cherry-pick、force操作、durable metadata rewriteは行わない。wrong checkpoint / claim / ref SHA、dirty、別named branch、別worktree、remote / ancestry / metadata ambiguity、lock / tombstone conflictは`BLOCKED: release claimed branch mismatch`または既存の厳密なmismatchとしてactive slotを保持する。repair後に完了を証明できない場合はrelease lockを残してrecoverへ渡し、`resume` / `recover` / generic claim-checkout mismatchの意味はこのrelease-only recoveryで変更しない。

idle state:

- declared `idle=branch`: clean local default-branch form at latest authoritative default;
- declared `idle=detached`: clean detached HEAD at latest authoritative default.

release開始時にlane自身がclaimed topic branchをcheckoutしていた場合だけ、idle transition後にそのlocal branchをcleanup candidateとする。local refがsaved checkpointのまま、checkpointがcurrent mainに含まれ、他worktreeにcheckoutされていないことを再確認し、expected-old SHA付きexact deletionを行う。

すでにidle stateからrelease continuationを行う場合、release開始時に使っていなかったlocal branchesを探索・一括削除しない。unmerged pause branch、別Issue / slice、`main`、他worktree使用中branchは保持する。

slot rename前のknown failureでcheckout / slot不変を証明できる場合はreleaseが取得した自分のlockだけrollbackしてよい。rename後のfailure / crashはtombstoneとlockを保持してexplicit recoveryへ渡す。

release成功後はcurrent Issueへ`Lane release checkpoint`を記録し、[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)に従ってread-backする。physical FREEのauthorityはactual local stateであり、Linear write failureでsuccessful releaseを巻き戻さない。

successful release outputはIssue、saved checkpoint、released claim / branch、idle branch、idle HEAD、authoritative origin main、`clean=yes`、`state=FREE`をself-containedに返す。fresh successful release envelopeを得た後、release checkpointのためだけに別preflightを行わない。

```text
IMPLEMENTATION RELEASED
lane=<implementation-lane>
issue=<released Issue>
saved_checkpoint=<exact checkpoint>
released_claim=<claim>
released_branch=<topic branch>
idle_branch=<default-branch|DETACHED>
idle_head=<actual final HEAD>
origin_main=<authoritative main used for release>
clean=yes
state=FREE
```

### Explicit recovery

```text
nuinui recover <implementation-lane> <expected-claim>
```

recoverは一般repair commandではない。valid lock / tombstoneとexpected claimをexact照合し、known interrupted `init | start | resume | release` stateだけを継続またはlock-only cleanupする。

multiple tombstones、claim mismatch、dirty、malformed state、wrong Base/history、wrong branch/HEAD等はrecoverしない。reset / stash / force-switch / broad cleanupへのfallbackは禁止。

## E2E marker

Human-test lanes are normally detached and hold a Git-local marker only while an exact test generation is active.

```bash
$(git -C <human-test-lane-path> rev-parse --git-dir)/nuinui-slot
```

format:

```text
issue=SAY-123
ref=<40-character tested commit SHA>
```

markerはworking treeへ置かない。E2E releaseの最後に削除する。

active markerがある間は、そのIssue/ref generationがauthorityであり、古いcompleted receiptから別callerが新しいmarkerを採用・releaseしてはならない。exact duplicate startはstrict marker、caller identity、clean checkout、HEAD、optional sessionをread-onlyで証明した場合だけno-op成功する。receiptはmarkerとsessionがないidle stateで、caller identityとcurrent authoritative default branch HEADが完全一致するときだけcompleted-release authorityになる。

### e2e start

1. selected Human-test laneがmanifest上FREEであることを確認する。
2. exact tested commit / stable refを決める。
3. detached checkoutしactual HEADを確認する。
4. markerへIssue / refを書く。
5. Manual E2Eを宣言されたtested stateでHumanが実行する。

E2E中にremote `main`が進んでもtested stateを途中更新しない。

### e2e release

Canonicalなsuccessful Human E2E closure handoffは、Sol High / ChatGPTが成功後のclosureを承認したうえで、Humanが同じterminalから次の短いnamed handoffを1回実行する。

```bash
nuinui-e2e-prepare closure-command --issue <Issue> [--lane <human-test-lane>]
```

`closure-command`はfreshなlocal authorityからtested ref、E2E root、current Human-test lane、active / cleanup-complete / released generationをread-onlyで解決し、terminal outputをcanonicalな実行記録として`cleanup -> e2e-release -> closure-check`の順に既存public commandへ渡す。Humanはlane、ref、rootを手で置換・再構成しない。`--lane`はcaller constraintであり、複数laneでは省略可能なのはrequested Issueのmatching generationが1つだけfreshに証明できる場合だけである。

Exact duplicate cleanup / releaseは既存authorityのsuccess envelopeのまま直ちに次stageへ進む。release後はcleanupのexact duplicateがcheckout/marker lifecycle上有効でないため、strict cleanup receiptで過去のcleanupを証明できる場合に限り、既存release duplicateからclosure-checkへ進む。このprojectionは新しいclosure stateやreceipt解釈を作らない。

`cleanup <Issue> <tested-ref> <e2e-root>`はIssue/refに加えてexact rootをsession-generation identityとして照合し、prepared sessionのowned process、temporary root、handoff、session metadataを削除するが、tested same-Issue markerは意図的に保持する。完了時はGit dirへstrictな`version=1 / issue / ref / root`の`nuinui-e2e-cleanup-receipt`を先に保存する。したがってcleanup成功後にmarkerが残り、session metadataがない状態がnormalなrelease-ready stateである。markerの削除は`e2e-release`だけがownerする。

`e2e-release <Issue> <tested-ref>`はcaller identityをmarkerと照合し、session metadataの不在、valid repository/origin、clean detached checkout、tested HEADをmutation前に要求する。fetch/prune後に同じproofを再検証し、current authoritative `origin/main`を取得する。Git dirへstrictな`version=1 / issue / ref`の`nuinui-e2e-release-receipt`をatomically write/replaceしてから安全に`origin/main`へdetachし、最後にmarkerを削除する。receipt writeに失敗した場合はmarkerを保持してBLOCKEDで停止する。

markerがない場合、同じcaller Issue/ref、strict receipt、session metadata不在、clean detached checkout、current authoritative `origin/main` HEADをread-onlyで完全一致証明できる場合だけ、`E2E ALREADY RELEASED` / `mutation=no-op`として受理する。active markerはreceiptより常に優先され、staleなreceiptから別Issueのreleaseを推測しない。

`nuinui-e2e-prepare closure-check [<human-test-lane>] <Issue>`はrelease後にだけ実行するfinal read-only closure proofである。通常のrelease前validationとしてcleanupとe2e-releaseの間に実行しない。同一Issueのmarkerが残っている場合、closure-checkは引き続き`BLOCKED`でなければならない。

各stageの実行時再検証、cleanup receipt、release receipt、marker、session/root/process cleanup、release mutation、final closure proofはそれぞれ従来のownerが保持する。どのstageでも`BLOCKED` / `ERROR`なら後続stageを実行せず、HumanはChatGPTへbounded diagnosisを返す。Manual E2EのPASS / FAIL judgmentとHumanのstop / pause semanticsは変更しない。

`nuinui-e2e-prepare prepare`でhostを起動した場合は、先に`nuinui-e2e-prepare cleanup [<human-test-lane>] <Issue> <tested-ref> <e2e-root>`でsession metadata / temporary root / handoff / owned processesをcleanupする。session metadataが残る間はe2e releaseしない。

## E2E failure

confirmed product implementation failureが出てもHuman-test laneでは修正しない。

```text
e2e FAIL
-> failure classification / fix contract
-> FREE declared implementation lane
-> Luna fix / verification / merge
-> new exact tested commit
-> selected Human-test laneでaffected unit rerun
```

すべてのdeclared implementation laneがBUSYなら既存Taskを壊してslotを作らない。

## CI reproduction

CI reproductionも追加のexecution laneを作らない。必要ならFREEなdeclared implementation laneを一時利用し、exact failing SHA / workflowをauthorityとしてLunaが診断する。全implementation laneがBUSYならsafe checkpointまで待つ。詳細は[`CI-INCIDENTS.md`](./CI-INCIDENTS.md)。

## Prohibited patterns

- Issueごとのdisposable worktree;
- persistent unregistered extra checkout;
- `/Users/yosomi/Code/nuinuiCAD-ci-repro`;
- active slice途中のroutine merge-main / rebase-main;
- unfinished parallel branch同士の取り込み;
- `NON-INTERFERING`なPost-integration Driftだけを理由にroutine integrationを繰り返すこと;
- FREE laneを埋めるためだけのparallel start;
- E2E checkoutでのproduct fix;
- checkout capacity不足をworktree追加で解消すること;
- checkout appearanceからclaimを推測生成すること;
- malformed / stale durable metadataのage-based deletion。

並列性はmanifestに宣言されたimplementation lane数で表現する。それ以上のdynamic laneを作らず、全laneを同時に使うこと自体も目的にしない。
