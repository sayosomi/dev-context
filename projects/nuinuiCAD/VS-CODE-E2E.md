# nuinuiCAD VS Code Manual E2E environment

## Purpose

VS Code extensionのuser-facing behaviorをManual E2Eで確認するときの**isolated Extension Development Host baseline**を定義する。

- test unitの`Judgment`、PASS / FAIL / BLOCKED、result handlingは [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。
- current Manual E2E executorはHuman only。
- local versioned helperのavailability / sync / repair / fallbackは [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) がauthority。
- locale-specific / translated-UI verificationは必要な場合だけ [`VS-CODE-E2E-LOCALE.md`](./VS-CODE-E2E-LOCALE.md) を追加で読む。
- この文書はHumanが操作するVS Code production-hostのisolation / local preparation / launch baselineをownerとする。

`LUNA-E2E-PLAYBOOK.md`はinactive historical reactivation referenceであり、normal Human Manual E2Eのhost authorityではない。

## Responsibility split

Current Human Manual E2Eでは標準責務を次のように分ける。

```text
ChatGPT / Sol High
  exact tested state / fixture / action / oracle / evidence planを固定
      ↓
Human terminal handoff
  versioned helperでexact checkoutを準備
  build
  fresh profile / fixtureを生成
  isolated Extension Development Hostを起動
      ↓
Human production-host execution
  declared initial stateを確認
  product action
  observe / judge
  evidenceを返す
      ↓
ChatGPT / Sol High
  PASS / FAIL candidate / BLOCKEDを分類してroute
```

Host preparation itself is not a product test result. `READY FOR HUMAN E2E`は「declared product actionを開始できるisolated hostが準備済み」というreadiness evidenceであり、PASSを意味しない。

## Human GUI execution

terminal preparationが完了した後、HumanはVS Code Extension Development Hostへ移動してproduct test unitを直接実行する。

HumanはTaskのdeclared action / oracleに必要な範囲で:

- VS Code GUIを見る;
- mouse / keyboardを操作する;
- Objective observationを確認する;
- visual / interaction qualityを判断する;
- screenshotを撮ってChatGPTへ提出する。

Screenshotのcase grouping、Human judgmentとの境界、追加evidenceの要求条件は [`MANUAL-E2E.md`](./MANUAL-E2E.md) のHuman execution / screenshot evidence ruleをauthorityとする。1枚で複数caseを明確に判定できる場合は、fixture / viewportを構成してその1枚へまとめる。

## Baseline

Manual E2Eでは普段使いのVS Code profileをそのまま使わない。

標準環境:

- exact tested checkout / commit
- fresh `--user-data-dir`
- empty `--extensions-dir`
- VS Code built-in completion OFF
- task-specific fixtureをcheckout外へ生成
- current tested checkoutで`npm run build:vscode`
- 必要なhost-neutral Rust `evaluation_stdio` binaryをtested checkoutの`rust-evaluator` crateからbuild
- `NUINUICAD_RUST_EVALUATION_BINARY`でexact binaryを明示
- `--extensionDevelopmentPath="$CHECKOUT/vscode-extension"`
- `--disable-workspace-trust`
- welcome / sessions welcome / release notesを抑止
- repository workspace folderへ依存せずfixture fileを直接open
- live observation / CDP / `NUINUICAD_MCP_OBSERVATION=1`はcurrent Manual E2E contractやversioned helper lifecycleが必要とする場合だけ使用し、Human testだからという理由だけでoracleへ追加しない

通常user settings、word-based suggestions、inline suggestions、keybindings、installed extensions等が結果へ混入すると、nuinuiCAD extension自体のPASS / FAILを判定できない。

## Tested-state preparation ownership

ChatGPT / Sol HighがHuman向けsetup commandを生成する前に:

1. latest remote stateを確認する。
2. testするexact commitを決める。
3. moving default branchからtest evidenceを隔離する必要があればstable remote E2E refを固定する。
4. fixture sourceとrequired binaries / extension bundleを決める。
5. locale-specific verificationが必要ならlocaleを固定する。
6. selected Human-test topologyにexplicit portが必要ならcaller-controlled portを固定する。
7. Humanへ渡すcanonical startup handoffへexact semantic valuesを埋める。

Humanはtested stateやoracleを設計しない。Human terminal stepはChatGPTが固定したstateを機械的に準備するだけにする。

## Human terminal setup contract

VS Code Human Manual E2Eの標準host-preparation handoffは、[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に登録されたversioned `nuinui-e2e-prepare` helperを使う。

current local dev-context cloneでhelperが利用可能でcurrent operationをsupportしている場合:

- ChatGPTはsemantic intentを固定し、`nuinui e2e-start-command --issue <SAY-123> --tested-ref <full-sha> --executor human --fixture <absolute-path> [--lane <human-test-lane>] [--locale <default|ja>] [--port <port>]`をHumanへ渡す;
- Humanはgeneratorを同じterminalで実行し、fresh read-only validation後に出るshell-quoted `e2e-start && prepare` continuationをverbatimに実行する。成功したgenerator outputをChatGPTへ戻してargument orderingを再構成しない;
- `--port`はcaller-controlledであり、Human-test laneが2つ以上のときは明示する。singleton topologyでは省略時の既定port互換を維持する;
- active policyは`--executor human`だけを使う。helperのlegacy parser/runtime compatibilityが別metadataを受け付けても、この文書はそれをcurrent execution pathとしてadvertiseしない;
- helperはexecutor selection、GUI action、test oracleを実行・生成しない;
- 同じbuild / fresh profile / VS Code launch / readiness / session metadata lifecycleを長いinline shellとして再実装しない;
- helper実行後のsession rootやlaunch PIDはhelper metadata / `status`をauthorityとし、temporary directoryを`find`等で再探索して推測しない。

Successful Manual E2E closure is also a single named terminal handoff after ChatGPT / Sol High authorizes closure:

```bash
nuinui-e2e-prepare closure-command --issue SAY-123 [--lane <human-test-lane>]
```

The helper resolves fresh lane, tested ref, and E2E root from local marker/session/receipt authority and serializes existing `cleanup -> e2e-release -> closure-check` public boundaries. Humanはlane、ref、rootを手でsubstituteしない。Exact duplicate success continues immediately; `BLOCKED` / `ERROR` stops later stages and returns to ChatGPT for bounded diagnosis. Existing cleanup, release, closure-check mutation/read-back ownership, PASS / FAIL judgment, and Human stop / pause semantics remain unchanged.

helperが未install、stale / broken、またはcurrent operationをsupportしない場合だけ、[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)のfallback / repair ruleに従ってinline setupへ降りる。helperのunexpected failureを受けて、その場で別の手書きlauncherへ迂回することはfallback条件にしない。

fallback inline setupが必要な場合も、Human向け準備は可能な限り**1つのcopy/paste block**へまとめる。

対話shell自体を誤って終了させないため、strict modeをHumanのcurrent shellへ直接設定しない。標準形は子shellに閉じ込める。

```bash
bash <<'BASH'
set -Eeuo pipefail
trap 's=$?; echo; echo "FAILED at line $LINENO: $BASH_COMMAND"; echo "exit=$s"; exit "$s"' ERR

# preparation commands
BASH
```

Human setupは成功時に次のfinal markerを出す。

```text
READY FOR HUMAN E2E
```

失敗時はTerminalを閉じず、失敗command / line / exit statusを表示する。

Human setupはproduct oracleを実行しない。例えばCompletionを開く、Canvasをclickする、Renameを実行する等はsetupに含めない。`READY FOR HUMAN E2E`後のGUI操作はHuman test unit本体として扱う。

## Fresh profile settings

最低限、fresh profileへ次を設定する。

```json
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
```

普段のVS Code側でsettingsやextensionを手動無効化する方法を標準手順にしない。

## Fixture rule

- Task-specific fixtureは`/tmp`等checkout/worktreeを汚さない場所へ生成する。
- setup lifecycle内でfixtureをmaterializeし、そのfileを起動時に明示的にopenする。
- current runのfixtureはunique filename / identityを持たせ、古いE2E hostやfixtureと客観的に区別できるようにする。
- fixture/state/action/oracleはcurrent IssueのManual E2E planをauthorityとする。
- Human visual runで複数caseを一画面へ安全に配置できる場合は、`MANUAL-E2E.md`のscreenshot evidence grouping ruleに従ってfixture側でまとめてよい。

## Surface lifecycle coverage

VS Code command / actionがCanvas、Output Preview、その他のWebview surfaceを新規作成・open・reveal・reuseできる場合、Manual E2E planはそのsurface lifecycleがuser-facing resultへ影響し得るかを確認する。

同じactionが次のmaterially different pathを持つなら、原則として別test unitで扱う。

- **cold path** — matching surface/sessionがまだ存在しない、またはclosed。command自身がsurfaceをopenして、その同じinvocationで要求されたselection / focus / navigation / operationまで完了する必要がある。
- **warm path** — matching surface/sessionが既にopenでauthoritative。commandが既存surfaceをreuseして同じ要求を完了する。
- **active / inactive path** — focus、command routing、view lifecycle等によって実装pathやacceptanceが変わる場合だけ追加する。

全commandでclosed/open/active/inactiveのCartesian productを機械的に回さない。実装path、host readiness、focus handoff、session reuse等が意味を持つ場合だけ分ける。

cold pathのacceptanceを、事前にtesterがsurfaceを手動openしてからactionを実行する手順で代替しない。commandがsurfaceを開く契約なら、`surfaceが開いた`だけでなく、open後に要求されたselection / focus / pan / target state等まで同じinvocationで成立したことを確認する。

## Theme-sensitive visual coverage

Human visual acceptanceがVS Code theme由来のcolor tokenやcontrastに依存する場合、少なくとも代表的な**Light theme 1つ + Dark theme 1つ**で確認する。

対象例:

- selection / focus / hover color
- frame / border / guide / handle
- label / icon / foreground-background contrast
- theme tokenから派生するCanvas presentation

選んだtheme名はevidenceまたはtest resultへ記録する。特定themeで不具合が見つかった場合、fix後は少なくともそのexact themeを再確認する。shared theme-resolution logicを変更した場合は、final PASS前にLight / Dark双方の代表確認を維持する。

非visualなObjective unitまでthemeごとに重複実行しない。themeがbehaviorそのものを変える契約でない限り、theme pairはtheme-sensitiveなvisual acceptanceだけに適用する。

## Host isolation

Human Manual E2E hostはproduction user profileと分離する。versioned preparation helperがselected generationのroot、profile、fixture、process、session metadataをownerし、fresh isolated hostを作る。

- stale or foreign host/processをcurrent generationとして推測しない;
- current runのowned processだけをhelper identityから管理する;
- helperが`BLOCKED`したprocess/session ambiguityをad-hoc kill / deleteでrepairしない;
- normal user VS Code processを「Manual E2Eだから」という理由だけで無条件に全終了するruleは置かない;
- current Taskがhost isolationのためにdedicated process policyを必要とする場合は、そのrequirementをplan / helper authorityで明示する。

## Reference / fallback Human launch shape

以下はhost-preparation contractのreference implementationであり、versioned `nuinui-e2e-prepare` が利用可能な通常のHuman handoffでChatGPTが再生成するtemplateではない。

`LOCAL-TOOLS.md`のfallback条件が成立した場合、またはhelper自体のrepair / developmentでbaselineを確認する場合にだけ、Task-specific valueを差し替えて使う。CDP / observation flagsはcurrent Task contractまたはhelper compatibility上必要な場合だけ追加する。

```bash
EXPECTED="<tested commit>"
CHECKOUT="<tested checkout>"

cd "$CHECKOUT"

test "$(git rev-parse HEAD)" = "$EXPECTED"
test -z "$(git status --porcelain)"

npm run build:vscode
cargo build --manifest-path rust-evaluator/Cargo.toml --bin evaluation_stdio

RUST_BIN="$CHECKOUT/rust-evaluator/target/debug/evaluation_stdio"
test -x "$RUST_BIN"
test -f "$CHECKOUT/vscode-extension/dist/extension.js"

E2E_ROOT="$(mktemp -d /tmp/nuinui-vscode-e2e.XXXXXX)"
mkdir -p \
  "$E2E_ROOT/user-data/User" \
  "$E2E_ROOT/extensions" \
  "$E2E_ROOT/evidence"

cat > "$E2E_ROOT/user-data/User/settings.json" <<'EOF'
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
EOF

FIXTURE="$E2E_ROOT/<task-fixture>.nui"
cat > "$FIXTURE" <<'EOF'
<task-specific fixture source>
EOF

APP="/Applications/Visual Studio Code.app"
EXEC_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")"
APP_BIN="$APP/Contents/MacOS/$EXEC_NAME"
test -x "$APP_BIN"

NUINUICAD_RUST_EVALUATION_BINARY="$RUST_BIN" \
"$APP_BIN" --new-window \
  --user-data-dir="$E2E_ROOT/user-data" \
  --extensions-dir="$E2E_ROOT/extensions" \
  --extensionDevelopmentPath="$CHECKOUT/vscode-extension" \
  --skip-welcome \
  --skip-sessions-welcome \
  --skip-release-notes \
  --disable-workspace-trust \
  "$FIXTURE" </dev/null
```

macOSでshellの`code` commandがunavailableでも、app bundle内のexecutableを直接使う。

`evaluation_stdio`のowner/pathはlatest repositoryをauthorityとする。過去promptの古いRust pathを流用しない。

`--enable-smoke-test-driver`等、通常のVS Code Extension Development Host pathを別test harnessへ変えるflagはTask contractが明示しない限り追加しない。

## Versioned helper failure routing

`nuinui-e2e-prepare prepare`がunexpected error、hang、session/state mismatchで完了しない場合は、次の順序を固定する。

1. product FAILとして扱わない。
2. `nuinui-e2e-prepare status <human-test-lane>`でselected Human-test checkout / marker / session metadata / recorded root / launch PIDをread-only確認する。
3. valid sessionが残りcleanupが必要なら、`LOCAL-TOOLS.md`とhelper contractに従って`cleanup`する。
4. helper defect / stale local clone / unsupported operation / environment blockerを分類し、`LOCAL-TOOLS.md`のrepair / fallback ruleへ進む。

失敗したprepareの復旧で次を行わない。

- `/tmp`や他temporary parentを`find`等で走査して「前回のE2E root」を推測する;
- session metadataを無視してPID / root / fixtureを再構築する;
- helper failure直後に別のad-hoc VS Code launcherを生成して同じrunを継続する;
- marker / checkout mismatchを手書きscriptでrepairする。

helper自体が未install、stale / broken、またはcurrent operationをsupportしないと確認された場合だけ、`LOCAL-TOOLS.md`のformal fallback条件へ移る。

## Environment blockers

Host preparationまたはHuman executionにGUI-only permission / modal / OS prerequisiteが現れ、declared actionを信頼できるinitial stateで実行できない場合はenvironment `BLOCKED`として扱う。product FAILへ変換しない。

例:

- macOS privacy / App Data permission prompt
- unexpected GUI confirmation dialog
- System Settings prerequisite
- VS Code trust / modal that invalidates declared initial state
- required host prerequisiteを客観確認できない状態

Prerequisiteを解決した後は、current planが要求するfresh stateからsetupをやり直す。Full Disk Access等を全runのbaseline requirementとして先回りで要求しない。

## Extension-registration / initial-state check

Product unitへ入る前にHumanはcurrent planで必要なinitial stateを確認する。必要に応じて:

1. current runのunique `.nui` fixtureをactiveにする。
2. language modeが`nui` / nuinuiCADでありPlain Textでないことを確認する。
3. required contributed commandを、そのcommandのdeclared Palette scopeに含まれるsurfaceをactiveにして確認する。
4. fresh profile / extension registrationがcurrent tested buildに対応することを確認する。

command registration確認はsurface-awareに行う。Source commandをCanvas-only surfaceで要求したり、その逆を行わない。

Initial-state/setup failureはproduct FAILではなくenvironment / setup `BLOCKED`またはplan correctionへrouteする。

## Relaunch rule

次の場合はfresh isolated hostを準備し直す。

- `npm run build:vscode`をやり直した後
- branch / commitを切り替えた後
- blocking fix後の再試験
- fresh profile stateが壊れた、またはinitial stateが不明になった場合
- previous runがenvironment `BLOCKED`となりhostを再構築する場合

古いhostをreuseして新しいbundleやcommitを検証したことにしない。

正式なrerunでは、`MANUAL-E2E.md`のruleに従ってaffected unitのdeclared initial stateを再構築する。例えば`Canvas closed`がinitial stateなら、action前にmatching Canvas sessionが存在しない状態から開始し、既にopenしたCanvasをそのまま使ってcold-path PASSとしない。

## Test-unit grouping

同じfixture・同じeditor state・同じ種類の操作で確認できる項目は、まとまったtest unitとして一度に実行する。

分割するのは主に次の場合:

- 結果によって次のfixture/stateが変わる
- source mutation / revertが必要
- failureが後続判定を無効にする
- source close / dispose等の破壊的操作を最後へ分離する必要がある
- surface/sessionのcold / warm等、lifecycle pathがmaterially different
- Objective observationとHuman visual/UX judgmentを独立して判定できる

最後の2点は [`MANUAL-E2E.md`](./MANUAL-E2E.md) のtest-unit boundary ruleを優先する。同じfixtureを使えることだけを理由に、異なるlifecycle pathや独立したObjective/Human oracleを1つへまとめない。

visual evidenceでは、同じ画面で複数caseを明確に判定できるなら1枚のscreenshotへまとめる。screenshot枚数を増やすためだけにcaseを分割しない。静止画で表現できないinteractionはHuman live observationで確認し、failure / ambiguity時に必要な追加screenshotを取る。

completion testでは、自動popupの有無だけに依存せず、必要に応じて`Trigger Suggest`を明示実行してnuinuiCAD providerの候補を確認する。

## Profile-dependent tests

通常user profileでのみ再現する問題は、isolated environmentのManual E2E failureと混同しない。profile / interoperability固有の別問題として扱う。

Task-specific Manual E2Eが意図的にexisting user settings / installed extensionsとのinteroperabilityを検証する場合だけ、このisolated baselineに加えて別途profile-dependent testを行う。
