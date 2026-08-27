# nuinuiCAD Codex-only interim workflow

Status: **Inactive**

Activated: 2026-08-25

Deactivated: 2026-08-27 by explicit Human instruction after ChatGPT usage capacity recovered.

Reactivation: Humanが明示的にこのinterim workflowの再有効化を指示したときだけ再有効化する。availability / rate limitの変化だけを理由に自動再有効化しない。

Inactiveな間、このdocumentは将来の再利用用referenceとして保持するが、通常のloading対象でもoverride authorityでもない。

## Purpose and precedence

Web ChatGPTをprimary coordinatorとして使わず、CodexだけでnuinuiCAD開発を逐次継続する間のtoken-minimizing overrideを定義する。

このdocumentがActiveな間、次のtopicについて既存ownerと衝突する場合はこのdocumentを優先する。

- executor / model selection;
- implementation parallelism / lane utilization;
- local checkpointとpush / PR / mergeのgranularity;
- Linear progress synchronization frequency;
- Manual E2E executor;
- Codex task / context loading strategy。

product contract、repository architecture、implementation semantics、source-of-truth、destructive-operation safety、e2e checkoutでproduct fixを行わないruleは上書きしない。

## Token-minimizing default

- 1つのprimary Codex task、1 active implementationだけで進める。
- 後述のLuna read-only monitoring exceptionを除き、subagent、parallel task、`sub` implementation laneは使わない。Humanが個別に明示許可した場合だけ例外にできる。
- implementationは`main` lane、Manual E2Eは`e2e` laneだけを使う。4つ目のcheckout / clone / worktreeを作らない。
- 同じCodex task内で既に読んだdocumentを、変更signalなしに読み直さない。
- startupではこのREADME router、本document、repository `AGENTS.md`、current workに必要なownerだけを読む。全owner documentを一括loadしない。
- repository探索は`rg`、targeted diff、known owner / callerから開始し、open-endedな全tree再調査を避ける。
- model切替だけを理由にnew Codex taskを作らない。reconstruction costより明確に節約できるescalationだけnew taskを許す。

最小の通常開始文:

```text
dev-context/projects/nuinuiCAD/README.mdを読み、SAY-123を続ける
```

## Model and reasoning routing

各段階の開始時に、Codexは使用するmodel / reasoning levelをHumanへ明示する。

| Work | Default |
| --- | --- |
| documentation、known-state recovery、focused verification、Git、Linear、Human E2E preparation / result sync | Luna medium |
| normal contract、multi-file implementation、batch review | Terra high |
| unknown root cause、shared architecture、authority conflict、重大なambiguous E2E failure | Sol high |
| GUI Manual E2E product operation / judgment | Human |

Rules:

- routine workへxhigh / maxを使わない。
- xhighは、highで一度失敗し、そのfailure evidenceから追加reasoningが再試行を減らす場合だけ使う。
- maxはdefault routeにしない。
- narrow mechanical workを上位modelへ移さない一方、severe unknown bugをLunaで反復して総tokenを増やさない。
- model別rate-limit consumptionが不明な場合、単一runの見かけ上の安さではなく、retry、context reload、duplicate reviewを含むexpected total consumptionで選ぶ。

### Coordinator-managed model decision checkpoints

Coordinator chatが別Codex taskをexecutorとして扱う場合、taskの開始・再開時にcurrent work classへ適したmodel / reasoningと、次のmodel-decision checkpointを指定する。

- child taskは、別のdefault routeへ移り得るwork class境界、またはfailure evidenceからescalationを再判断する境界で、current atomic operationを最初のsafe recovery pointまで終えて停止する。通常checkpointごとの機械的な停止は行わず、同じrouteの作業は継続する。
- model切替だけを理由にcommit、push、Linear sync、new task作成を行わない。repository / external stateのcheckpointは各ownerの既存ruleが要求する場合だけ作る。
- 停止時は、完了内容とevidence、current local / Git checkpoint、次のwork class、未解決のfailure / ambiguity、推奨model / reasoningをconciseに返す。
- Coordinatorはhandoffを評価し、Humanの再指示を待たず、原則として同じchild taskへ選択したmodel / reasoning override付きで次段階を送る。GitHub Auto-mergeのCI failure Discord通知後だけは[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)に従いHuman明示resumeを待つ。段階開始時のmodel / reasoning明示は維持する。
- normal implementationからunknown root cause investigation、high failureからxhigh再試行、implementation / reviewからfocused verification・Git・Linear等のroutine continuationへ移る場合はmodel-decision checkpointとする。
- この停止はHuman action待ちではない。Human-only判断やconcrete blockerがなければCoordinatorがcontinuationを再開し、remote-only continuationをHumanへの細かなhandoffへ分割しない。

### Luna read-only monitoring subagent exception

明確なterminal conditionを持つread-only monitoringは、active implementationを増やさない限定例外として、同じprimary task tree内のLuna medium subagentへ委任してよい。

- Sol / Terra parentがCI、PR checks、その他のexternal jobを一度確認し、statusが`queued` / `in_progress`等の非terminal stateなら、以後の監視を自動的にLuna medium subagentへ委任する。single immediate status checkだけなら委任せず、parentがLunaなら新しいsubagentを作らず自身で監視する。
- monitoring subagentは同時に最大1つとし、複数check / jobも1 agentへまとめる。parentは同じ対象を重複pollingせず、subagentのterminal reportを待つ。
- monitoringにはbounded wait / polling mechanismを使い、tight loopを行わない。PASS、FAIL、cancelled、timeout、またはstatus / authority ambiguityをterminal report条件とする。
- monitoring subagentはread-onlyに限定する。code / test実行、failure diagnosis、review、merge、GitHub / Linear update、checkout / lane操作、Manual E2Eを行わない。
- terminal reportには対象ref / check / job、最終status、必要な最小evidence、次の推奨work classを含める。FAIL / ambiguityでは原因を推測せずmodel-decision checkpointとしてparentへ返す。
- この例外はnew user-owned Codex task、implementation lane、checkout / worktreeを作らない。monitoring終了時にsubagentを終了し、Coordinatorまたはparentが次のmodel / reasoningを選択してcurrent execution trackを続ける。

## Sequential Git batch

通常のsource-code workは`main` laneのlong-lived branch `codex/interim-sequential`で、複数Issueを1件ずつ逐次処理する。

- natural recovery / revert boundaryでlocal commitを作る。commit messageにcurrent `SAY-123` identifierを含める。
- micro-sliceごとのroutine fetch、push、PR、merge、blocking reviewを行わない。
- Issue completionごとのpush / mergeも要求しない。Human Manual E2Eは必要ならexact local commitをtested refにできる。
- active batch中はlocal checkout、branch history、commit logをcurrent execution checkpointのauthorityとする。
- unrelated cleanup、refactor、format churnをbatchへ混ぜない。

User-facing control:

```text
続ける   -> current long-lived branchでlocal workを継続する。publishしない。
publish  -> current batchをremoteへ公開・統合する。
```

`publish`では次を一度だけ行う。

1. latest remote / interferenceをfetchして確認する。
2. 必要なmain integrationを1回行う。remote driftがunexpectedなら自動rebase / resetせず停止する。
3. batch全体のrequired verificationをまとめて行う。
4. branchを1回pushする。
5. 1 PRと1 blocking reviewを行う。GitHub Auto-mergeがcurrent repositoryで有効な場合は、[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) のpreconditionを満たしたexact headにだけauto-mergeを予約し、予約evidenceを返してexecution trackを終了する。CIの完了待機、mergeのpolling、failureからの自動resumeは行わない。
6. auto-mergeを予約しない場合だけ、1 mergeでbatchを統合し、batch内Linear Issuesをまとめて同期する。予約した場合のmerge後Linear同期は、Discord通知を見たHumanが明示的にresumeした後にfresh remote stateから行う。

Local commitをまだremote保存していないことだけを理由にroutine publishしない。destructive recovery、別machine handoff、remote-only execution等でremote checkpointが実際に必要な場合は、その理由を明示してpublishを提案する。

## Verification batching

- 各changeではchanged behaviorを直接coverするfocused testを先に実行する。
- build / lint / full regressionは、継続判断に必要な場合を除きpublish checkpointへまとめる。
- shared parser / compiler / document runtime / evaluator等、focused testだけでは独立機能regressionを検出できないownerはrepository `AGENTS.md`のrisk-based broad gateを維持する。
- retry-until-greenをverificationにしない。
- publish reviewはbatch combined diffに対して1回行い、Issueごとのduplicate full reviewを作らない。

## Linear synchronization

CodexがLinear操作を担当し、Humanへmanual updateを要求しない。

- current Issue / contractはwork selection時に1回読む。
- status、comment、label、relationはimplementation start、explicit pause / rotation、publish、Manual E2E result等、external recoveryに必要なcheckpointだけでまとめて更新する。
- local-only micro-commitやCodex commentaryをLinearへ複製しない。
- active local batch中はLinear progressがlocal commitより遅れることを許容する。publish時にauthoritative remote stateへ同期する。
- GitHub Issues public mirrorはexisting sync ownerへ任せ、同内容を手動二重投稿しない。
- Auto-merge予約後のCI failure Discord通知はimplementationのrestart authorizationではない。Humanの明示resumeまでcode変更、rerun、cancel、merge、Linear updateを行わず、常駐monitor / subagentも作らない。

## Human Manual E2E

このdocumentがActiveな間、すべてのManual E2E unitは`Executor: Human`とする。Objective / Human judgmentのoracle分類自体は維持する。

- Codexがexact tested commit、fixture、e2e marker、isolated host build / launch、copy/paste不要な準備、test stepsを確定する。
- Humanはproduction GUIでdeclared actionを実行し、live observationを判定する。
- PASS時は簡潔なresultでよい。dynamic interactionへroutine screenshotを要求しない。
- FAIL / ambiguity時だけ、failed step、observed result、必要な最小screenshotを取得する。
- confirmed product FAILは`e2e` checkoutで修正しない。`main` laneのcurrent sequential branchへfixを戻す。

## Deactivation

Humanがinterim workflowの解除を明示したら、本documentをInactive化または削除し、READMEのAlways-load routeを外す。同じ変更で、long-lived batch、unpublished local checkpoint、Linear lag、active e2e markerを監査し、通常policyへ安全に復帰できるcheckpointを作る。

### 2026-08-27 deactivation checkpoint

- Human explicitly requested deactivation after ChatGPT usage capacity recovered. This document is retained for possible future reactivation.
- Latest remote `sayosomi/nuinuiCAD` `main` observed during deactivation: `50c99d19f3c96094d74c353aba73628e7f2b8fa0` (merge of PR #571).
- Remote branch `codex/interim-sequential` is absent. The interim SAY-142 Linear checkpoint still names that branch and a local starting HEAD `65526f8de6b94cdefd35ecec30439c1b99fa0d24`; that SHA is not available from the remote GitHub repository.
- Linear audit found SAY-142 as the only `In Progress` Issue and found no Issue labeled `Manual E2E: Running` / `Running`.
- This ChatGPT session cannot directly inspect the three local checkouts, so unpublished local commits / working-tree changes and the local `e2e` marker are not asserted absent. Deactivation performs no destructive local mutation and does not reassign any lane. Before the next implementation start/resume, the normal [`CHECKOUTS.md`](./CHECKOUTS.md) mandatory 3-lane preflight must reconcile actual local state and then synchronize SAY-142's lifecycle checkpoint if needed.

## Reactivation

If Human later explicitly requests this contingency again:

1. audit current remote repository, Linear lifecycle state, and all three local lanes from fresh evidence;
2. set this document to `Status: Active` and record the new activation date;
3. restore the README `Active override` Always-load route in the same change;
4. establish a fresh interim execution checkpoint from current state rather than blindly reusing the historical `codex/interim-sequential` branch or any checkpoint recorded above.
