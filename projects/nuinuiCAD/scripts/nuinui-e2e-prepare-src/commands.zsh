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
  if [[ "$SESSION_KIND" == preparing ]]; then
    echo "BLOCKED: E2E preparation is already in flight"
    echo "  lane=$SESSION_LANE"
    echo "  issue=$SESSION_ISSUE"
    echo "  ref=$SESSION_REF"
    echo "  root=$SESSION_ROOT"
    echo "  prepare_owner=$SESSION_PREPARE_OWNER"
    echo "  prepare_pid=$SESSION_PREPARE_PID"
    return 1
  fi
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
  local preparing_session_snapshot=""
  local preparation_reserved=0
  local generation_error=""
  local -a launch_args

  cleanup_failed_prepare() {
    local result="$1" cleanup_result=0
    if [[ -n "$e2e_root" ]]; then
      if [[ -n "$vscode_pid" ]]; then
        stop_owned_processes "$e2e_root" "$vscode_pid" >/dev/null 2>&1 || cleanup_result=1
      else
        assert_process_ownership "$e2e_root" "" 0 >/dev/null 2>&1 || cleanup_result=1
      fi
      (( cleanup_result == 0 )) &&
        assert_no_owned_processes "$e2e_root" >/dev/null 2>&1 || cleanup_result=1
      if (( cleanup_result == 0 )); then
        [[ -z "$handoff" || ! -e "$handoff" && ! -L "$handoff" ]] || {
          rm -f -- "$handoff" || cleanup_result=1
        }
      fi
      if (( cleanup_result == 0 )); then
        [[ -z "$e2e_root" || ! -e "$e2e_root" && ! -L "$e2e_root" ]] || {
          rm -rf -- "$e2e_root" || cleanup_result=1
        }
      fi
    fi
    if (( preparation_reserved == 1 && cleanup_result == 0 )); then
      remove_owned_preparing_session "$preparing_session_snapshot" "$E2E_LANE" \
        "$issue" "$tested_ref" "$e2e_root" || cleanup_result=1
    fi
    if (( cleanup_result != 0 )); then
      echo "BLOCKED: owned E2E prepare cleanup could not be proven complete"
      return 1
    fi
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

  handoff="$E2E_TEMP_PARENT/nuinui-${issue}-human-e2e.env"
  write_preparing_session "$E2E_LANE" "$issue" "$tested_ref" "$e2e_root" "$$" || {
    cleanup_failed_prepare 1
    return 1
  }
  preparation_reserved=1
  preparing_session_snapshot="$(cat "$session"; printf '\001')" || {
    cleanup_failed_prepare 1
    return 1
  }
  generation_error="$(assert_checkout "$issue" "$tested_ref" 2>&1)" || {
    printf '%s\n' "$generation_error"
    echo "BLOCKED: E2E prepare generation drift detected after reservation"
    echo "  expected_issue=$issue"
    echo "  expected_ref=$tested_ref"
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

  write_handoff_file "$handoff" "$E2E_LANE" "$issue" "$tested_ref" "$repo" \
    "$e2e_root" "$prepared_fixture" "$cdp_port" "$rust_bin" || {
    cleanup_failed_prepare 1
    return 1
  }

  generation_error="$(assert_checkout "$issue" "$tested_ref" 2>&1)" || {
    printf '%s\n' "$generation_error"
    echo "BLOCKED: E2E prepare generation drift detected before active publication"
    echo "  expected_issue=$issue"
    echo "  expected_ref=$tested_ref"
    cleanup_failed_prepare 1
    return 1
  }

  replace_preparing_session "$E2E_LANE" "$issue" "$tested_ref" "$source_fixture" \
    "$e2e_root" "$handoff" "$cdp_port" "$vscode_pid" "$locale" \
    "$preparing_session_snapshot" || {
    cleanup_failed_prepare 1
    return 1
  }
  preparation_reserved=0

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

recover_split() {
  local marker_issue="$1"
  local marker_ref="$2"
  local session_issue="$3"
  local session_ref="$4"
  local requested_root="$5"
  local session="" marker="" handoff=""
  local marker_snapshot="" session_snapshot=""
  local marker_after="" session_after=""
  local status_output=""

  [[ "$marker_issue" =~ '^SAY-[0-9]+$' && "$session_issue" =~ '^SAY-[0-9]+$' ]] || {
    echo 'ERROR: marker and session Issues must look like SAY-123'
    return 2
  }
  [[ "$marker_ref" =~ '^[0-9a-fA-F]{40}$' && "$session_ref" =~ '^[0-9a-fA-F]{40}$' ]] || {
    echo 'ERROR: marker and session refs must be full commit SHAs'
    return 2
  }
  assert_session_root "$requested_root" || {
    echo 'BLOCKED: split recovery root is invalid'
    return 1
  }
  session="$(session_path)" || { echo 'BLOCKED: cannot resolve E2E session path'; return 1; }
  marker="$(marker_path)" || { echo 'BLOCKED: cannot resolve E2E marker path'; return 1; }

  [[ -f "$marker" && ! -L "$marker" ]] || {
    echo 'BLOCKED: split recovery marker is missing or invalid'
    return 1
  }
  assert_marker "$marker" || return 1
  [[ "$MARKER_ISSUE" == "$marker_issue" && "$MARKER_REF" == "$marker_ref" ]] || {
    echo 'BLOCKED: split recovery marker identity mismatch'
    echo "  expected_issue=$marker_issue"
    echo "  expected_ref=$marker_ref"
    echo "  actual_issue=$MARKER_ISSUE"
    echo "  actual_ref=$MARKER_REF"
    return 1
  }
  marker_snapshot="$(cat "$marker"; printf '\001')" || {
    echo 'BLOCKED: could not snapshot E2E marker'
    return 1
  }
  assert_checkout "$marker_issue" "$marker_ref" >/dev/null || return $?

  [[ -f "$session" && ! -L "$session" ]] || {
    echo 'BLOCKED: split recovery active session is missing or invalid'
    return 1
  }
  load_session "$session" || {
    echo 'BLOCKED: split recovery active session metadata is malformed'
    return 1
  }
  session_snapshot="$(cat "$session"; printf '\001')" || {
    echo 'BLOCKED: could not snapshot E2E session'
    return 1
  }
  [[ "$SESSION_KIND" == current || "$SESSION_KIND" == pre-locale ]] || {
    echo 'BLOCKED: split recovery requires a normal active E2E session'
    return 1
  }
  [[ "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$session_issue" &&
    "$SESSION_REF" == "$session_ref" && "$SESSION_ROOT" == "$requested_root" ]] || {
    echo 'BLOCKED: split recovery session identity mismatch'
    echo "  expected_issue=$session_issue"
    echo "  expected_ref=$session_ref"
    echo "  expected_root=$requested_root"
    echo "  actual_issue=$SESSION_ISSUE"
    echo "  actual_ref=$SESSION_REF"
    echo "  actual_root=$SESSION_ROOT"
    return 1
  }
  if [[ "$marker_issue" == "$session_issue" && "$marker_ref" == "$session_ref" ]]; then
    echo 'BLOCKED: marker and active session are consistent; split recovery is not applicable'
    return 1
  fi
  assert_session_root "$SESSION_ROOT" || {
    echo 'BLOCKED: split recovery session root is invalid'
    return 1
  }
  handoff="$SESSION_HANDOFF"
  assert_session_handoff "$SESSION_ISSUE" "$handoff" || {
    echo 'BLOCKED: split recovery session handoff path is invalid'
    return 1
  }
  assert_handoff_file "$handoff" "$SESSION_ISSUE" "$SESSION_REF" "$SESSION_ROOT" \
    "$SESSION_CDP_PORT" "$SESSION_SOURCE_FIXTURE" || {
    echo 'BLOCKED: split recovery session handoff metadata is invalid'
    return 1
  }
  assert_process_ownership "$SESSION_ROOT" "$SESSION_LAUNCH_PID" 0 || {
    echo 'BLOCKED: split recovery process ownership could not be proven'
    return 1
  }

  revalidate_split_snapshots() {
    local current_marker="" current_session=""
    current_marker="$(cat "$marker"; printf '\001')" || return 1
    current_session="$(cat "$session"; printf '\001')" || return 1
    [[ "$current_marker" == "$marker_snapshot" && "$current_session" == "$session_snapshot" ]] || {
      echo 'BLOCKED: marker or active session changed during split recovery'
      return 1
    }
    assert_checkout "$marker_issue" "$marker_ref" >/dev/null || return 1
  }

  revalidate_split_snapshots || return 1
  stop_owned_processes "$SESSION_ROOT" "$SESSION_LAUNCH_PID" || {
    echo 'BLOCKED: split recovery could not stop only owned E2E processes'
    return 1
  }
  assert_no_owned_processes "$SESSION_ROOT" || {
    echo 'BLOCKED: split recovery found an owned E2E process after stop'
    return 1
  }
  if path_exists "$handoff"; then
    rm -f -- "$handoff" || {
      echo 'ERROR: could not remove stale E2E handoff'
      return 1
    }
  fi
  if path_exists "$requested_root"; then
    rm -rf -- "$requested_root" || {
      echo 'ERROR: could not remove stale E2E root'
      return 1
    }
  fi
  [[ ! -e "$handoff" && ! -L "$handoff" && ! -e "$requested_root" && ! -L "$requested_root" ]] || {
    echo 'BLOCKED: stale E2E artifacts remain after split recovery cleanup'
    return 1
  }

  revalidate_split_snapshots || return 1
  load_session "$session" || {
    echo 'BLOCKED: active E2E session changed before split recovery removal'
    return 1
  }
  [[ "$SESSION_KIND" == current || "$SESSION_KIND" == pre-locale ]] || {
    echo 'BLOCKED: active E2E session changed before split recovery removal'
    return 1
  }
  [[ "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$session_issue" &&
    "$SESSION_REF" == "$session_ref" && "$SESSION_ROOT" == "$requested_root" ]] || {
    echo 'BLOCKED: active E2E session identity changed before split recovery removal'
    return 1
  }
  rm -- "$session" || {
    echo 'ERROR: could not remove stale E2E session metadata'
    return 1
  }

  status_output="$(status 2>&1)" || {
    printf '%s\n' "$status_output"
    echo 'BLOCKED: split recovery read-back did not prove canonical status'
    return 1
  }
  echo 'E2E SPLIT RECOVERED'
  echo "  marker_issue=$marker_issue"
  echo "  marker_ref=$marker_ref"
  echo "  session_issue=$session_issue"
  echo "  session_ref=$session_ref"
  echo "  root=$requested_root"
  echo '  mutation=yes'
  echo '  status=canonical'
  printf '%s\n' "$status_output"
}

recover_preparing() {
  local issue="$1"
  local tested_ref="$2"
  local requested_root="$3"
  local session="" marker="" handoff=""
  local marker_snapshot="" session_snapshot="" handoff_snapshot=""
  local current_marker="" current_session="" current_handoff=""
  local handoff_cdp_port="" status_output=""

  [[ "$issue" =~ '^SAY-[0-9]+$' ]] || {
    echo 'ERROR: Issue must look like SAY-123'
    return 2
  }
  [[ "$tested_ref" =~ '^[0-9a-fA-F]{40}$' ]] || {
    echo 'ERROR: tested-ref must be a full commit SHA'
    return 2
  }
  assert_session_root "$requested_root" || {
    echo 'BLOCKED: stale preparing root is invalid'
    return 1
  }
  session="$(session_path)" || { echo 'BLOCKED: cannot resolve E2E session path'; return 1; }
  marker="$(marker_path)" || { echo 'BLOCKED: cannot resolve E2E marker path'; return 1; }

  [[ -f "$marker" && ! -L "$marker" ]] || {
    echo 'BLOCKED: E2E marker is missing or invalid'
    return 1
  }
  assert_marker "$marker" || return 1
  [[ "$MARKER_ISSUE" == "$issue" && "$MARKER_REF" == "$tested_ref" ]] || {
    echo 'BLOCKED: E2E marker identity mismatch'
    echo "  expected_issue=$issue"
    echo "  expected_ref=$tested_ref"
    echo "  actual_issue=$MARKER_ISSUE"
    echo "  actual_ref=$MARKER_REF"
    return 1
  }
  marker_snapshot="$(cat "$marker"; printf '\001')" || {
    echo 'BLOCKED: could not snapshot E2E marker'
    return 1
  }
  assert_checkout "$issue" "$tested_ref" >/dev/null || return $?

  [[ -f "$session" && ! -L "$session" ]] || {
    echo 'BLOCKED: preparing E2E session is missing or invalid'
    return 1
  }
  load_session "$session" || {
    echo 'BLOCKED: preparing E2E session metadata is malformed'
    return 1
  }
  [[ "$SESSION_KIND" == preparing ]] || {
    echo 'BLOCKED: recover-preparing requires a kind=preparing session'
    return 1
  }
  session_snapshot="$(cat "$session"; printf '\001')" || {
    echo 'BLOCKED: could not snapshot preparing E2E session'
    return 1
  }
  [[ "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$issue" &&
    "$SESSION_REF" == "$tested_ref" && "$SESSION_ROOT" == "$requested_root" &&
    "$SESSION_PREPARE_OWNER" == "$PREPARING_SESSION_OWNER" ]] || {
    echo 'BLOCKED: preparing E2E session identity or ownership mismatch'
    echo "  expected_issue=$issue"
    echo "  expected_ref=$tested_ref"
    echo "  expected_root=$requested_root"
    echo "  actual_issue=$SESSION_ISSUE"
    echo "  actual_ref=$SESSION_REF"
    echo "  actual_root=$SESSION_ROOT"
    return 1
  }
  if kill -0 "$SESSION_PREPARE_PID" >/dev/null 2>&1; then
    echo 'BLOCKED: recorded preparing owner PID is still running'
    echo "  prepare_pid=$SESSION_PREPARE_PID"
    return 1
  fi

  handoff="$E2E_TEMP_PARENT/nuinui-${issue}-human-e2e.env"
  if path_exists "$handoff"; then
    [[ -f "$handoff" && ! -L "$handoff" ]] || {
      echo 'BLOCKED: canonical E2E handoff is ambiguous'
      return 1
    }
    handoff_cdp_port="$(handoff_value "$handoff" CDP_PORT)" || {
      echo 'BLOCKED: canonical E2E handoff CDP port is malformed'
      return 1
    }
    assert_port "$handoff_cdp_port" || {
      echo 'BLOCKED: canonical E2E handoff CDP port is invalid'
      return 1
    }
    assert_handoff_file "$handoff" "$issue" "$tested_ref" "$requested_root" "$handoff_cdp_port" "" || {
      echo 'BLOCKED: canonical E2E handoff identity or ownership could not be proven'
      return 1
    }
    handoff_snapshot="$(cat "$handoff"; printf '\001')" || {
      echo 'BLOCKED: could not snapshot E2E handoff'
      return 1
    }
  else
    handoff_snapshot='__ABSENT__'
  fi
  assert_process_ownership "$requested_root" "" 0 || {
    echo 'BLOCKED: stale preparing process ownership could not be proven'
    return 1
  }

  revalidate_preparing_state() {
    current_marker="$(cat "$marker"; printf '\001')" || return 1
    current_session="$(cat "$session"; printf '\001')" || return 1
    [[ "$current_marker" == "$marker_snapshot" &&
      "$current_session" == "$session_snapshot" ]] || {
      echo 'BLOCKED: marker or preparing session changed during recovery'
      return 1
    }
    assert_checkout "$issue" "$tested_ref" >/dev/null || return 1
  }

  revalidate_preparing_handoff() {
    if [[ "$handoff_snapshot" == '__ABSENT__' ]]; then
      path_exists "$handoff" && {
        echo 'BLOCKED: canonical E2E handoff appeared during recovery'
        return 1
      }
      return 0
    fi
    [[ -f "$handoff" && ! -L "$handoff" ]] || {
      echo 'BLOCKED: canonical E2E handoff changed during recovery'
      return 1
    }
    current_handoff="$(cat "$handoff"; printf '\001')" || return 1
    [[ "$current_handoff" == "$handoff_snapshot" ]] || {
      echo 'BLOCKED: canonical E2E handoff changed during recovery'
      return 1
    }
    assert_handoff_file "$handoff" "$issue" "$tested_ref" "$requested_root" "$handoff_cdp_port" "" || {
      echo 'BLOCKED: canonical E2E handoff ownership changed during recovery'
      return 1
    }
  }

  revalidate_preparing_state || return 1
  revalidate_preparing_handoff || return 1
  stop_owned_processes "$requested_root" "" || {
    echo 'BLOCKED: could not stop only stale root-owned E2E processes'
    return 1
  }
  assert_no_owned_processes "$requested_root" || {
    echo 'BLOCKED: stale root-owned E2E processes remain after stop'
    return 1
  }
  revalidate_preparing_state || return 1
  revalidate_preparing_handoff || return 1

  if [[ "$handoff_snapshot" != '__ABSENT__' ]]; then
    rm -f -- "$handoff" || {
      echo 'ERROR: could not remove stale E2E handoff'
      return 1
    }
  fi
  if path_exists "$requested_root"; then
    rm -rf -- "$requested_root" || {
      echo 'ERROR: could not remove stale E2E root'
      return 1
    }
  fi
  [[ ! -e "$requested_root" && ! -L "$requested_root" ]] || {
    echo 'BLOCKED: stale E2E root remains after recovery cleanup'
    return 1
  }
  [[ ! -e "$handoff" && ! -L "$handoff" ]] || {
    echo 'BLOCKED: stale E2E handoff remains after recovery cleanup'
    return 1
  }
  revalidate_preparing_state || return 1
  remove_stale_preparing_session "$session_snapshot" "$E2E_LANE" \
    "$issue" "$tested_ref" "$requested_root" || return 1
  [[ ! -e "$session" && ! -L "$session" ]] || {
    echo 'BLOCKED: stale preparing E2E session remains after recovery'
    return 1
  }
  assert_checkout "$issue" "$tested_ref" >/dev/null || {
    echo 'BLOCKED: marker or checkout changed during recovery read-back'
    return 1
  }
  assert_no_owned_processes "$requested_root" || {
    echo 'BLOCKED: stale root-owned E2E process remains after recovery read-back'
    return 1
  }
  status_output="$(status 2>&1)" || {
    printf '%s\n' "$status_output"
    echo 'BLOCKED: recover-preparing read-back did not prove canonical status'
    return 1
  }
  echo 'E2E PREPARATION RECOVERED'
  echo "  lane=$E2E_LANE"
  echo "  issue=$issue"
  echo "  ref=$tested_ref"
  echo "  e2e_root=$requested_root"
  echo '  mutation=yes'
  printf '%s\n' "$status_output"
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
  closure-command)
    closure_command "${@:2}"
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
  recover-split)
    [[ "$#" -eq 7 ]] || { usage; exit 2; }
    select_human_lane "$2" || exit $?
    recover_split "$3" "$4" "$5" "$6" "$7"
    ;;
  recover-preparing)
    [[ "$#" -eq 5 ]] || { usage; exit 2; }
    select_human_lane "$2" || exit $?
    recover_preparing "$3" "$4" "$5"
    ;;
  *)
    usage
    exit 2
    ;;
esac
