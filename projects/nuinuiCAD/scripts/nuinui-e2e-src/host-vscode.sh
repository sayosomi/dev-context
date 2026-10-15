# Inactive VS Code host adapter. Runtime artifacts come from a verified
# immutable dogfood snapshot; this source never builds inside the product tree.

nuinui_e2e_host_vscode__valid_text() {
  [ "$#" = 1 ] || return 2
  python3 - "$1" <<'PY'
import sys
value = sys.argv[1]
raise SystemExit(1 if any(ord(character) < 32 or ord(character) == 127 for character in value) else 0)
PY
}

nuinui_e2e_host_vscode__fake_launcher_content() {
  printf '#!/usr/bin/env node\n'
  cat <<'JS'
const fs = require("node:fs");
const http = require("node:http");
const portArg = process.argv.slice(2).find(value => value.startsWith("--remote-debugging-port="));
const extensionPathArg = process.argv.slice(2).find(value => value.startsWith("--extensionDevelopmentPath="));
const rust = process.env.NUINUICAD_RUST_EVALUATION_BINARY || "";
const rustStat = rust ? fs.statSync(rust, { throwIfNoEntry: false }) : undefined;
const fixturePath = process.argv[process.argv.length - 1];
const extensionPath = extensionPathArg ? extensionPathArg.slice("--extensionDevelopmentPath=".length) : "";
const extensionStat = extensionPath ? fs.statSync(extensionPath, { throwIfNoEntry: false }) : undefined;
const fixtureStat = fixturePath ? fs.statSync(fixturePath, { throwIfNoEntry: false }) : undefined;
if (!portArg || !extensionStat || !extensionStat.isDirectory() ||
    !fixtureStat || !fixtureStat.isFile() || !rustStat || !rustStat.isFile() ||
    (rustStat.mode & 0o111) === 0) {
  process.exitCode = 1;
  process.exit();
}
const port = Number(portArg.split("=", 2)[1]);
const userDataArg = process.argv.slice(2).find(value => value.startsWith("--user-data-dir="));
const extensionsArg = process.argv.slice(2).find(value => value.startsWith("--extensions-dir="));
const cdpKind = process.env.NUINUI_E2E_TEST_CDP_KIND || "fake";
if (!userDataArg || !extensionsArg || !["fake", "electron"].includes(cdpKind)) {
  process.exitCode = 1;
  process.exit();
}
const userData = userDataArg.slice("--user-data-dir=".length);
const extensions = extensionsArg.slice("--extensions-dir=".length);
const writeProfileFile = (base, relative, content) => {
  const path = require("node:path");
  const file = path.join(base, relative);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content, { flag: "wx", mode: 0o600 });
};
writeProfileFile(userData, "User/globalStorage/state.vscdb", "disposable global storage\n");
writeProfileFile(userData, "User/workspaceStorage/fixture-workspace/workspace.json", "{}\n");
writeProfileFile(userData, "logs/2026-10-13/window1/exthost/extension.log", "disposable extension log\n");
writeProfileFile(userData, "CachedData/disposable/session.json", "{}\n");
writeProfileFile(extensions, "extensions.json", "[]\n");
writeProfileFile(extensions, "publisher.extension-1.0.0/package.json", "{}\n");
const server = http.createServer((request, response) => {
  if (request.url !== "/json/version") {
    response.writeHead(404);
    response.end();
    return;
  }
  const body = JSON.stringify(cdpKind === "fake" ? {
    Browser: "FakeVSCode/1.0",
    "Protocol-Version": "1.3",
    webSocketDebuggerUrl: `ws://127.0.0.1:${port}/devtools/browser/disposable`,
  } : {
    Browser: "Chrome/134.0.6998.205",
    "Protocol-Version": "1.3",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.205 Electron/35.1.5 Safari/537.36",
    "V8-Version": "13.5.212.10-electron.0",
    "WebKit-Version": "537.36 (@disposable)",
    webSocketDebuggerUrl: `ws://127.0.0.1:${port}/devtools/browser/disposable-electron`,
  });
  response.writeHead(200, { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body) });
  response.end(body);
});
server.listen(port, "127.0.0.1");
JS
}

nuinui_e2e_host_vscode__fake_launcher_sha() {
  nuinui_e2e_host_vscode__fake_launcher_content | shasum -a 256 | awk 'NR == 1 {print $1}'
}

nuinui_e2e_host_vscode__snapshot_info() {
  [ "$#" = 3 ] || return 2
  python3 - "$1" "$2" "$3" <<'PY'
import hashlib, json, os, platform, stat, sys
root, tested, expected_identity = sys.argv[1:]
metadata_path = os.path.join(root, "snapshot.json")
def fail(message):
    raise SystemExit("BLOCKED: " + message)
def regular(path):
    try: s = os.lstat(path)
    except OSError: return False
    return stat.S_ISREG(s.st_mode)
def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""): h.update(block)
    return h.hexdigest()
def safe(path):
    return (isinstance(path, str) and path and not path.startswith("/") and
            "\\" not in path and all(part not in ("", ".", "..") for part in path.split("/")))
try:
    if os.path.islink(root) or not os.path.isdir(root): fail("prepared artifact snapshot root is not a real directory")
    if not regular(metadata_path): fail("prepared artifact snapshot metadata is missing or unsafe")
    with open(metadata_path, encoding="utf-8") as stream: meta = json.load(stream)
except (OSError, ValueError) as error:
    fail(f"prepared artifact snapshot cannot be read: {error}")
keys = {"schemaVersion", "identity", "gitSha", "platform", "architecture", "extensionPath", "evaluatorPath", "files"}
if not isinstance(meta, dict) or set(meta) != keys or meta.get("schemaVersion") != 1:
    fail("prepared artifact snapshot schema is not exact")
if meta.get("gitSha") != tested or meta.get("identity") != expected_identity:
    fail("prepared artifact snapshot does not match the exact tested SHA")
machine = platform.machine()
architecture = {"x86_64": "x64", "aarch64": "arm64"}.get(machine, machine)
if meta.get("platform") != "darwin" or meta.get("architecture") != architecture:
    fail("prepared artifact snapshot platform or architecture does not match this Mac")
if meta.get("extensionPath") != "extension" or meta.get("evaluatorPath") != "bin/evaluation_stdio":
    fail("prepared artifact snapshot runtime paths are unsupported")
files = meta.get("files")
if not isinstance(files, dict) or not files or list(files) != sorted(files):
    fail("prepared artifact snapshot file manifest is empty or non-deterministic")
required = {
    "extension/package.json", "extension/language-configuration.json",
    "extension/dist/extension.js", "extension/dist/webview.js",
    "extension/dist/webview.css", "bin/evaluation_stdio"
}
if not required.issubset(files): fail("prepared artifact snapshot is missing a required runtime artifact")
allowed = lambda p: (
    p == "bin/evaluation_stdio" or
    p.startswith("extension/") and (
        p in {"extension/package.json", "extension/language-configuration.json",
              "extension/dist/extension.js", "extension/dist/webview.js", "extension/dist/webview.css"} or
        p.startswith("extension/syntaxes/") or p.startswith("extension/media/") or
        p.startswith("extension/package.nls") and p.endswith(".json")
    )
)
if any(not safe(path) or not allowed(path) or not isinstance(value, str) or
       len(value) != 64 or any(c not in "0123456789abcdef" for c in value)
       for path, value in files.items()):
    fail("prepared artifact snapshot manifest contains an invalid path or digest")
if not any(path.startswith("extension/syntaxes/") for path in files):
    fail("prepared extension bundle is missing syntax resources")
actual_files, actual_dirs = [], []
for current, dirs, names in os.walk(root, followlinks=False):
    for name in list(dirs):
        path = os.path.join(current, name)
        if os.path.islink(path): fail("prepared artifact snapshot contains a symbolic link")
        actual_dirs.append(os.path.relpath(path, root).replace(os.sep, "/"))
    for name in names:
        path = os.path.join(current, name)
        if os.path.islink(path) or not regular(path): fail("prepared artifact snapshot contains an unsafe file")
        actual_files.append(os.path.relpath(path, root).replace(os.sep, "/"))
actual_files.sort(); actual_dirs.sort()
expected_files = sorted(list(files) + ["snapshot.json"])
expected_dirs = sorted({"/".join(p.split("/")[:i]) for p in expected_files
                        for i in range(1, len(p.split("/")))})
if actual_files != expected_files or actual_dirs != expected_dirs:
    fail("prepared artifact snapshot tree differs from its exact manifest")
for relative, expected in files.items():
    if digest(os.path.join(root, *relative.split("/"))) != expected:
        fail(f"prepared artifact content hash mismatch: {relative}")
package_path = os.path.join(root, "extension", "package.json")
try:
    with open(package_path, encoding="utf-8") as stream: package = json.load(stream)
except (OSError, ValueError) as error:
    fail(f"prepared extension package is invalid: {error}")
if not isinstance(package, dict) or package.get("main") != "./dist/extension.js":
    fail("prepared extension bundle has an unexpected entry point")
if not any(path.startswith("extension/syntaxes/") for path in files):
    fail("prepared extension package has no syntax resources")
rust_path = os.path.join(root, "bin", "evaluation_stdio")
if not os.access(rust_path, os.X_OK): fail("prepared Rust evaluation_stdio binary is not executable")
identity = meta["identity"]
extension_items = [(p, files[p]) for p in sorted(files) if p.startswith("extension/")]
extension_hash = hashlib.sha256("".join(f"{p}={h}\n" for p, h in extension_items).encode()).hexdigest()
root_stat = os.stat(root, follow_symlinks=False)
print("snapshot_identity=" + identity)
print("snapshot_sha256=" + digest(metadata_path))
print("snapshot_identity_stat=" + f"{root_stat.st_dev}:{root_stat.st_ino}")
print("extension_path=" + os.path.join(root, "extension"))
print("extension_sha256=" + extension_hash)
print("rust_binary_path=" + rust_path)
print("rust_binary_sha256=" + files["bin/evaluation_stdio"])
PY
}

nuinui_e2e_host_vscode__app_info() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_app_root=$1
  nuinui_e2e_vscode_test_app=no
  nuinui_e2e_vscode_test_app_mode=direct
  [ -d "$nuinui_e2e_vscode_app_root" ] && [ ! -L "$nuinui_e2e_vscode_app_root" ] || return 1
  nuinui_e2e_vscode_app_root=$(realpath "$nuinui_e2e_vscode_app_root" 2>/dev/null) || return 1
  nuinui_e2e_vscode_info=$nuinui_e2e_vscode_app_root/Contents/Info.plist
  nuinui_e2e__regular "$nuinui_e2e_vscode_info" || return 1
  [ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "$nuinui_e2e_vscode_info" 2>/dev/null)" = com.microsoft.VSCode ] || return 1
  nuinui_e2e_vscode_app_executable=$(/usr/libexec/PlistBuddy \
    -c 'Print :CFBundleExecutable' "$nuinui_e2e_vscode_info" 2>/dev/null) || return 1
  case "$nuinui_e2e_vscode_app_executable" in ''|*/*|*'..'*|*' '*) return 1 ;; esac
  nuinui_e2e_host_vscode__valid_text "$nuinui_e2e_vscode_app_executable" || return 1
  nuinui_e2e_vscode_app_path=$nuinui_e2e_vscode_app_root/Contents/MacOS/$nuinui_e2e_vscode_app_executable
  nuinui_e2e__regular "$nuinui_e2e_vscode_app_path" &&
    [ -x "$nuinui_e2e_vscode_app_path" ] &&
    [ "$(realpath "$nuinui_e2e_vscode_app_path" 2>/dev/null)" = \
      "$nuinui_e2e_vscode_app_path" ] || return 1
  nuinui_e2e_vscode_app_sha=$(nuinui_e2e__sha256 \
    "$nuinui_e2e_vscode_app_path") || return 1
  if [ -n "${NUINUI_E2E_TEST_VSCODE_APP_ROOT:-}" ]; then
    [ "$nuinui_e2e_self_test" = yes ] || return 1
    nuinui_e2e_vscode_test_app_real=$(realpath \
      "$NUINUI_E2E_TEST_VSCODE_APP_ROOT" 2>/dev/null) || return 1
    case "$nuinui_e2e_vscode_test_app_real" in
      "$nuinui_e2e_fixture_root"/*) ;;
      *) return 1 ;;
    esac
    nuinui_e2e_vscode_test_app_mode=${NUINUI_E2E_TEST_VSCODE_APP_MODE:-launcher}
    case "$nuinui_e2e_vscode_test_app_mode" in
      launcher)
        [ "$nuinui_e2e_vscode_app_sha" = \
          "$(nuinui_e2e_host_vscode__fake_launcher_sha)" ] || return 1
        nuinui_e2e_vscode_fake_app=yes
        ;;
      direct)
        nuinui_e2e_valid_digest "${NUINUI_E2E_TEST_VSCODE_APP_SHA256:-}" &&
          [ "$nuinui_e2e_vscode_app_sha" = \
            "$NUINUI_E2E_TEST_VSCODE_APP_SHA256" ] || return 1
        nuinui_e2e_vscode_fake_app=no
        ;;
      *) return 1 ;;
    esac
    nuinui_e2e_vscode_test_app=yes
  else
    nuinui_e2e_vscode_fake_app=no
    command -v codesign >/dev/null 2>&1 &&
      codesign --verify --deep --strict "$nuinui_e2e_vscode_app_root" >/dev/null 2>&1 || {
        echo 'BLOCKED: Visual Studio Code code signature is missing or invalid'
        return 1
      }
    codesign -dv --verbose=4 "$nuinui_e2e_vscode_app_root" 2>&1 |
      grep -q '^TeamIdentifier=UBF8T346G9$' || {
        echo 'BLOCKED: application bundle is not signed by Microsoft'
        return 1
      }
  fi
  printf '%s\n%s\n' "$nuinui_e2e_vscode_app_path" \
    "$nuinui_e2e_vscode_app_sha"
}

nuinui_e2e_host_vscode__validate_artifacts() {
  [ "$#" = 4 ] || return 2
  nuinui_e2e_vscode_tested=$1
  nuinui_e2e_vscode_fixture=$2
  nuinui_e2e_vscode_port=$3
  nuinui_e2e_vscode_locale=$4
  [ "$(uname -s 2>/dev/null)" = Darwin ] || {
    echo 'BLOCKED: vscode-isolated adapter requires macOS'
    return 1
  }
  nuinui_e2e_host__valid_port "$nuinui_e2e_vscode_port" || {
    echo 'BLOCKED: caller-controlled CDP port must be an integer from 1 through 65535'
    return 1
  }
  case "$nuinui_e2e_vscode_locale" in default|ja) ;; *)
    echo 'BLOCKED: explicit locale must be default or ja'
    return 1 ;; esac
  case "$nuinui_e2e_vscode_fixture" in /*) ;; *) return 1 ;; esac
  nuinui_e2e_host_vscode__valid_text "$nuinui_e2e_vscode_fixture" || return 1
  nuinui_e2e__regular "$nuinui_e2e_vscode_fixture" &&
    [ "$(realpath "$nuinui_e2e_vscode_fixture" 2>/dev/null)" = \
      "$nuinui_e2e_vscode_fixture" ] || {
        echo 'BLOCKED: task fixture must be a canonical regular file outside the tested checkout'
        return 1
      }
  case "$nuinui_e2e_vscode_fixture" in "$nuinui_e2e_checkout"/*) return 1 ;; esac
  nuinui_e2e_vscode_fixture_sha=$(nuinui_e2e__sha256 \
    "$nuinui_e2e_vscode_fixture") || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_vscode_fixture_sha" || return 1

  if [ -n "${NUINUI_E2E_TEST_DOGFOOD_ROOT:-}" ]; then
    [ "$nuinui_e2e_self_test" = yes ] || return 1
    [ -d "$NUINUI_E2E_TEST_DOGFOOD_ROOT" ] &&
      [ ! -L "$NUINUI_E2E_TEST_DOGFOOD_ROOT" ] || return 1
    nuinui_e2e_vscode_dogfood_root=$(realpath \
      "$NUINUI_E2E_TEST_DOGFOOD_ROOT" 2>/dev/null) || return 1
    [ "$nuinui_e2e_vscode_dogfood_root" = "$NUINUI_E2E_TEST_DOGFOOD_ROOT" ] || return 1
    case "$nuinui_e2e_vscode_dogfood_root" in
      "$nuinui_e2e_fixture_root"/*) ;;
      *) echo 'BLOCKED: test dogfood root is outside the verified disposable fixture'; return 1 ;;
    esac
  else
    nuinui_e2e_vscode_dogfood_root=${HOME:?}/.nuinuicad/dogfood
    [ -d "$nuinui_e2e_vscode_dogfood_root" ] &&
      [ ! -L "$nuinui_e2e_vscode_dogfood_root" ] || return 1
    [ "$(realpath "$nuinui_e2e_vscode_dogfood_root" 2>/dev/null)" = \
      "$nuinui_e2e_vscode_dogfood_root" ] || {
        echo 'BLOCKED: prepared dogfood root is missing, symlinked, or non-canonical'
        return 1
      }
  fi
  nuinui_e2e_vscode_current=$nuinui_e2e_vscode_dogfood_root/current.json
  nuinui_e2e__regular "$nuinui_e2e_vscode_current" || {
    echo 'BLOCKED: prepared artifact selection is missing or unsafe'
    return 1
  }
  case "$(uname -m)" in
    x86_64) nuinui_e2e_vscode_architecture=x64 ;;
    aarch64|arm64) nuinui_e2e_vscode_architecture=arm64 ;;
    *) nuinui_e2e_vscode_architecture=unknown ;;
  esac
  nuinui_e2e_vscode_expected_identity=$nuinui_e2e_vscode_tested-darwin-$nuinui_e2e_vscode_architecture
  nuinui_e2e_vscode_selected=$(python3 - "$nuinui_e2e_vscode_current" \
    "$nuinui_e2e_vscode_expected_identity" <<'PY'
import json, os, stat, sys
path, expected = sys.argv[1:]
try:
    if stat.S_ISLNK(os.lstat(path).st_mode): raise ValueError("symbolic link")
    with open(path, encoding="utf-8") as stream: data = json.load(stream)
except (OSError, ValueError) as error:
    raise SystemExit("BLOCKED: prepared artifact selection is invalid: " + str(error))
if not isinstance(data, dict) or set(data) != {"schemaVersion", "identity"} or data["schemaVersion"] != 1 or data["identity"] != expected:
    raise SystemExit("BLOCKED: prepared dogfood selection does not name the exact tested SHA and Mac")
print(data["identity"])
PY
  ) || return 1
  [ "$nuinui_e2e_vscode_selected" = "$nuinui_e2e_vscode_expected_identity" ] || return 1
  nuinui_e2e_vscode_snapshot=$nuinui_e2e_vscode_dogfood_root/snapshots/$nuinui_e2e_vscode_selected
  [ "$(realpath "$nuinui_e2e_vscode_snapshot" 2>/dev/null)" = \
    "$nuinui_e2e_vscode_snapshot" ] || {
      echo 'BLOCKED: selected prepared artifact snapshot is missing or non-canonical'
      return 1
    }
  nuinui_e2e_vscode_snapshot_rows=$(nuinui_e2e_host_vscode__snapshot_info \
    "$nuinui_e2e_vscode_snapshot" "$nuinui_e2e_vscode_tested" \
    "$nuinui_e2e_vscode_selected") || return 1
  nuinui_e2e_vscode_snapshot_sha=$(printf '%s\n' \
    "$nuinui_e2e_vscode_snapshot_rows" | sed -n 's/^snapshot_sha256=//p')
  nuinui_e2e_vscode_snapshot_stat=$(printf '%s\n' \
    "$nuinui_e2e_vscode_snapshot_rows" | sed -n 's/^snapshot_identity_stat=//p')
  nuinui_e2e_vscode_extension=$(printf '%s\n' \
    "$nuinui_e2e_vscode_snapshot_rows" | sed -n 's/^extension_path=//p')
  nuinui_e2e_vscode_extension_sha=$(printf '%s\n' \
    "$nuinui_e2e_vscode_snapshot_rows" | sed -n 's/^extension_sha256=//p')
  nuinui_e2e_vscode_rust=$(printf '%s\n' \
    "$nuinui_e2e_vscode_snapshot_rows" | sed -n 's/^rust_binary_path=//p')
  nuinui_e2e_vscode_rust_sha=$(printf '%s\n' \
    "$nuinui_e2e_vscode_snapshot_rows" | sed -n 's/^rust_binary_sha256=//p')
  [ -n "$nuinui_e2e_vscode_extension" ] &&
    [ -n "$nuinui_e2e_vscode_rust" ] &&
    [ -n "$nuinui_e2e_vscode_rust_sha" ] || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_vscode_snapshot_sha" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_extension_sha" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_rust_sha" || return 1

  if [ -n "${NUINUI_E2E_TEST_VSCODE_APP_ROOT:-}" ]; then
    nuinui_e2e_vscode_app_root=$NUINUI_E2E_TEST_VSCODE_APP_ROOT
  else
    nuinui_e2e_vscode_app_root='/Applications/Visual Studio Code.app'
  fi
  nuinui_e2e_vscode_app_rows=$(nuinui_e2e_host_vscode__app_info \
    "$nuinui_e2e_vscode_app_root") || {
      echo 'BLOCKED: Visual Studio Code application executable provenance could not be verified'
      return 1
    }
  nuinui_e2e_vscode_app_path=$(printf '%s\n' "$nuinui_e2e_vscode_app_rows" | sed -n '1p')
  nuinui_e2e_vscode_app_sha=$(printf '%s\n' "$nuinui_e2e_vscode_app_rows" | sed -n '2p')
  if [ -n "${NUINUI_E2E_TEST_VSCODE_APP_ROOT:-}" ]; then
    nuinui_e2e_vscode_test_app=yes
    nuinui_e2e_vscode_test_app_mode=${NUINUI_E2E_TEST_VSCODE_APP_MODE:-launcher}
    case "$nuinui_e2e_vscode_test_app_mode" in
      launcher) nuinui_e2e_vscode_fake_app=yes ;;
      direct) nuinui_e2e_vscode_fake_app=no ;;
      *) return 1 ;;
    esac
    nuinui_e2e_vscode_cdp_kind=${NUINUI_E2E_TEST_CDP_KIND:-fake}
    case "$nuinui_e2e_vscode_cdp_kind" in fake|electron) ;; *)
      echo 'BLOCKED: test CDP response kind is unsupported'
      return 1 ;; esac
  else
    nuinui_e2e_vscode_test_app=no
    nuinui_e2e_vscode_fake_app=no
    nuinui_e2e_vscode_cdp_kind=electron
  fi
  if [ "$nuinui_e2e_vscode_fake_app" = yes ]; then
    nuinui_e2e_vscode_runtime=$(command -v node) || {
      echo 'BLOCKED: test-only Node.js runtime is unavailable for the disposable fake host'
      return 1
    }
    nuinui_e2e_vscode_runtime=$(realpath "$nuinui_e2e_vscode_runtime" 2>/dev/null) || return 1
    nuinui_e2e__regular "$nuinui_e2e_vscode_runtime" &&
      [ -x "$nuinui_e2e_vscode_runtime" ] || return 1
  else
    nuinui_e2e_vscode_runtime=$nuinui_e2e_vscode_app_path
  fi
  nuinui_e2e_vscode_artifact_root=$nuinui_e2e_vscode_dogfood_root
  nuinui_e2e_vscode_artifact_identity=$nuinui_e2e_vscode_snapshot_stat
  nuinui_e2e_vscode_artifact_snapshot=$nuinui_e2e_vscode_snapshot
  nuinui_e2e_vscode_artifact_identity_name=$nuinui_e2e_vscode_selected
  nuinui_e2e_host_vscode__configure_paths
}

nuinui_e2e_host_vscode__configure_paths() {
  nuinui_e2e_vscode_root=$(nuinui_e2e_host__root_for \
    "$nuinui_e2e_expected_generation") || return 1
  nuinui_e2e_vscode_owner=$nuinui_e2e_vscode_root/.nuinui-vscode-host-owner-v1
  nuinui_e2e_vscode_user_data=$nuinui_e2e_vscode_root/user-data
  nuinui_e2e_vscode_user_settings=$nuinui_e2e_vscode_user_data/User/settings.json
  nuinui_e2e_vscode_extensions_dir=$nuinui_e2e_vscode_root/extensions
  nuinui_e2e_vscode_workspace=$nuinui_e2e_vscode_root/fixture.nui
  nuinui_e2e_vscode_launch_args=$nuinui_e2e_vscode_root/launch-args-v1
  nuinui_e2e_vscode_cdp_evidence=$nuinui_e2e_vscode_root/cdp-response-sha256
}

nuinui_e2e_host_vscode__settings_content() {
  cat <<'SETTINGS'
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
SETTINGS
}

nuinui_e2e_host_vscode__launch_args_content() {
  printf '%s\n' \
    '--new-window' \
    "--user-data-dir=$nuinui_e2e_vscode_user_data" \
    "--extensions-dir=$nuinui_e2e_vscode_extensions_dir" \
    "--extensionDevelopmentPath=$nuinui_e2e_vscode_extension" \
    "--remote-debugging-port=$nuinui_e2e_vscode_port" \
    '--remote-allow-origins=*' \
    '--skip-welcome' \
    '--skip-sessions-welcome' \
    '--skip-release-notes' \
    '--disable-workspace-trust'
  if [ "$nuinui_e2e_vscode_locale" = ja ]; then
    printf '%s\n' '--locale=ja'
  fi
  printf '%s\n' "$nuinui_e2e_vscode_workspace"
}

nuinui_e2e_host_vscode__owner_content() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'issue_url=%s\n' "$nuinui_e2e_host_url"
  printf 'local_id=%s\n' "$nuinui_e2e_host_token"
  printf 'lane=%s\n' "$nuinui_e2e_host_lane"
  printf 'repository=sayosomi/nuinuiCAD\n'
  printf 'checkout=%s\n' "$nuinui_e2e_host_checkout"
  printf 'git_dir=%s\n' "$nuinui_e2e_host_git_dir"
  printf 'manifest=%s\n' "$nuinui_e2e_host_manifest"
  printf 'manifest_sha256=%s\n' "$nuinui_e2e_host_manifest_sha"
  printf 'default_branch=%s\n' "$nuinui_e2e_host_default_branch"
  printf 'idle_policy=detached\n'
  printf 'tested_sha=%s\n' "$nuinui_e2e_host_tested"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'active_sha256=%s\n' "$nuinui_e2e_host_active_sha"
  printf 'fixture_path=%s\n' "$nuinui_e2e_host_fixture"
  printf 'fixture_sha256=%s\n' "$nuinui_e2e_host_fixture_sha"
  printf 'port=%s\n' "$nuinui_e2e_host_port"
  printf 'locale=%s\n' "$nuinui_e2e_host_locale"
  printf 'adapter=vscode-isolated\n'
  printf 'root=%s\n' "$nuinui_e2e_host_root"
  printf 'root_identity=%s\n' "$nuinui_e2e_host_root_identity"
  printf 'vscode_app_path=%s\n' "$nuinui_e2e_vscode_app_path"
  printf 'vscode_app_sha256=%s\n' "$nuinui_e2e_vscode_app_sha"
  printf 'vscode_artifact_root=%s\n' "$nuinui_e2e_vscode_artifact_root"
  printf 'vscode_artifact_identity=%s\n' "$nuinui_e2e_vscode_artifact_identity"
  printf 'vscode_artifact_snapshot=%s\n' "$nuinui_e2e_vscode_artifact_snapshot"
  printf 'vscode_artifact_identity_name=%s\n' "$nuinui_e2e_vscode_artifact_identity_name"
  printf 'vscode_snapshot_sha256=%s\n' "$nuinui_e2e_vscode_snapshot_sha"
  printf 'vscode_extension_path=%s\n' "$nuinui_e2e_vscode_extension"
  printf 'vscode_extension_sha256=%s\n' "$nuinui_e2e_vscode_extension_sha"
  printf 'vscode_rust_binary_path=%s\n' "$nuinui_e2e_vscode_rust"
  printf 'vscode_rust_binary_sha256=%s\n' "$nuinui_e2e_vscode_rust_sha"
  printf 'vscode_user_data_dir=%s\n' "$nuinui_e2e_vscode_user_data"
  printf 'vscode_extensions_dir=%s\n' "$nuinui_e2e_vscode_extensions_dir"
  printf 'vscode_workspace=%s\n' "$nuinui_e2e_vscode_workspace"
  printf 'vscode_launch_args_sha256=%s\n' "$nuinui_e2e_vscode_launch_args_sha"
}

nuinui_e2e_host_vscode__record_fields() {
  nuinui_e2e_host_vscode__owner_content
}

nuinui_e2e_host_vscode__root_identity() {
  [ "$#" = 1 ] || return 2
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  stat -f '%d:%i' "$1" 2>/dev/null
}

nuinui_e2e_host_vscode__root_tree() {
  [ "$#" = 4 ] || return 2
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import os, stat, sys

root, expected_identity, mode, action = sys.argv[1:]
def blocked(message):
    raise SystemExit("BLOCKED: " + message)
if mode not in ("partial", "complete") or action not in ("verify", "clean-profiles"):
    blocked("invalid owned-profile operation")
try:
    expected_device, expected_inode = (int(part) for part in expected_identity.split(":"))
except (ValueError, AttributeError):
    blocked("generation root identity is invalid")
if os.path.realpath(root) != root:
    blocked("generation root is not canonical")
flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
try:
    root_fd = os.open(root, flags)
except OSError as error:
    blocked("generation root cannot be opened safely: " + str(error))

def check_dir_fd(fd, expected=None):
    info = os.fstat(fd)
    if not stat.S_ISDIR(info.st_mode) or info.st_dev != expected_device:
        blocked("owned profile tree contains a non-directory or crosses a filesystem boundary")
    if expected is not None and (info.st_dev, info.st_ino) != expected:
        blocked("owned profile directory identity changed")
    return info

def inspect_tree(fd, rel, remove=False):
    check_dir_fd(fd)
    try:
        names = sorted(os.listdir(fd))
    except OSError as error:
        blocked("owned profile directory cannot be inspected: " + str(error))
    for name in names:
        try:
            before = os.stat(name, dir_fd=fd, follow_symlinks=False)
        except OSError as error:
            blocked("owned profile entry cannot be inspected: " + str(error))
        if before.st_dev != expected_device:
            blocked("owned profile entry crosses a filesystem boundary")
        if stat.S_ISLNK(before.st_mode):
            blocked("owned profile contains a symbolic link")
        if stat.S_ISDIR(before.st_mode):
            child_flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
            try:
                child_fd = os.open(name, child_flags, dir_fd=fd)
            except OSError as error:
                blocked("owned profile directory cannot be opened without following links: " + str(error))
            try:
                check_dir_fd(child_fd, (before.st_dev, before.st_ino))
                inspect_tree(child_fd, rel + "/" + name, remove)
            finally:
                os.close(child_fd)
            if remove:
                current = os.stat(name, dir_fd=fd, follow_symlinks=False)
                if not stat.S_ISDIR(current.st_mode) or (current.st_dev, current.st_ino) != (before.st_dev, before.st_ino):
                    blocked("owned profile directory changed during cleanup")
                os.rmdir(name, dir_fd=fd)
        elif stat.S_ISREG(before.st_mode):
            if before.st_nlink != 1:
                blocked("owned profile contains a multiply-linked file")
            if remove:
                file_flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
                try:
                    file_fd = os.open(name, file_flags, dir_fd=fd)
                except OSError as error:
                    blocked("owned profile file cannot be opened without following links: " + str(error))
                try:
                    opened = os.fstat(file_fd)
                    if not stat.S_ISREG(opened.st_mode) or (opened.st_dev, opened.st_ino) != (before.st_dev, before.st_ino):
                        blocked("owned profile file identity changed during cleanup")
                    current = os.stat(name, dir_fd=fd, follow_symlinks=False)
                    if not stat.S_ISREG(current.st_mode) or (current.st_dev, current.st_ino) != (before.st_dev, before.st_ino):
                        blocked("owned profile file changed during cleanup")
                    os.unlink(name, dir_fd=fd)
                finally:
                    os.close(file_fd)
        else:
            blocked("owned profile contains a special or unsupported filesystem object")

try:
    root_info = check_dir_fd(root_fd, (expected_device, expected_inode))
    profile_dirs = {}
    allowed_files = {
        ".nuinui-vscode-host-owner-v1", "fixture.nui", "launch-args-v1",
        "process-owner-v1", "cdp-response-sha256", "launch-intent-v1", "stop-intent-v1",
    }
    for name in sorted(os.listdir(root_fd)):
        entry = os.stat(name, dir_fd=root_fd, follow_symlinks=False)
        if entry.st_dev != root_info.st_dev or stat.S_ISLNK(entry.st_mode):
            blocked("generation root contains a linked or foreign-device entry")
        if name in ("user-data", "extensions"):
            if not stat.S_ISDIR(entry.st_mode):
                blocked("isolated profile root is not a real directory")
            profile_dirs[name] = (entry.st_dev, entry.st_ino)
            child_fd = os.open(name, flags, dir_fd=root_fd)
            try:
                check_dir_fd(child_fd, profile_dirs[name])
                inspect_tree(child_fd, name)
            finally:
                os.close(child_fd)
        elif name in allowed_files:
            if not stat.S_ISREG(entry.st_mode) or entry.st_nlink != 1:
                blocked("generation root contains an unsafe ownership record")
        else:
            blocked("generation root contains an unowned or unexpected resource")
    if mode == "complete":
        if set(profile_dirs) != {"user-data", "extensions"}:
            blocked("complete generation is missing an isolated profile root")
        user_fd = os.open("user-data", flags, dir_fd=root_fd)
        try:
            try:
                user_info = os.stat("User", dir_fd=user_fd, follow_symlinks=False)
            except FileNotFoundError:
                blocked("complete generation is missing its isolated User profile")
            if not stat.S_ISDIR(user_info.st_mode) or user_info.st_dev != root_info.st_dev:
                blocked("isolated User profile is not a real owned directory")
        finally:
            os.close(user_fd)
    if action == "clean-profiles":
        for name in ("user-data", "extensions"):
            expected = profile_dirs.get(name)
            if expected is None:
                continue
            child_fd = os.open(name, flags, dir_fd=root_fd)
            try:
                check_dir_fd(child_fd, expected)
                inspect_tree(child_fd, name, remove=True)
            finally:
                os.close(child_fd)
            current = os.stat(name, dir_fd=root_fd, follow_symlinks=False)
            if not stat.S_ISDIR(current.st_mode) or (current.st_dev, current.st_ino) != expected:
                blocked("isolated profile root changed during cleanup")
            os.rmdir(name, dir_fd=root_fd)
    check_dir_fd(root_fd, (expected_device, expected_inode))
finally:
    os.close(root_fd)
PY
}

nuinui_e2e_host_vscode__verify_root() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_vscode_verify_root=$1
  nuinui_e2e_vscode_verify_mode=$2
  case "$nuinui_e2e_vscode_verify_mode" in partial|complete) ;; *) return 2 ;; esac
  [ -d "$nuinui_e2e_vscode_verify_root" ] &&
    [ ! -L "$nuinui_e2e_vscode_verify_root" ] &&
    [ "$(realpath "$nuinui_e2e_vscode_verify_root" 2>/dev/null)" = \
      "$nuinui_e2e_vscode_root" ] &&
    [ "$(nuinui_e2e_host_vscode__root_identity \
      "$nuinui_e2e_vscode_verify_root")" = "$nuinui_e2e_host_root_identity" ] || return 1
  nuinui_e2e_host_vscode__root_tree "$nuinui_e2e_vscode_verify_root" \
    "$nuinui_e2e_host_root_identity" "$nuinui_e2e_vscode_verify_mode" verify || return 1
  if nuinui_e2e__exists "$nuinui_e2e_vscode_launch_args"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_launch_args" || return 1
    nuinui_e2e_host_vscode__launch_args_content | cmp -s - \
      "$nuinui_e2e_vscode_launch_args" || return 1
    nuinui_e2e_vscode_launch_args_sha=$(nuinui_e2e__sha256 \
      "$nuinui_e2e_vscode_launch_args") || return 1
  elif [ "$nuinui_e2e_vscode_verify_mode" = complete ]; then
    return 1
  fi
  nuinui_e2e_vscode_launch_intent=$nuinui_e2e_vscode_root/launch-intent-v1
  if nuinui_e2e__exists "$nuinui_e2e_vscode_launch_intent"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_launch_intent" || return 1
    nuinui_e2e_vscode_expected_intent=$(nuinui_e2e_host_vscode__launch_intent_content) || return 1
    printf '%s' "$nuinui_e2e_vscode_expected_intent" |
      cmp -s - "$nuinui_e2e_vscode_launch_intent" || return 1
  fi
  nuinui_e2e_vscode_stop_intent=$nuinui_e2e_vscode_root/stop-intent-v1
  if nuinui_e2e__exists "$nuinui_e2e_vscode_stop_intent"; then
    nuinui_e2e_host_vscode__read_process_record || return 1
    nuinui_e2e__regular "$nuinui_e2e_vscode_stop_intent" || return 1
    nuinui_e2e_vscode_expected_stop=$(nuinui_e2e_host_vscode__stop_intent_content) || return 1
    printf '%s' "$nuinui_e2e_vscode_expected_stop" |
      cmp -s - "$nuinui_e2e_vscode_stop_intent" || return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_owner"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_owner" || return 1
    nuinui_e2e_host_vscode__owner_content |
      cmp -s - "$nuinui_e2e_vscode_owner" || return 1
  elif [ "$nuinui_e2e_vscode_verify_mode" = complete ]; then
    return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_user_settings"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_user_settings" || return 1
    nuinui_e2e_host_vscode__settings_content | cmp -s - \
      "$nuinui_e2e_vscode_user_settings" || return 1
  elif [ "$nuinui_e2e_vscode_verify_mode" = complete ]; then
    return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_workspace"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_workspace" &&
      [ "$(nuinui_e2e__sha256 "$nuinui_e2e_vscode_workspace")" = \
        "$nuinui_e2e_host_fixture_sha" ] || return 1
  elif [ "$nuinui_e2e_vscode_verify_mode" = complete ]; then
    return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_launch_args"; then
    :
  elif [ "$nuinui_e2e_vscode_verify_mode" = complete ]; then
    return 1
  fi
  if [ "$nuinui_e2e_vscode_verify_mode" = complete ]; then
    [ -d "$nuinui_e2e_vscode_user_data/User" ] &&
      [ -d "$nuinui_e2e_vscode_extensions_dir" ] &&
      nuinui_e2e__regular "$nuinui_e2e_vscode_owner" &&
      nuinui_e2e__regular "$nuinui_e2e_vscode_user_settings" &&
      nuinui_e2e__regular "$nuinui_e2e_vscode_workspace" &&
      nuinui_e2e__regular "$nuinui_e2e_vscode_launch_args" || return 1
  fi
  nuinui_e2e_vscode_process_record=$nuinui_e2e_vscode_root/process-owner-v1
  if nuinui_e2e__exists "$nuinui_e2e_vscode_process_record"; then
    nuinui_e2e_host_vscode__read_process_record || return 1
  else
    nuinui_e2e__exists "$nuinui_e2e_vscode_cdp_evidence" && return 1
  fi
  return 0
}

nuinui_e2e_host_vscode__listener_pids() {
  [ "$#" = 1 ] || return 2
  command -v /usr/sbin/lsof >/dev/null 2>&1 || return 1
  if nuinui_e2e_vscode_lsof=$(/usr/sbin/lsof -nP -iTCP:"$1" \
    -sTCP:LISTEN -Fpn 2>&1); then
    nuinui_e2e_vscode_lsof_status=0
  else
    nuinui_e2e_vscode_lsof_status=$?
  fi
  case "$nuinui_e2e_vscode_lsof_status" in
    0) ;;
    1)
      [ -z "$nuinui_e2e_vscode_lsof" ] || {
        echo "BLOCKED: lsof returned diagnostics while inspecting port $1: $nuinui_e2e_vscode_lsof"
        return 1
      }
      ;;
    *)
      echo "BLOCKED: lsof inspection failed with exit $nuinui_e2e_vscode_lsof_status for port $1"
      return 1
      ;;
  esac
  python3 - "$1" "$nuinui_e2e_vscode_lsof" <<'PY'
import sys
port, raw = sys.argv[1:]
try: expected_port = int(port)
except ValueError: raise SystemExit("BLOCKED: CDP listener port is malformed")
current_pid = None
listener_pids = set()
for line in raw.splitlines():
    if line.startswith("p") and line[1:].isdigit():
        current_pid = line[1:]
    elif line.startswith("n"):
        if current_pid is None: raise SystemExit("BLOCKED: lsof returned a listener without process identity")
        endpoint = line[1:].removesuffix(" (LISTEN)")
        if endpoint.startswith("[") and "]:" in endpoint:
            host, raw_port = endpoint[1:].split("]:", 1)
        elif ":" in endpoint:
            host, raw_port = endpoint.rsplit(":", 1)
        else:
            raise SystemExit("BLOCKED: lsof returned a malformed CDP bind address")
        if raw_port != str(expected_port) or host not in ("127.0.0.1", "::1"):
            raise SystemExit("BLOCKED: CDP listener is not bound exclusively to loopback")
        listener_pids.add(current_pid)
    elif line.startswith("f") or line == "":
        continue
    else:
        raise SystemExit("BLOCKED: lsof returned an unsupported listener identity field")
print("\n".join(sorted(listener_pids, key=int)))
PY
}

nuinui_e2e_host_vscode__port_free() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_pids=$(nuinui_e2e_host_vscode__listener_pids "$1") || return 1
  [ -z "$nuinui_e2e_vscode_pids" ] || {
    echo "BLOCKED: caller-controlled CDP port is already owned by a process: $1"
    return 1
  }
}

nuinui_e2e_host_vscode__process_ids_for_root() {
  [ "$#" = 1 ] || return 2
  command -v pgrep >/dev/null 2>&1 || return 1
  pgrep -f "user-data-dir=$1/user-data" 2>/dev/null || true
}

nuinui_e2e_host_vscode__process_command_line_owned() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_vscode_owned_root=$1
  nuinui_e2e_vscode_owned_command=$2
  case "$nuinui_e2e_vscode_owned_command" in
    *"user-data-dir=$nuinui_e2e_vscode_owned_root/user-data"*) ;;
    *) return 1 ;;
  esac
  case "$nuinui_e2e_vscode_owned_command" in
    *"$nuinui_e2e_vscode_app_root/Contents/"*) ;;
    *) return 1 ;;
  esac
}

nuinui_e2e_host_vscode__assert_process_ownership() {
  [ "$#" -ge 1 ] && [ "$#" -le 3 ] || return 2
  nuinui_e2e_vscode_owned_root=$1
  nuinui_e2e_vscode_launch_pid=${2:-}
  nuinui_e2e_vscode_require_launch=${3:-0}
  [ "$nuinui_e2e_vscode_owned_root" = "$nuinui_e2e_vscode_root" ] || return 1
  case "$nuinui_e2e_vscode_require_launch" in 0|1) ;; *) return 2 ;; esac
  if [ -n "$nuinui_e2e_vscode_launch_pid" ]; then
    case "$nuinui_e2e_vscode_launch_pid" in ''|*[!0-9]*|0|1) return 1 ;; esac
  elif [ "$nuinui_e2e_vscode_require_launch" = 1 ]; then
    echo 'BLOCKED: recorded launch PID is missing'
    return 1
  fi
  if [ -n "$nuinui_e2e_vscode_launch_pid" ] &&
    kill -0 "$nuinui_e2e_vscode_launch_pid" >/dev/null 2>&1; then
    nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_launch_pid" -o command= 2>/dev/null || true)
    if [ -z "$nuinui_e2e_vscode_command_line" ]; then
      if [ "$nuinui_e2e_vscode_require_launch" = 1 ]; then
        echo 'BLOCKED: recorded launch PID is not running'
        return 1
      fi
    else
      nuinui_e2e_host_vscode__process_command_line_owned \
        "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_command_line" || {
          echo 'BLOCKED: launch PID ownership mismatch'
          return 1
        }
    fi
  elif [ "$nuinui_e2e_vscode_require_launch" = 1 ]; then
    echo 'BLOCKED: recorded launch PID is not running'
    return 1
  fi
  nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
    "$nuinui_e2e_vscode_owned_root") || return 1
  for nuinui_e2e_vscode_pid in $nuinui_e2e_vscode_owned_pids; do
    case "$nuinui_e2e_vscode_pid" in ''|*[!0-9]*|0|1) return 1 ;; esac
    nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_pid" \
      -o command= 2>/dev/null || true)
    [ -n "$nuinui_e2e_vscode_command_line" ] || continue
    nuinui_e2e_host_vscode__process_command_line_owned \
      "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_command_line" || {
        echo 'BLOCKED: E2E process ownership is ambiguous'
        return 1
      }
  done
}

nuinui_e2e_host_vscode__stop_owned_processes() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_vscode_owned_root=$1
  nuinui_e2e_vscode_launch_pid=$2
  nuinui_e2e_host_vscode__assert_process_ownership \
    "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_launch_pid" 0 || return 1
  nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
    "$nuinui_e2e_vscode_owned_root") || return 1
  for nuinui_e2e_vscode_pid in $nuinui_e2e_vscode_launch_pid $nuinui_e2e_vscode_owned_pids; do
    case "$nuinui_e2e_vscode_pid" in ''|*[!0-9]*|0|1) continue ;; esac
    kill -0 "$nuinui_e2e_vscode_pid" >/dev/null 2>&1 || continue
    nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_pid" \
      -o command= 2>/dev/null || true)
    [ -n "$nuinui_e2e_vscode_command_line" ] || continue
    nuinui_e2e_host_vscode__process_command_line_owned \
      "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_command_line" || return 1
    kill -TERM "$nuinui_e2e_vscode_pid" >/dev/null 2>&1 || {
      kill -0 "$nuinui_e2e_vscode_pid" >/dev/null 2>&1 || continue
      return 1
    }
  done
  nuinui_e2e_vscode_stop_attempt=0
  while [ "$nuinui_e2e_vscode_stop_attempt" -lt 10 ]; do
    nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
      "$nuinui_e2e_vscode_owned_root") || return 1
    nuinui_e2e_vscode_remaining=no
    for nuinui_e2e_vscode_pid in $nuinui_e2e_vscode_owned_pids; do
      nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_pid" \
        -o command= 2>/dev/null || true)
      [ -n "$nuinui_e2e_vscode_command_line" ] || continue
      nuinui_e2e_host_vscode__process_command_line_owned \
        "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_command_line" || return 1
      nuinui_e2e_vscode_remaining=yes
    done
    [ "$nuinui_e2e_vscode_remaining" = no ] && return 0
    nuinui_e2e_vscode_stop_attempt=$((nuinui_e2e_vscode_stop_attempt + 1))
    sleep 0.2
  done
  nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
    "$nuinui_e2e_vscode_owned_root") || return 1
  for nuinui_e2e_vscode_pid in $nuinui_e2e_vscode_launch_pid $nuinui_e2e_vscode_owned_pids; do
    case "$nuinui_e2e_vscode_pid" in ''|*[!0-9]*|0|1) continue ;; esac
    kill -0 "$nuinui_e2e_vscode_pid" >/dev/null 2>&1 || continue
    nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_pid" \
      -o command= 2>/dev/null || true)
    [ -n "$nuinui_e2e_vscode_command_line" ] || continue
    nuinui_e2e_host_vscode__process_command_line_owned \
      "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_command_line" || return 1
    kill -KILL "$nuinui_e2e_vscode_pid" >/dev/null 2>&1 || {
      kill -0 "$nuinui_e2e_vscode_pid" >/dev/null 2>&1 || continue
      return 1
    }
  done
  nuinui_e2e_vscode_stop_attempt=0
  while [ "$nuinui_e2e_vscode_stop_attempt" -lt 10 ]; do
    nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
      "$nuinui_e2e_vscode_owned_root") || return 1
    nuinui_e2e_vscode_remaining=no
    for nuinui_e2e_vscode_pid in $nuinui_e2e_vscode_owned_pids; do
      nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_pid" \
        -o command= 2>/dev/null || true)
      [ -n "$nuinui_e2e_vscode_command_line" ] || continue
      nuinui_e2e_host_vscode__process_command_line_owned \
        "$nuinui_e2e_vscode_owned_root" "$nuinui_e2e_vscode_command_line" || return 1
      nuinui_e2e_vscode_remaining=yes
    done
    [ "$nuinui_e2e_vscode_remaining" = no ] && return 0
    nuinui_e2e_vscode_stop_attempt=$((nuinui_e2e_vscode_stop_attempt + 1))
    sleep 0.2
  done
  echo 'BLOCKED: isolated VS Code processes remained after shutdown'
  return 1
}

nuinui_e2e_host_vscode__cdp_content() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'readiness_sha256=%s\n' "$nuinui_e2e_vscode_readiness_sha"
}

nuinui_e2e_host_vscode__launch_intent_content() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'root=%s\n' "$nuinui_e2e_host_root"
  printf 'root_identity=%s\n' "$nuinui_e2e_host_root_identity"
  printf 'port=%s\n' "$nuinui_e2e_host_port"
  printf 'adapter=vscode-isolated\n'
}

nuinui_e2e_host_vscode__stop_intent_content() {
  nuinui_e2e_host_vscode__launch_intent_content
}

nuinui_e2e_host_vscode__process_record_content() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'root=%s\n' "$nuinui_e2e_host_root"
  printf 'root_identity=%s\n' "$nuinui_e2e_host_root_identity"
  printf 'port=%s\n' "$nuinui_e2e_host_port"
  printf 'app_path=%s\n' "$nuinui_e2e_vscode_app_path"
  printf 'app_sha256=%s\n' "$nuinui_e2e_vscode_app_sha"
  printf 'pid=%s\n' "$nuinui_e2e_vscode_process_pid"
}

nuinui_e2e_host_vscode__read_process_record() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_vscode_process_record=$nuinui_e2e_vscode_root/process-owner-v1
  nuinui_e2e__regular "$nuinui_e2e_vscode_process_record" || return 1
  nuinui_ownership_validate_exact_file "$nuinui_e2e_vscode_process_record" \
    schema_version,issue,generation,root,root_identity,port,app_path,app_sha256,pid || return 1
  nuinui_e2e_vscode_process_pid=$(nuinui_ownership_field \
    "$nuinui_e2e_vscode_process_record" pid) || return 1
  case "$nuinui_e2e_vscode_process_pid" in ''|*[!0-9]*|0|1) return 1 ;; esac
  [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" schema_version)" = 1 ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" issue)" = "$nuinui_e2e_host_issue" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" generation)" = "$nuinui_e2e_host_generation" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" root)" = "$nuinui_e2e_host_root" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" root_identity)" = "$nuinui_e2e_host_root_identity" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" port)" = "$nuinui_e2e_host_port" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" app_path)" = "$nuinui_e2e_vscode_app_path" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" app_sha256)" = "$nuinui_e2e_vscode_app_sha" ] || return 1
  nuinui_e2e_vscode_expected_process=$(nuinui_e2e_host_vscode__process_record_content) || return 1
  printf '%s' "$nuinui_e2e_vscode_expected_process" | cmp -s - \
    "$nuinui_e2e_vscode_process_record" || return 1
  nuinui_e2e_host_process_pid=$nuinui_e2e_vscode_process_pid
}

nuinui_e2e_host_vscode__classify_process_exit() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
    "$nuinui_e2e_vscode_root") || return 1
  if [ -n "$nuinui_e2e_vscode_owned_pids" ]; then
    nuinui_e2e_host_vscode__assert_process_ownership \
      "$nuinui_e2e_vscode_root" "${nuinui_e2e_vscode_process_pid:-}" 0 || return 1
    printf 'LIVE\n'
    return 0
  fi
  if [ -n "${nuinui_e2e_vscode_process_pid:-}" ] &&
    kill -0 "$nuinui_e2e_vscode_process_pid" >/dev/null 2>&1; then
    nuinui_e2e_vscode_command_line=$(ps -ww -p "$nuinui_e2e_vscode_process_pid" \
      -o command= 2>/dev/null || true)
    if [ -n "$nuinui_e2e_vscode_command_line" ]; then
      nuinui_e2e_host_vscode__process_command_line_owned \
        "$nuinui_e2e_vscode_root" "$nuinui_e2e_vscode_command_line" || {
          echo 'BLOCKED: recorded launch PID ownership mismatch'
          return 1
        }
      printf 'LIVE\n'
      return 0
    fi
  fi
  printf 'EXITED\n'
}

nuinui_e2e_host_vscode__readiness() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_host_vscode__verify_owned_process \
    "$nuinui_e2e_vscode_process_pid" || return 1
  nuinui_e2e_vscode_response=$(curl --noproxy '*' --silent --show-error \
    --max-time 1 --fail "http://127.0.0.1:$nuinui_e2e_host_port/json/version" \
    2>/dev/null) || return 1
  nuinui_e2e_vscode_readiness_sha=$(printf '%s' "$nuinui_e2e_vscode_response" |
    shasum -a 256 | awk 'NR == 1 {print $1}') || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_vscode_readiness_sha" || return 1
  nuinui_e2e_vscode_cdp_content=$(nuinui_e2e_host_vscode__cdp_content) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_cdp_evidence" \
    "$nuinui_e2e_vscode_cdp_content" || return 1
  nuinui_e2e_host_vscode__verify_owned_process \
    "$nuinui_e2e_vscode_process_pid"
}

nuinui_e2e_host_vscode__verify_owned_process() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_expected_pid=$1
  nuinui_e2e_host_vscode__assert_process_ownership \
    "$nuinui_e2e_vscode_root" "$nuinui_e2e_vscode_expected_pid" 1 || return 1
  nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
    "$nuinui_e2e_vscode_root") || return 1
  nuinui_e2e_vscode_listener=$(nuinui_e2e_host_vscode__listener_pids \
    "$nuinui_e2e_host_port") || return 1
  [ -n "$nuinui_e2e_vscode_listener" ] || {
    echo 'BLOCKED: isolated host has no CDP listener'
    return 1
  }
  for nuinui_e2e_vscode_listener_pid in $nuinui_e2e_vscode_listener; do
    nuinui_e2e_vscode_listener_command_line=$(ps -ww -p \
      "$nuinui_e2e_vscode_listener_pid" -o command= 2>/dev/null || true)
    [ -n "$nuinui_e2e_vscode_listener_command_line" ] || return 1
    nuinui_e2e_host_vscode__process_command_line_owned \
      "$nuinui_e2e_vscode_root" "$nuinui_e2e_vscode_listener_command_line" || {
        echo 'BLOCKED: CDP listener is outside the isolated VS Code host'
        return 1
      }
  done
}

nuinui_e2e_host_vscode__create_resources() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_host_vscode__configure_paths || return 1
  umask 077
  [ -d "$nuinui_e2e_vscode_root" ] && [ ! -L "$nuinui_e2e_vscode_root" ] || return 1
  nuinui_e2e_host_root_identity=$(nuinui_e2e_host_vscode__root_identity \
    "$nuinui_e2e_vscode_root") || return 1
  mkdir "$nuinui_e2e_vscode_user_data" \
    "$nuinui_e2e_vscode_user_data/User" \
    "$nuinui_e2e_vscode_extensions_dir" || {
      echo 'BLOCKED: isolated user-data or extensions directories could not be created'
      return 1
    }
  nuinui_e2e_vscode_settings_content=$(nuinui_e2e_host_vscode__settings_content; printf '.') || return 1
  nuinui_e2e_vscode_settings_content=${nuinui_e2e_vscode_settings_content%.}
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_user_settings" \
    "$nuinui_e2e_vscode_settings_content" || {
      echo 'BLOCKED: isolated VS Code user settings could not be created without replacing existing content'
      return 1
    }
  nuinui_e2e_host__atomic_copy "$nuinui_e2e_host_fixture" \
    "$nuinui_e2e_vscode_workspace" "$nuinui_e2e_host_fixture_sha" || {
      echo 'BLOCKED: isolated workspace fixture could not be created without replacing existing content'
      return 1
    }
  nuinui_e2e_vscode_launch_args_content=$(nuinui_e2e_host_vscode__launch_args_content; printf '.') || return 1
  nuinui_e2e_vscode_launch_args_content=${nuinui_e2e_vscode_launch_args_content%.}
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_launch_args" \
    "$nuinui_e2e_vscode_launch_args_content" || {
      echo 'BLOCKED: exact VS Code launch arguments could not be created without replacing existing content'
      return 1
    }
  nuinui_e2e_vscode_launch_args_sha=$(nuinui_e2e__sha256 \
    "$nuinui_e2e_vscode_launch_args") || return 1
  nuinui_e2e_vscode_owner_content=$(nuinui_e2e_host_vscode__owner_content; printf '.') || return 1
  nuinui_e2e_vscode_owner_content=${nuinui_e2e_vscode_owner_content%.}
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_owner" \
    "$nuinui_e2e_vscode_owner_content" || {
      echo 'BLOCKED: generation-bound VS Code owner record could not be created without replacement'
      return 1
    }
  nuinui_e2e_host_vscode__verify_root "$nuinui_e2e_vscode_root" complete || {
    echo 'BLOCKED: isolated VS Code resources failed exact ownership verification'
    return 1
  }
}

nuinui_e2e_host_vscode__verify_process_state() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_allow_stopped=$1
  nuinui_e2e_vscode_process_record=$nuinui_e2e_vscode_root/process-owner-v1
  nuinui_e2e_vscode_launch_intent=$nuinui_e2e_vscode_root/launch-intent-v1
  nuinui_e2e_vscode_stop_intent=$nuinui_e2e_vscode_root/stop-intent-v1
  nuinui_e2e_vscode_has_process_record=no
  nuinui_e2e_vscode_process_pid=
  if nuinui_e2e__exists "$nuinui_e2e_vscode_process_record"; then
    nuinui_e2e_host_vscode__read_process_record || return 1
    nuinui_e2e_vscode_has_process_record=yes
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_launch_intent"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_launch_intent" || return 1
    nuinui_e2e_vscode_expected_intent=$(nuinui_e2e_host_vscode__launch_intent_content) || return 1
    printf '%s' "$nuinui_e2e_vscode_expected_intent" |
      cmp -s - "$nuinui_e2e_vscode_launch_intent" || return 1
    nuinui_e2e_vscode_has_launch_intent=yes
  else
    nuinui_e2e_vscode_has_launch_intent=no
  fi
  if [ "$nuinui_e2e_vscode_has_process_record" = no ] &&
    [ "$nuinui_e2e_vscode_has_launch_intent" = no ]; then
    nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
      "$nuinui_e2e_vscode_root") || return 1
    nuinui_e2e_vscode_listeners=$(nuinui_e2e_host_vscode__listener_pids \
      "$nuinui_e2e_host_port") || return 1
    [ -z "$nuinui_e2e_vscode_owned_pids" ] &&
      [ -z "$nuinui_e2e_vscode_listeners" ] || {
        echo 'BLOCKED: a process or listener exists without generation launch intent'
        return 1
      }
    case "$nuinui_e2e_vscode_allow_stopped" in preparing|cleanup-pending) return 0 ;; *) return 1 ;; esac
  fi
  nuinui_e2e_vscode_process_state=$(nuinui_e2e_host_vscode__classify_process_exit) || return 1
  if [ "$nuinui_e2e_vscode_process_state" = LIVE ]; then
    if [ "$nuinui_e2e_vscode_allow_stopped" = ready ]; then
      [ "$nuinui_e2e_vscode_has_process_record" = yes ] || return 1
      nuinui_e2e_host_vscode__verify_owned_process \
        "$nuinui_e2e_vscode_process_pid" || return 1
    else
      nuinui_e2e_host_vscode__assert_process_ownership \
        "$nuinui_e2e_vscode_root" "${nuinui_e2e_vscode_process_pid:-}" 0 || return 1
    fi
  else
    nuinui_e2e_vscode_listeners=$(nuinui_e2e_host_vscode__listener_pids \
      "$nuinui_e2e_host_port") || return 1
    [ -z "$nuinui_e2e_vscode_listeners" ] || {
      echo 'BLOCKED: a CDP listener remains after the isolated host exited'
      return 1
    }
    case "$nuinui_e2e_vscode_allow_stopped:$nuinui_e2e_operation" in
      ready:host-status|ready:host-recover|preparing:host-status|preparing:host-recover)
        nuinui_e2e_vscode_process_state=ABNORMAL-EXIT-RECOVERY-SAFE
        ;;
      ready:host-cleanup|preparing:host-cleanup)
        [ "${nuinui_e2e_host_abnormal_exit_recovery:-no}" = yes ] || {
          echo 'BLOCKED: abnormal exit cleanup requires an explicit host-recover operation'
          return 1
        }
        nuinui_e2e_vscode_process_state=ABNORMAL-EXIT-RECOVERY-SAFE
        ;;
      cleanup-pending:host-status|cleanup-pending:host-recover)
        if nuinui_e2e__exists "$nuinui_e2e_vscode_stop_intent"; then
          nuinui_e2e__regular "$nuinui_e2e_vscode_stop_intent" || return 1
          nuinui_e2e_vscode_expected_stop=$(nuinui_e2e_host_vscode__stop_intent_content) || return 1
          printf '%s' "$nuinui_e2e_vscode_expected_stop" |
            cmp -s - "$nuinui_e2e_vscode_stop_intent" || return 1
          nuinui_e2e_vscode_process_state=STOPPED-AFTER-VERIFIED-CLEANUP
        else
          nuinui_e2e_vscode_process_state=ABNORMAL-EXIT-RECOVERY-SAFE
        fi
        ;;
      cleanup-pending:host-cleanup)
        if [ "${nuinui_e2e_host_abnormal_exit_recovery:-no}" = yes ]; then
          nuinui_e2e_vscode_process_state=ABNORMAL-EXIT-RECOVERY-SAFE
        else
          nuinui_e2e__regular "$nuinui_e2e_vscode_stop_intent" || {
            echo 'BLOCKED: recorded host process exited without a durable cleanup intent'
            return 1
          }
          nuinui_e2e_vscode_expected_stop=$(nuinui_e2e_host_vscode__stop_intent_content) || return 1
          printf '%s' "$nuinui_e2e_vscode_expected_stop" |
            cmp -s - "$nuinui_e2e_vscode_stop_intent" || return 1
          nuinui_e2e_vscode_process_state=STOPPED-AFTER-VERIFIED-CLEANUP
        fi
        ;;
      *)
        echo 'BLOCKED: generation-owned VS Code process exited outside verified cleanup'
        return 1
        ;;
    esac
  fi
  if [ "$nuinui_e2e_vscode_allow_stopped" = cleanup-pending ] &&
    [ "$nuinui_e2e_vscode_process_state" = LIVE ]; then
    nuinui_e2e_vscode_listeners=$(nuinui_e2e_host_vscode__listener_pids \
      "$nuinui_e2e_host_port") || return 1
    for nuinui_e2e_vscode_listener_pid in $nuinui_e2e_vscode_listeners; do
      nuinui_e2e_vscode_listener_command_line=$(ps -ww -p \
        "$nuinui_e2e_vscode_listener_pid" -o command= 2>/dev/null || true)
      [ -n "$nuinui_e2e_vscode_listener_command_line" ] || return 1
      nuinui_e2e_host_vscode__process_command_line_owned \
        "$nuinui_e2e_vscode_root" "$nuinui_e2e_vscode_listener_command_line" || {
          echo 'BLOCKED: CDP listener is outside the isolated VS Code host'
          return 1
        }
    done
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_cdp_evidence"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_cdp_evidence" || return 1
    nuinui_ownership_validate_exact_file "$nuinui_e2e_vscode_cdp_evidence" \
      schema_version,issue,generation,readiness_sha256 || return 1
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" schema_version)" = 1 ] &&
      [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" issue)" = "$nuinui_e2e_host_issue" ] &&
      [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" generation)" = "$nuinui_e2e_host_generation" ] || return 1
    nuinui_e2e_vscode_readiness_sha=$(nuinui_ownership_field \
      "$nuinui_e2e_vscode_cdp_evidence" readiness_sha256) || return 1
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_readiness_sha" || return 1
  elif [ "$nuinui_e2e_vscode_allow_stopped" = ready ]; then
    return 1
  fi
}

nuinui_e2e_host_vscode__launch_and_ready() {
  [ "$#" = 0 ] || return 2
  if [ "$nuinui_e2e_vscode_fake_app" != yes ] &&
    [ "${nuinui_e2e_production:-no}" != yes ] &&
    { [ "$nuinui_e2e_self_test" != yes ] ||
      [ "$nuinui_e2e_vscode_test_app" != yes ]; }; then
    echo 'BLOCKED: real VS Code activation requires explicit production mode'
    return 1
  fi
  nuinui_e2e_host_vscode__validate_artifacts "$nuinui_e2e_host_tested" \
    "$nuinui_e2e_host_fixture" "$nuinui_e2e_host_port" \
    "$nuinui_e2e_host_locale" || return 1
  [ "$nuinui_e2e_vscode_fixture_sha" = "$nuinui_e2e_host_fixture_sha" ] || return 1
  nuinui_e2e_host_vscode__verify_root "$nuinui_e2e_vscode_root" complete || return 1
  nuinui_e2e_host_vscode__port_free "$nuinui_e2e_host_port" || return 1
  set --
  while IFS= read -r nuinui_e2e_vscode_arg || [ -n "$nuinui_e2e_vscode_arg" ]; do
    [ -n "$nuinui_e2e_vscode_arg" ] || return 1
    set -- "$@" "$nuinui_e2e_vscode_arg"
  done < "$nuinui_e2e_vscode_launch_args"
  nuinui_e2e_vscode_launch_intent=$nuinui_e2e_vscode_root/launch-intent-v1
  nuinui_e2e_vscode_launch_content=$(nuinui_e2e_host_vscode__launch_intent_content) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_launch_intent" \
    "$nuinui_e2e_vscode_launch_content" || return 1
  NUINUICAD_RUST_EVALUATION_BINARY="$nuinui_e2e_vscode_rust" \
  NUINUICAD_MCP_OBSERVATION=1 \
    "$nuinui_e2e_vscode_app_path" "$@" >/dev/null 2>&1 &
  nuinui_e2e_vscode_process_pid=$!
  nuinui_e2e_vscode_process_content=$(nuinui_e2e_host_vscode__process_record_content) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_root/process-owner-v1" \
    "$nuinui_e2e_vscode_process_content" || return 1
  nuinui_e2e_host_vscode__read_process_record || return 1
  nuinui_e2e_host_vscode__assert_process_ownership \
    "$nuinui_e2e_vscode_root" "$nuinui_e2e_vscode_process_pid" 1 || return 1
  nuinui_e2e__failpoint after-vscode-process-record && {
    echo 'BLOCKED: injected interruption after VS Code launch record; recovery evidence retained'
    return 1
  }
  nuinui_e2e_vscode_attempt=0
  while [ "$nuinui_e2e_vscode_attempt" -lt 120 ]; do
    if nuinui_e2e_host_vscode__readiness; then
      nuinui_e2e_host_vscode__verify_process_state ready || return 1
      nuinui_e2e_host_vscode__validate_artifacts "$nuinui_e2e_host_tested" \
        "$nuinui_e2e_host_fixture" "$nuinui_e2e_host_port" \
        "$nuinui_e2e_host_locale" || return 1
      [ "$nuinui_e2e_vscode_fixture_sha" = "$nuinui_e2e_host_fixture_sha" ] || return 1
      nuinui_e2e_host_vscode__verify_root "$nuinui_e2e_vscode_root" complete || return 1
      nuinui_e2e_host_vscode__verify_owned_process \
        "$nuinui_e2e_vscode_process_pid" || return 1
      return 0
    fi
    nuinui_e2e_vscode_owned_pids=$(nuinui_e2e_host_vscode__process_ids_for_root \
      "$nuinui_e2e_vscode_root") || return 1
    if [ -z "$nuinui_e2e_vscode_owned_pids" ] &&
      ! kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null; then
      return 1
    fi
    nuinui_e2e_vscode_attempt=$((nuinui_e2e_vscode_attempt + 1))
    sleep 0.5
  done
  return 1
}

nuinui_e2e_host_vscode__stop_owned_process() {
  [ "$#" = 0 ] || return 2
  [ "$nuinui_e2e_vscode_test_app" = yes ] ||
    [ "${nuinui_e2e_production:-no}" = yes ] || {
    echo 'BLOCKED: real VS Code shutdown requires explicit production mode'
    return 1
  }
  nuinui_e2e_host_vscode__verify_process_state cleanup-pending || {
    echo 'BLOCKED: process ownership cannot be proven for cleanup'
    return 1
  }
  if ! nuinui_e2e__exists "$nuinui_e2e_vscode_root/process-owner-v1" &&
    ! nuinui_e2e__exists "$nuinui_e2e_vscode_root/launch-intent-v1"; then
    return 0
  fi
  if [ "${nuinui_e2e_vscode_process_state:-}" = LIVE ]; then
    nuinui_e2e_vscode_stop_intent=$nuinui_e2e_vscode_root/stop-intent-v1
    nuinui_e2e_vscode_expected_stop=$(nuinui_e2e_host_vscode__stop_intent_content) || return 1
    if nuinui_e2e__exists "$nuinui_e2e_vscode_stop_intent"; then
      nuinui_e2e__regular "$nuinui_e2e_vscode_stop_intent" &&
        printf '%s' "$nuinui_e2e_vscode_expected_stop" |
          cmp -s - "$nuinui_e2e_vscode_stop_intent" || return 1
    else
      nuinui_e2e__atomic_create "$nuinui_e2e_vscode_stop_intent" \
        "$nuinui_e2e_vscode_expected_stop" || return 1
    fi
    nuinui_e2e_host_vscode__assert_process_ownership \
      "$nuinui_e2e_vscode_root" "${nuinui_e2e_vscode_process_pid:-}" 0 || return 1
  fi
  nuinui_e2e_host_vscode__stop_owned_processes \
    "$nuinui_e2e_vscode_root" "${nuinui_e2e_vscode_process_pid:-}" || return 1
  nuinui_e2e_vscode_listener=$(nuinui_e2e_host_vscode__listener_pids \
    "$nuinui_e2e_host_port") || return 1
  [ -z "$nuinui_e2e_vscode_listener" ] || {
    echo 'BLOCKED: CDP listener remains after isolated VS Code cleanup'
    return 1
  }
}

nuinui_e2e_host_vscode__remove_root() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_remove_mode=$1
  case "$nuinui_e2e_vscode_remove_mode" in partial|complete) ;; *) return 2 ;; esac
  if ! nuinui_e2e__exists "$nuinui_e2e_vscode_root"; then
    return 0
  fi
  nuinui_e2e_host_vscode__verify_root "$nuinui_e2e_vscode_root" partial || return 1
  if nuinui_e2e__exists "$nuinui_e2e_vscode_root/process-owner-v1" ||
    nuinui_e2e__exists "$nuinui_e2e_vscode_root/launch-intent-v1"; then
    nuinui_e2e_host_vscode__verify_process_state cleanup-pending || return 1
  fi
  nuinui_e2e_host_vscode__root_tree "$nuinui_e2e_vscode_root" \
    "$nuinui_e2e_host_root_identity" partial clean-profiles || return 1
  for nuinui_e2e_vscode_remove_file in \
    "$nuinui_e2e_vscode_user_settings" "$nuinui_e2e_vscode_workspace" \
    "$nuinui_e2e_vscode_launch_args" "$nuinui_e2e_vscode_process_record" \
    "$nuinui_e2e_vscode_cdp_evidence" \
    "$nuinui_e2e_vscode_root/launch-intent-v1" \
    "$nuinui_e2e_vscode_root/stop-intent-v1" "$nuinui_e2e_vscode_owner"; do
    if nuinui_e2e__exists "$nuinui_e2e_vscode_remove_file"; then
      nuinui_e2e__regular "$nuinui_e2e_vscode_remove_file" || return 1
      rm "$nuinui_e2e_vscode_remove_file" || return 1
    fi
  done
  [ -z "$(find "$nuinui_e2e_vscode_root" -mindepth 1 -maxdepth 1 -print 2>/dev/null)" ] || return 1
  [ "$(nuinui_e2e_host_vscode__root_identity "$nuinui_e2e_vscode_root")" = \
    "$nuinui_e2e_host_root_identity" ] || return 1
  rmdir "$nuinui_e2e_vscode_root"
}
