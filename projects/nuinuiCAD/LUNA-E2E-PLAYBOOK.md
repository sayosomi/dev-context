# nuinuiCAD Luna Manual E2E playbook

## Purpose

Codex Luna xhighでnuinuiCAD Manual E2Eを安定して実行するためのoperational playbook。

Authorityを分ける。

- test classification、`Judgment`、`Executor`、PASS / FAIL / BLOCKED、Sol High result ownership: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- VS Code isolated Extension Development Hostのisolation / Human terminal preparation / launch baseline: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- current Issueのfixture / action / oracle / acceptance: current Linear Issue contract / Manual E2E plan
- この文書: Luna prompt、tested-state verification、attach/preflight、evidence、retry boundary、capability reuse、common pitfalls

このplaybookがauthority文書と矛盾した場合はauthority側を優先し、playbookをその場でrefreshする。矛盾した古いrunbookを残したまま優先順位だけで運用しない。

## Operating model

VS Codeの`Executor: Luna` Manual E2Eは次を標準とする。

```text
Sol High
  exact tested state / stable ref / fixture / launch contractを固定
      ↓
Human (remote Terminal only)
  exact checkoutを準備
  build
  fresh profile / fixtureを生成
  stale VS Codeをcleanup
  isolated Extension Development Hostを起動
  CDP readinessを確認
  handoff fileを書き出す
      ↓
counted Luna run
  prepared hostへattach
  read-only environment identity preflight
  operate -> observe -> compare -> evidence
```

Lunaはtest operatorでありtest designerではない。

通常のstartup handoffでは、Sol HighがIssue、tested ref、fixture、locale、port、`Executor: Luna`をsemanticに固定し、Humanが同じterminalで`nuinui e2e-start-command`を1回実行する。generatorはread-onlyで既存Human-test classifierを検証し、既存`e2e-start && nuinui-e2e-prepare prepare`の短いshell-safe continuationだけを出力する。Humanは成功した生成行をverbatimに実行し、terminal outputへ大きなLuna promptを追加・コピーしない。既存prepareの`handoff=` path、session、CDP、checkout、fixture、locale readinessがLunaへのbounded transport identityであり、Luna prompt自体はSol Highがcurrent contractから別に構成する。generatorはexecutor分類、tested-ref選択、lane scheduling、test oracleを行わない。

Successful closure is authorized by Sol High / ChatGPT and started by Human with one short named command in the same terminal:

```bash
nuinui-e2e-prepare closure-command --issue SAY-123 [--lane <human-test-lane>]
```

The closure helper fresh-resolves lane, tested ref, and E2E root, then invokes the existing cleanup, `e2e-release`, and `closure-check` authorities in canonical order. Terminal output is the canonical orchestration record; Human does not reconstruct or substitute lane/ref/root. Exact duplicate stages continue immediately. A `BLOCKED` / `ERROR` short-circuits later stages and returns to ChatGPT for bounded diagnosis. PASS / FAIL judgment and Human stop / pause semantics remain unchanged.

Lunaへ次をさせない。

- checkout切替、build、VS Code process cleanup、fresh host launch
- architecture調査
- product / UX / aesthetic judgment
- test plan redesign
- missing oracleの発明
- implementation fix
- implementation root-cause investigation
- unrelated cleanup
- Human-assigned unitの実行
- HumanへのGUI rescue依頼

`FAIL` / `BLOCKED`後はevidenceを残してtest-operator resultを返す。implementation codeを読んで原因調査やrepairへ移行しない。

## 1. Freeze the tested state when `main` is moving

Manual E2E実行前にSol Highがlatest remoteを確認し、exact tested commitを決める。

quietなrepositoryならcurrent `origin/main` exact commitをtested stateにしてよい。

nuinuiCADでは並行mergeが多いため、必要ならreview済みcommitへstable remote E2E refを作る。

```text
origin/sayosomi/<issue>-manual-e2e-freeze
```

Human setup scriptにはexpected commit / stable refを埋め込み、Lunaはhandoff後にread-onlyで再確認する。

Luna側の最低限preflight例:

```bash
source /tmp/nuinui-<issue>-luna.env

git -C "$CHECKOUT" fetch origin --prune

test "$(git -C "$CHECKOUT" rev-parse HEAD)" = "$EXPECTED"
test -z "$(git -C "$CHECKOUT" status --porcelain)"

if [ -n "${E2E_REF:-}" ]; then
  test "$(git -C "$CHECKOUT" rev-parse "$E2E_REF")" = "$EXPECTED"
fi

git -C "$CHECKOUT" merge-base --is-ancestor "$EXPECTED" origin/main
```

LunaはpreflightでHEADを動かさない。`origin/main`のnormal advancementだけではblockせず、execution-time SHAをresultへ記録する。

### Tested-commit observation surface

Promptで使うimplementation-specific factは実際にtestするcommitに対して確認する。

例:

- contributed command名
- DOM / accessibility selector
- webview structure
- label / exact visible string
- fixture syntax

latest `main`だけを見てtested frozen commitにも同じsurfaceがあると推測しない。

### Post-result main-drift review

Luna結果受領後、Sol Highがlatest `main`をfresh-checkし、tested commitからlatest `main`までのintervening changesをtest unitごとにreviewする。

mainが進んだだけではcompleted E2Eをinvalidateしない。affected unitをrerunするのは、その変更が次のいずれかへ到達し得る場合だけ。

1. unitのinitial state / fixture成立
2. action semantics
3. expected observationを生成するimplementation / data flow
4. production-host wiring / observation surface

同じfile / subsystemを触っただけではrerun理由として十分ではない。逆に別fileでも上記data flowへ到達するならmaterial drift。

completed evidenceを持つfreeze refを黙って別commitへ動かさない。

## 2. Human terminal preparation boundary

Human preparationのauthorityは[`VS-CODE-E2E.md`](./VS-CODE-E2E.md)。

Humanは遠隔Terminalだけを操作できる前提とし、Terminal外へ出ない。

Human setupで行うこと:

- exact checkout / commit検証
- required build
- fresh `--user-data-dir`
- empty `--extensions-dir`
- task fixture生成
- stale VS Code process cleanup
- exact development extension / Rust binaryを指定したhost launch
- dedicated CDP port readiness確認
- handoff file生成
- `READY FOR LUNA` marker出力

Human setupで行わないこと:

- Completion、Rename、Canvas click等のproduct oracle実行
- VS Code windowを見る / 操作する
- GUI modal dismissal
- macOS System Settings操作
- GUI permission approval
- screenshotやGUI judgment

canonical generator経由の通常pathでは、versioned prepare helperが返す既存の`E2E SETUP READY`、`handoff=...`、session identityをそのまま使う。`READY FOR LUNA`を含む下記のfallback/reference setupは別のreadiness authorityを追加するものではなく、generatorがそのmarkerや大きなpromptを合成することもない。

GUI-only environment prerequisiteが必要ならHumanへTerminal外操作を要求せずenvironment `BLOCKED`として扱う。

Human setup scriptはstrict modeをchild bash内に閉じ込め、失敗してもremote interactive shell自体を終了させない。

## 3. Attach to the prepared host and preflight before product tests

counted Luna runは`READY FOR LUNA`後にのみ開始する。

Lunaはhandoff fileを読み、prepared hostへattachする。build / launchをやり直さない。

product oracle実行前に最低限確認する。

1. checkout HEAD / stable ref / clean status / `origin/main` relationship
2. CDP endpointがreachable
3. current runのunique fixtureを含むworkbenchへattachしたこと
4. active documentがexpected fixture
5. language modeが`nui` / nuinuiCADでPlain Textでないこと
6. current testに必要なnuinuiCAD command / extension registration
7. `vscode_observe`が必要ならexact fixtureをresolveできること

preflight失敗はproduct `FAIL`ではなくenvironment `BLOCKED`。

prepared hostがstale / unreachable / wrong identityならLunaはcleanupやrelaunchを行わない。BLOCKEDを返し、run終了後に必要ならHuman terminal setupをfreshにやり直す。

### VS Code objective test: prefer Playwright / CDP

Playwright/CDPから操作・観測できるsurfaceはComputer UseよりPlaywright/CDPを優先する。

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

Computer Use / raw GUI coordinate automationはrequired oracleをCDP / accessibility / DOMから取得できず、かつpixel-level操作 / 観測がtest contract上必要な場合だけ使う。

### Command Palette operation

SAY-188 calibrationで次を実証済み。

- command searchは先頭`>`でcommand modeを明示
- commandの存在/選択判定はstable command text / accessible identityを使う
- `recently used`等のrow metadataをexact matchへ含めない
- predeclared command identityが一意に確定しない場合はguessしない

### Deterministic Source edit

Sourceの特定token/spanを書き換えるunitではtyping前に対象rangeを客観確認する。

```text
resolve exact document
-> select exact intended range
-> verify selected range/text
-> type once
-> fresh live Source evidence
-> wait for stable dependent state
-> fresh dependent evidence
```

誤range入力後のrepair editを標準手順にしない。

## 4. Keep counted Luna runs unattended

User copy/paste before/after Luna runはtransportでありHuman product executionではない。

counted Luna run開始後、HumanはTerminalからも介入しない。

Humanに次をさせない。

- click / typing
- modal/dialog dismissal
- focus restoration
- VS Code window manipulation
- host relaunch / process cleanup
- fixture repair
- Terminalからのprocess intervention

unexpected dialogやhost stateが出てもLuna自身がpredeclared product-operation範囲で処理できなければ`BLOCKED`を返す。

unplanned Human interactionがrunへ入った場合:

1. そのrunはproduct FAILにしない
2. evidenceはincident recordとして保存
3. counted resultから除外
4. run終了後にHuman terminal setupからfresh runを作る

Human judgment unitや別途明示されたlocal Human sessionをLuna unattended runへ混在させない。

## 5. Design fixtures for objective identity

Luna向けfixtureはUI上で機械的に識別できるidentity markerを持たせる。

multi-document test例:

```text
PrintA / SvgA / PieceA
PrintB / SvgB / PieceB
```

VS Code runではcurrent `E2E_ROOT`を含むunique fixture basenameを使い、古いrunと区別する。

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

- attached live MCP observation when published
- DOM / accessibility state
- exact visible strings
- accessible name
- active tab title
- selector value
- exact live source text
- before / after state
- count / stable identity
- screenshot as supporting evidence

MCP/script-onlyで完結するdeterministic verificationはLunaへ送らない。`MANUAL-E2E.md`のMCP-only ruleに従う。

`vscode_observe`がpublishするstable `canvas.selectedElementIds`とraw `runtimeSelectedElementIds`は別namespaceとして扱う。

Source edit後はpre-action snapshotをpost-action evidenceとして再利用しない。

## 7. Order units and restore state without relaunching the host

破壊的操作は可能なら最後へ置く。

例:

- source close / session disposal
- delete
- irreversible mutation

promptにはfailureが後続unitを無効化するかを書く。

独立unitなら、1 unitのFAILで残りのevidenceを隠さずcontinueさせる。

同一prepared host内でpredeclared Undo / source restoration / tab reopen等によりexact initial stateを客観的に戻せる場合はrestoreして次unitを続けてよい。

**fresh hostが必要になった時点でLuna run内ではresetしない。**

- dependent unitでstate continuity自体がoracle → planどおりstop / FAIL / BLOCKED
- independent unitだがfresh hostが必要 → affected later unitをBLOCKEDとして返す
- run終了後にHuman terminal setupでfresh hostを作り、Sol Highがaffected unitだけretryするか判断

Lunaへprocess cleanup / new profile creation / host relaunchをさせない。

## 8. New Luna capability and calibration under terminal-only Human access

`MANUAL-E2E.md`のfirst-use calibrationは`when practical`であり、遠隔HumanがTerminal外へ出られない環境ではGUI ground-truth passはpracticalではない。

したがってstandard remote flowではHumanへVS Code GUI calibrationを依頼しない。

materially new Luna operation/evidence familyでは:

1. Sol Highがobjective oracleを事前固定する
2. already-proven primitive / DOM / live structured observationで十分なground truthが得られるか確認する
3. Lunaがfresh prepared hostでindependently実行する
4. Sol Highがevidenceをoracleへ照合する
5. operation/evidence techniqueが再利用可能ならplaybook / Skillへ記録する

objective evidenceだけでnew primitiveの成功を十分に確立できない場合は、Human GUI rescueへ切り替えず`Luna capability BLOCKED`とする。

GUIを必要とする`Judgment: Human` unitもstandard remote flowでは実行不能。Terminalだけで代替判定せず、別途GUIへアクセスできるHuman sessionが用意されるまでDeferred / BLOCKEDとして扱う。

別日にHumanがGUIへ直接アクセスできるlocal sessionが明示的に用意された場合だけ、one-time paired calibrationを実施してよい。そのsessionはterminal-only preparationとは別物として扱う。

### Proven capability reuse

同じcapability limitationをIssueごとに繰り返し試さない。

実証済みpositive capabilityも再利用する。VS Code version、Playwright/CDP behavior、対象surface、host wiring、observation API等にmaterial driftがある場合だけ再probeする。

### Proven VS Code CDP capability baseline

2026-08-23時点で、isolated VS Code Extension Development Host + Playwright/CDP + nuinuiCAD live observationについて次を実機確認済み。

- VS Code `1.134.0`
- CDP attach
- tab-list / snapshot / screenshot
- current unique fixtureをworkbenchから識別
- Command Palette command mode (`>`)からnuinuiCAD commandを発見・実行
- Command Palette row metadataが付いてもstable command textで識別
- `nuinuiCAD: Open Canvas` / `nuinuiCAD: Fit Drawing` / `nuinuiCAD: Open Output Preview` / `nuinuiCAD: Reveal in Canvas`の実行
- `vscode-webview://...` frame内のnuinuiCAD Canvas DOMへ到達
- `.canvas-viewport` / `.drawing-overlay` / `.overlay-draggable-point`観測
- DOM bounding box由来のcoordinate click
- selected point / glow / selected identityのDOM観測
- Source / Canvas / Output Previewのactive surface/session identityを`vscode_observe`で区別
- headless stable identityとCanvas stable selected identityの一致確認
- runtime selected ID namespaceをstable IDと分離
- deterministic Source range verification -> one edit -> fresh live Source/Canvas evidence
- ambiguous targetでguessせず`BLOCKED`
- live diagnosticsは`vscode_observe`のexact range/code/messageとnative Problems UIのvisible textを組み合わせて客観確認
- native `Trigger Suggest` completion popupはDOM/accessibility option rowsを列挙し、label/detailでdistinct candidate identityを確認してから選択し、fresh live Sourceでexact insertion textを検証
- native Go to Definitionはexact Source caret positionを固定し、command実行後のactive document + destination caret/selectionでtarget identityを確認
- native Find All ReferencesはReferences treeのresult countを取得し、同一表示textのrowが複数ある場合は各rowをnavigateしてsource line/range identityを証明
- native Rename Symbolはexact source identifierからrename inputを開き、1回apply後にfull live Sourceを取得してcross-site rewrite条件を同時確認し、必要なら1 Undoでbaseline restorationを確認

このbaselineに該当するoperationは未知のLuna capabilityとして毎Issue再probeしない。

## 9. Build a self-contained but non-duplicative Luna prompt

fresh Luna sessionではexecution-critical informationをprompt内へ完結させる。

必須要素:

- handoff file path
- expected tested commit / stable ref
- read-only remote / checkout verification
- prepared hostへattachするCDP endpoint
- expected fixture identity
- selected Luna units only
- per unit: initial state / action / oracle / evidence
- 同一host内で許可されたrestoration / stop条件
- result format

Luna promptへbuild / checkout switch / VS Code cleanup / host launch scriptを含めない。

LunaへLinear、GitHub、過去chat、repository architectureからtest planを再発見させない。

promptへ明示するboundary例:

```text
Do not modify implementation code.
Do not build or relaunch the prepared host.
Do not switch the checkout.
Do not fix a failure.
Do not inspect implementation code for root-cause investigation.
Do not redesign or expand the test plan.
Do not perform Human-assigned units.
Do not ask the Human to rescue the run.
Return BLOCKED if the prepared state cannot be verified objectively.
```

same Luna sessionへaffected-unit retryするのは、prepared hostがそのままvalidでproduct stateだけをpredeclared restorationできる場合に限る。fresh hostが必要ならnew Human terminal preparation後のnew runにする。

## 10. Distinguish BLOCKED from FAIL

典型的`BLOCKED`:

- handoff fileがない / malformed
- tested remote stateがstale / rewritten
- stable refがexpected commitを指さない
- prepared checkoutがdirty / wrong HEAD
- prepared CDP endpointへattachできない
- attached workbenchがexpected unique fixtureではない
- development extensionがregisteredされない
- `.nui`がPlain Text
- required commandがない
- required initial UI stateを確実に作れない
- required resultを確実にobserveできない
- fresh hostが必要だがcounted run中である
- prompt / oracleがambiguous

典型的true `FAIL`:

```text
Environment preflight passed.
Specified product action was executed.
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
VS Code version:
Playwright/CDP version when available:
E2E_ROOT:
Fixture:
Prepared-host handoff / environment preflight:
Repository implementation files modified: YES | NO
Unplanned Human interaction during counted run: YES | NO
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

最後に必ず:

```text
Reusable-operation observation: none | <concise factual observation>
```

を返す。

## 12. Sol High acceptance checklist

Luna結果をacceptする前に確認する。

1. tested commit / stable refがintended stateか
2. Human terminal preparationがproduct oracleを実行せず完了したか
3. prepared-host environment preflightがPASSか
4. Lunaがbuild / checkout switch / process cleanup / relaunchをしていないか
5. Manual E2E中にrepository implementation filesを変更していないか
6. 各required Luna unitにoracleを直接支えるevidenceがあるか
7. implementation-specific selector / command / observable surfaceがtested commitに存在するものか
8. counted Luna runへunplanned Human rescueが入っていないか
9. reusable-operation observationをownerへ反映する必要があるか
10. latest `origin/main` driftをunitごとにreviewしたか
11. material driftがある場合affected unitだけrerunしたか
12. aggregate `Manual E2E: Passed`の前提を満たすか
13. Done-before Ready contract freshness checkを別checkpointで実施したか

## Common pitfalls

### Moving-main false blocker

症状: `origin/main`がprompt SHAより新しいだけでBLOCKED。

対策: stable E2E refでtested stateを固定し、execution-time mainはancestor relationshipを確認。結果後にunit別drift review。

### Stale Extension Development Host steals the run

症状:

- old E2E fixtureがactive
- old Extension Development Hostへattach
- current unique fixtureをpreflightで確認できない

対策: Human terminal setupでcounted run前に全VS Code processをcleanupし、0 process確認後にfresh isolated hostを1つ起動する。Lunaはwrong hostを見つけたらBLOCKEDであり、自分でrelaunchしない。

### CDP endpoint is slow or absent

症状: host launch後に`/json/version`が取れない。

対策: Human terminal setup中にbounded readiness pollを行う。readyでなければLunaを開始しない。必要なretryもproduct action前のHuman setup内でfresh profileを使って行う。

### GUI-only environment prerequisite

症状: permission prompt、System Settings、GUI confirmationが必要。

対策: HumanはTerminal外へ出ない。environment BLOCKEDとして止め、別途prerequisiteが解消された後にfresh setupをやり直す。

### VS Code opens but nuinuiCAD is absent

症状:

- `.nui`がPlain Text
- required nuinuiCAD commandがない
- Running Extensionsにdev extensionがない

対策: product FAILにせずenvironment BLOCKED。Lunaはrebuild/relaunchせず結果を返す。

### Human accidentally intervenes after Luna begins

症状: HumanがTerminalからprocess cleanupやrelaunchを行う。

対策: そのrunをFAILにもPASSにも数えない。run終了後にfresh Human terminal setupからやり直す。

### Independent unit needs a fresh host

症状: previous unitでselection / source / sessionが壊れ、同一host内のpredeclared restorationでは次unitのinitial stateを作れない。

対策: Lunaはfresh hostを起動しない。later unitをBLOCKEDとして返し、run終了後にHuman terminal setupでfresh hostを作ってaffected unitだけrerunする。

## Maintenance rule

Manual E2Eから再利用可能なoperational lessonが得られたらこのplaybookへ追加する。

追加対象:

- stable ref / freshness strategy
- prepared-host handoff / preflight technique
- evidence technique
- proven positive Luna capability
- repeated Luna capability boundary
- prompt pattern
- environment pitfall

個別Issueの完了履歴や巨大なcompleted promptを保存しない。incident detailはGit / Linear historyへ残し、ここには再利用可能なruleだけを残す。
