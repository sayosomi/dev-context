# nuinuiCAD Codex-only interim workflow

Status: **Active**

Activated: 2026-08-25

Deactivation: Humanが明示的にこのinterim workflowの解除を指示したときだけ解除する。日付やChatGPT model availabilityを理由に自動解除しない。

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
- Coordinatorはhandoffを評価し、Humanの再指示を待たず、原則として同じchild taskへ選択したmodel / reasoning override付きで次段階を送る。段階開始時のmodel / reasoning明示は維持する。
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
5. 1 PR、1 blocking review、1 mergeでbatchを統合する。
6. batch内Linear Issuesをまとめて同期する。

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

## Human Manual E2E

このdocumentがActiveな間、すべてのManual E2E unitは`Executor: Human`とする。Objective / Human judgmentのoracle分類自体は維持する。

- Codexがexact tested commit、fixture、e2e marker、isolated host build / launch、copy/paste不要な準備、test stepsを確定する。
- Humanはproduction GUIでdeclared actionを実行し、live observationを判定する。
- PASS時は簡潔なresultでよい。dynamic interactionへroutine screenshotを要求しない。
- FAIL / ambiguity時だけ、failed step、observed result、必要な最小screenshotを取得する。
- confirmed product FAILは`e2e` checkoutで修正しない。`main` laneのcurrent sequential branchへfixを戻す。

## Deactivation

Humanがinterim workflowの解除を明示したら、本documentをInactive化または削除し、READMEのAlways-load routeを外す。同じ変更で、long-lived batch、unpublished local checkpoint、Linear lag、active e2e markerを監査し、通常policyへ安全に復帰できるcheckpointを作る。
