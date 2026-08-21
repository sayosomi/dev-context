# nuinuiCAD VS Code Manual E2E environment

## Purpose

VS Code extensionのuser-facing behaviorをManual E2Eで確認するときの**isolated Extension Development Host baseline**を定義する。

- test unitの`Judgment` / `Executor`分類、PASS / FAIL / BLOCKED、Sol Highの結果判定は [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。
- Lunaを安定して操作させるprompt構成、stable test ref、evidence、known pitfallsは [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md) を使う。
- この文書はhost/environment setupだけをownerとする。

## Baseline

Manual E2Eでは、普段使いのVS Code profileをそのまま使わない。

標準環境:

- fresh `--user-data-dir`
- empty `--extensions-dir`
- VS Code built-in completion OFF
- task-specific fixtureをcheckout外へ生成
- current checkoutで`npm run build:vscode`
- 必要なRust `evaluation_stdio` binaryをcurrent checkoutからbuild
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
- multi-document testではA/BをUI上で客観的に区別できる名前やoutput identityをfixtureへ入れる。
- fixture/state/action/oracleはcurrent IssueのManual E2E planをauthorityとする。

## Canonical launch shape

Taskごとのfixture sourceを差し替えて使う。

```bash
cd <nuinuiCAD checkout>

npm run build:vscode
cargo build --manifest-path src-tauri/Cargo.toml --bin evaluation_stdio

RUST_BIN="$PWD/src-tauri/target/debug/evaluation_stdio"
test -x "$RUST_BIN"
test -f "$PWD/vscode-extension/dist/extension.js"
test -f "$PWD/vscode-extension/package.json"
test -f "$PWD/vscode-extension/language-configuration.json"
test -f "$PWD/vscode-extension/syntaxes/nui.tmLanguage.json"

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
"$CODE_BIN" --version

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

## Extension-registration preflight

Luna実行ではproduct unitへ入る前にenvironment preflightを行う。

最低限:

1. `.nui` fixtureをactiveにする。
2. language modeが`nui` / nuinuiCADでありPlain Textでないことを確認する。
3. current testに必要なcontributed nuinuiCAD commandがCommand Paletteへ登録されていることを確認する。
4. 必要ならRunning Extensions / fresh profile logsも確認する。

preflight失敗はproduct FAILではなくenvironment `BLOCKED`。

## Relaunch rule

次の場合、古いExtension Development Hostを閉じてfresh isolated hostを起動し直す。

- `npm run build:vscode`をやり直した後
- branch / commitを切り替えた後
- blocking fix後の再試験
- fresh profile stateが壊れた、またはinitial stateが不明になった場合

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
