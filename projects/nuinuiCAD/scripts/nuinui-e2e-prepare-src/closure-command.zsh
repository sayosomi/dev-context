# Canonical Manual E2E cleanup/release/closure handoff resolution and dispatch.

closure_command_parse_args() {
  local -a args
  local i=1 arg value issue_seen=0 lane_seen=0

  CLOSURE_COMMAND_ISSUE=''
  CLOSURE_COMMAND_REQUESTED_LANE=''
  args=("$@")
  while (( i <= $# )); do
    arg="${args[i]}"
    case "$arg" in
      --issue)
        (( issue_seen++ ))
        (( issue_seen == 1 )) || { echo 'ERROR: duplicate --issue option'; return 2; }
        (( i < $# )) || { echo 'ERROR: --issue requires a value'; return 2; }
        value="${args[i+1]}"
        [[ -n "$value" && "$value" != --* && "$value" != -* ]] || {
          echo 'ERROR: --issue requires a value'
          return 2
        }
        CLOSURE_COMMAND_ISSUE="$value"
        (( i += 2 ))
        ;;
      --lane)
        (( lane_seen++ ))
        (( lane_seen == 1 )) || { echo 'ERROR: duplicate --lane option'; return 2; }
        (( i < $# )) || { echo 'ERROR: --lane requires a value'; return 2; }
        value="${args[i+1]}"
        [[ -n "$value" && "$value" != --* && "$value" != -* ]] || {
          echo 'ERROR: --lane requires a value'
          return 2
        }
        CLOSURE_COMMAND_REQUESTED_LANE="$value"
        (( i += 2 ))
        ;;
      --*|-*)
        echo "ERROR: unknown option: $arg"
        return 2
        ;;
      *)
        echo "ERROR: unexpected positional argument: $arg"
        return 2
        ;;
    esac
  done
  (( issue_seen == 1 )) || { echo 'ERROR: --issue is required'; return 2; }
  [[ "$CLOSURE_COMMAND_ISSUE" =~ '^SAY-[0-9]+$' ]] || {
    echo 'ERROR: Issue must look like SAY-123'
    return 2
  }
}

closure_command_resolve_paths() {
  local self="$E2E_HELPER_INVOCATION" self_dir self_name
  case "$self" in
    */*) ;;
    *) self="$(command -v -- "$self" 2>/dev/null || true)" ;;
  esac
  [[ -n "$self" ]] || { echo 'BLOCKED: could not resolve the E2E preparation helper path'; return 1; }
  case "$self" in
    /*) ;;
    *) self="$(CDPATH= cd -- "$(dirname -- "$self")" && pwd -P)/$(basename -- "$self")" || return 1 ;;
  esac
  self_dir="$(CDPATH= cd -- "$(dirname -- "$self")" && pwd -P)" || return 1
  self_name="$(basename -- "$self")"
  [[ "$self_name" == nuinui-e2e-prepare && -f "$self" && ! -L "$self" && -x "$self" ]] || {
    echo 'BLOCKED: closure-command must run from the canonical E2E preparation helper'
    return 1
  }
  CLOSURE_COMMAND_PREPARE="$self_dir/$self_name"
  CLOSURE_COMMAND_NUINUI="$self_dir/nuinui"
  [[ -f "$CLOSURE_COMMAND_NUINUI" && ! -L "$CLOSURE_COMMAND_NUINUI" && -x "$CLOSURE_COMMAND_NUINUI" ]] || {
    echo "BLOCKED: sibling nuinui command is unavailable: $CLOSURE_COMMAND_NUINUI"
    return 1
  }
}

closure_command_receipt_values() {
  local receipt="$1" keys="$2"
  metadata_matches "$receipt" "$keys" || return 1
  CLOSURE_RECEIPT_VERSION="$(metadata_value "$receipt" version)" || return 1
  CLOSURE_RECEIPT_ISSUE="$(metadata_value "$receipt" issue)" || return 1
  CLOSURE_RECEIPT_REF="$(metadata_value "$receipt" ref)" || return 1
  [[ "$CLOSURE_RECEIPT_VERSION" == 1 && "$CLOSURE_RECEIPT_ISSUE" =~ '^SAY-[0-9]+$' &&
    "$CLOSURE_RECEIPT_REF" =~ '^[0-9a-fA-F]{40}$' ]] || return 1
  if [[ "$keys" == "$CLEANUP_RECEIPT_KEYS" ]]; then
    CLOSURE_RECEIPT_ROOT="$(metadata_value "$receipt" root)" || return 1
    assert_session_root "$CLOSURE_RECEIPT_ROOT" || return 1
  else
    CLOSURE_RECEIPT_ROOT=''
  fi
}

closure_command_release_receipt_path() {
  local git_dir
  git_dir="$(git -C "$E2E_WT" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  printf '%s/nuinui-e2e-release-receipt\n' "$git_dir"
}

closure_command_validate_release_receipt() {
  local receipt="$1"
  closure_command_receipt_values "$receipt" 'version,issue,ref' || {
    echo 'BLOCKED: E2E release receipt is malformed'
    return 1
  }
}

closure_command_validate_cleanup_receipt() {
  local receipt="$1" issue="$2" tested_ref="$3" root="$4"
  closure_command_receipt_values "$receipt" "$CLEANUP_RECEIPT_KEYS" || {
    echo 'BLOCKED: E2E cleanup receipt is malformed'
    return 1
  }
  [[ "$CLOSURE_RECEIPT_ISSUE" == "$issue" && "${CLOSURE_RECEIPT_REF:l}" == "${tested_ref:l}" &&
    "$CLOSURE_RECEIPT_ROOT" == "$root" ]] || {
    echo 'BLOCKED: E2E cleanup receipt identity mismatch'
    return 1
  }
}

closure_command_validate_marker_session() {
  local session="$1" lane="$2" issue="$3" tested_ref="$4"
  [[ -f "$session" && ! -L "$session" ]] || {
    echo 'BLOCKED: invalid E2E session metadata'
    return 1
  }
  load_session "$session" || { echo 'BLOCKED: invalid E2E session metadata'; return 1; }
  case "$SESSION_KIND" in
    preparing)
      echo 'BLOCKED: E2E preparation is already in flight'
      return 1
      ;;
    current|pre-locale)
      [[ "$SESSION_LANE" == "$lane" && "$SESSION_ISSUE" == "$issue" &&
        "${SESSION_REF:l}" == "${tested_ref:l}" ]] || {
        echo 'BLOCKED: active session identity does not match the marker'
        return 1
      }
      assert_session_root "$SESSION_ROOT" || {
        echo 'BLOCKED: active E2E root is invalid'
        return 1
      }
      ;;
    *)
      echo 'BLOCKED: legacy E2E session cannot qualify for closure'
      return 1
      ;;
  esac
}

# Return 0 for a requested generation, 3 for a valid unrelated lane, and 1 for
# any malformed or unsafe evidence. The returned mode/root/ref are globals.
closure_command_inspect_lane() {
  local lane="$1" requested_issue="$2" marker session cleanup_receipt release_receipt
  local marker_issue marker_ref

  select_human_lane "$lane" >/dev/null 2>&1 || {
    echo "BLOCKED: selected lane is not a valid Human-test lane: $lane"
    return 1
  }
  marker="$(marker_path)" || { echo 'BLOCKED: cannot resolve E2E marker path'; return 1; }
  session="$(session_path)" || { echo 'BLOCKED: cannot resolve E2E session path'; return 1; }
  cleanup_receipt="$(cleanup_receipt_path)" || { echo 'BLOCKED: cannot resolve E2E cleanup receipt path'; return 1; }
  release_receipt="$(closure_command_release_receipt_path)" || {
    echo 'BLOCKED: cannot resolve E2E release receipt path'
    return 1
  }

  CLOSURE_COMMAND_MODE=''
  CLOSURE_COMMAND_ROOT=''
  CLOSURE_COMMAND_REF=''

  if path_exists "$marker"; then
    [[ -f "$marker" && ! -L "$marker" ]] || { echo 'BLOCKED: E2E marker is malformed'; return 1; }
    assert_marker "$marker" >/dev/null || return 1
    marker_issue="$MARKER_ISSUE"
    marker_ref="$MARKER_REF"
    if path_exists "$release_receipt"; then
      closure_command_validate_release_receipt "$release_receipt" || return 1
    fi
    if [[ "$marker_issue" != "$requested_issue" ]]; then
      if path_exists "$session"; then
        closure_command_validate_marker_session "$session" "$lane" "$marker_issue" "$marker_ref" || return 1
      fi
      return 3
    fi
    assert_checkout "$marker_issue" "$marker_ref" >/dev/null || {
      echo 'BLOCKED: active E2E checkout identity could not be proved'
      return 1
    }
    if ! path_exists "$session"; then
      path_exists "$cleanup_receipt" || { echo 'BLOCKED: E2E cleanup receipt is missing'; return 1; }
      closure_command_receipt_values "$cleanup_receipt" "$CLEANUP_RECEIPT_KEYS" || {
        echo 'BLOCKED: E2E cleanup receipt is malformed'
        return 1
      }
      [[ "$CLOSURE_RECEIPT_ISSUE" == "$marker_issue" &&
        "${CLOSURE_RECEIPT_REF:l}" == "${marker_ref:l}" ]] || {
        echo 'BLOCKED: E2E cleanup receipt identity mismatch'
        return 1
      }
      CLOSURE_COMMAND_ROOT="$CLOSURE_RECEIPT_ROOT"
      CLOSURE_COMMAND_REF="$marker_ref"
      CLOSURE_COMMAND_MODE='cleanup-duplicate'
      return 0
    fi
    closure_command_validate_marker_session "$session" "$lane" "$marker_issue" "$marker_ref" || return 1
    CLOSURE_COMMAND_ROOT="$SESSION_ROOT"
    CLOSURE_COMMAND_REF="$marker_ref"
    CLOSURE_COMMAND_MODE='active'
    return 0
  fi

  if path_exists "$session"; then
    echo 'BLOCKED: E2E session exists without a valid active marker'
    return 1
  fi
  path_exists "$cleanup_receipt" || return 3
  closure_command_receipt_values "$cleanup_receipt" "$CLEANUP_RECEIPT_KEYS" || {
    echo 'BLOCKED: E2E cleanup receipt is malformed'
    return 1
  }
  [[ "$CLOSURE_RECEIPT_ISSUE" == "$requested_issue" ]] || return 3
  CLOSURE_COMMAND_REF="$CLOSURE_RECEIPT_REF"
  CLOSURE_COMMAND_ROOT="$CLOSURE_RECEIPT_ROOT"
  path_exists "$release_receipt" || { echo 'BLOCKED: E2E release receipt is missing'; return 1; }
  closure_command_validate_release_receipt "$release_receipt" || return 1
  [[ "$CLOSURE_RECEIPT_ISSUE" == "$requested_issue" && "${CLOSURE_RECEIPT_REF:l}" == "${CLOSURE_COMMAND_REF:l}" ]] || {
    echo 'BLOCKED: E2E release receipt identity mismatch'
    return 1
  }
  CLOSURE_COMMAND_MODE='released'
  return 0
}

closure_command_resolve_generation() {
  local issue="$1" requested_lane="$2" lane rc count=0
  local -a lanes matches refs roots modes

  matches=(); refs=(); roots=(); modes=()
  if [[ -n "$requested_lane" ]]; then
    closure_command_inspect_lane "$requested_lane" "$issue"
    rc=$?
    (( rc == 0 )) || {
      (( rc == 3 )) && echo "BLOCKED: requested Issue has no provable generation on lane: $requested_lane"
      return 1
    }
    CLOSURE_COMMAND_LANE="$requested_lane"
    return 0
  fi

  lanes=("${(@f)$(lane_manifest_lanes_by_role "$E2E_MANIFEST" human-test)}")
  (( ${#lanes} > 0 )) || { echo 'BLOCKED: no Human-test lane is declared'; return 1; }
  for lane in "${lanes[@]}"; do
    [[ -n "$lane" ]] || continue
    closure_command_inspect_lane "$lane" "$issue"
    rc=$?
    if (( rc == 0 )); then
      (( count++ ))
      matches+=("$lane")
      refs+=("$CLOSURE_COMMAND_REF")
      roots+=("$CLOSURE_COMMAND_ROOT")
      modes+=("$CLOSURE_COMMAND_MODE")
    elif (( rc != 3 )); then
      return 1
    fi
  done
  (( count == 1 )) || {
    if (( count == 0 )); then
      echo "BLOCKED: no unique Human-test generation is proved for Issue $issue"
    else
      echo "BLOCKED: multiple Human-test generations match Issue $issue: ${matches[*]}"
    fi
    return 1
  }
  CLOSURE_COMMAND_LANE="${matches[1]}"
  CLOSURE_COMMAND_REF="${refs[1]}"
  CLOSURE_COMMAND_ROOT="${roots[1]}"
  CLOSURE_COMMAND_MODE="${modes[1]}"
}

closure_command_run() {
  local stage rc
  if [[ "$CLOSURE_COMMAND_MODE" != released ]]; then
    stage='cleanup'
    echo "CLOSURE STAGE: $stage"
    "$CLOSURE_COMMAND_PREPARE" cleanup "$CLOSURE_COMMAND_LANE" "$CLOSURE_COMMAND_ISSUE" "$CLOSURE_COMMAND_REF" "$CLOSURE_COMMAND_ROOT" || {
      rc=$?
      echo "BLOCKED: closure-command stopped after stage=$stage"
      return "$rc"
    }
  fi

  stage='e2e-release'
  echo "CLOSURE STAGE: $stage"
  "$CLOSURE_COMMAND_NUINUI" e2e-release "$CLOSURE_COMMAND_LANE" "$CLOSURE_COMMAND_ISSUE" "$CLOSURE_COMMAND_REF" || {
    rc=$?
    echo "BLOCKED: closure-command stopped after stage=$stage"
    return "$rc"
  }

  stage='closure-check'
  echo "CLOSURE STAGE: $stage"
  "$CLOSURE_COMMAND_PREPARE" closure-check "$CLOSURE_COMMAND_LANE" "$CLOSURE_COMMAND_ISSUE" || {
    rc=$?
    echo "BLOCKED: closure-command stopped after stage=$stage"
    return "$rc"
  }
}

closure_command() {
  closure_command_parse_args "$@" || return $?
  e2e_context || { echo 'BLOCKED: authoritative project lane manifest is unavailable'; return 1; }
  closure_command_resolve_paths || return 1
  closure_command_resolve_generation "$CLOSURE_COMMAND_ISSUE" "$CLOSURE_COMMAND_REQUESTED_LANE" || return 1
  echo 'E2E CLOSURE HANDOFF'
  echo "  issue=$CLOSURE_COMMAND_ISSUE"
  echo "  lane=$CLOSURE_COMMAND_LANE"
  echo "  ref=$CLOSURE_COMMAND_REF"
  echo "  e2e_root=$CLOSURE_COMMAND_ROOT"
  if [[ "$CLOSURE_COMMAND_MODE" == released ]]; then
    echo '  cleanup=already-proven-by-exact-receipt'
  fi
  echo '  order=cleanup -> e2e-release -> closure-check'
  closure_command_run
}
