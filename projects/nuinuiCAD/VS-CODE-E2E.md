# nuinuiCAD VS Code Manual E2E environment

## Purpose

VS Code extensionのuser-facing behaviorをManual E2Eで確認するときの**isolated Extension Development Host baseline**を定義する。

- test unitの`Judgment` / `Executor`分類、PASS / FAIL / BLOCKED、Sol Highの結果判定は [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。
- Lunaを安定して操作させるprompt構成、stable test ref、evidence、known pitfallsは [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md) を使う。
- この文書はVS Code production-hostのisolation / local preparation / launch baselineをownerとする。

この文書のhost preparation ruleと`LUNA-E2E-PLAYBOOK.md`の古い記述が衝突する場合、この文書を優先する。

## Responsibility split

VS Codeの`Executor: Luna` Manual E2Eでは、標準責務を次のように分ける。

```text
Sol High
  tested state / stable ref / fixture / launch contractを固定
      ↓
Human (terminal only)
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
  environment identityを客観preflight
  product operation -> observe -> compare -> evidence
```

Human preparationはManual E2Eのproduct test unitではない。Humanがshell scriptを起動しただけで`Executor: Human`へ分類しない。

### Human access constraint

Humanは**遠隔Terminalだけを操作できる**前提とする。

Humanへ次を要求しない。

- VS Code windowを見る
- mouse / keyboardでVS Codeを操作する
- dialog / modalを閉じる
- macOS System Settingsを開く
- permission promptをGUIで許可する
- screenshotを撮る、またはGUI状態を判定する
- Terminal外のアプリへ移動する

Human preparationはshellだけで完結しなければならない。

GUI-only permission / modal / OS interactionが必要になった場合、その場でHumanへTerminal外操作を依頼しない。host preparationをenvironment `BLOCKED`として止め、別途environment prerequisiteとして解決してからfresh preparationをやり直す。

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
- live VS Code observationが必要なrunでは`NUINUICAD_MCP_OBSERVATION=1`
- `--extensionDevelopmentPath="$CHECKOUT/vscode-extension"`
- `--disable-workspace-trust`
- welcome / sessions welcome / release notesを抑止
- repository workspace folderへ依存せずfixture fileを直接open
- Luna objective UI runではdedicated CDP portを明示

通常user settings、word-based suggestions、inline suggestions、keybindings、installed extensions等が結果へ混入すると、nuinuiCAD extension自体のPASS / FAILを判定できない。

## Tested-state preparation ownership

Sol HighがHuman向けsetup commandを生成する前に:

1. latest remote stateを確認する。
2. testするexact commitを決める。
3. moving `main`からtest evidenceを隔離する必要があればstable remote E2E refを固定する。
4. fixture sourceとrequired binaries / extension bundle / CDP portを決める。
5. Humanへ渡す準備scriptにexpected commit/refを埋め込む。

Humanはtested stateを設計しない。Human setup scriptはSol Highが固定したstateを機械的に準備するだけにする。

## Human terminal setup contract

Human向け準備は、可能な限り**1つのcopy/paste block**へまとめる。

対話shell自体を誤って終了させないため、strict modeをHumanのcurrent shellへ直接設定しない。標準形は子shellに閉じ込める。

```bash
bash <<'BASH'
set -Eeuo pipefail
trap 's=$?; echo; echo "FAILED at line $LINENO: $BASH_COMMAND"; echo "exit=$s"; exit "$s"' ERR

# preparation commands
BASH
```

Human scriptは成功時に機械判定可能なfinal markerを出す。

```text
READY FOR LUNA
```

失敗時はTerminalを閉じず、失敗command / line / exit statusを表示する。

Human setupはproduct oracleを実行しない。例えばCompletionを開く、Canvasをclickする、Renameを実行する等はsetupに含めない。

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
- setup command block内でfixtureを作り、そのfileを起動時に明示的にopenする。
- Luna向けfixtureはcurrent runだけに対応するunique filename / identityを持たせ、古いE2E hostやfixtureと客観的に区別できるようにする。
- fixture/state/action/oracleはcurrent IssueのManual E2E planをauthorityとする。
- setup終了時にfixture absolute pathをhandoff fileへ保存する。

## Dedicated-machine process isolation

Luna Manual E2Eを実行するmacOS machineでは、実行中に他用途でVS Codeを使用しないことを前提とする。

**Human terminal setup中に**既存のVisual Studio Code processをすべて終了し、0 processであることを確認してからfresh isolated hostを起動する。通常終了後も残るstale Extension Development Host / helper processはTerminalからforce terminationしてよい。

標準形:

```bash
VSCODE_PATTERN='/Applications/Visual Studio Code.app/Contents/'

pkill -TERM -f "$VSCODE_PATTERN" 2>/dev/null || true
sleep 1
pkill -KILL -f "$VSCODE_PATTERN" 2>/dev/null || true
sleep 1

if pgrep -f "$VSCODE_PATTERN" >/dev/null; then
  echo "BLOCKED — Visual Studio Code processes remain after cleanup"
  pgrep -fal "$VSCODE_PATTERN" || true
  exit 1
fi
```

counted Luna run開始後はHumanがprocess cleanup / relaunchを行わない。

## Canonical Human launch shape

Task-specific valueを差し替えて使う。

```bash
EXPECTED="<tested commit>"
CHECKOUT="<tested checkout>"
CDP_PORT=9223

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

CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [ ! -x "$CODE_BIN" ]; then
  CODE_BIN="$(command -v code || true)"
fi
test -n "$CODE_BIN"
test -x "$CODE_BIN"

if lsof -nP -iTCP:"$CDP_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "BLOCKED — CDP port already in use"
  exit 1
fi

NUINUICAD_RUST_EVALUATION_BINARY="$RUST_BIN" \
NUINUICAD_MCP_OBSERVATION=1 \
"$CODE_BIN" --new-window \
  --user-data-dir="$E2E_ROOT/user-data" \
  --extensions-dir="$E2E_ROOT/extensions" \
  --extensionDevelopmentPath="$CHECKOUT/vscode-extension" \
  --remote-debugging-port="$CDP_PORT" \
  '--remote-allow-origins=*' \
  --skip-welcome \
  --skip-sessions-welcome \
  --skip-release-notes \
  --disable-workspace-trust \
  "$FIXTURE"
```

macOSでshellの`code` commandがunavailableでも、app bundle内のexecutableを直接使う。

`evaluation_stdio`のowner/pathはlatest repositoryをauthorityとする。過去promptの古いRust pathを流用しない。

`--enable-smoke-test-driver`等、通常のVS Code Extension Development Host pathを別test harnessへ変えるflagはTask contractが明示しない限り追加しない。

## CDP readiness is Human preparation

Luna objective run用hostでは、Human setup scriptがLunaを呼ぶ前にCDP endpoint readyまで確認する。

標準目安:

```bash
READY=0
for _ in $(seq 1 120); do
  if curl --max-time 1 -fsS \
    "http://127.0.0.1:${CDP_PORT}/json/version" \
    > "$E2E_ROOT/evidence/cdp-version.json"; then
    READY=1
    break
  fi
  sleep 0.5
done

test "$READY" = 1
```

CDPを確立できない状態でcounted Luna runを開始しない。Human setup内でhost launchが失敗した場合はLuna tokenを使わずsetupを修正する。

setup scriptでbounded retryを許す場合も、product actionはまだ一切実行していないことを条件にする。retryはfresh profile / fresh fixtureで行い、古いhost stateをreuseしない。

## GUI-only environment blockers

HumanはTerminal外へ出られないため、次はHuman setup scriptでは解消不能なenvironment blockerとして扱う。

- macOS privacy / App Data permission prompt
- GUI confirmation dialog
- System Settings操作
- VS Code window内でのmanual trust / modal dismissal
- shellから客観確認できないGUI prerequisite

これらが発生した場合:

```text
BLOCKED — GUI-only environment prerequisite requires separate resolution
```

としてsetupを止める。

Humanへ「画面を見て許可」「VS Codeで閉じて」等を依頼しない。prerequisiteが別経路で解決された後、新しいfresh setupを最初から実行する。

Full Disk Access等を全runのbaseline requirementとして先回りで要求しない。

## Handoff file

Human setup成功時は、Lunaが再解釈せず使えるhandoff fileを`/tmp`へ書く。

最低限:

```text
EXPECTED
E2E_REF when used
CHECKOUT
E2E_ROOT
FIXTURE
CDP_PORT
RUST_BIN
```

例:

```bash
cat > /tmp/nuinui-<issue>-luna.env <<EOF
EXPECTED='$EXPECTED'
E2E_REF='$E2E_REF'
CHECKOUT='$CHECKOUT'
E2E_ROOT='$E2E_ROOT'
FIXTURE='$FIXTURE'
CDP_PORT='$CDP_PORT'
RUST_BIN='$RUST_BIN'
EOF

printf '\nREADY FOR LUNA\n'
cat /tmp/nuinui-<issue>-luna.env
```

Humanはこのmarkerを確認したらsetupを終了する。VS Code GUIへ移動しない。

## Counted Luna run boundary

`READY FOR LUNA`後にcounted Luna runを開始する。

Lunaはprepared hostへattachし、product action前にread-only environment preflightを行う。

最低限:

1. handoff fileを読む。
2. checkout HEAD / stable E2E ref / clean status / execution-time `origin/main` relationshipを確認する。
3. CDP endpointが引き続きreachableであることを確認する。
4. 接続先workbenchがcurrent unique fixtureを含むことを確認する。
5. active document / language mode / required extension registrationを確認する。
6. `vscode_observe`が必要なrunではexact fixtureをresolveできることを確認する。

このpreflightは**prepared environmentのidentity確認**であり、Lunaにbuild / checkout切替 / process cleanup / host launchをやり直させるものではない。

preflightでprepared hostが不正・stale・unreachableと判明した場合はenvironment `BLOCKED`。counted run中にHuman rescueを入れない。

## Failure after counted run begins

counted Luna run開始後にhostが壊れた、CDPが消えた、unexpected dialogで操作不能になった等の場合:

1. Lunaは`BLOCKED`を返す。
2. Humanはrun中に介入しない。
3. run終了後、必要ならHuman terminal setupをfresh root / fresh fixture / fresh hostでやり直す。
4. Sol Highがaffected unitだけのretry可否を判断する。

Human terminal preparationとcounted Luna product executionを1つのunattended runへ混ぜない。

## Extension-registration preflight

Lunaはproduct unitへ入る前にenvironment preflightを行う。

最低限:

1. current runのunique `.nui` fixtureをactiveにする。
2. language modeが`nui` / nuinuiCADでありPlain Textでないことを確認する。
3. current testに必要なcontributed nuinuiCAD commandを、**そのcommandのdeclared Palette scopeに含まれるsurfaceをactiveにして**Command Paletteで確認する。
4. Playwright/CDP runでは、接続先workbenchがcurrent runのunique fixtureを含むことを客観的に確認する。
5. 必要ならRunning Extensions / fresh profile logsも確認する。

command registration確認はsurface-awareに行う。Source commandをCanvas-only surfaceで要求したり、その逆を行わない。

preflight失敗はproduct FAILではなくenvironment `BLOCKED`。

## Relaunch rule

次の場合は**counted Luna runを開始する前にHuman terminal setupをやり直し**、fresh isolated hostを起動する。

- `npm run build:vscode`をやり直した後
- branch / commitを切り替えた後
- blocking fix後の再試験
- fresh profile stateが壊れた、またはinitial stateが不明になった場合
- previous Luna runがenvironment `BLOCKED`となりhostを再構築する場合

古いhostをreuseして新しいbundleやcommitを検証したことにしない。

## Test-unit grouping

同じfixture・同じeditor state・同じ種類の操作で確認できる項目は、まとまったtest unitとして一度に実行する。

分割するのは主に次の場合:

- 結果によって次のfixture/stateが変わる
- source mutation / revertが必要
- failureが後続判定を無効にする
- source close / dispose等の破壊的操作を最後へ分離する必要がある

completion testでは、自動popupの有無だけに依存せず、必要に応じて`Trigger Suggest`を明示実行してnuinuiCAD providerの候補を確認する。

## Profile-dependent tests

通常user profileでのみ再現する問題は、isolated environmentのManual E2E failureと混同しない。profile / interoperability固有の別問題として扱う。

Task-specific Manual E2Eが意図的にexisting user settings / installed extensionsとのinteroperabilityを検証する場合だけ、このisolated baselineに加えて別途profile-dependent testを行う。
