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
  local issue="$1" tested_ref="$2" source_fixture="$3" cdp_port="$4" session="$5" locale="$6"
  [[ -f "$session" && ! -L "$session" ]] || { echo "BLOCKED: invalid E2E session metadata"; return 1; }
  load_session "$session" || { echo "BLOCKED: invalid E2E session metadata"; return 1; }
  [[ "$SESSION_KIND" == current || "$SESSION_KIND" == pre-locale ]] || { echo "BLOCKED: legacy E2E session cannot qualify for duplicate prepare"; return 1; }
  if [[ "$SESSION_KIND" == pre-locale && "$locale" == ja ]]; then
    echo "BLOCKED: pre-locale E2E session cannot qualify for Japanese duplicate prepare"
    return 1
  fi
  [[ "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$issue" && "$SESSION_REF" == "$tested_ref" &&
    "$SESSION_SOURCE_FIXTURE" == "$source_fixture" && "$SESSION_CDP_PORT" == "$cdp_port" &&
    ( "$SESSION_KIND" == pre-locale || "$SESSION_LOCALE" == "$locale" ) ]] || {
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
  if [[ "$locale" == ja ]]; then
    wait_for_japanese_effective_locale "$SESSION_ROOT" "$SESSION_LAUNCH_PID" || {
      echo "BLOCKED: Japanese locale host/environment readiness could not be proven"
      echo "  requested_locale=ja"
      echo "  effective_locale=${EFFECTIVE_LOCALE:-unknown}"
      echo "  locale_readiness=${JAPANESE_LOCALE_READINESS_REASON:-unknown}"
      return 1
    }
  fi
  printf 'E2E SETUP ALREADY READY\nissue=%s\ntested_ref=%s\ne2e_root=%s\nfixture=%s\nsource_fixture=%s\ncdp_port=%s\nhandoff=%s\nsession=%s\nmutation=no-op\nREADY FOR HUMAN E2E\n' \
    "$issue" "$tested_ref" "$SESSION_ROOT" "$PREPARED_FIXTURE" "$source_fixture" \
    "$cdp_port" "$SESSION_HANDOFF" "$session"
}

prepare() {
  local issue="$1"
  local tested_ref="$2"
  local fixture="$3"
  local locale="$4"
  local cdp_port="${5:-$DEFAULT_CDP_PORT}"
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
  local launch_output="/dev/null"
  local relaunch_count=0
  local launch_bin=""
  local -a launch_args

  cleanup_failed_prepare() {
    local result="$1"
    if [[ -n "$vscode_pid" ]]; then
      stop_owned_processes "$e2e_root" "$vscode_pid" >/dev/null 2>&1 || true
    fi
    [[ -z "$handoff" || ! -e "$handoff" ]] || rm -f -- "$handoff"
    [[ -z "$e2e_root" || ! -e "$e2e_root" ]] || rm -rf -- "$e2e_root"
    return "$result"
  }

  report_locale_failure() {
    local summary="$1" reason="$2"
    echo "ERROR: $summary"
    echo "  requested_locale=ja"
    echo "  effective_locale=${EFFECTIVE_LOCALE:-unknown}"
    echo "  locale_readiness=${reason:-unknown}"
    if [[ "$launch_output" != /dev/null && -s "$launch_output" ]]; then
      echo "  launch_diagnostic_tail_begin"
      tail -c 8192 "$launch_output"
      echo "  launch_diagnostic_tail_end"
    fi
  }

  assert_locale "$locale" || return $?
  assert_checkout "$issue" "$tested_ref" >/dev/null || return $?
  assert_port "$cdp_port" || { echo "ERROR: CDP port must be between 1 and 65535"; return 2; }
  source_fixture="$(resolve_existing_path "$fixture")" || {
    echo "ERROR: could not resolve fixture path"
    return 1
  }

  session="$(session_path)" || { echo "ERROR: cannot resolve E2E session path"; return 1; }
  if path_exists "$session"; then
    prepare_duplicate "$issue" "$tested_ref" "$source_fixture" "$cdp_port" "$session" "$locale"
    return $?
  fi

  code_bin="$(resolve_code_bin)" || {
    echo "BLOCKED: VS Code CLI executable not found"
    return 1
  }
  if [[ "$locale" == ja ]]; then
    resolve_vscode_application_executable || {
      echo "BLOCKED: VS Code application executable could not be resolved from CFBundleExecutable"
      return 1
    }
  fi

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

  if [[ "$locale" == ja ]]; then
    "$code_bin" \
      --user-data-dir="$e2e_root/user-data" \
      --extensions-dir="$e2e_root/extensions" \
      --install-extension "$JAPANESE_LANGUAGE_PACK" \
      --force >/dev/null 2>&1 || {
        echo "ERROR: Japanese language pack installation failed"
        cleanup_failed_prepare 1
        return 1
      }
    wait_for_japanese_extension_installation "$e2e_root" "$code_bin" || {
      report_locale_failure \
        'locale host/environment preparation failed before launch (Japanese extension installation was not proven)' \
        "${JAPANESE_EXTENSION_INSTALLATION_ERROR:-unknown}"
      cleanup_failed_prepare 1
      return 1
    }
  fi

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

  launch_args=(
    --new-window
    --user-data-dir="$e2e_root/user-data"
    --extensions-dir="$e2e_root/extensions"
    --extensionDevelopmentPath="$repo/vscode-extension"
    --remote-debugging-port="$cdp_port"
    '--remote-allow-origins=*'
    --skip-welcome
    --skip-sessions-welcome
    --skip-release-notes
    --disable-workspace-trust
  )
  if [[ "$locale" == ja ]]; then
    launch_bin="$VS_CODE_APPLICATION_EXECUTABLE"
    launch_args=(--locale=ja "${launch_args[@]}")
    launch_output="$e2e_root/evidence/vscode-launch.log"
    : > "$launch_output" || { cleanup_failed_prepare 1; return 1; }
  else
    launch_bin="$code_bin"
  fi

  launch_host() {
    NUINUICAD_RUST_EVALUATION_BINARY="$rust_bin" \
    NUINUICAD_MCP_OBSERVATION=1 \
    "$launch_bin" "${launch_args[@]}" "$prepared_fixture" >> "$launch_output" 2>&1 &
    vscode_pid=$!
  }

  wait_for_host() {
    ready=0
    wait_for_cdp "$cdp_port" "$e2e_root/evidence/cdp-version.json" && ready=1
  }

  launch_host
  wait_for_host

  if [[ "$ready" != 1 ]]; then
    if [[ "$locale" == ja ]]; then
      report_locale_failure 'locale host/environment preparation failed before CDP readiness' 'CDP readiness timeout'
    else
      echo "ERROR: CDP readiness timeout"
      echo "E2E_ROOT: $e2e_root"
    fi
    cleanup_failed_prepare 1
    return 1
  fi

  if [[ "$locale" == ja ]] && ! wait_for_japanese_effective_locale "$e2e_root" "$vscode_pid"; then
    if ! wait_for_japanese_language_pack_state "$e2e_root"; then
      report_locale_failure \
        'locale host/environment preparation failed (post-first-launch Japanese language-pack cache was not ready)' \
        "${JAPANESE_LANGUAGE_PACK_STATE_ERROR:-unknown}"
      cleanup_failed_prepare 1
      return 1
    fi
    if (( relaunch_count == 0 )); then
      stop_owned_processes "$e2e_root" "$vscode_pid" || {
        report_locale_failure \
          'locale host/environment preparation failed while stopping the first owned host' \
          'owned host termination proof failed'
        cleanup_failed_prepare 1
        return 1
      }
      relaunch_count=1
      launch_host
      wait_for_host
      if [[ "$ready" == 1 ]] && wait_for_japanese_effective_locale "$e2e_root" "$vscode_pid"; then
        :
      else
        if [[ "$ready" == 1 ]]; then
          report_locale_failure 'locale host/environment preparation failed' \
            "${JAPANESE_LOCALE_READINESS_REASON:-Japanese NLS proof failed}"
        else
          report_locale_failure 'locale host/environment preparation failed' 'CDP readiness timeout'
        fi
        cleanup_failed_prepare 1
        return 1
      fi
    else
      report_locale_failure 'locale host/environment preparation failed' \
        "${JAPANESE_LOCALE_READINESS_REASON:-unknown}"
      cleanup_failed_prepare 1
      return 1
    fi
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

  write_session "$E2E_LANE" "$issue" "$tested_ref" "$source_fixture" "$e2e_root" "$handoff" "$cdp_port" "$vscode_pid" "$locale" || {
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
  echo "  locale=$locale"
  echo "  handoff=$handoff"
  echo "  session=$session"
  echo "READY FOR HUMAN E2E"
}

case "${1:-}" in
  version)
    echo "$VERSION"
    ;;
  check)
    parse_locale_options "${@:2}" || exit $?
    assert_locale "$LOCALE" || exit $?
    set -- "$1" "${LOCALE_ARGS[@]}"
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
    if [[ "$LOCALE" == ja ]]; then
      check_code_bin="$(resolve_code_bin)" || {
        echo "BLOCKED: VS Code CLI executable not found"
        exit 1
      }
      resolve_vscode_application_executable || {
        echo "BLOCKED: VS Code application executable could not be resolved from CFBundleExecutable"
        exit 1
      }
      echo "  locale=ja"
      echo "  vscode_cli=$check_code_bin"
      echo "  vscode_application_executable=$VS_CODE_APPLICATION_EXECUTABLE"
    fi
    ;;
  prepare)
    parse_locale_options "${@:2}" || exit $?
    assert_locale "$LOCALE" || exit $?
    set -- "$1" "${LOCALE_ARGS[@]}"
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
    prepare "$prepare_issue" "$prepare_ref" "$prepare_fixture" "$LOCALE" "$prepare_port"
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
