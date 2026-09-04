# E2E preparation session, closure, cleanup, and ownership helpers.
ensure_dependencies() {
  local repo="$E2E_WT"
  local e2e_root="$1"
  local npm_cache="$e2e_root/npm-cache"

  mkdir -p "$npm_cache" || {
    echo "ERROR: could not create isolated npm cache"
    return 1
  }

  echo "DEPENDENCIES: INSTALL LOCKED"
  NPM_CONFIG_CACHE="$npm_cache" npm -C "$repo" ci --include=dev || {
    echo "ERROR: dependency installation failed"
    return 1
  }

  [[ -x "$repo/node_modules/.bin/esbuild" ]] || {
    echo "ERROR: esbuild is unavailable after dependency installation"
    return 1
  }

  assert_no_tracked_mutations "dependency preparation" || return 1

  echo "DEPENDENCIES: READY"
}

write_preparing_session() {
  local lane="$1"
  local issue="$2"
  local tested_ref="$3"
  local root="$4"
  local prepare_pid="$5"
  local session=""
  local temporary=""

  session="$(session_path)" || return 1
  [[ ! -e "$session" && ! -L "$session" ]] || {
    echo "BLOCKED: E2E session metadata already exists"
    echo "SESSION: $session"
    return 1
  }
  [[ "$lane" =~ '^[A-Za-z0-9._-]+$' && "$issue" =~ '^SAY-[0-9]+$' &&
    "$tested_ref" =~ '^[0-9a-fA-F]{40}$' &&
    "$prepare_pid" =~ '^[1-9][0-9]*$' ]] || return 1
  assert_session_root "$root" || return 1

  temporary="$(mktemp "${session}.XXXXXX")" || {
    echo "ERROR: could not create preparing E2E session metadata"
    return 1
  }
  if ! {
    printf 'kind=preparing\n'
    printf 'lane=%s\n' "$lane"
    printf 'issue=%s\n' "$issue"
    printf 'ref=%s\n' "$tested_ref"
    printf 'root=%s\n' "$root"
    printf 'prepare_owner=%s\n' "$PREPARING_SESSION_OWNER"
    printf 'prepare_pid=%s\n' "$prepare_pid"
  } > "$temporary"; then
    rm -f -- "$temporary"
    echo "ERROR: could not write preparing E2E session metadata"
    return 1
  fi
  if ! ln "$temporary" "$session"; then
    rm -f -- "$temporary"
    echo "BLOCKED: E2E session metadata appeared during preparation reservation"
    return 1
  fi
  rm -f -- "$temporary"
}

write_current_session_metadata() {
  local temporary="$1"
  local lane="$2"
  local issue="$3"
  local tested_ref="$4"
  local source_fixture="$5"
  local root="$6"
  local handoff="$7"
  local cdp_port="$8"
  local launch_pid="$9"
  local locale="${10}"

  {
    printf 'lane=%s\n' "$lane"
    printf 'issue=%s\n' "$issue"
    printf 'ref=%s\n' "$tested_ref"
    printf 'source_fixture=%s\n' "$source_fixture"
    printf 'root=%s\n' "$root"
    printf 'handoff=%s\n' "$handoff"
    printf 'cdp_port=%s\n' "$cdp_port"
    printf 'launch_pid=%s\n' "$launch_pid"
    printf 'locale=%s\n' "$locale"
  } > "$temporary"
}

write_session() {
  local lane="$1"
  local issue="$2"
  local tested_ref="$3"
  local source_fixture="$4"
  local root="$5"
  local handoff="$6"
  local cdp_port="$7"
  local launch_pid="$8"
  local locale="$9"
  local session=""
  local temporary=""

  session="$(session_path)" || return 1
  if [[ -e "$session" ]]; then
    echo "BLOCKED: E2E session metadata already exists"
    echo "SESSION: $session"
    return 1
  fi
  assert_session_root "$root" || return 1
  assert_session_handoff "$issue" "$handoff" || return 1
  [[ -n "$source_fixture" ]] || return 1
  assert_port "$cdp_port" || return 1
  [[ "$launch_pid" =~ '^[1-9][0-9]*$' ]] || return 1
  assert_locale "$locale" || return 1

  temporary="$(mktemp "${session}.XXXXXX")" || {
    echo "ERROR: could not create E2E session metadata"
    return 1
  }
  if ! write_current_session_metadata "$temporary" "$lane" "$issue" "$tested_ref" \
    "$source_fixture" "$root" "$handoff" "$cdp_port" "$launch_pid" "$locale"; then
    rm -f -- "$temporary"
    echo "ERROR: could not write E2E session metadata"
    return 1
  fi
  mv "$temporary" "$session" || {
    rm -f -- "$temporary"
    echo "ERROR: could not finalize E2E session metadata"
    return 1
  }
}

remove_owned_preparing_session() {
  local expected_snapshot="$1"
  local session="" actual_snapshot=""

  session="$(session_path)" || return 1
  [[ -n "$expected_snapshot" && -f "$session" && ! -L "$session" ]] || {
    echo "BLOCKED: preparing E2E session is missing or not a regular file"
    return 1
  }
  actual_snapshot="$(cat "$session"; printf '\001')" || return 1
  [[ "$actual_snapshot" == "$expected_snapshot" ]] || {
    echo "BLOCKED: preparing E2E session changed before owned cleanup"
    return 1
  }
  load_session "$session" || {
    echo "BLOCKED: preparing E2E session became invalid before owned cleanup"
    return 1
  }
  [[ "$SESSION_KIND" == preparing &&
    "$SESSION_LANE" == "$E2E_LANE" &&
    "$SESSION_PREPARE_OWNER" == "$PREPARING_SESSION_OWNER" &&
    "$SESSION_PREPARE_PID" == "$$" ]] || {
    echo "BLOCKED: preparing E2E session ownership mismatch during cleanup"
    return 1
  }
  rm -- "$session" || {
    echo "ERROR: could not remove preparing E2E session metadata"
    return 1
  }
}

replace_preparing_session() {
  local lane="$1"
  local issue="$2"
  local tested_ref="$3"
  local source_fixture="$4"
  local root="$5"
  local handoff="$6"
  local cdp_port="$7"
  local launch_pid="$8"
  local locale="$9"
  local expected_snapshot="${10}"
  local session="" actual_snapshot="" temporary=""

  session="$(session_path)" || return 1
  [[ -n "$expected_snapshot" && -f "$session" && ! -L "$session" ]] || {
    echo "BLOCKED: preparing E2E session is missing before active publication"
    return 1
  }
  actual_snapshot="$(cat "$session"; printf '\001')" || return 1
  [[ "$actual_snapshot" == "$expected_snapshot" ]] || {
    echo "BLOCKED: preparing E2E session changed before active publication"
    return 1
  }
  load_session "$session" || {
    echo "BLOCKED: preparing E2E session is invalid before active publication"
    return 1
  }
  [[ "$SESSION_KIND" == preparing && "$SESSION_LANE" == "$lane" &&
    "$SESSION_ISSUE" == "$issue" && "$SESSION_REF" == "$tested_ref" &&
    "$SESSION_ROOT" == "$root" &&
    "$SESSION_PREPARE_OWNER" == "$PREPARING_SESSION_OWNER" &&
    "$SESSION_PREPARE_PID" == "$$" ]] || {
    echo "BLOCKED: preparing E2E session identity or ownership mismatch before active publication"
    return 1
  }
  assert_session_root "$root" || return 1
  assert_session_handoff "$issue" "$handoff" || return 1
  assert_handoff_file "$handoff" "$issue" "$tested_ref" "$root" "$cdp_port" "$source_fixture" || {
    echo "BLOCKED: E2E handoff is invalid before active publication"
    return 1
  }
  [[ -n "$source_fixture" ]] || return 1
  assert_port "$cdp_port" || return 1
  [[ "$launch_pid" =~ '^[1-9][0-9]*$' ]] || return 1
  assert_locale "$locale" || return 1
  assert_process_ownership "$root" "$launch_pid" 1 || return 1

  temporary="$(mktemp "${session}.XXXXXX")" || {
    echo "ERROR: could not create active E2E session metadata"
    return 1
  }
  if ! write_current_session_metadata "$temporary" "$lane" "$issue" "$tested_ref" \
    "$source_fixture" "$root" "$handoff" "$cdp_port" "$launch_pid" "$locale"; then
    rm -f -- "$temporary"
    echo "ERROR: could not write active E2E session metadata"
    return 1
  fi
  actual_snapshot="$(cat "$session"; printf '\001')" || {
    rm -f -- "$temporary"
    echo "BLOCKED: preparing E2E session could not be revalidated before active publication"
    return 1
  }
  [[ "$actual_snapshot" == "$expected_snapshot" ]] || {
    rm -f -- "$temporary"
    echo "BLOCKED: preparing E2E session changed before active publication"
    return 1
  }
  mv "$temporary" "$session" || {
    rm -f -- "$temporary"
    echo "ERROR: could not publish active E2E session metadata"
    return 1
  }
}

status() {
  setopt local_options null_glob
  local repo="$E2E_WT" session marker head branch dirty issue tested_ref source_fixture root handoff launch_pid prepare_pid command_line candidate
  local result=0 session_valid=0
  local -a root_candidates handoff_candidates
  [[ -d "$repo" ]] && git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "BLOCKED: e2e checkout is unavailable"; return 1; }
  session="$(session_path)" || return 1
  marker="$(marker_path)" || return 1
  head="$(git -C "$repo" rev-parse HEAD)" || return 1
  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  dirty="$(git -C "$repo" status --porcelain)"
  echo "E2E STATUS"
  echo "  checkout=$repo"
  echo "  head=$head"
  echo "  branch=${branch:-DETACHED}"
  echo "  clean=$([[ -z "$dirty" ]] && echo yes || echo no)"
  if [[ -f "$marker" && ! -L "$marker" ]] && assert_marker "$marker" >/dev/null 2>&1; then
    echo "  marker=present"
    echo "  marker_issue=$MARKER_ISSUE"
    echo "  marker_ref=$MARKER_REF"
  elif path_exists "$marker"; then
    echo "  marker=invalid"
    result=1
  else
    echo "  marker=none"
  fi
  if [[ ! -e "$session" && ! -L "$session" ]]; then
    echo "  session=none"
  elif [[ -f "$session" && ! -L "$session" ]] && load_session "$session"; then
    issue="$SESSION_ISSUE"; tested_ref="$SESSION_REF"; source_fixture="$SESSION_SOURCE_FIXTURE"
    root="$SESSION_ROOT"; handoff="$SESSION_HANDOFF"; launch_pid="$SESSION_LAUNCH_PID"
    if [[ "$SESSION_KIND" == preparing ]]; then
      prepare_pid="$SESSION_PREPARE_PID"
      if [[ "$SESSION_LANE" == "$E2E_LANE" ]] &&
        assert_session_root "$root" >/dev/null 2>&1; then
        session_valid=1
        echo "  session=preparing"
        echo "  issue=$issue"
        echo "  ref=$tested_ref"
        echo "  prepare_owner=$SESSION_PREPARE_OWNER"
        if kill -0 "$prepare_pid" >/dev/null 2>&1; then
          echo "  prepare_pid=$prepare_pid (running)"
        else
          echo "  prepare_pid=$prepare_pid (not-running)"
        fi
        echo "  root=$root ($([[ -e "$root" ]] && echo present || echo missing))"
        echo '  handoff=not-published'
        echo '  preparation=in-flight'
        result=1
        [[ "$MARKER_ISSUE" == "$issue" && "$MARKER_REF" == "$tested_ref" ]] &&
          echo '  session_marker=consistent' || { echo '  session_marker=INCONSISTENT'; result=1; }
      else
        echo '  session=INVALID'
        result=1
      fi
    elif [[ "$SESSION_LANE" == "$E2E_LANE" ]] &&
      assert_session_root "$root" >/dev/null 2>&1 && assert_session_handoff "$issue" "$handoff" >/dev/null 2>&1; then
      session_valid=1; echo "  session=active"; echo "  issue=$issue"; echo "  ref=$tested_ref"
      echo "  locale=$SESSION_LOCALE"
      echo "  root=$root ($([[ -e "$root" ]] && echo present || echo missing))"; echo "  handoff=$handoff ($([[ -e "$handoff" ]] && echo present || echo missing))"
      if kill -0 "$launch_pid" >/dev/null 2>&1; then
        command_line="$(ps -ww -p "$launch_pid" -o command= 2>/dev/null || true)"
        if [[ -n "$command_line" ]] && assert_process_ownership "$root" "$launch_pid" 1 >/dev/null 2>&1; then
          echo "  launch_pid=$launch_pid (owned-process-running)"
        else
          echo "  launch_pid=$launch_pid (process-ownership-mismatch)"
          result=1
        fi
      else echo "  launch_pid=$launch_pid (not-running)"; fi
      [[ "$MARKER_ISSUE" == "$issue" && "$MARKER_REF" == "$tested_ref" ]] && echo "  session_marker=consistent" || { echo "  session_marker=INCONSISTENT"; result=1; }
    else echo "  session=INVALID"; result=1
    fi
  else
    echo "  session=INVALID"; result=1
  fi
  root_candidates=("$E2E_TEMP_PARENT"/nuinui-vscode-e2e.*(N))
  for candidate in "${root_candidates[@]}"; do [[ "$session_valid" == 1 && "$candidate" == "$root" ]] || echo "    root-candidate=$candidate"; done
  handoff_candidates=("$E2E_TEMP_PARENT"/nuinui-*-human-e2e.env(N))
  for candidate in "${handoff_candidates[@]}"; do [[ "$session_valid" == 1 && "$candidate" == "$handoff" ]] || echo "    handoff-candidate=$candidate"; done
  (( result == 0 )) || { echo "E2E STATUS BLOCKED: inspect the reported state; do not delete artifacts automatically."; return 1; }
  echo "E2E STATUS COMPLETE"
}


closure_check_lane() {
  setopt local_options null_glob
  local requested_issue="$1" issue_number="${1#SAY-}" session marker session_issue marker_issue temp_parent candidate processes result=0
  local -a temp_parents root_candidates
  [[ "$requested_issue" =~ '^SAY-[0-9]+$' ]] || { echo "ERROR: Issue must look like SAY-123"; return 2; }
  session="$(session_path)" || { echo "BLOCKED: cannot resolve E2E session path"; return 1; }
  marker="$(marker_path)" || { echo "BLOCKED: cannot resolve E2E marker path"; return 1; }
  echo "E2E CLOSURE CHECK"
  echo "  issue=$requested_issue"
  if [[ ! -e "$session" && ! -L "$session" ]]; then
    echo "  session=none-for-requested-issue"
  elif [[ -f "$session" && ! -L "$session" ]] && load_session "$session"; then
    session_issue="$SESSION_ISSUE"
    [[ "$session_issue" == "$requested_issue" ]] && { echo "  session=BLOCKING-SAME-ISSUE"; result=1; } || echo "  session=other-issue:$session_issue"
  else echo "  session=INVALID"; result=1
  fi
  if [[ -f "$marker" && ! -L "$marker" ]] && assert_marker "$marker" >/dev/null 2>&1; then
    marker_issue="$MARKER_ISSUE"
    [[ "$marker_issue" == "$requested_issue" ]] && { echo "  marker=BLOCKING-SAME-ISSUE"; result=1; } || echo "  marker=other-issue:$marker_issue"
  elif path_exists "$marker"; then echo "  marker=INVALID"; result=1
  else echo "  marker=none-for-requested-issue"
  fi
  temp_parents=("$E2E_TEMP_PARENT")
  [[ -n "${TMPDIR:-}" && "${TMPDIR%/}" != "$E2E_TEMP_PARENT" ]] && temp_parents+=("${TMPDIR%/}")
  for temp_parent in "${temp_parents[@]}"; do
    [[ -d "$temp_parent" ]] || continue
    root_candidates=("$temp_parent"/nuinui-say${issue_number}-e2e.*(N) "$temp_parent"/nuinui-SAY${issue_number}-e2e.*(N) "$temp_parent"/nuinui-SAY-${issue_number}-e2e.*(N))
    for candidate in "${root_candidates[@]}"; do [[ -d "$candidate" ]] && { echo "  fallback-root=BLOCKING:$candidate"; result=1; }; done
    for candidate in "$temp_parent/nuinui-${requested_issue}-human-e2e.env" "$temp_parent/nuinui-say${issue_number}-human-e2e.env"; do path_exists "$candidate" && { echo "  handoff=BLOCKING:$candidate"; result=1; }; done
  done
  processes="$({ pgrep -fal "nuinui-say${issue_number}-e2e\\." 2>/dev/null || true; pgrep -fal "nuinui-SAY${issue_number}-e2e\\." 2>/dev/null || true; pgrep -fal "nuinui-SAY-${issue_number}-e2e\\." 2>/dev/null || true; } | awk '!seen[$0]++')"
  if [[ -n "$processes" ]]; then echo "  process=BLOCKING"; printf '%s\n' "$processes"; result=1; else echo "  process=none-for-requested-issue"; fi
  (( result == 0 )) && { echo "E2E CLOSURE CLEAN"; return 0; }
  echo "E2E CLOSURE BLOCKED"
  return 1
}

cleanup_receipt_path() {
  local git_dir="$(git -C "$E2E_WT" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  printf '%s/nuinui-e2e-cleanup-receipt\n' "$git_dir"
}

write_cleanup_receipt() {
  local issue="$1" tested_ref="$2" root="$3" receipt temporary
  receipt="$(cleanup_receipt_path)" || return 1
  [[ ! -e "$receipt" && ! -L "$receipt" || -f "$receipt" && ! -L "$receipt" ]] || return 1
  temporary="$(mktemp "${receipt}.XXXXXX")" || return 1
  if ! {
    printf 'version=1\n'
    printf 'issue=%s\n' "$issue"
    printf 'ref=%s\n' "$tested_ref"
    printf 'root=%s\n' "$root"
  } > "$temporary"; then rm -f -- "$temporary"; return 1; fi
  mv -- "$temporary" "$receipt" || { rm -f -- "$temporary"; return 1; }
  metadata_matches "$receipt" "$CLEANUP_RECEIPT_KEYS" || return 1
  [[ "$(metadata_value "$receipt" issue)" == "$issue" &&
    "$(metadata_value "$receipt" ref)" == "$tested_ref" &&
    "$(metadata_value "$receipt" root)" == "$root" ]]
}

assert_cleanup_args() {
  [[ "$1" =~ '^SAY-[0-9]+$' ]] || { echo "ERROR: Issue must look like SAY-123"; return 2; }
  [[ "$2" =~ '^[0-9a-fA-F]{40}$' ]] || { echo "ERROR: invalid tested-ref"; return 2; }
  assert_session_root "$3" || return 2
}

assert_no_owned_processes() {
  local root="$1"
  local pid command_line
  local -a pids
  assert_process_ownership "$root" "" 0 || return 1
  pids=("${(@f)$(process_ids_for_root "$root")}")
  for pid in "${pids[@]}"; do
    [[ -z "$pid" ]] && continue
    command_line="$(ps -ww -p "$pid" -o command= 2>/dev/null || true)"
    [[ -n "$command_line" ]] || continue
    process_command_line_owned "$root" "$command_line" || return 1
    echo "BLOCKED: E2E process still belongs to the cleaned root (PID $pid)"
    return 1
  done
}

cleanup_duplicate() {
  local issue="$1" tested_ref="$2" root="$3" receipt receipt_issue receipt_ref receipt_root handoff
  receipt="$(cleanup_receipt_path)" || return 1
  path_exists "$receipt" || { echo "BLOCKED: E2E cleanup receipt is missing"; return 1; }
  metadata_matches "$receipt" "$CLEANUP_RECEIPT_KEYS" || { echo "BLOCKED: E2E cleanup receipt is malformed"; return 1; }
  [[ "$(metadata_value "$receipt" version)" == 1 ]] || { echo "BLOCKED: E2E cleanup receipt version is unsupported"; return 1; }
  receipt_issue="$(metadata_value "$receipt" issue)"
  receipt_ref="$(metadata_value "$receipt" ref)"
  receipt_root="$(metadata_value "$receipt" root)"
  [[ "$receipt_issue" =~ '^SAY-[0-9]+$' && "$receipt_ref" =~ '^[0-9a-fA-F]{40}$' ]] || return 1
  assert_session_root "$receipt_root" || return 1
  [[ "$receipt_issue" == "$issue" && "$receipt_ref" == "$tested_ref" && "$receipt_root" == "$root" ]] || { echo "BLOCKED: E2E cleanup receipt identity mismatch"; return 1; }
  assert_checkout "$issue" "$tested_ref" >/dev/null || return $?
  path_exists "$root" && { echo "BLOCKED: cleaned E2E root still exists"; return 1; }
  handoff="$E2E_TEMP_PARENT/nuinui-${issue}-human-e2e.env"
  path_exists "$handoff" && { echo "BLOCKED: cleaned E2E handoff still exists"; return 1; }
  assert_no_owned_processes "$root" || return 1
  printf 'E2E CLEANUP ALREADY COMPLETE\nissue=%s\nref=%s\ne2e_root=%s\nmutation=no-op\n' \
    "$issue" "$tested_ref" "$root"
}

cleanup() {
  local issue="$1"
  local tested_ref="$2"
  local requested_root="$3"
  local session="" session_snapshot="" session_final_snapshot=""
  local session_snapshot_lane="" session_snapshot_issue="" session_snapshot_ref=""
  local session_snapshot_source_fixture="" session_snapshot_root=""
  local session_snapshot_handoff="" session_snapshot_cdp_port="" session_snapshot_launch_pid=""
  local session_snapshot_locale="" session_snapshot_kind=""
  local handoff=""

  assert_cleanup_args "$issue" "$tested_ref" "$requested_root" || return $?
  session="$(session_path)" || { echo "BLOCKED: cannot resolve E2E session path"; return 1; }
  if [[ ! -e "$session" && ! -L "$session" ]]; then
    cleanup_duplicate "$issue" "$tested_ref" "$requested_root"
    return $?
  fi
  [[ -f "$session" && ! -L "$session" ]] || {
    echo "BLOCKED: invalid E2E session metadata"
    return 1
  }
  load_session "$session" || { echo "BLOCKED: invalid E2E session metadata"; return 1; }
  [[ "$SESSION_KIND" == current || "$SESSION_KIND" == pre-locale ]] || {
    echo "BLOCKED: legacy E2E session cannot be cleaned by the current lifecycle"
    return 1
  }
  session_snapshot="$(cat "$session"; printf '\001')" || {
    echo "BLOCKED: could not snapshot E2E session metadata"
    return 1
  }
  session_snapshot_lane="$SESSION_LANE"
  session_snapshot_issue="$SESSION_ISSUE"
  session_snapshot_ref="$SESSION_REF"
  session_snapshot_source_fixture="$SESSION_SOURCE_FIXTURE"
  session_snapshot_root="$SESSION_ROOT"
  session_snapshot_handoff="$SESSION_HANDOFF"
  session_snapshot_cdp_port="$SESSION_CDP_PORT"
  session_snapshot_launch_pid="$SESSION_LAUNCH_PID"
  session_snapshot_locale="$SESSION_LOCALE"
  session_snapshot_kind="$SESSION_KIND"
  [[ "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$issue" && "$SESSION_REF" == "$tested_ref" && "$SESSION_ROOT" == "$requested_root" ]] || {
    echo "BLOCKED: active session identity mismatch"
    return 1
  }
  assert_session_root "$SESSION_ROOT" || return 1
  assert_session_handoff "$SESSION_ISSUE" "$SESSION_HANDOFF" || return 1
  if path_exists "$SESSION_HANDOFF"; then
    assert_handoff_file "$SESSION_HANDOFF" "$SESSION_ISSUE" "$SESSION_REF" "$SESSION_ROOT" "$SESSION_CDP_PORT" "$SESSION_SOURCE_FIXTURE" || return 1
  fi
  assert_checkout "$SESSION_ISSUE" "$SESSION_REF" >/dev/null || return $?
  stop_owned_processes "$SESSION_ROOT" "$SESSION_LAUNCH_PID" || return 1
  assert_no_owned_processes "$SESSION_ROOT" || return 1
  if path_exists "$SESSION_ROOT"; then
    rm -rf -- "$SESSION_ROOT" || { echo "ERROR: could not remove E2E root"; return 1; }
  fi
  handoff="$SESSION_HANDOFF"
  if path_exists "$handoff"; then
    rm -f -- "$handoff" || { echo "ERROR: could not remove E2E handoff"; return 1; }
  fi
  write_cleanup_receipt "$SESSION_ISSUE" "$SESSION_REF" "$SESSION_ROOT" || {
    echo "BLOCKED: could not atomically write the E2E cleanup receipt; session retained"
    return 1
  }
  [[ -f "$session" && ! -L "$session" ]] || {
    echo "BLOCKED: E2E session changed before metadata removal; receipt retained"
    return 1
  }
  session_final_snapshot="$(cat "$session"; printf '\001')" || {
    echo "BLOCKED: E2E session changed before metadata removal; receipt retained"
    return 1
  }
  [[ "$session_final_snapshot" == "$session_snapshot" ]] || {
    echo "BLOCKED: E2E session changed before metadata removal; receipt retained"
    return 1
  }
  load_session "$session" || { echo "BLOCKED: E2E session changed before metadata removal; receipt retained"; return 1; }
  [[ "$SESSION_KIND" == "$session_snapshot_kind" &&
    "$SESSION_LANE" == "$session_snapshot_lane" &&
    "$SESSION_ISSUE" == "$session_snapshot_issue" &&
    "$SESSION_REF" == "$session_snapshot_ref" &&
    "$SESSION_SOURCE_FIXTURE" == "$session_snapshot_source_fixture" &&
    "$SESSION_ROOT" == "$session_snapshot_root" &&
    "$SESSION_HANDOFF" == "$session_snapshot_handoff" &&
    "$SESSION_CDP_PORT" == "$session_snapshot_cdp_port" &&
    "$SESSION_LAUNCH_PID" == "$session_snapshot_launch_pid" &&
    "$SESSION_LOCALE" == "$session_snapshot_locale" &&
    "$SESSION_LANE" == "$E2E_LANE" && "$SESSION_ISSUE" == "$issue" &&
    "$SESSION_REF" == "$tested_ref" && "$SESSION_ROOT" == "$requested_root" ]] || {
    echo "BLOCKED: E2E session changed before metadata removal; receipt retained"
    return 1
  }
  rm -- "$session" || { echo "ERROR: could not remove E2E session metadata; receipt retained"; return 1; }

  echo "E2E CLEANUP COMPLETE"
  echo "  issue=$issue"
  echo "  ref=$tested_ref"
  echo "  e2e_root=$requested_root"
}

assert_no_tracked_mutations() {
  local phase="$1"
  local repo="$E2E_WT"
  local dirty=""

  dirty="$(git -C "$repo" status --porcelain --untracked-files=no)" || {
    echo "ERROR: could not inspect tracked-file status after $phase"
    return 1
  }
  [[ -z "$dirty" ]] || {
    echo "ERROR: tracked-file mutation detected after $phase"
    git -C "$repo" status --short --untracked-files=no
    return 1
  }
}
