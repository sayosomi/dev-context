# nuinuiCAD VS Code Manual E2E environment

## Purpose

VS Code extensionのuser-facing behaviorをManual E2Eで確認するときの**isolated Extension Development Host baseline**を定義する。

- test unitの`Judgment` / `Executor`分類、PASS / FAIL / BLOCKED、Sol Highの結果判定は [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。
- Lunaを安定して操作させるprompt構成、stable test ref、evidence、known pitfallsは [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md) を使う。
- この文書はVS Code production-hostのisolation / launch baselineをownerとする。

## Baseline

Manual E2Eでは、普段使いのVS Code profileをそのまま使わない。

標準環境:

- fresh `--user-data-dir`
- empty `--extensions-dir`
- VS Code built-in completion OFF
- task-specific fixtureをcheckout外へ生成
- current checkoutで`npm run build:vscode`
- 必要なhost-neutral Rust `evaluation_stdio` binaryをcurrent checkoutの`rust-evaluator` crateからbuild
- `NUINUICAD_RUST_EVALUATION_BINARY`でexact binaryを明示
- `--extensionDevelopmentPath="$PWD/vscode-extension"`
- `--disable-workspace-trust`
- welcome / sessions welcome / release notesを抑止
- repository workspace folderへ依存せずfixture fileを直接open

通常user settings、word-based suggestions、inline suggestions、keybindings、installed extensions等が結果へ混入すると、nuinuiCAD extension自体のPASS / FAILを判定できない。

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
- 起動command block内でfixtureを作り、そのfileを起動時に明示的にopenする。
- Luna向けfixtureはcurrent runだけに対応するunique filename / identityを持たせ、古いE2E hostやfixtureと客観的に区別できるようにする。
- fixture/state/action/oracleはcurrent IssueのManual E2E planをauthorityとする。

## Luna dedicated-machine process isolation

Luna Manual E2Eを実行するmacOS machineでは、実行中に他用途でVS Codeを使用しないことを前提とする。

Luna run開始前に既存のVisual Studio Code processをすべて終了し、0 processであることを確認してからfresh isolated hostを起動する。通常終了後も残るstale Extension Development Host / helper processがある場合はforce terminationしてよい。

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

Luna run終了時も同じprocess cleanupを行う。Human Manual E2Eや、他用途のVS Code sessionを意図的に共存させるtestにはこの全process kill ruleを機械的に適用しない。

## Canonical launch shape

Taskごとのfixture sourceを差し替えて使う。

```bash
cd <nuinuiCAD checkout>

npm run build:vscode
cargo build --manifest-path rust-evaluator/Cargo.toml --bin evaluation_stdio

RUST_BIN="$PWD/rust-evaluator/target/debug/evaluation_stdio"
test -x "$RUST_BIN"
test -f "$PWD/vscode-extension/dist/extension.js"

E2E_ROOT="$(mktemp -d /tmp/nuinui-vscode-e2e.XXXXXX)"
mkdir -p "$E2E_ROOT/user-data/User" "$E2E_ROOT/extensions"

cat > "$E2E_ROOT/user-data/User/settings.json" <<'EOF'
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
EOF

cat > "$E2E_ROOT/<task-fixture>.nui" <<'EOF'
<task-specific fixture source>
EOF

CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [ ! -x "$CODE_BIN" ]; then
  CODE_BIN="$(command -v code || true)"
fi
test -n "$CODE_BIN"
test -x "$CODE_BIN"

NUINUICAD_RUST_EVALUATION_BINARY="$RUST_BIN" \
"$CODE_BIN" --new-window \
  --user-data-dir="$E2E_ROOT/user-data" \
  --extensions-dir="$E2E_ROOT/extensions" \
  --extensionDevelopmentPath="$PWD/vscode-extension" \
  --skip-welcome \
  --skip-sessions-welcome \
  --skip-release-notes \
  --disable-workspace-trust \
  "$E2E_ROOT/<task-fixture>.nui"
```

macOSでshellの`code` commandがunavailableでも、app bundle内のexecutableを直接使う。task-specific requirementが追加される場合も、fresh profile、empty extensions、built-in completion OFF、explicit dev extension path、workspace trust無効化、fixture-only openをbaselineとして維持する。

`evaluation_stdio`のowner/pathはlatest repositoryをauthorityとする。上の`rust-evaluator` pathはcurrent canonical ownerであり、過去の`src-tauri/Cargo.toml` / `src-tauri/target/debug/evaluation_stdio`を古いpromptから流用しない。

## Luna Playwright / CDP launch additions

VS Code production-hostの`Executor: Luna` objective testでは、Playwrightから操作 / 観測できるsurfaceはComputer UseよりPlaywright/CDPを優先する。

canonical launchへdedicated CDP portを追加する。current VS Code 1.134系で実走確認済みのlocal CDP pathでは`--remote-allow-origins=*`も付ける。

```bash
CDP_PORT=9223

if lsof -nP -iTCP:"$CDP_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "BLOCKED — CDP port already in use"
  exit 1
fi

NUINUICAD_RUST_EVALUATION_BINARY="$RUST_BIN" \
"$CODE_BIN" --new-window \
  --user-data-dir="$E2E_ROOT/user-data" \
  --extensions-dir="$E2E_ROOT/extensions" \
  --extensionDevelopmentPath="$PWD/vscode-extension" \
  --remote-debugging-port="$CDP_PORT" \
  '--remote-allow-origins=*' \
  --skip-welcome \
  --skip-sessions-welcome \
  --skip-release-notes \
  --disable-workspace-trust \
  "$E2E_ROOT/<task-fixture>.nui"
```

`--enable-smoke-test-driver`等、通常のVS Code Extension Development Host pathを別test harnessへ変えるflagはTask contractが明示しない限り追加しない。

### CDP readiness / bounded retry

CDP endpointは起動直後に即readyとは限らない。Luna runではproduct testへ入る前に最大約60秒までreadyをpollしてよい。

標準目安:

```bash
for _ in $(seq 1 120); do
  if curl --max-time 1 -fsS \
    "http://127.0.0.1:${CDP_PORT}/json/version" \
    > "$E2E_ROOT/evidence/cdp-version.json"; then
    break
  fi
  sleep 0.5
done
```

最初のfresh launchが60秒以内にCDPを公開しなかった場合はproduct `FAIL`にしない。

1. launch stdout / stderr、CLI exit、VS Code process一覧、port listener、fresh profile logsをevidenceへ保存する。
2. VS Code processをすべてcleanupする。
3. 同じprofileをreuseせず、新しいfresh `--user-data-dir` / empty `--extensions-dir`で**1回だけ**launch retryしてよい。
4. 2回目もCDP endpointを確立できなければenvironment `BLOCKED`。

bounded retryをproduct behaviorのretryやfailure repairへ拡張しない。

### Persistent PTY launch-lifetime fallback

macOSのCodex/runner環境では、VS Code launch command自体が正しくても、one-shot shell/runner sessionの終了に引きずられてGUI processまたはCDP listenerのlifetimeが不安定になる場合がある。SAY-188 calibrationでは、同じGUI binary / launch argumentsをpersistent PTY内で保持することでfresh isolated hostのlifetimeが安定した実走例がある。

このfallbackは**runner process lifetimeのenvironment対策**であり、nuinuiCAD product requirementでも全runのbaseline requirementでもない。

使ってよい条件:

- canonical launch args / env / exact tested stateは変更しない;
- one-shot runner側のprocess lifetimeが原因と合理的に見える;
- product actionをまだretryしていないlaunch/preflight段階である;
- PTY内でも同じCDP readiness / fresh profile / process isolation ruleを使う。

PTYを使った場合はresultへ記録する。PTYでもbounded launch procedure後にhostを確立できなければenvironment `BLOCKED`。

### macOS permission prompt / unattended launch pitfall

Codex Desktop / ChatGPT.appからmacOS上のVS Code launchを行うと、OSのApp Data / privacy permission promptがlaunchを止める場合がある。SAY-158実走では、`code` invocation後にVS Code processもCDP listenerも残らずlaunch logも空、という形で現れ、permissionを許可してCodex Desktopをrestartした後は同じisolated launchがunattendedで成功した。

この症状ではproduct FAILや「VS Codeは起動不能」と即断しない。

1. macOS側にpending permission promptがないか確認する。
2. current machine policyで許可されるexpected promptなら、そのenvironment permissionを解消してhost appをrestartする。
3. その後、通常のbounded fresh-profile retryを行う。

Full Disk AccessをすべてのLuna E2Eのbaseline requirementとして先回りで要求しない。permission stateはmachine/environment固有であり、必要性が実際に確認された場合だけenvironment setupとして扱う。

## Extension-registration preflight

Luna実行ではproduct unitへ入る前にenvironment preflightを行う。

最低限:

1. current runのunique `.nui` fixtureをactiveにする。
2. language modeが`nui` / nuinuiCADでありPlain Textでないことを確認する。
3. current testに必要なcontributed nuinuiCAD commandを、**そのcommandのdeclared Palette scopeに含まれるsurfaceをactiveにして**Command Paletteで確認する。
4. Playwright/CDP runでは、接続先workbenchがcurrent runのunique fixtureを含むことを客観的に確認する。
5. 必要ならRunning Extensions / fresh profile logsも確認する。

command registration確認はsurface-awareに行う。Sourceから使う`Open Canvas` / `Open Output Preview`等はSource active時に確認できる。一方、Canvas-only commandをSource active時に要求しない。SAY-158実走では`Fit Drawing`をSource preflightで必須にしたことがfalse blockerになり、Canvasを開いた後の確認が正しかった。

preflight失敗はproduct FAILではなくenvironment `BLOCKED`。

## Relaunch rule

次の場合、古いExtension Development Hostを閉じてfresh isolated hostを起動し直す。

- `npm run build:vscode`をやり直した後
- branch / commitを切り替えた後
- blocking fix後の再試験
- fresh profile stateが壊れた、またはinitial stateが不明になった場合

Luna dedicated-machine runでは「古いhostを見分けてreuseする」のではなく、開始前にVS Codeを0 processへ戻してからfresh hostを1つだけ起動する。

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
