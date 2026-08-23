# nuinuiCAD Luna Manual E2E playbook

## Purpose

Codex Luna xhighでnuinuiCAD Manual E2Eを安定して実行するための**operational playbook**。

Authorityを分ける。

- test classification、`Judgment`、`Executor`、PASS / FAIL / BLOCKED、Sol High result ownership: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- VS Code isolated Extension Development Host baseline: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- current Issueのfixture / action / oracle / acceptance: current Linear Issue contract / Manual E2E plan
- この文書: Luna prompt、stable tested state、evidence、retry、capability calibration、common pitfalls

このplaybookがauthority文書と矛盾したらauthority側を優先し、その後playbookをrefreshする。

## Operating model

Lunaはtest operatorでありtest designerではない。

```text
prepare exact state
-> operate
-> observe
-> compare with predeclared oracle
-> capture evidence
-> report PASS / FAIL / BLOCKED
```

Lunaへ次をさせない。

- architecture調査
- product / UX / aesthetic judgment
- test plan redesign
- missing oracleの発明
- implementation fix
- implementation root-cause investigation
- unrelated cleanup
- Human-assigned unitの実行

`FAIL` / `BLOCKED`後はevidenceを残してtest-operator resultを返す。implementation codeを読んで原因調査やrepairへ移行しない。

## 1. Freeze the tested state when `main` is moving

Manual E2E実行前に必ず:

```bash
git fetch origin --prune
```

quietなrepositoryならcurrent `origin/main` exact commitをtested stateにしてよい。

nuinuiCADでは並行mergeが多いため、prompt生成からLuna実行までの間に`origin/main`が進むことがある。単純に:

```text
origin/main == <prompt SHA>
```

を要求すると、tested behaviorが変わっていなくてもfalse `BLOCKED`になり得る。

必要ならreview済みcommitへstable remote E2E refを作る。

```text
origin/sayosomi/<issue>-manual-e2e-freeze
```

Luna側で最低限:

```bash
EXPECTED="<tested commit>"
E2E_REF="origin/sayosomi/<issue>-manual-e2e-freeze"

test "$(git rev-parse "$E2E_REF")" = "$EXPECTED"
git merge-base --is-ancestor "$EXPECTED" origin/main
```

`origin/main`のnormal advancementだけではblockしない。実行時の`origin/main` SHAをresultへ記録する。

### Tested-commit observation surface

Promptで使うimplementation-specific factは、実際にtestするcommitに対して確認する。

例:

- contributed command名
- DOM / accessibility selector
- webview structure
- label / exact visible string
- fixture syntax

latest `main`だけを見てtested frozen commitにも同じsurfaceがあると推測しない。latest `main`はdrift reviewのauthority、実行時のselector / command / observable surfaceはtested commitのimplementationをauthorityとする。

### Post-result main-drift review

Luna結果受領後、Sol Highがlatest `main`をfresh-checkし、tested commitからlatest `main`までのintervening changesを**test unitごと**にreviewする。

mainが進んだだけではcompleted E2Eをinvalidateしない。affected unitをrerunするのは、その変更が次のいずれかへ到達し得る場合だけ:

1. unitが必要とするinitial state / fixtureの成立
2. unitで実行するactionのsemantics
3. expected observationを生成するimplementation / data flow
4. unitが必要とするproduction-host wiring / observation surface

同じfile / directory / subsystemを触ったという事実だけではrerun理由として十分ではない。逆に、別fileでも上記data flowへ到達するならmaterial driftになり得る。

- 上記への影響を合理的に除外できる → completed PASSを維持する。
- 影響し得る → **affected unitだけ**new reviewed stateでrerunする。
- change review後も影響を合理的に除外できない → safety側に倒してaffected unitだけrerunする。
- tested commitがlatest `main`のancestorでなくなった → rewrite / stale tested stateとして扱い、valid current baseから必要unitをrerunする。

completed evidenceを持つfreeze refを黙って別commitへ動かさない。新しいtested stateが必要ならnew/versioned refを使う。

## 2. Protect local checkouts

checkout運用は [`CHECKOUTS.md`](./CHECKOUTS.md) に従う。

Luna promptでは実行前にstandard checkoutsのstateを確認させる。

最低限:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
```

cleanでidleなcheckoutだけを使う。

frozen commit検証でdetached HEADを使う場合:

```bash
git switch --detach "$EXPECTED"
test "$(git rev-parse HEAD)" = "$EXPECTED"
test -z "$(git status --porcelain)"
```

Manual E2Eのためにunrelated user workをreset / stash / discard / overwrite / force-switchしない。

## 3. Run environment preflight before product tests

VS Code host setupは [`VS-CODE-E2E.md`](./VS-CODE-E2E.md) のcanonical baselineを使う。

Luna dedicated-machine runでは、開始前に全VS Code processをcleanupし、古いExtension Development Host / fixtureが残らない状態からfresh hostを1つ起動する。

product oracle実行前にextension-registration preflightを行う。

`.nui` fixtureで:

1. current runのunique fixtureをactiveにする。
2. language modeが`nui` / nuinuiCADでありPlain Textでないことを確認する。
3. current testに必要なnuinuiCAD contributed commandがCommand Paletteに存在することを確認する。
4. Playwright/CDP runでは接続先workbenchがcurrent unique fixtureを含むことを確認する。
5. 必要ならRunning Extensions / fresh profile logsも確認する。

preflight失敗は:

```text
BLOCKED — development extension registration / test environment unavailable
```

でありproduct `FAIL`ではない。

必要ならfresh profileのlogsからextension host / window / main logを確認し、`nuinuiCAD`、`extensionDevelopmentPath`、scanning / activation、error / warningをevidenceとして返す。

Lunaはその場でimplementation codeを修正しない。

### VS Code objective test: prefer Playwright / CDP

VS Code production-hostのobjective Luna testでは、Playwright/CDPから操作・観測できるsurfaceはPlaywright/CDPを優先する。

優先対象:

- workbench / active tab identity
- Command Palette / command registration
- Monaco editor keyboard input
- Problems等のvisible text
- webview / frame discovery
- DOM / accessibility state
- DOM element count / identity / bounding box
- DOM-derived coordinate click / drag
- screenshot

Computer Use / raw GUI coordinate automationは、required oracleをCDP / accessibility / DOMから取得できず、かつそのpixel-level操作 / 観測がtest contract上必要な場合にだけ使う。CDPでobjectiveに取れる事実をComputer Useの目視解釈へ戻さない。

### Command Palette operation

SAY-188 calibrationで、CDPからCommand Paletteを安定して扱うため次を実証した。

- command searchは先頭`>`でcommand modeを明示する。
- commandの存在/選択判定はstable command text / accessible identityを使う。
- VS Codeがrowへ`recently used`等のmetadataを付加し得るため、rendered row全体のexact string matchを要求しない。
- metadataを無視することと曖昧なsubstring選択は別。predeclared command identityが一意に確定しない場合はguessしない。

### Deterministic Source edit

Sourceの特定token/spanを書き換えるunitでは、typing前に対象rangeを客観的に確認する。

```text
resolve exact document
-> select exact intended range
-> verify selected range/text
-> type once
-> fresh live Source evidence
-> wait for stable dependent state
-> fresh dependent evidence
```

誤rangeへ入力した後に「修正のための2回目の編集」を行う方式を標準にしない。one-edit oracleを守るため、編集前verificationを使う。

### CDP startup retry

`VS-CODE-E2E.md`のCDP readiness ruleを使う。

- endpoint readyは最大約60秒pollする。
- 1回目のfresh launchが失敗したらdiagnosticsを保存する。
- VS Codeを全cleanupする。
- new fresh profileで1回だけretryしてよい。
- 2回目もendpointを確立できなければenvironment `BLOCKED`。

診断evidenceには少なくとも次を含める。

- `code` CLI exit
- launch stdout / stderr
- VS Code process一覧
- CDP port listener
- fresh profile logs / file listing when useful

## 4. Keep counted Luna runs unattended

User copy/paste before/after a Luna run istransportでありHuman executionではない。一方、**run開始後のHuman rescueはtest executionへの介入**になる。

counted Luna run中はHumanに次をさせない。

- click / typing
- modal/dialog dismissal
- focus restoration
- VS Code window manipulation
- host relaunch / process cleanup
- fixture repair

unexpected dialogやhost stateが出ても、Luna自身がpredeclared/bounded procedureで処理できなければ`BLOCKED`を返す。

Humanが反射的に操作する等、unplanned Human interactionがrunへ入った場合:

1. そのrunはproduct FAILにしない。
2. evidenceはincident recordとして保存する。
3. counted resultから除外する。
4. environmentをcleanupし、新しいrun root / fixture / fresh hostからrerunする。

Human judgment unitや明示的Human calibration passはこのruleの対象外だが、それらとLuna unattended runを混在させない。

## 5. Design fixtures for objective identity

Luna向けfixtureは、UI上で機械的に識別できるidentity markerを持たせる。

multi-document test例:

```text
PrintA / SvgA / PieceA
PrintB / SvgB / PieceB
```

VS Code runではcurrent `E2E_ROOT`を含むunique fixture basenameを使い、古いrunのfixtureと区別できるようにする。

oracleにも識別方法を書く。

悪い例:

```text
the right document opened
```

良い例:

```text
Preview selector shows PrintA and active Canvas tab identifies say89-A.nui
```

state-preservation testはbefore / afterで同じidentityを記録する。

例:

- selected geometry identity
- Preview selector value
- active tab title
- exact source span
- session count / duplicate absence
- A/B tabs before and after source close

## 6. Prefer objective evidence over narration

Lunaの`PASS`は「looks correct」だけではacceptしない。

優先するevidence:

- structured MCP state when published
- DOM / accessibility state when available
- exact visible strings
- accessible name
- active tab title
- selector value
- exact live source text
- before / after version/state
- count / stable identity evidence
- screenshot as supporting evidence

VS Code Canvas等でmain geometryが`<canvas>`でも、SVG / HTML overlayやwebview DOMにoracleを直接表すidentity / selection / handleがあるならそれをprimary evidenceとして使う。screenshotはsupporting evidenceにする。

visual checkでもoracleをbinary factへ固定する。

例:

```text
PASS if the same selection marker remains on the same identified geometry.
```

スクリーンショットがあること自体はaesthetic judgmentの許可ではない。

`vscode_observe`がpublishするstable `canvas.selectedElementIds`とraw `runtimeSelectedElementIds`は別namespaceとして扱う。headless stable IDとの比較にruntime IDを使わない。

Source edit後はpre-action snapshotをpost-action evidenceとして再利用しない。documentVersionの増分数そのものをuser edit回数と同一視せず、predeclared stable current stateへ収束した後のfresh evidenceを比較する。

## 7. Order units and re-establish independent initial state

破壊的操作は可能なら最後へ置く。

例:

- source close / session disposal
- delete
- state reset
- irreversible mutation

promptにはfailureが後続unitを無効化するかを書く。

独立unitなら、1 unitのFAILで残りのevidenceを隠さずcontinueさせる。

前unitのFAILによりselection、source、session、focus等が汚染され、次の**独立unit**のinitial stateを通常restoreだけで作れない場合、promptで許可されたfresh fixture / fresh host resetを使って次unitのexact initial stateを再確立する。

- predeclared independent unit → previous FAIL由来のcontaminated stateだけを理由に即`BLOCKED`にしない。
- state continuation自体がoracleの一部であるdependent unit → fresh resetして別testへ変えない。planどおりstop / BLOCKED / FAILを判断する。

fresh reset後もrequired initial stateを客観的に作れない場合は`BLOCKED`。

## 8. First-use paired capability calibration

未知のLuna操作を増やすときは、Humanを毎Issueの恒常executorにせず**one-time ground truth**として使う。

`MANUAL-E2E.md`のfirst-use paired calibration ruleに従い、current proven baselineにないmaterially new operation/evidence familyだけを対象にする。

典型例:

- first Hover interaction / hover evidence
- first native Quick Fix open/select/apply flow
- first drag or resize operation
- first new webview surface interaction type
- first multi-document retarget/lifecycle operation
- first new structured observation field/path

手順:

1. Sol Highがsame tested state / same objective oracleを固定する。
2. Humanが**new primitiveに必要な最小範囲だけ1回**ground truthを実行する。
3. 値・identity・expected visible stateを記録する。
4. fresh host/stateからLunaがindependently同じobjective unitを実行する。
5. Sol HighがHuman/Luna evidenceを比較する。
6. operation/evidence technique、pitfall、capability boundaryを抽出する。
7. 成功したcapabilityをこのplaybookまたはrepository Skillへ追加する。
8. 以後の同familyはLuna only。material drift時だけ再calibrateする。

Humanへfull scenarioを何回も再実行させない。既にprovenなSource activation、Canvas open、CDP attach等まで毎回Human側で繰り返す必要はなく、新しいprimitiveのground truthに必要なsetup/action/evidenceだけ行う。

HumanとLunaが一致しない場合、Human repeatを最初の解決策にしない。fixture/oracle/environment/operation/evidence/capability/productのどこで差が生まれたかを分類する。

### Proven capability reuse

同じcapability limitationをIssueごとに繰り返し試さない。再利用可能なboundaryが判明したらこのplaybookへ記録し、future classificationで最初から使う。

同様に、**実証済みpositive capability**も再利用する。成功済みoperation / observationをIssueごとに毎回capability probeし直さない。VS Code version、Playwright/CDP behavior、対象surface、host wiring、observation API等にmaterial driftがある場合だけ再probeする。

### Proven VS Code CDP capability baseline

2026-08-23時点で、isolated VS Code Extension Development Host + Playwright CLI/CDP + nuinuiCAD MCP observationについて次を実機で確認済み。

- VS Code `1.134.0`
- Playwright CLI `0.1.18`
- CDP attach
- tab-list / snapshot / screenshot
- current unique fixtureをworkbenchから識別
- Command Palette command mode (`>`)からnuinuiCAD commandを発見・実行
- Command Palette row metadata (`recently used`等)が付いてもstable command textで識別
- `nuinuiCAD: Open Canvas` / `nuinuiCAD: Fit Drawing` / `nuinuiCAD: Open Output Preview` / `nuinuiCAD: Reveal in Canvas`の実行
- `vscode-webview://...` frame内のnuinuiCAD Canvas DOMへ到達
- `.canvas-viewport` / `.drawing-overlay` / `.overlay-draggable-point`を観測
- DOM bounding box由来のcoordinate click
- selected point / glow / selected identityのDOM観測
- Source / Canvas / Output Previewのactive surface/session identityを`vscode_observe`で区別
- headless stable identityとCanvas stable selected identityの一致確認
- runtime selected ID namespaceをstable IDと分離
- deterministic Source range verification -> one edit -> fresh live Source/Canvas evidence
- ambiguous targetでguessせず`BLOCKED`
- live diagnosticsは`vscode_observe`のexact range/code/messageとnative Problems UIのvisible textを組み合わせて客観確認できる
- native `Trigger Suggest` completion popupはDOM/accessibility option rowsを列挙し、label/detailでshorthand等のdistinct candidate identityを確認してから1 candidateを選択し、fresh live Sourceでexact insertion textを検証できる
- native Go to Definitionは事前にexact Source caret positionを固定し、command実行後のactive document + destination caret/selectionでtarget identityを確認できる。reference prefix文字自体をoracleに含める場合もそのexact positionから実行する
- native Find All ReferencesはReferences treeのresult countを取得し、同一表示textのrowが複数ある場合は各rowをnavigateしてsource line/range identityを証明する
- native Rename Symbolはexact source identifierからrename inputを開き、1回apply後にfull live Sourceを取得してcross-site rewrite条件を同時確認し、必要なら1 Undoでbaseline restorationを確認できる

このbaselineに該当するoperationは、未知のLuna capabilityとして毎Issue Human pair/probeし直さない。tested commitのsurface freshnessとcurrent environment driftだけ確認する。

## 9. Build a self-contained but non-duplicative Luna prompt

fresh Luna sessionでは、execution-critical informationをprompt内へ完結させる。

必須要素:

- repository / checkout identity
- expected tested commit / stable ref
- remote verification commands
- checkout safety conditions
- exact build / launch baseline or canonical runner invocation
- exact fixture contents
- selected Luna units only
- per unit: initial state / action / oracle / evidence
- independent unitのreset / stop条件
- result format

LunaへLinear、GitHub、過去chat、repository architectureからtest planを再発見させない。

一方、durable environment operationをpromptごとに独自再実装しない。`VS-CODE-E2E.md`にcanonical ruleがある場合はそれに従い、将来repository-owned canonical E2E runnerが導入されたら、promptはrunner invocation + task-specific fixture / action / oracleへ寄せる。runnerが存在する場合、巨大なlaunch / cleanup logicを毎回別実装しない。

promptへ明示するboundary例:

```text
Do not modify implementation code.
Do not fix a failure.
Do not inspect implementation code for root-cause investigation.
Do not redesign or expand the test plan.
Do not perform Human-assigned units.
Do not ask the Human to rescue the run.
Return BLOCKED if the required state cannot be established objectively.
```

same Luna sessionへretryする場合はdelta promptでもよいが、retained contextが曖昧ならself-contained promptへ戻す。

## 10. Distinguish BLOCKED from FAIL

典型的`BLOCKED`:

- tested remote stateがstale / rewritten
- stable refがexpected commitを指さない
- safe clean checkoutがない
- VS Code executable / Rust binaryがない
- bounded launch後もCDP endpointを確立できない
- development extensionがregisteredされない
- `.nui`がPlain Text
- extension未loadのためrequired commandがない
- required initial UI stateを確実に作れない
- required resultを確実にobserveできない
- prompt / oracleがambiguous

典型的true `FAIL`:

```text
Environment preflight passed.
Specified action was executed.
Required state was objectively observable.
Observed result contradicted the predeclared oracle.
```

environment / instruction / Luna capability problemをimplementation failure loopへ入れない。

## 11. Result format

headerでtested environmentを記録する。

```text
Tested commit:
Stable E2E ref:
Checkout used:
origin/main at execution:
Repository status before test:
VS Code executable:
VS Code version:
Playwright CLI version: <when used>
E2E_ROOT:
Extension registration / environment preflight:
Repository implementation files modified: YES | NO
```

per unit:

```text
Unit <id>: PASS | FAIL | BLOCKED
Expected:
Observed:
Evidence:
Reproduction steps if FAIL:
Blocker if BLOCKED:
```

grouped identity testは各subcaseを明示する。`works`だけでまとめない。

CDP launch retryやPTY fallbackを使った場合はattempt/fallbackごとのCDP reached / CLI exit / diagnostic evidenceもresultへ記録する。

最後に必ず:

```text
Reusable-operation observation: none | <concise factual observation>
```

を返す。new capability、runner/host pitfall、evidence technique、capability boundaryを積極的に拾う。

## 12. Sol High acceptance checklist

Luna結果をacceptする前に確認する。

1. tested commit / stable refがintended stateか。
2. environment preflightがPASSか。
3. Manual E2E中にrepository implementation filesを変更していないか。
4. 各required Luna unitにoracleを直接支えるevidenceがあるか。
5. implementation-specific selector / command / observable surfaceがtested commitに存在するものか。
6. Human-assigned unitが残っていないか。
7. counted Luna runへunplanned Human rescueが入っていないか。
8. first-use paired calibration対象ならHuman/Luna evidenceを比較したか。
9. reusable-operation observationをownerへ反映する必要があるか判定したか。
10. latest `origin/main` driftをunitごとにreviewしたか。
11. tested resultへ到達し得るmaterial driftがある場合、affected unitだけrerunしたか。
12. aggregate `Manual E2E: Passed`の前提を満たすか。
13. Done-before Ready contract freshness checkは別checkpointとして実施したか。

## Common pitfalls

### Moving-main false blocker

症状: fetch直後、`origin/main`がprompt SHAより新しいだけでLunaがBLOCKED。

対策: Sol Highがdriftをreviewし、stable E2E refでtested stateを固定し、実行後にlatest-main freshness reviewを分離する。same file / subsystemという理由だけでrerunせず、各unitのinitial state / action / observation data flowへの到達可能性で判断する。

### Stale Extension Development Host steals the run

症状:

- old E2E fixtureがactiveになる
- old `[Extension Development Host]` window / Search windowをLunaが操作する
- current unique fixtureをpreflightで確認できない

対策: Luna dedicated-machine runでは開始前にVS Codeを全process cleanupし、0 process確認後にfresh isolated hostを1つだけ起動する。古いhostをGUI上で見分けてreuseしない。

### CDP endpoint is slow or intermittently absent

症状: VS Code launch直後の短いpollで`/json/version`が取れずenvironment BLOCKEDになる。

対策: 最大約60秒pollする。失敗時はlaunch diagnosticsを保存し、VS Codeを全cleanupしてnew fresh profileで1回だけretryする。2回とも失敗した場合だけenvironment BLOCKED。

### Runner shell exits before GUI host is durable

症状: 正しいlaunch argsでもone-shot runner shell終了とともにVS Code GUI/CDP listenerが消える、またはlifetimeが不安定になる。

対策: `VS-CODE-E2E.md`のbounded persistent-PTY fallbackを使う。PTYを全runの必須baselineにはしない。

### VS Code opens but nuinuiCAD is absent

症状:

- VS Code自体は起動
- `.nui`がPlain Text
- required nuinuiCAD commandがない
- Running Extensionsにdev extensionがない

対策: product FAILにせずenvironment BLOCKED。`VS-CODE-E2E.md`のcanonical isolated launchを使い、extension-registration preflightを先に通す。

### Human accidentally rescues a Luna run

症状: process cleanupやunexpected host stateによりdialogが出て、Humanが閉じる/クリックする等の操作をしてしまう。

対策: そのrunをFAILにもPASSにも数えない。evidenceを残してfresh independent runをやり直す。Luna run中はPCをHumanが操作しない運用をdefaultにする。

### Independent unit is hidden by previous unit contamination

症状: Unit AのFAILでselection / source / sessionが壊れ、独立なUnit Bがその汚染stateだけを理由にBLOCKEDになる。

対策: Unit Bがplan上independentなら、fresh fixture / fresh hostを含む指定resetでexact initial stateを再確立してUnit Bを続行する。Unit Bがstate continuationを検証するdependent unitならresetしない。

## Maintenance rule

Manual E2Eから再利用可能なoperational lessonが得られたらこのplaybookへ追加する。

追加対象:

- stable ref / freshness strategy
- evidence technique
- proven positive Luna capability
- repeated Luna capability boundary
- prompt pattern
- environment pitfall
- Human/Luna first-use calibrationから得たoperation primitive

個別Issueの完了履歴や巨大なcompleted promptを保存しない。incident detailはGit / Linear historyへ残し、ここには再利用可能なruleだけを残す。
