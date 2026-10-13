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
  cat <<'JS'
const fs = require("node:fs");
const http = require("node:http");
const portArg = process.argv.slice(2).find(value => value.startsWith("--remote-debugging-port="));
const rust = process.env.NUINUICAD_RUST_EVALUATION_BINARY || "";
const rustStat = rust ? fs.statSync(rust, { throwIfNoEntry: false }) : undefined;
if (!portArg || !rustStat || !rustStat.isFile() || (rustStat.mode & 0o111) === 0) {
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

nuinui_e2e_host_vscode__file_identity() {
  [ "$#" = 1 ] || return 2
  python3 - "$1" <<'PY'
import os, sys
p = sys.argv[1]
s = os.stat(p, follow_symlinks=False)
print(f"{s.st_dev}:{s.st_ino}:{s.st_size}:{s.st_mtime_ns}:{s.st_ctime_ns}:{s.st_mode:o}")
PY
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
  nuinui_e2e_vscode_app_identity=$(nuinui_e2e_host_vscode__file_identity \
    "$nuinui_e2e_vscode_app_path") || return 1
  [ -n "$nuinui_e2e_vscode_app_identity" ] || return 1
  if [ -n "${NUINUI_E2E_TEST_VSCODE_APP_ROOT:-}" ]; then
    [ "$nuinui_e2e_self_test" = yes ] || return 1
    nuinui_e2e_vscode_test_app_real=$(realpath \
      "$NUINUI_E2E_TEST_VSCODE_APP_ROOT" 2>/dev/null) || return 1
    case "$nuinui_e2e_vscode_test_app_real" in
      "$nuinui_e2e_fixture_root"/*) ;;
      *) return 1 ;;
    esac
    [ "$nuinui_e2e_vscode_app_sha" = \
      "$(nuinui_e2e_host_vscode__fake_launcher_sha)" ] || return 1
    nuinui_e2e_vscode_fake_app=yes
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
  printf '%s\n%s\n%s\n' "$nuinui_e2e_vscode_app_path" \
    "$nuinui_e2e_vscode_app_sha" "$nuinui_e2e_vscode_app_identity"
}

nuinui_e2e_host_vscode__validate_artifacts() {
  [ "$#" = 4 ] || return 2
  nuinui_e2e_vscode_tested=$1
  nuinui_e2e_vscode_fixture=$2
  nuinui_e2e_vscode_port=$3
  nuinui_e2e_vscode_locale=$4
  [ "$(uname -s 2>/dev/null)" = Darwin ] || {
    echo 'BLOCKED: vscode-isolated adapter requires macOS process identity APIs'
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
      echo 'BLOCKED: Visual Studio Code application executable identity could not be verified'
      return 1
    }
  nuinui_e2e_vscode_app_path=$(printf '%s\n' "$nuinui_e2e_vscode_app_rows" | sed -n '1p')
  nuinui_e2e_vscode_app_sha=$(printf '%s\n' "$nuinui_e2e_vscode_app_rows" | sed -n '2p')
  nuinui_e2e_vscode_app_identity=$(printf '%s\n' "$nuinui_e2e_vscode_app_rows" | sed -n '3p')
  if [ -n "${NUINUI_E2E_TEST_VSCODE_APP_ROOT:-}" ]; then
    nuinui_e2e_vscode_fake_app=yes
    nuinui_e2e_vscode_cdp_kind=${NUINUI_E2E_TEST_CDP_KIND:-fake}
    case "$nuinui_e2e_vscode_cdp_kind" in fake|electron) ;; *)
      echo 'BLOCKED: test CDP response kind is unsupported'
      return 1 ;; esac
  else
    nuinui_e2e_vscode_fake_app=no
    nuinui_e2e_vscode_cdp_kind=electron
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
  printf 'vscode_app_identity=%s\n' "$nuinui_e2e_vscode_app_identity"
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
    if [ "$nuinui_e2e_vscode_verify_mode" = complete ] &&
      nuinui_e2e__exists "$nuinui_e2e_vscode_launch_intent"; then
      return 1
    fi
    nuinui_e2e__exists "$nuinui_e2e_vscode_cdp_evidence" && return 1
  fi
  return 0
}

nuinui_e2e_host_vscode__listener_pids() {
  [ "$#" = 1 ] || return 2
  command -v /usr/sbin/lsof >/dev/null 2>&1 || return 1
  if nuinui_e2e_vscode_lsof=$(/usr/sbin/lsof -nP -iTCP:"$1" \
    -sTCP:LISTEN -Fp 2>&1); then
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
  while IFS= read -r nuinui_e2e_vscode_lsof_field ||
    [ -n "$nuinui_e2e_vscode_lsof_field" ]; do
    case "$nuinui_e2e_vscode_lsof_field" in
      '') ;;
      p*)
        case "${nuinui_e2e_vscode_lsof_field#p}" in
          ''|*[!0-9]*) return 1 ;;
        esac
        ;;
      f*) ;;
      *)
        echo "BLOCKED: lsof returned an unsupported identity field for port $1: $nuinui_e2e_vscode_lsof_field"
        return 1
        ;;
    esac
  done <<EOF
$nuinui_e2e_vscode_lsof
EOF
  printf '%s\n' "$nuinui_e2e_vscode_lsof" | awk '/^p[0-9]+$/ {print substr($0, 2)}' | sort -u
}

nuinui_e2e_host_vscode__port_free() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_pids=$(nuinui_e2e_host_vscode__listener_pids "$1") || return 1
  [ -z "$nuinui_e2e_vscode_pids" ] || {
    echo "BLOCKED: caller-controlled CDP port is already owned by a process: $1"
    return 1
  }
}

nuinui_e2e_host_vscode__process_snapshot() {
  [ "$#" = 5 ] || return 2
  python3 - "$1" "$2" "$3" "$4" "$5" <<'PY'
import ctypes, hashlib, os, stat, struct, sys
pid_s, app_path, args_path, rust_path, fake = sys.argv[1:]
def fail(message): raise SystemExit("BLOCKED: " + message)
try: pid = int(pid_s)
except ValueError: fail("process identity has an invalid PID")
if pid <= 1: fail("process identity has an invalid PID")
class BSDInfo(ctypes.Structure):
    _fields_ = [("flags", ctypes.c_uint32), ("status", ctypes.c_uint32),
                ("xstatus", ctypes.c_uint32), ("pid", ctypes.c_uint32),
                ("ppid", ctypes.c_uint32), ("uid", ctypes.c_uint32),
                ("gid", ctypes.c_uint32), ("ruid", ctypes.c_uint32),
                ("rgid", ctypes.c_uint32), ("svuid", ctypes.c_uint32),
                ("svgid", ctypes.c_uint32), ("rfu", ctypes.c_uint32),
                ("comm", ctypes.c_char * 16), ("name", ctypes.c_char * 32),
                ("nfiles", ctypes.c_uint32), ("pgid", ctypes.c_uint32),
                ("pjobc", ctypes.c_uint32), ("tdev", ctypes.c_uint32),
                ("tpgid", ctypes.c_uint32), ("nice", ctypes.c_int32),
                ("start_sec", ctypes.c_uint64), ("start_usec", ctypes.c_uint64)]
try:
    lib = ctypes.CDLL("/usr/lib/system/libsystem_kernel.dylib", use_errno=True)
    info_fn = lib.proc_pidinfo
    info_fn.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_int]
    info_fn.restype = ctypes.c_int
    info = BSDInfo()
    result = info_fn(pid, 3, 0, ctypes.byref(info), ctypes.sizeof(info))
    if result != ctypes.sizeof(info) or info.pid != pid: fail("process exited or PID identity is inaccessible")
    path_fn = lib.proc_pidpath
    path_fn.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32]
    path_fn.restype = ctypes.c_int
    buffer = ctypes.create_string_buffer(4096)
    if path_fn(pid, buffer, len(buffer)) <= 0: fail("process executable identity is inaccessible")
    process_path = os.path.realpath(os.fsdecode(buffer.value))
    mib = (ctypes.c_int * 3)(1, 49, pid)
    sysctl_lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
    sysctl_fn = sysctl_lib.sysctl
    sysctl_fn.argtypes = [ctypes.POINTER(ctypes.c_int), ctypes.c_uint, ctypes.c_void_p,
                          ctypes.POINTER(ctypes.c_size_t), ctypes.c_void_p, ctypes.c_size_t]
    sysctl_fn.restype = ctypes.c_int
    size = ctypes.c_size_t()
    if sysctl_fn(mib, 3, None, ctypes.byref(size), None, 0) != 0 or size.value < 8:
        fail("exact process arguments are inaccessible")
    raw_buffer = ctypes.create_string_buffer(size.value)
    if sysctl_fn(mib, 3, raw_buffer, ctypes.byref(size), None, 0) != 0:
        fail("exact process arguments are inaccessible")
    raw = raw_buffer.raw[:size.value]
    argc = struct.unpack_from("i", raw)[0]
    if argc < 1: fail("process argument count is invalid")
    index = raw.find(b"\0", 4)
    if index < 0: fail("process argument vector is malformed")
    index += 1
    while index < len(raw) and raw[index] == 0: index += 1
    def read_vector(start, count=None):
        values = []
        while start < len(raw) and raw[start] != 0 and (count is None or len(values) < count):
            end = raw.find(b"\0", start)
            if end < 0: fail("process argument or environment vector is malformed")
            values.append(os.fsdecode(raw[start:end]))
            start = end + 1
        if count is not None and len(values) != count: fail("process argument vector is incomplete")
        return values, start
    argv, index = read_vector(index, argc)
    env, _ = read_vector(index)
    rust_values = [entry.split("=", 1)[1] for entry in env
                   if entry.startswith("NUINUICAD_RUST_EVALUATION_BINARY=")]
    if rust_values != [rust_path]: fail("host process does not carry the explicit verified Rust evaluator path")
    with open(args_path, encoding="utf-8") as stream: launch_args = stream.read().splitlines()
    expected = [process_path]
    if fake == "yes": expected.append(app_path)
    elif process_path != os.path.realpath(app_path): fail("process executable differs from verified VS Code executable")
    expected.extend(launch_args)
    if argv != expected: fail("process launch arguments or isolated root differ from the exact generation")
    exe_stat = os.stat(process_path, follow_symlinks=False)
    exe_identity = f"{exe_stat.st_dev}:{exe_stat.st_ino}:{exe_stat.st_size}:{exe_stat.st_mtime_ns}:{exe_stat.st_ctime_ns}:{exe_stat.st_mode:o}"
    args_sha = hashlib.sha256(b"\0".join(value.encode() for value in argv)).hexdigest()
    env_sha = hashlib.sha256(b"\0".join(value.encode() for value in sorted(env))).hexdigest()
    # Re-read the kernel identity after reading argv to reject a PID change mid-snapshot.
    after = BSDInfo()
    result = info_fn(pid, 3, 0, ctypes.byref(after), ctypes.sizeof(after))
    if result != ctypes.sizeof(after) or (after.pid, after.start_sec, after.start_usec) != (info.pid, info.start_sec, info.start_usec):
        fail("process identity changed while it was being verified")
except (OSError, ValueError, IndexError) as error:
    fail(f"process identity could not be verified: {error}")
print("process_pid=" + str(pid))
print(f"process_start={info.start_sec}.{info.start_usec:06d}")
print("process_executable=" + process_path)
print("process_executable_identity=" + exe_identity)
print("process_args_sha256=" + args_sha)
print("process_environment_sha256=" + env_sha)
PY
}

nuinui_e2e_host_vscode__process_identity_sha() {
  [ "$#" = 7 ] || return 2
  python3 - "$@" <<'PY'
import hashlib, sys
print(hashlib.sha256("\0".join(sys.argv[1:]).encode()).hexdigest())
PY
}

nuinui_e2e_host_vscode__read_process_snapshot() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_process_rows=$(nuinui_e2e_host_vscode__process_snapshot \
    "$1" "$nuinui_e2e_vscode_app_path" "$nuinui_e2e_vscode_launch_args" \
    "$nuinui_e2e_vscode_rust" "$nuinui_e2e_vscode_fake_app") || return 1
  nuinui_e2e_vscode_process_pid=$(printf '%s\n' "$nuinui_e2e_vscode_process_rows" | sed -n 's/^process_pid=//p')
  nuinui_e2e_vscode_process_start=$(printf '%s\n' "$nuinui_e2e_vscode_process_rows" | sed -n 's/^process_start=//p')
  nuinui_e2e_vscode_process_executable=$(printf '%s\n' "$nuinui_e2e_vscode_process_rows" | sed -n 's/^process_executable=//p')
  nuinui_e2e_vscode_process_executable_identity=$(printf '%s\n' "$nuinui_e2e_vscode_process_rows" | sed -n 's/^process_executable_identity=//p')
  nuinui_e2e_vscode_process_args_sha=$(printf '%s\n' "$nuinui_e2e_vscode_process_rows" | sed -n 's/^process_args_sha256=//p')
  nuinui_e2e_vscode_process_environment_sha=$(printf '%s\n' "$nuinui_e2e_vscode_process_rows" | sed -n 's/^process_environment_sha256=//p')
  nuinui_e2e_valid_digest "$nuinui_e2e_vscode_process_args_sha" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_process_environment_sha" &&
    [ -n "$nuinui_e2e_vscode_process_start" ] &&
    [ -n "$nuinui_e2e_vscode_process_executable_identity" ]
}

nuinui_e2e_host_vscode__capture_process() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_capture_pid=$1
  nuinui_e2e_vscode_capture_attempt=0
  while [ "$nuinui_e2e_vscode_capture_attempt" -lt 60 ]; do
    if nuinui_e2e_host_vscode__read_process_snapshot \
      "$nuinui_e2e_vscode_capture_pid"; then
      nuinui_e2e_vscode_listener=$(nuinui_e2e_host_vscode__listener_pids \
        "$nuinui_e2e_host_port") || return 1
      [ "$nuinui_e2e_vscode_listener" = "$nuinui_e2e_vscode_capture_pid" ] && return 0
    fi
    kill -0 "$nuinui_e2e_vscode_capture_pid" 2>/dev/null || return 1
    nuinui_e2e_vscode_capture_attempt=$((nuinui_e2e_vscode_capture_attempt + 1))
    sleep 0.1
  done
  return 1
}

nuinui_e2e_host_vscode__verify_process_identity_only() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_expected_pid=$1
  case "$nuinui_e2e_vscode_expected_pid" in ''|*[!0-9]*|0) return 1 ;; esac
  kill -0 "$nuinui_e2e_vscode_expected_pid" 2>/dev/null || {
    echo 'BLOCKED: recorded VS Code process exited unexpectedly'
    return 1
  }
  nuinui_e2e_host_vscode__read_process_snapshot \
    "$nuinui_e2e_vscode_expected_pid" || return 1
  nuinui_e2e_vscode_current_app_sha=$(nuinui_e2e__sha256 \
    "$nuinui_e2e_vscode_app_path") || return 1
  nuinui_e2e_vscode_current_app_identity=$(nuinui_e2e_host_vscode__file_identity \
    "$nuinui_e2e_vscode_app_path") || return 1
  [ "$nuinui_e2e_vscode_current_app_sha" = "$nuinui_e2e_vscode_app_sha" ] &&
    [ "$nuinui_e2e_vscode_current_app_identity" = "$nuinui_e2e_vscode_app_identity" ] || {
      echo 'BLOCKED: verified VS Code application executable changed after validation'
      return 1
    }
  nuinui_e2e_vscode_expected_identity=$(nuinui_e2e_host_vscode__process_identity_sha \
    "$nuinui_e2e_vscode_process_pid" "$nuinui_e2e_vscode_process_start" \
    "$nuinui_e2e_vscode_process_executable" \
    "$nuinui_e2e_vscode_process_executable_identity" \
    "$nuinui_e2e_vscode_process_args_sha" \
    "$nuinui_e2e_vscode_process_environment_sha" \
    "$nuinui_e2e_vscode_root:$nuinui_e2e_host_root_identity:$nuinui_e2e_expected_generation") || return 1
  [ "$nuinui_e2e_vscode_process_start" = "$nuinui_e2e_host_process_start" ] &&
    [ "$nuinui_e2e_vscode_process_executable" = "$nuinui_e2e_host_process_executable" ] &&
    [ "$nuinui_e2e_vscode_process_executable_identity" = "$nuinui_e2e_host_process_executable_identity" ] &&
    [ "$nuinui_e2e_vscode_process_args_sha" = "$nuinui_e2e_host_process_args_sha" ] &&
    [ "$nuinui_e2e_vscode_process_environment_sha" = "$nuinui_e2e_host_process_environment_sha" ] &&
    [ "$nuinui_e2e_vscode_expected_identity" = "$nuinui_e2e_host_process_identity_sha" ] || {
      echo 'BLOCKED: VS Code PID, process start, executable, launch arguments, environment, root, or generation identity changed'
      return 1
    }
}

nuinui_e2e_host_vscode__verify_owned_process() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_vscode_expected_pid=$1
  nuinui_e2e_host_vscode__verify_process_identity_only \
    "$nuinui_e2e_vscode_expected_pid" || return 1
  nuinui_e2e_vscode_listener=$(nuinui_e2e_host_vscode__listener_pids \
    "$nuinui_e2e_host_port") || return 1
  [ "$nuinui_e2e_vscode_listener" = "$nuinui_e2e_vscode_expected_pid" ] || {
    echo 'BLOCKED: CDP listener is not owned by the exact verified generation process'
    return 1
  }
}

nuinui_e2e_host_vscode__readiness() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_host_vscode__verify_owned_process \
    "$nuinui_e2e_host_process_pid" || return 1
  nuinui_e2e_vscode_response=$(curl --noproxy '*' --silent --show-error \
    --max-time 3 --fail "http://127.0.0.1:$nuinui_e2e_host_port/json/version" 2>/dev/null) || {
      echo 'BLOCKED: generation-owned CDP readiness endpoint is inaccessible'
      return 1
    }
  nuinui_e2e_host_vscode__validate_cdp_response \
    "$nuinui_e2e_vscode_cdp_kind" "$nuinui_e2e_host_port" \
    "$nuinui_e2e_vscode_response" || return 1
  nuinui_e2e_vscode_readiness_sha=$(printf '%s' "$nuinui_e2e_vscode_response" |
    shasum -a 256 | awk 'NR == 1 {print $1}') || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_vscode_readiness_sha" || return 1
  nuinui_e2e_vscode_cdp_content=$(nuinui_e2e_host_vscode__cdp_content) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_cdp_evidence" \
    "$nuinui_e2e_vscode_cdp_content" || return 1
  nuinui_e2e_host_vscode__verify_owned_process \
    "$nuinui_e2e_vscode_process_pid"
}

nuinui_e2e_host_vscode__validate_cdp_response() {
  [ "$#" = 3 ] || return 2
  python3 - "$1" "$2" "$3" <<'PY'
import json, re, sys
from urllib.parse import urlsplit

kind, raw_port, raw_body = sys.argv[1:]
def blocked(message):
    raise SystemExit("BLOCKED: " + message)
if kind not in ("fake", "electron") or not raw_port.isdigit():
    blocked("CDP response validation mode or port is invalid")
port = int(raw_port)
def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key")
        result[key] = value
    return result
try:
    body = json.loads(raw_body, object_pairs_hook=unique_object)
except (ValueError, TypeError):
    blocked("CDP readiness response is not unique-key JSON")
if not isinstance(body, dict) or body.get("Protocol-Version") != "1.3":
    blocked("CDP readiness response has an unsupported protocol version")
browser = body.get("Browser")
websocket = body.get("webSocketDebuggerUrl")
if not isinstance(browser, str) or not isinstance(websocket, str):
    blocked("CDP readiness response is missing browser or WebSocket identity")
try:
    address = urlsplit(websocket)
    address_port = address.port
except ValueError:
    blocked("CDP readiness WebSocket address is malformed")
if (address.scheme != "ws" or address.hostname not in ("127.0.0.1", "localhost", "::1") or
        address_port != port or address.username is not None or address.password is not None or
        address.query or address.fragment or
        not re.fullmatch(r"/devtools/browser/[A-Za-z0-9._:-]{1,256}", address.path)):
    blocked("CDP readiness WebSocket address is not bound to the requested loopback port")
if kind == "fake":
    if set(body) != {"Browser", "Protocol-Version", "webSocketDebuggerUrl"} or browser != "FakeVSCode/1.0":
        blocked("test CDP response does not match the explicit disposable fake-host shape")
else:
    chrome = re.fullmatch(r"Chrome/(\d+(?:\.\d+){1,3})", browser)
    user_agent = body.get("User-Agent")
    if not chrome:
        blocked("Electron CDP response has no versioned Chromium browser identity")
    if user_agent is not None:
        if not isinstance(user_agent, str):
            blocked("Electron CDP User-Agent is not text")
        ua_chrome = re.search(r"(?:^|\s)Chrome/(\d+(?:\.\d+){1,3})(?:\s|$)", user_agent)
        if ua_chrome and ua_chrome.group(1) != chrome.group(1):
            blocked("Electron CDP User-Agent disagrees with its Chromium browser identity")
        electron_versions = re.findall(r"(?:^|\s)Electron/(\d+(?:\.\d+){1,3})(?:\s|$)", user_agent)
        if len(electron_versions) > 1:
            blocked("Electron CDP User-Agent contains ambiguous Electron versions")
PY
}

nuinui_e2e_host_vscode__cdp_content() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'process_identity_sha256=%s\n' "$nuinui_e2e_vscode_process_identity_sha"
  printf 'readiness_sha256=%s\n' "$nuinui_e2e_vscode_readiness_sha"
  printf 'response_kind=%s\n' "$nuinui_e2e_vscode_cdp_kind"
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
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'root=%s\n' "$nuinui_e2e_host_root"
  printf 'root_identity=%s\n' "$nuinui_e2e_host_root_identity"
  printf 'process_identity_sha256=%s\n' "$nuinui_e2e_vscode_process_identity_sha"
  printf 'adapter=vscode-isolated\n'
}

nuinui_e2e_host_vscode__process_record_content() {
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
  printf 'tested_sha=%s\n' "$nuinui_e2e_host_tested"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'adapter=vscode-isolated\n'
  printf 'root=%s\n' "$nuinui_e2e_host_root"
  printf 'root_identity=%s\n' "$nuinui_e2e_host_root_identity"
  printf 'port=%s\n' "$nuinui_e2e_host_port"
  printf 'app_path=%s\n' "$nuinui_e2e_vscode_app_path"
  printf 'app_sha256=%s\n' "$nuinui_e2e_vscode_app_sha"
  printf 'app_identity=%s\n' "$nuinui_e2e_vscode_app_identity"
  printf 'pid=%s\n' "$nuinui_e2e_vscode_process_pid"
  printf 'process_start=%s\n' "$nuinui_e2e_vscode_process_start"
  printf 'process_executable=%s\n' "$nuinui_e2e_vscode_process_executable"
  printf 'process_executable_identity=%s\n' "$nuinui_e2e_vscode_process_executable_identity"
  printf 'process_args_sha256=%s\n' "$nuinui_e2e_vscode_process_args_sha"
  printf 'process_environment_sha256=%s\n' "$nuinui_e2e_vscode_process_environment_sha"
  printf 'process_identity_sha256=%s\n' "$nuinui_e2e_vscode_process_identity_sha"
}

nuinui_e2e_host_vscode__read_process_record() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_vscode_process_record=$nuinui_e2e_vscode_root/process-owner-v1
  nuinui_e2e__regular "$nuinui_e2e_vscode_process_record" || return 1
  nuinui_ownership_validate_exact_file "$nuinui_e2e_vscode_process_record" \
    schema_version,issue,issue_url,local_id,lane,repository,checkout,git_dir,manifest,manifest_sha256,tested_sha,generation,adapter,root,root_identity,port,app_path,app_sha256,app_identity,pid,process_start,process_executable,process_executable_identity,process_args_sha256,process_environment_sha256,process_identity_sha256 || return 1
  nuinui_e2e_vscode_process_pid=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" pid) || return 1
  nuinui_e2e_vscode_process_start=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" process_start) || return 1
  nuinui_e2e_vscode_process_executable=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" process_executable) || return 1
  nuinui_e2e_vscode_process_executable_identity=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" process_executable_identity) || return 1
  nuinui_e2e_vscode_process_args_sha=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" process_args_sha256) || return 1
  nuinui_e2e_vscode_process_environment_sha=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" process_environment_sha256) || return 1
  nuinui_e2e_vscode_process_identity_sha=$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" process_identity_sha256) || return 1
  nuinui_e2e_host_process_pid=$nuinui_e2e_vscode_process_pid
  nuinui_e2e_host_process_start=$nuinui_e2e_vscode_process_start
  nuinui_e2e_host_process_executable=$nuinui_e2e_vscode_process_executable
  nuinui_e2e_host_process_executable_identity=$nuinui_e2e_vscode_process_executable_identity
  nuinui_e2e_host_process_args_sha=$nuinui_e2e_vscode_process_args_sha
  nuinui_e2e_host_process_environment_sha=$nuinui_e2e_vscode_process_environment_sha
  nuinui_e2e_host_process_identity_sha=$nuinui_e2e_vscode_process_identity_sha
  case "$nuinui_e2e_vscode_process_pid" in ''|*[!0-9]*|0) return 1 ;; esac
  case "$nuinui_e2e_vscode_process_start" in ''|*[!0-9.]*|.*|*.) return 1 ;; esac
  [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" issue)" = "$nuinui_e2e_host_issue" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" issue_url)" = "$nuinui_e2e_host_url" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" local_id)" = "$nuinui_e2e_host_token" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" lane)" = "$nuinui_e2e_host_lane" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" checkout)" = "$nuinui_e2e_host_checkout" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" git_dir)" = "$nuinui_e2e_host_git_dir" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" manifest)" = "$nuinui_e2e_host_manifest" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" manifest_sha256)" = "$nuinui_e2e_host_manifest_sha" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" tested_sha)" = "$nuinui_e2e_host_tested" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" generation)" = "$nuinui_e2e_host_generation" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" root)" = "$nuinui_e2e_host_root" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" root_identity)" = "$nuinui_e2e_host_root_identity" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" port)" = "$nuinui_e2e_host_port" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" app_path)" = "$nuinui_e2e_vscode_app_path" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" app_sha256)" = "$nuinui_e2e_vscode_app_sha" ] &&
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_process_record" app_identity)" = "$nuinui_e2e_vscode_app_identity" ] || return 1
  nuinui_e2e_vscode_expected_process=$(nuinui_e2e_host_vscode__process_record_content) || return 1
  printf '%s' "$nuinui_e2e_vscode_expected_process" | cmp -s - \
    "$nuinui_e2e_vscode_process_record" || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_vscode_process_args_sha" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_process_environment_sha" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_process_identity_sha" || return 1
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
  if ! nuinui_e2e__exists "$nuinui_e2e_vscode_process_record"; then
    nuinui_e2e_vscode_launch_intent=$nuinui_e2e_vscode_root/launch-intent-v1
    if nuinui_e2e__exists "$nuinui_e2e_vscode_launch_intent"; then
      nuinui_e2e__regular "$nuinui_e2e_vscode_launch_intent" || return 1
      nuinui_e2e_vscode_expected_intent=$(nuinui_e2e_host_vscode__launch_intent_content) || return 1
      printf '%s' "$nuinui_e2e_vscode_expected_intent" |
        cmp -s - "$nuinui_e2e_vscode_launch_intent" || return 1
      echo 'BLOCKED: launch intent exists without a durable process identity; ownership is unknown'
      return 1
    fi
    nuinui_e2e_vscode_listeners=$(nuinui_e2e_host_vscode__listener_pids \
      "$nuinui_e2e_host_port") || return 1
    [ -z "$nuinui_e2e_vscode_listeners" ] || {
      echo 'BLOCKED: a listener occupies the generation port without durable ownership evidence'
      return 1
    }
    case "$nuinui_e2e_vscode_allow_stopped" in preparing|cleanup-pending) return 0 ;; *) return 1 ;; esac
  fi
  nuinui_e2e_host_vscode__read_process_record || return 1
  if kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null; then
    if [ "$nuinui_e2e_vscode_allow_stopped" = cleanup-pending ]; then
      nuinui_e2e_host_vscode__verify_process_identity_only \
        "$nuinui_e2e_vscode_process_pid" || return 1
      nuinui_e2e_vscode_listeners=$(nuinui_e2e_host_vscode__listener_pids \
        "$nuinui_e2e_host_port") || return 1
      [ "$nuinui_e2e_vscode_listeners" = "$nuinui_e2e_vscode_process_pid" ] || return 1
    else
      nuinui_e2e_host_vscode__verify_owned_process \
        "$nuinui_e2e_vscode_process_pid" || return 1
    fi
  elif [ "$nuinui_e2e_vscode_allow_stopped" != cleanup-pending ]; then
    echo 'BLOCKED: generation-owned VS Code process exited outside verified cleanup'
    return 1
  else
    nuinui_e2e_vscode_stop_intent=$nuinui_e2e_vscode_root/stop-intent-v1
    nuinui_e2e__regular "$nuinui_e2e_vscode_stop_intent" || {
      echo 'BLOCKED: recorded host process exited without a durable cleanup signal intent'
      return 1
    }
    nuinui_e2e_vscode_expected_stop=$(nuinui_e2e_host_vscode__stop_intent_content) || return 1
    printf '%s' "$nuinui_e2e_vscode_expected_stop" |
      cmp -s - "$nuinui_e2e_vscode_stop_intent" || return 1
  fi
  nuinui_e2e_vscode_listeners=$(nuinui_e2e_host_vscode__listener_pids \
    "$nuinui_e2e_host_port") || return 1
  if [ "$nuinui_e2e_vscode_allow_stopped" = cleanup-pending ] &&
    ! kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null; then
    [ -z "$nuinui_e2e_vscode_listeners" ] || {
      echo 'BLOCKED: a listener remains after the owned process exited'
      return 1
    }
  else
    [ "$nuinui_e2e_vscode_listeners" = "$nuinui_e2e_vscode_process_pid" ] || return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_vscode_cdp_evidence"; then
    nuinui_e2e__regular "$nuinui_e2e_vscode_cdp_evidence" || return 1
    nuinui_ownership_validate_exact_file "$nuinui_e2e_vscode_cdp_evidence" \
      schema_version,issue,generation,process_identity_sha256,readiness_sha256,response_kind || return 1
    [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" schema_version)" = 1 ] &&
      [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" issue)" = "$nuinui_e2e_host_issue" ] &&
      [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" generation)" = "$nuinui_e2e_host_generation" ] &&
      [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" process_identity_sha256)" = "$nuinui_e2e_vscode_process_identity_sha" ] &&
      [ "$(nuinui_ownership_field "$nuinui_e2e_vscode_cdp_evidence" response_kind)" = "$nuinui_e2e_vscode_cdp_kind" ] || return 1
    nuinui_e2e_vscode_readiness_sha=$(nuinui_ownership_field \
      "$nuinui_e2e_vscode_cdp_evidence" readiness_sha256) || return 1
    nuinui_e2e_valid_digest "$nuinui_e2e_vscode_readiness_sha" || return 1
  elif [ "$nuinui_e2e_vscode_allow_stopped" = ready ]; then
    return 1
  fi
}

nuinui_e2e_host_vscode__launch_and_ready() {
  [ "$#" = 0 ] || return 2
  [ "$nuinui_e2e_vscode_fake_app" = yes ] || {
    echo 'BLOCKED: actual VS Code host activation is deferred to D3-C2c2'
    return 1
  }
  nuinui_e2e_host_vscode__port_free "$nuinui_e2e_host_port" || return 1
  nuinui_e2e_vscode_runtime=$(command -v node) || {
    echo 'BLOCKED: test-only Node.js runtime is unavailable for the disposable fake host'
    return 1
  }
  nuinui_e2e_vscode_runtime=$(realpath "$nuinui_e2e_vscode_runtime" 2>/dev/null) || return 1
  nuinui_e2e__regular "$nuinui_e2e_vscode_runtime" &&
    [ -x "$nuinui_e2e_vscode_runtime" ] || return 1
  set --
  while IFS= read -r nuinui_e2e_vscode_arg || [ -n "$nuinui_e2e_vscode_arg" ]; do
    [ -n "$nuinui_e2e_vscode_arg" ] || return 1
    set -- "$@" "$nuinui_e2e_vscode_arg"
  done < "$nuinui_e2e_vscode_launch_args"
  nuinui_e2e_host_vscode__port_free "$nuinui_e2e_host_port" || return 1
  nuinui_e2e_vscode_launch_intent=$nuinui_e2e_vscode_root/launch-intent-v1
  nuinui_e2e_vscode_launch_content=$(nuinui_e2e_host_vscode__launch_intent_content) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_launch_intent" \
    "$nuinui_e2e_vscode_launch_content" || return 1
  env NUINUICAD_RUST_EVALUATION_BINARY="$nuinui_e2e_vscode_rust" \
    "$nuinui_e2e_vscode_runtime" "$nuinui_e2e_vscode_app_path" "$@" \
    >/dev/null 2>&1 &
  nuinui_e2e_vscode_launched_pid=$!
  nuinui_e2e_host_vscode__capture_process \
    "$nuinui_e2e_vscode_launched_pid" || return 1
  nuinui_e2e_vscode_process_identity_sha=$(nuinui_e2e_host_vscode__process_identity_sha \
    "$nuinui_e2e_vscode_process_pid" "$nuinui_e2e_vscode_process_start" \
    "$nuinui_e2e_vscode_process_executable" \
    "$nuinui_e2e_vscode_process_executable_identity" \
    "$nuinui_e2e_vscode_process_args_sha" \
    "$nuinui_e2e_vscode_process_environment_sha" \
    "$nuinui_e2e_vscode_root:$nuinui_e2e_host_root_identity:$nuinui_e2e_expected_generation") || return 1
  nuinui_e2e_vscode_process_content=$(nuinui_e2e_host_vscode__process_record_content) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_vscode_root/process-owner-v1" \
    "$nuinui_e2e_vscode_process_content" || return 1
  nuinui_e2e_host_vscode__read_process_record || return 1
  nuinui_e2e_host_vscode__verify_owned_process \
    "$nuinui_e2e_vscode_process_pid" || return 1
  nuinui_e2e__failpoint after-vscode-process-record && {
    echo 'BLOCKED: injected interruption after verified fake host process; recovery evidence retained'
    return 1
  }
  nuinui_e2e_vscode_attempt=0
  while [ "$nuinui_e2e_vscode_attempt" -lt 60 ]; do
    if nuinui_e2e_host_vscode__readiness; then
      nuinui_e2e_host_vscode__verify_process_state ready || return 1
      return 0
    fi
    kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null || return 1
    nuinui_e2e_vscode_attempt=$((nuinui_e2e_vscode_attempt + 1))
    sleep 0.1
  done
  return 1
}

nuinui_e2e_host_vscode__stop_owned_process() {
  [ "$#" = 0 ] || return 2
  [ "$nuinui_e2e_vscode_fake_app" = yes ] || {
    echo 'BLOCKED: real VS Code host shutdown is deferred to D3-C2c2'
    return 1
  }
  nuinui_e2e_host_vscode__verify_process_state cleanup-pending || {
    echo 'BLOCKED: process ownership cannot be proven for cleanup'
    return 1
  }
  if nuinui_e2e__exists "$nuinui_e2e_vscode_root/process-owner-v1" &&
    kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null; then
    nuinui_e2e_host_vscode__verify_owned_process \
      "$nuinui_e2e_vscode_process_pid" || return 1
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
    nuinui_e2e_host_vscode__verify_process_identity_only \
      "$nuinui_e2e_vscode_process_pid" || return 1
    kill -TERM "$nuinui_e2e_vscode_process_pid" 2>/dev/null || return 1
    nuinui_e2e_vscode_stop_attempt=0
    while [ "$nuinui_e2e_vscode_stop_attempt" -lt 50 ]; do
      kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null || break
      nuinui_e2e_vscode_stop_attempt=$((nuinui_e2e_vscode_stop_attempt + 1))
      sleep 0.1
    done
    if kill -0 "$nuinui_e2e_vscode_process_pid" 2>/dev/null; then
      nuinui_e2e_host_vscode__verify_process_identity_only \
        "$nuinui_e2e_vscode_process_pid" || return 1
      kill -KILL "$nuinui_e2e_vscode_process_pid" 2>/dev/null || return 1
    fi
    wait "$nuinui_e2e_vscode_process_pid" 2>/dev/null || true
  fi
  nuinui_e2e_vscode_listener=$(nuinui_e2e_host_vscode__listener_pids \
    "$nuinui_e2e_host_port") || return 1
  [ -z "$nuinui_e2e_vscode_listener" ] || {
    echo 'BLOCKED: CDP listener remains after exact owned process cleanup'
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
  if nuinui_e2e__exists "$nuinui_e2e_vscode_root/process-owner-v1"; then
    nuinui_e2e_host_vscode__read_process_record || return 1
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
