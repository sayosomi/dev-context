# nuinuiCAD VS Code locale-specific Manual E2E

## Purpose

VS Code Extension Development Hostで**display language / localeそのものを確認するManual E2E**が必要な場合だけ読む補助文書。

通常のManual E2Eではこの文書をloadしない。

Authority / baseline:

- Manual E2EのJudgment / Executor / PASS-FAIL-BLOCKEDは [`MANUAL-E2E.md`](./MANUAL-E2E.md)。
- 通常のisolated Extension Development Host baselineは [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)。
- versioned helperのavailability / fallback / repairは [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)。
- この文書はlocale-specific host preparation / launch / cleanupだけを補足する。

この文書はcanonical E2E lane lifecycleを置き換えない。`e2e-start` / `e2e-release`、helper-managed session、tested ref fixation等は既存owner documentに従う。

## Load condition

次のいずれかをtest oracleが要求する場合だけloadする。

- Japanese UI等、VS Code自体のdisplay languageを固定した確認
- translated command / menu / Quick Pick / descriptionの確認
- locale固有の検索語、表示、interactionの確認

単にnuinuiCAD product textを確認するだけで、VS Code hostのdisplay languageを変える必要がない場合はloadしない。

## Isolation rule

locale-specific runでも普段使いのVS Code profileを使わない。

必須:

- exact tested checkout / commit
- fresh `--user-data-dir`
- isolated `--extensions-dir`
- task-specific fixtureをcheckout外へ配置
- `--extensionDevelopmentPath=<tested checkout>/vscode-extension`
- tested checkoutのRust evaluatorを `NUINUICAD_RUST_EVALUATION_BINARY` で固定
- locale-specific language packをisolated extensions directoryへinstall
- host起動時にlocaleをcommand lineで固定
- locale host専用のroot / stateを記録し、終了時にそのrootへ属するprocessだけをcleanup

普段使いのVS Code process / profileをlocale E2E cleanupの対象にしない。

## Important pitfall: GUI restartを使わない

Extension Development Host内で `Configure Display Language` / `表示言語の構成` からlanguageを選び、GUIのRestartを使う方法をlocale E2Eの標準手順にしない。

isolated hostは起動時の `--user-data-dir` / `--extensions-dir` / `--extensionDevelopmentPath` 等でidentityを固定している。GUI restartではそのexact launch contractを維持できず、通常のVS Codeへ戻ることがあるため、test environment identityを失う。

localeは**host起動時から**固定する。

## Currently validated Japanese launch

2026-09-03にmacOS上で実際に確認できたJapanese host launch contract:

- VS Code application: `/Applications/Visual Studio Code.app`
- Japanese language pack: `MS-CEINTL.vscode-language-pack-ja`
- runtime locale: `--locale=ja`
- application executable: `Visual Studio Code.app/Contents/MacOS/<CFBundleExecutable>`

`CFBundleExecutable`は`Info.plist`から取得し、`Electron`等の名前を推測しない。

```zsh
APP="/Applications/Visual Studio Code.app"
EXEC_NAME="$(/usr/libexec/PlistBuddy \
  -c 'Print :CFBundleExecutable' \
  "$APP/Contents/Info.plist")"
APP_BIN="$APP/Contents/MacOS/$EXEC_NAME"
```

current validated appでは`APP_BIN`は次になる。

```text
/Applications/Visual Studio Code.app/Contents/MacOS/Code
```

## Reference Japanese host preparation

これはlocale-specific operationをcurrent versioned helperがsupportしていない場合のreference fallback。通常E2Eで毎回再生成するtemplateではない。

`<...>`はcurrent E2E runでChatGPTがlatest external stateから固定した値へ置き換える。

```zsh
(
  CHECKOUT="<exact Human-test checkout>"
  EXPECTED="<exact tested SHA>"
  SOURCE_FIXTURE="<absolute source fixture>"
  ISSUE="<SAY-123>"
  LOCALE="ja"
  LANGUAGE_PACK="MS-CEINTL.vscode-language-pack-ja"

  CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  APP="/Applications/Visual Studio Code.app"
  STATE_FILE="/private/tmp/nuinui-${ISSUE}-locale-e2e.env"

  [[ "$(git -C "$CHECKOUT" rev-parse HEAD 2>/dev/null)" == "$EXPECTED" ]] || {
    echo "BLOCKED: E2E checkout is not at the tested ref"
    exit 1
  }

  [[ -z "$(git -C "$CHECKOUT" status --porcelain)" ]] || {
    echo "BLOCKED: E2E checkout is dirty"
    git -C "$CHECKOUT" status --short
    exit 1
  }

  [[ -f "$SOURCE_FIXTURE" ]] || {
    echo "BLOCKED: source fixture is missing"
    exit 1
  }

  [[ -x "$CODE_CLI" ]] || {
    echo "BLOCKED: VS Code CLI not found"
    exit 1
  }

  EXEC_NAME="$(/usr/libexec/PlistBuddy \
    -c 'Print :CFBundleExecutable' \
    "$APP/Contents/Info.plist" 2>/dev/null)" || {
      echo "BLOCKED: could not read CFBundleExecutable"
      exit 1
    }

  APP_BIN="$APP/Contents/MacOS/$EXEC_NAME"

  [[ -x "$APP_BIN" ]] || {
    echo "BLOCKED: VS Code application executable not found"
    echo "  expected=$APP_BIN"
    exit 1
  }

  ROOT="$(mktemp -d /private/tmp/nuinui-vscode-e2e-locale.XXXXXX)" || exit 1
  mkdir -p "$ROOT/user-data/User" "$ROOT/extensions"

  FIXTURE="$ROOT/$(basename "$SOURCE_FIXTURE")"
  cp "$SOURCE_FIXTURE" "$FIXTURE" || exit 1

  cat > "$ROOT/user-data/User/settings.json" <<'EOF'
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
EOF

  "$CODE_CLI" \
    --user-data-dir="$ROOT/user-data" \
    --extensions-dir="$ROOT/extensions" \
    --install-extension "$LANGUAGE_PACK" \
    --force || {
      echo "BLOCKED: locale language pack installation failed"
      rm -rf -- "$ROOT"
      exit 1
    }

  RUST_BIN="$CHECKOUT/rust-evaluator/target/debug/evaluation_stdio"

  [[ -x "$RUST_BIN" ]] || {
    echo "BLOCKED: tested Rust evaluator is missing"
    rm -rf -- "$ROOT"
    exit 1
  }

  [[ -f "$CHECKOUT/vscode-extension/dist/extension.js" ]] || {
    echo "BLOCKED: tested VS Code extension build artifact is missing"
    rm -rf -- "$ROOT"
    exit 1
  }

  NUINUICAD_RUST_EVALUATION_BINARY="$RUST_BIN" \
    "$APP_BIN" \
      --locale="$LOCALE" \
      --new-window \
      --user-data-dir="$ROOT/user-data" \
      --extensions-dir="$ROOT/extensions" \
      --extensionDevelopmentPath="$CHECKOUT/vscode-extension" \
      --skip-welcome \
      --skip-sessions-welcome \
      --skip-release-notes \
      --disable-workspace-trust \
      "$FIXTURE" \
      >"/private/tmp/nuinui-${ISSUE}-locale-vscode.log" 2>&1 &

  PID=$!

  {
    echo "ROOT=$ROOT"
    echo "PID=$PID"
    echo "LOCALE=$LOCALE"
  } > "$STATE_FILE"

  echo "LOCALE E2E HOST LAUNCHED"
  echo "  locale=$LOCALE"
  echo "  root=$ROOT"
  echo "  fixture=$FIXTURE"
  echo "  pid=$PID"
  echo "  state=$STATE_FILE"
)
```

起動後、Humanはproduct testを始める前に最低限次を確認する。

- windowがExtension Development Hostである
- task fixtureが開いている
- VS Code chrome / Command Palette等がrequested localeになっている

requested localeになっていなければproduct FAILにせずenvironment setup failureとして停止する。

## Cleanup rule

locale-specific fallback hostはcanonical `e2e-release` / final closureより前に必ずcleanupする。

cleanupではrecorded parent PIDだけに依存しない。Electron child processが残る場合があるため、**recorded ROOTの`user-data`をcommand lineに持ち、かつVisual Studio Code.app配下のprocessであること**をownership proofにする。

Humanが先にwindowを閉じた場合、process enumerationからownership確認までの間にprocessが消えることがある。`ps`結果が空になったPIDは正常なraceとして無視し、ownership mismatch扱いにしない。

reference cleanup:

```zsh
(
  ISSUE="<SAY-123>"
  STATE_FILE="/private/tmp/nuinui-${ISSUE}-locale-e2e.env"

  [[ -f "$STATE_FILE" ]] || {
    echo "BLOCKED: locale E2E state file is missing"
    exit 1
  }

  ROOT="$(awk -F= '$1=="ROOT"{print substr($0,6)}' "$STATE_FILE")"

  [[ "$ROOT" == /private/tmp/nuinui-vscode-e2e-locale.* ]] || {
    echo "BLOCKED: unexpected locale E2E root"
    echo "  root=$ROOT"
    exit 1
  }

  PIDS="$({
    ps -axo pid=,command= |
      awk -v root="$ROOT/user-data" '
        index($0, root) &&
        index($0, "/Applications/Visual Studio Code.app/Contents/") {
          print $1
        }
      '
  })"

  for PID in ${(f)PIDS}; do
    [[ -z "$PID" ]] && continue

    CMD="$(ps -ww -p "$PID" -o command= 2>/dev/null || true)"

    # The process may have exited after enumeration.
    [[ -z "$CMD" ]] && continue

    if [[ "$CMD" == *"$ROOT/user-data"* &&
          "$CMD" == *"/Applications/Visual Studio Code.app/Contents/"* ]]; then
      kill "$PID" 2>/dev/null || true
    else
      echo "BLOCKED: unexpected live process"
      echo "  pid=$PID"
      echo "  command=$CMD"
      exit 1
    fi
  done

  sleep 1

  REMAINING="$({
    ps -axo pid=,command= |
      awk -v root="$ROOT/user-data" '
        index($0, root) &&
        index($0, "/Applications/Visual Studio Code.app/Contents/") {
          print
        }
      '
  })"

  if [[ -n "$REMAINING" ]]; then
    echo "BLOCKED: locale E2E VS Code processes remain"
    echo "$REMAINING"
    exit 1
  fi

  rm -rf -- "$ROOT"
  rm -f -- \
    "$STATE_FILE" \
    "/private/tmp/nuinui-${ISSUE}-locale-vscode.log"

  echo "LOCALE E2E CLEANUP COMPLETE"
  echo "  root=$ROOT"
)
```

Do not:

- `pkill` / `killall` all VS Code processes for a Human locale E2E cleanup;
- delete a root whose path does not match the recorded locale-E2E namespace;
- infer root from `/private/tmp` search when a state file exists;
- run canonical `e2e-release` while the locale fallback host/root is still live.

## Known non-baseline approaches

次はlocale E2Eの標準手順にしない。

- Extension Development Host内でdisplay languageを選び、そのwindowからRestartする。
- custom `--user-data-dir`配下へ`argv.json`を書くだけでlocale切替を期待する。
- `/Contents/MacOS/Electron`等、application executable名を推測する。
- normal VS Code profileへlanguage pack / locale変更を入れて代用する。

## Future helper direction

locale-specific host preparationが繰り返し必要になる場合、手書きfallbackを恒久運用せずversioned `nuinui-e2e-prepare`へ昇格する。

望ましいpublic contract例:

```text
nuinui-e2e-prepare prepare <human-test-lane> <SAY-123> <tested-ref> <fixture> [port] --locale ja
```

helper化する場合は少なくとも次を一体管理する。

- locale -> required language pack resolution
- isolated language-pack installation
- direct application executable resolution
- `--locale=<locale>` launch
- localeを含むsession identity / status evidence
- canonical cleanup / closure proof
- existing non-locale `prepare`とのbackward compatibility

actual helper contract / version / promotion lifecycleは [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) がownerする。
