# nuinuiCAD Implementation chat

## Purpose

Implementation chatは`Contract: Ready`なIssueのrepository implementation / blocking fix / verification / integration / blocking review / mergeを進めるchat。

実行capacityはchat数ではなく [`CHECKOUTS.md`](./CHECKOUTS.md) のfixed implementation laneで決まる。

- `main`: at most 1 implementation track
- `sub`: at most 1 implementation track
- 合計最大2 implementation track

Implementation chatを新しく作っただけではlaneをclaimしない。実際のstartup gate / lane assignment / Base checkpoint記録が完了した時点でexecutionが開始する。

通常のrepository implementation / blocking fixは [`CODING-AGENT.md`](./CODING-AGENT.md) に従いLuna xhighが担当する。

## Documentation / policy direct execution exception

Repository-owned documentation / specification / policy workは、source-code implementationとは別のexecution classとする。

次の条件をすべて満たすTaskは、implementation lane / Lunaを使わずChatGPTが直接実行してよい。

- 変更対象が`docs/**`、`AGENTS.md`、repository/project `README.md`、`ARCHITECTURE.md`、CHANGELOG等のrepository-owned documentation / specification / policy fileに限定される;
- source code、test code、fixtures、build設定、CI、runtime behavior、generated artifactを変更しない;
- plan、target file、intended changeをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- 文面修正だけでなく、新しいproduct / UX / architecture / engineering / operational ruleの決定を含んでもよい。ただし、その判断内容はユーザーが許可したplanのscope内であること;
- latest remote repositoryとcurrent relevant management/spec stateを確認してから編集する;
- verificationはdocumentation consistency / policy consistencyを確認するread-only / focused checkで足り、source-code implementation-side test-debug loopを必要としない;
- scopeがdocumentation / specification / policy changeからsource-code implementationへmaterially拡大しない。

この例外では固定`main` / `sub` implementation lane、Base checkpoint、Luna sessionをclaimしない。ChatGPTがremote repository上で編集、必要なfocused verification、blocking review、commit / push / merge、Linear synchronizationまで直接担当してよい。

途中でsource code / test / generated outputの変更が必要になった場合、または許可されたplanのscopeを越えるproduct / architecture decisionが必要になった場合は、いったん停止してplanを更新し、必要なら通常のLuna / implementation-lane lifecycleへ戻す。

Manual E2Eが必要な場合は本例外では扱わず、[`MANUAL-E2E.md`](./MANUAL-E2E.md) / [`CHAT-E2E.md`](./CHAT-E2E.md) をauthorityとする。

## Implementation start / resume completion rule

Humanがimplementation Issueについて`開始` / `再開` / `続ける` / `進める`等を指示した場合、ChatGPTはremote / Linear / policyの再確認やblocker説明だけで停止しない。

その応答は、次のどちらかに到達して初めてstart / resume handoffとして完了する。

1. ChatGPT側で次のexecutionを実際に開始できる状態まで進み、必要なlane assignment / checkpoint / Luna handoffを開始する。
2. Human actionが必要なら、Humanが**その応答から直ちに実行できる最初の完全なhandoff**を同じ応答内に提示する。

Human action待ちになる場合の原則:

- `Xの出力待ち`、`preflight結果待ち`、`上のaudit結果待ち`等とだけ述べて停止しない。
- そのXを取得するためのcommand / instructionが必要なら、同じ応答内に完全な形で提示する。
- 実際には提示していないcommand / blockを`上のcommand`、`先ほどのaudit`等として参照しない。
- concrete blockerを報告するときは、blockerの説明と**解除するための次のaction**をセットで出す。
- local lane evidence不足が唯一のblockerなら、[`CHECKOUTS.md`](./CHECKOUTS.md) のmandatory preflight handoff ruleに従い、その場で最初の実行可能なread-only handoffまで出す。
- versioned local helperがcurrentで利用可能なら、[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に従い、長大なinline shellではなく必要値を埋めたhelper invocationをcomplete Human handoffとして使ってよい。helperが未install / stale / broken / unsupportedなら`CHECKOUTS.md`のinline fallbackを同じ応答で提示する。
- Humanが必要なfresh evidenceをすでに現在の会話で提示している場合は、同じ取得手順を機械的に要求し直さない。

### Local-success-before-In-Progress rule

通常のsource-code implementationを新しくstart / checkpoint-pauseからresumeするとき、Linearの`In Progress`は「開始予定」ではなく**actual implementation laneでexecution開始済み**を表す。

Human terminal handoffで`nuinui start` / `nuinui resume`等を実行する場合:

1. commandをHumanへ渡す前に、fresh 3-lane evidenceとLinearのcurrent implementation `In Progress`集合をIssue identity単位で照合する。stale / orphaned `In Progress`があれば新しいstart / resumeより先に解消する。既存authorityだけで安全に解消できない場合はstart / resumeを行わない。
2. target Issueはcommand提示、`CHECKING`、read-only verification、start可能判定だけでは`In Progress`へ進めない。新規startなら`Todo`、pause済みresumeならそのcurrent non-running statusを維持する。
3. Humanからhelperのsuccessful local transition result（新規startでは`STARTED`）が返り、lane / Issue / branch / Baseまたはcheckpointがintended handoffと一致することを確認した後で初めてtarget Issueを`In Progress`へ変更する。
4. 同じcontinuationで`Implementation checkpoint`を記録し、`LINEAR-ISSUES.md`のPost-write verificationに従ってstatus / checkpointをread-backする。

ChatGPTがactual local transitionを直接かつauthoritatively確認できるexecution routeでは、Human round-trip自体は必須ではない。ただし**actual lane transition成功の確認より先に`In Progress`を書かない**というorderingは同じ。

start / resume後のidentity invariantは、physical `BUSY`な`main` / `sub` laneから読めるimplementation Issue集合とLinear上のcurrent implementation `In Progress`集合が一致すること。単に`In Progress <= 2`であることだけでは成功条件にならない。

product / UX decision、approval-gated dev-context write、unsafe / destructive unknown-state recoveryなど、Human判断そのものが必要なboundaryはこのruleで自動決定しない。その場合も「何を判断 / 実行すれば先へ進めるか」を具体化して返す。

## Implementation continuation completion rule

HumanがLuna implementation / integration checkpoint等の結果を返した後、残る作業がChatGPTから直接扱えるremote / management stateだけで完結する場合、その工程をHumanへの細かなhandoffへ分割しない。

典型的なremote-only continuation:

```text
Luna result
-> pushed HEAD / latest main freshness
-> blocking review
-> [Auto-merge enabled: exact-head reservation -> task ends without CI wait]
   or
   [manual merge: fresh CI completion -> merge -> merged-state verification -> Linear synchronization]
```

原則:

- Auto-mergeがcurrent repositoryで有効なら、[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) のpreconditionを満たすexact headへ予約した時点でtaskを終了する。fresh CIが`queued` / `in_progress`でもwait / polling / monitoring subagentを作らず、GitHubとDiscord routeへ委ねる。
- CI failure Discord通知はHuman明示resumeを要求するterminal stopである。failureから自動でtaskを再開、rerun、cancel、repair、merge、Linear synchronizationしない。resume後のrepair / BLOCKED boundaryは`LINEAR-GITHUB.md`をauthorityとする。
- Auto-mergeを使わないrepositoryまたはbootstrap PRだけは、fresh CIが`queued` / `in_progress`でも、それ自体を理由に`CI結果をまた返してください`等のHuman actionへ変換しない。ChatGPTが同じexecution trackでremote stateを追跡し、PASS / FAIL / concrete blockerまで進める。
- progress updateは出してよいが、Humanが何もする必要のないremote-only intermediate stateをconversation handoff boundaryにしない。
- blocking reviewに必要なGitHub diff / code / review thread / CI evidenceをChatGPTが取得できるならHumanに再取得させない。
- safe merge authorizationが既にcurrent execution trackへ与えられている場合、通常のmerge confirmationを再要求しない。merge gateは`LINEAR-GITHUB.md`に従う。
- manual merge後のGitHub / Linear synchronizationは、Human-only actionがなければ同じcontinuationで完了する。auto-mergeではHuman明示resumeまでdeferする。

Humanへ戻してよいのは、product / UX / scope decision、unsafe local state、destructive operation、Human-only environment / observation、required approval boundary、またはcurrent toolsでは解消できないconcrete blocker等、**Human actionが実際に必要な場合だけ**。

local checkoutのdeterministic releaseだけが残る場合は、Work completion / Linear statusと物理lane cleanupを混同しない。lane stateは`CHECKOUTS.md`、Issue statusは`LINEAR-ISSUES.md` / `LINEAR-GITHUB.md`をauthorityとする。

## Final closure declaration rule

Issueの`Done`はWork completionを表し、implementation laneを含むexecution lifecycle全体のcloseとは区別する。

`main` / `sub` implementation laneを使用し、local releaseが必要なWorkについて、ChatGPTが「完全終了」「すべて終了」「追加作業なし」等のfinal closureを宣言してよいのは、次をすべて満たした後だけとする。

1. Work completion / Issue status synchronizationがcurrent policyに従って完了している。
2. [`CHECKOUTS.md`](./CHECKOUTS.md) に従うlane releaseが成功し、actual local laneが`FREE`になっている。
3. release結果をcurrent Linear Issueへ`Lane release checkpoint`として記録している。
4. [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のPost-write verificationに従い、そのcheckpointをread-backしてcurrent stateを確認している。

Humanが`nuinui release`等のfresh release成功outputを返した場合、そのoutputをactual local stateのevidenceとして扱う。Linear操作をChatGPT側で実行できるなら、release成功の説明だけで停止せず、同じcontinuationで`Lane release checkpoint`の記録とread-backまで完了する。

Issueが既に`Done`でもlane release、release checkpoint、またはそのread-backが残っている場合は、Work completionとremaining closure stepを分けて報告し、「完全終了」「追加作業なし」とは宣言しない。

release checkpointの記録失敗だけを理由に、既に有効なmerge / Manual E2E / Done判定を巻き戻さない。ただし、その場合はfinal closure未完了として扱い、必要なmanagement synchronizationを残作業として明示する。

## Startup / execution boundary

Implementation開始・再開では、READMEのloading ruleに従ってcurrent Linear / remote repository / required implementation policiesを確認する。

通常のsource-code implementation local executionが必要なら[`CHECKOUTS.md`](./CHECKOUTS.md)の3-lane preflightとstartup gateを使う。通常のsource-code sliceのslice / Base checkpoint / integration checkpointは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)をauthorityとする。

Documentation / policy direct execution exceptionでは、implementation laneのclaim / Base checkpointは不要。ただしwrite直前にlatest remote target file SHA、current management/spec state、そしてユーザーが許可したplanとのscope一致を確認する。

ChatGPT web環境からfixed checkoutへ直接アクセスできないことを理由に、通常のsource-code implementationについて代替clone / fourth worktree / direct-GitHub implementationへ迂回しない。Documentation / policy direct execution exceptionだけは本policyの明示範囲内でGitHub remote editingを許可する。

## Chat rotation

Implementation chatのrotation自体はTask pauseではない。status、lane ownership、Base checkpoint、branch、current sliceをrotationだけで変更しない。

Work自体をpause / releaseする場合だけ`LINEAR-ISSUES.md` / `CHECKOUTS.md` / `IMPLEMENTATION-SLICING.md`の該当ruleを使う。

## Loading rule

Implementation chatでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのimplementation loading ruleに従う。

## Maintenance rule

このdocumentはImplementation chat固有のstart / resume / continuation / handoff lifecycleだけをownerする。checkout操作、slice semantics、Coding Agent detail、Linear lifecycleは各owner documentを参照し、ここへ複製しない。
