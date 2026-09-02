# E2E preparation command implementations and public dispatch.
build_artifacts() {
  local repo="$E2E_WT"

  npm -C "$repo" run build:vscode || {
    echo "ERROR: npm run build:vscode failed"
    return 1
  }
  assert_no_tracked_mutations "npm run build:vscode" || return 1

  cargo build --manifest-path "$repo/rust-evaluator/Cargo.toml" --bin evaluation_stdio || {
    echo "ERROR: evaluation_stdio build failed"
    return 1
  }
  assert_no_tracked_mutations "cargo build" || return 1

  [[ -f "$repo/vscode-extension/dist/extension.js" ]] || {
    echo "ERROR: VS Code extension build artifact missing"
    return 1
  }

  [[ -x "$repo/rust-evaluator/target/debug/evaluation_stdio" ]] || {
    echo "ERROR: evaluation_stdio binary missing"
    return 1
  }
}

resolve_code_bin() {
  local code_bin="$VS_CODE_APP/Contents/Resources/app/bin/code"
  if [[ -x "$code_bin" ]]; then
    echo "$code_bin"
    return 0
  fi
  code_bin="$(command -v code || true)"
  [[ -n "$code_bin" && -x "$code_bin" ]] || return 1
  echo "$code_bin"
}

prepare_duplicate() {
  local issue="$1" tested_ref="$2" source_fixture="$3" cdp_port="$4" session="$5"
  [[ -f "$session" && ! -L "$session" ]] || { echo "BLOCKED: invalid E2E session metadata"; return 1; }
  load_session "$session" || { echo "BLOCKED: invalid E2E session metadata"; return 1; }
  [[ "$SESSION_KIND" == current ]] || { echo "BLOCKED: legacy E2E session cannot qualify for duplicate prepare"; return 1; }
  [[ "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$issue" && "$SESSION_REF" == "$tested_ref" &&
    "$SESSION_SOURCE_FIXTURE" == "$source_fixture" && "$SESSION_CDP_PORT" == "$cdp_port" ]] || {
    echo "BLOCKED: active session identity mismatch"
    return 1
  }
  assert_session_root "$SESSION_ROOT" || return 1
  [[ -d "$SESSION_ROOT" && ! -L "$SESSION_ROOT" ]] || { echo "BLOCKED: active E2E root is missing or invalid"; return 1; }
  assert_session_handoff "$SESSION_ISSUE" "$SESSION_HANDOFF" || return 1
  assert_handoff_file "$SESSION_HANDOFF" "$SESSION_ISSUE" "$SESSION_REF" \
    "$SESSION_ROOT" "$SESSION_CDP_PORT" "$SESSION_SOURCE_FIXTURE" || return 1
  assert_process_ownership "$SESSION_ROOT" "$SESSION_LAUNCH_PID" 1 || return 1
  assert_cdp_reachable "$SESSION_CDP_PORT" || { echo "BLOCKED: recorded CDP host is unreachable"; return 1; }
  printf 'E2E SETUP ALREADY READY\nissue=%s\ntested_ref=%s\ne2e_root=%s\nfixture=%s\nsource_fixture=%s\ncdp_port=%s\nhandoff=%s\nsession=%s\nmutation=no-op\nREADY FOR HUMAN E2E\n' \
    "$issue" "$tested_ref" "$SESSION_ROOT" "$PREPARED_FIXTURE" "$source_fixture" \
    "$cdp_port" "$SESSION_HANDOFF" "$session"
}

prepare() {
  local issue="$1"
  local tested_ref="$2"
  local fixture="$3"
  local cdp_port="${4:-$DEFAULT_CDP_PORT}"
  local source_fixture=""
  local repo="$E2E_WT"
  local code_bin=""
  local e2e_root=""
  local fixture_name=""
  local prepared_fixture=""
  local rust_bin=""
  local handoff=""
  local session=""
  local ready=0
  local vscode_pid=""

  cleanup_failed_prepare() {
    local result="$1"
    if [[ -n "$vscode_pid" ]]; then
      stop_owned_processes "$e2e_root" "$vscode_pid" >/dev/null 2>&1 || true
    fi
    [[ -z "$handoff" || ! -e "$handoff" ]] || rm -f -- "$handoff"
    [[ -z "$e2e_root" || ! -e "$e2e_root" ]] || rm -rf -- "$e2e_root"
    return "$result"
  }

  assert_checkout "$issue" "$tested_ref" >/dev/null || return $?
  assert_port "$cdp_port" || { echo "ERROR: CDP port must be between 1 and 65535"; return 2; }
  source_fixture="$(resolve_existing_path "$fixture")" || {
    echo "ERROR: could not resolve fixture path"
    return 1
  }

  session="$(session_path)" || { echo "ERROR: cannot resolve E2E session path"; return 1; }
  if path_exists "$session"; then
    prepare_duplicate "$issue" "$tested_ref" "$source_fixture" "$cdp_port" "$session"
    return $?
  fi

  code_bin="$(resolve_code_bin)" || {
    echo "BLOCKED: VS Code CLI executable not found"
    return 1
  }

  if lsof -nP -iTCP:"$cdp_port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "BLOCKED: CDP port already in use"
    echo "PORT: $cdp_port"
    return 1
  fi

  e2e_root="$(mktemp -d "$E2E_TEMP_PARENT/nuinui-vscode-e2e.XXXXXX")" || {
    echo "ERROR: could not create E2E root"
    return 1
  }
  mkdir -p "$e2e_root/user-data/User" "$e2e_root/extensions" "$e2e_root/evidence" || {
    cleanup_failed_prepare 1
    return 1
  }

  ensure_dependencies "$e2e_root" || { cleanup_failed_prepare 1; return 1; }
  build_artifacts || { cleanup_failed_prepare 1; return 1; }

  cat > "$e2e_root/user-data/User/settings.json" <<'EOF'
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
EOF

  [[ -f "$e2e_root/user-data/User/settings.json" ]] || { cleanup_failed_prepare 1; return 1; }

  fixture_name="$(basename "$source_fixture")"
  prepared_fixture="$e2e_root/$fixture_name"
  cp "$source_fixture" "$prepared_fixture" || {
    echo "ERROR: fixture copy failed"
    cleanup_failed_prepare 1
    return 1
  }

  rust_bin="$repo/rust-evaluator/target/debug/evaluation_stdio"

  NUINUICAD_RUST_EVALUATION_BINARY="$rust_bin" \
  NUINUICAD_MCP_OBSERVATION=1 \
  "$code_bin" --new-window \
    --user-data-dir="$e2e_root/user-data" \
    --extensions-dir="$e2e_root/extensions" \
    --extensionDevelopmentPath="$repo/vscode-extension" \
    --remote-debugging-port="$cdp_port" \
    '--remote-allow-origins=*' \
    --skip-welcome \
    --skip-sessions-welcome \
    --skip-release-notes \
    --disable-workspace-trust \
    "$prepared_fixture" >/dev/null 2>&1 &
  vscode_pid=$!

  for _ in $(seq 1 120); do
    if curl --max-time 1 -fsS \
      "http://127.0.0.1:${cdp_port}/json/version" \
      > "$e2e_root/evidence/cdp-version.json"; then
      ready=1
      break
    fi
    sleep 0.5
  done

  if [[ "$ready" != 1 ]]; then
    echo "ERROR: CDP readiness timeout"
    echo "E2E_ROOT: $e2e_root"
    cleanup_failed_prepare 1
    return 1
  fi

  handoff="$E2E_TEMP_PARENT/nuinui-${issue}-human-e2e.env"
  cat > "$handoff" <<EOF
LANE='$E2E_LANE'
ISSUE='$issue'
TESTED_REF='$tested_ref'
CHECKOUT='$repo'
E2E_ROOT='$e2e_root'
FIXTURE='$prepared_fixture'
CDP_PORT='$cdp_port'
RUST_BIN='$rust_bin'
EOF

  write_session "$E2E_LANE" "$issue" "$tested_ref" "$source_fixture" "$e2e_root" "$handoff" "$cdp_port" "$vscode_pid" || {
    cleanup_failed_prepare 1
    return 1
  }

  echo "E2E SETUP READY"
  echo "  lane=$E2E_LANE"
  echo "  issue=$issue"
  echo "  tested_ref=$tested_ref"
  echo "  checkout=$repo"
  echo "  e2e_root=$e2e_root"
  echo "  fixture=$prepared_fixture"
  echo "  source_fixture=$source_fixture"
  echo "  cdp_port=$cdp_port"
  echo "  handoff=$handoff"
  echo "  session=$session"
  echo "READY FOR HUMAN E2E"
}

case "${1:-}" in
  version)
    echo "$VERSION"
    ;;
  check)
    if [[ "$#" -eq 4 ]]; then
      select_human_lane || exit $?
      check_issue=$2; check_ref=$3; check_fixture=$4
    elif [[ "$#" -eq 5 ]]; then
      select_human_lane "$2" || exit $?
      check_issue=$3; check_ref=$4; check_fixture=$5
    else
      usage; exit 2
    fi
    assert_inputs "$check_issue" "$check_ref" "$check_fixture" || exit $?
    assert_checkout "$check_issue" "$check_ref"
    ;;
  prepare)
    if [[ "$#" -eq 4 ]]; then
      select_human_lane || exit $?
      prepare_issue=$2; prepare_ref=$3; prepare_fixture=$4; prepare_port="${5:-$DEFAULT_CDP_PORT}"
    elif [[ "$#" -eq 5 ]] && {
      e2e_context || exit $?
      lane_manifest_validate_lane_name "$E2E_MANIFEST" "$2" >/dev/null 2>&1 &&
        [[ "$(lane_manifest_lane_role "$E2E_MANIFEST" "$2")" == human-test ]]
    }; then
      select_human_lane "$2" || exit $?
      prepare_issue=$3; prepare_ref=$4; prepare_fixture=$5; prepare_port="${6:-$DEFAULT_CDP_PORT}"
    elif [[ "$#" -eq 5 ]]; then
      select_human_lane || exit $?
      prepare_issue=$2; prepare_ref=$3; prepare_fixture=$4; prepare_port=$5
    elif [[ "$#" -eq 6 ]]; then
      select_human_lane "$2" || exit $?
      prepare_issue=$3; prepare_ref=$4; prepare_fixture=$5; prepare_port=$6
    else
      usage; exit 2
    fi
    assert_inputs "$prepare_issue" "$prepare_ref" "$prepare_fixture" || exit $?
    prepare "$prepare_issue" "$prepare_ref" "$prepare_fixture" "$prepare_port"
    ;;
  status)
    [[ "$#" -eq 1 || "$#" -eq 2 ]] || { usage; exit 2; }
    if [[ "$#" -eq 2 ]]; then select_human_lane "$2" || exit $?; else select_human_lane || exit $?; fi
    status
    ;;
  closure-check)
    if [[ "$#" -eq 2 ]]; then
      select_human_lane || exit $?
      closure_check_lane "$2"
    elif [[ "$#" -eq 3 ]]; then
      select_human_lane "$2" || exit $?
      closure_check_lane "$3"
    else
      usage; exit 2
    fi
    ;;
  cleanup)
    if [[ "$#" -eq 4 ]]; then
      select_human_lane || exit $?
      cleanup "$2" "$3" "$4"
    elif [[ "$#" -eq 5 ]]; then
      select_human_lane "$2" || exit $?
      cleanup "$3" "$4" "$5"
    else
      usage; exit 2
    fi
    ;;
  *)
    usage
    exit 2
    ;;
esac
