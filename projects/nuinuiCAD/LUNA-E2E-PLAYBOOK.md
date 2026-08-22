# nuinuiCAD Luna Manual E2E playbook

## Purpose

Codex Luna xhighでnuinuiCAD Manual E2Eを安定して実行するための**operational playbook**。

Authorityを分ける。

- test classification、`Judgment`、`Executor`、PASS / FAIL / BLOCKED、Sol High result ownership: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- VS Code isolated Extension Development Host baseline: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- current Issueのfixture / action / oracle / acceptance: current Linear Issue contract / Manual E2E plan
- この文書: Luna prompt、stable tested state、evidence、retry、common pitfalls

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

## 4. Design fixtures for objective identity

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

## 5. Prefer objective evidence over narration

Lunaの`PASS`は「looks correct」だけではacceptしない。

優先するevidence:

- DOM / accessibility state when available
- exact visible strings
- accessible name
- active tab title
- selector value
- exact source text
- before / after state
- count evidence
- screenshot

VS Code Canvas等でmain geometryが`<canvas>`でも、SVG / HTML overlayやwebview DOMにoracleを直接表すidentity / selection / handleがあるならそれをprimary evidenceとして使う。screenshotはsupporting evidenceにする。

visual checkでもoracleをbinary factへ固定する。

例:

```text
PASS if the same selection marker remains on the same identified geometry.
```

スクリーンショットがあること自体はaesthetic judgmentの許可ではない。

## 6. Order units and re-establish independent initial state

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

## 7. Build a self-contained but non-duplicative Luna prompt

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
Return BLOCKED if the required state cannot be established objectively.
```

same Luna sessionへretryする場合はdelta promptでもよいが、retained contextが曖昧ならself-contained promptへ戻す。

## 8. Prefer Luna for objective units, without weakening the oracle

`Judgment: Objective`で、既知のLuna capability / evidence blockerがなく、required stateを作成・操作・観測できると合理的に見込めるunitは、原則`Executor: Luna`で試す。

「できるか少し不安」というだけで最初からHumanへ回さない。

Lunaがrequired stateを確実に作れない、または観測できない場合は`BLOCKED`でよい。

例:

- required selectionを客観的identity付きで確立できない
- popup/candidateをevidence上区別できない
- physical-device操作が必要
- required observation surfaceをLunaから取得できない

`BLOCKED`後は原因を分ける。

- bounded environment / launch / prompt問題で明確に修正可能 → setup / promptを直してaffected unitをrerun
- actual Luna operation / observation / evidence capability boundary → `Judgment: Objective / Executor: Human / Reason: Luna capability`へreclassify
- missing / ambiguous product oracle → Humanへ逃がさずcontract / test planを非Readyへ戻す

Lunaを維持するためにoracleを簡単な別物へ置換しない。

同じcapability limitationをIssueごとに繰り返し試さない。再利用可能なboundaryが判明したらこのplaybookへ記録し、future classificationで最初から使う。

同様に、**実証済みpositive capability**も再利用する。成功済みoperation / observationをIssueごとに毎回capability probeし直さない。VS Code version、Playwright/CDP behavior、対象surface、host wiring等にmaterial driftがある場合だけ再probeする。

### Proven VS Code CDP capability baseline

2026-08-22時点で、isolated VS Code Extension Development Host + Playwright CLI/CDPについて次を実機で確認済み。

- VS Code `1.134.0`
- Playwright CLI `0.1.18`
- CDP attach
- tab-list / snapshot / screenshot
- current unique fixtureをworkbenchから識別
- Command Paletteで`nuinuiCAD: Open Canvas` / `nuinuiCAD: Fit Drawing`を発見・実行
- `vscode-webview://...` frame内のnuinuiCAD Canvas DOMへ到達
- `.canvas-viewport` / `.drawing-overlay` / `.overlay-draggable-point`を観測
- DOM bounding box由来のcoordinate click
- selected point / glow / selected identityのDOM観測

このbaselineに該当するobjective VS Code Canvas operationは、未知のLuna capabilityとして毎Issue probeし直さない。tested commitのsurface freshnessとcurrent environment driftだけ確認する。

## 9. Distinguish BLOCKED from FAIL

典型的`BLOCKED`:

- tested remote stateがstale / rewritten
- stable refがexpected commitを指さない
- safe clean checkoutがない
- VS Code executable / Rust binaryがない
- 2回のbounded launch後もCDP endpointを確立できない
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

## 10. Result format

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

CDP launch retryを使った場合はattemptごとのCDP reached / CLI exit / diagnostic evidenceもresultへ記録する。

## 11. Sol High acceptance checklist

Luna結果をacceptする前に確認する。

1. tested commit / stable refがintended stateか。
2. environment preflightがPASSか。
3. Manual E2E中にrepository implementation filesを変更していないか。
4. 各required Luna unitにoracleを直接支えるevidenceがあるか。
5. implementation-specific selector / command / observable surfaceがtested commitに存在するものか。
6. Human-assigned unitが残っていないか。
7. latest `origin/main` driftをunitごとにreviewしたか。
8. tested resultへ到達し得るmaterial driftがある場合、affected unitだけrerunしたか。
9. aggregate `Manual E2E: Passed`の前提を満たすか。
10. Done-before Ready contract freshness checkは別checkpointとして実施したか。

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

### VS Code opens but nuinuiCAD is absent

症状:

- VS Code自体は起動
- `.nui`がPlain Text
- required nuinuiCAD commandがない
- Running Extensionsにdev extensionがない

対策: product FAILにせずenvironment BLOCKED。`VS-CODE-E2E.md`のcanonical isolated launchを使い、extension-registration preflightを先に通す。

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

個別Issueの完了履歴や巨大なcompleted promptを保存しない。incident detailはGit / Linear historyへ残し、ここには再利用可能なruleだけを残す。
