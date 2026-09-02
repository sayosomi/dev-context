# Public command membership, usage, validation, routing, and dispatch.
# K is consumed by both usage and the existing context-check implementation.
V=1.8.0
K='preflight verify lane-init begin start resume release recover pr-auto-merge integrate-clean e2e-start e2e-start-local-main e2e-release context-audit context-sync context-dev-audit context-dev-transition doctor transition-audit context-check self-test last-result'

nuinui_validate_public_issue_branch() {
  local nuinui_request_issue nuinui_request_branch nuinui_request_occurrences
  local nuinui_request_occurrence nuinui_request_identifier nuinui_request_identifiers
  local nuinui_request_found

  nuinui_request_issue=$1
  nuinui_request_branch=$2

  if ! nuinui_ownership_valid_issue "$nuinui_request_issue"; then
    printf 'ERROR: requested Issue is invalid\n'
    printf 'expected=SAY-<digits>\nfound=%s\nbranch=%s\n' \
      "$nuinui_request_issue" "$nuinui_request_branch"
    return 1
  fi
  if ! nuinui_ownership_valid_branch "$nuinui_request_branch"; then
    printf 'ERROR: invalid Git branch syntax\n'
    printf 'expected=%s\nfound=invalid\nbranch=%s\n' \
      "$nuinui_request_issue" "$nuinui_request_branch"
    return 1
  fi

  nuinui_request_identifiers=
  nuinui_request_occurrences=$(printf '%s\n' "$nuinui_request_branch" | grep -Eio 'say-[0-9]+' || true)
  for nuinui_request_occurrence in $nuinui_request_occurrences; do
    nuinui_request_identifier=$(printf '%s\n' "$nuinui_request_occurrence" | tr '[:lower:]' '[:upper:]')
    case " $nuinui_request_identifiers " in
      *" $nuinui_request_identifier "*) ;;
      *)
        if [ -n "$nuinui_request_identifiers" ]; then
          nuinui_request_identifiers="$nuinui_request_identifiers $nuinui_request_identifier"
        else
          nuinui_request_identifiers=$nuinui_request_identifier
        fi
        ;;
    esac
  done

  set -- $nuinui_request_identifiers
  case "$#" in
    1)
      [ "$1" = "$nuinui_request_issue" ] && return 0
      printf 'ERROR: branch issue identifier does not match requested Issue\n'
      printf 'expected=%s\nfound=%s\nbranch=%s\n' \
        "$nuinui_request_issue" "$1" "$nuinui_request_branch"
      ;;
    0)
      printf 'ERROR: branch does not contain requested issue identifier\n'
      printf 'expected=%s\nfound=-\nbranch=%s\n' \
        "$nuinui_request_issue" "$nuinui_request_branch"
      ;;
    *)
      nuinui_request_found=$(printf '%s\n' "$nuinui_request_identifiers" | tr ' ' ',')
      printf 'ERROR: branch contains multiple issue identifiers\n'
      printf 'expected=%s\nfound=%s\nbranch=%s\n' \
        "$nuinui_request_issue" "$nuinui_request_found" "$nuinui_request_branch"
      ;;
  esac
  return 1
}

nuinui_validate_public_issue_branch_human() {
  nuinui_validation_public_name=$1
  nuinui_validation_issue=$2
  nuinui_validation_branch=$3
  nuinui_validation_output=
  nuinui_validation_rc=0
  nuinui_validation_output=$(nuinui_validate_public_issue_branch \
    "$nuinui_validation_issue" "$nuinui_validation_branch" 2>&1) || {
    nuinui_validation_rc=$?
  }
  [ "$nuinui_validation_rc" = 0 ] || {
    printf '%s\n' "$nuinui_validation_output" |
      nuinui_render_human_output "$nuinui_validation_public_name"
    return "$nuinui_validation_rc"
  }
}

nuinui_usage() {
  echo "nuinui $V"
  echo "Commands: $K"
}

nuinui_render_human_output() {
  nuinui_human_command=$1
  if [ "$nuinui_human_command" = doctor ]; then
    printf '🩺 NUINUI DOCTOR\n'
  fi
  awk '
    function decorate_prefix(line, prefix,    indentation, remainder) {
      match(line, /^[[:space:]]*/)
      indentation = substr(line, 1, RLENGTH)
      remainder = substr(line, RLENGTH + 1)
      return indentation prefix remainder
    }
    {
      line = $0
      if (line == "===== NUINUI PREFLIGHT RESULT =====") {
        line = "✈️ NUINUI PREFLIGHT RESULT"
      } else if (line == "===== NUINUI COMMAND RESULT =====") {
        line = "🧾 NUINUI COMMAND RESULT"
      } else if (line == "===== NUINUI LAST RESULT =====") {
        line = "🧾 NUINUI LAST RESULT"
      } else if (line == "===== END NUINUI COMMAND RESULT =====" ||
                 line == "===== END NUINUI LAST RESULT =====") {
        next
      } else if (line == "PREFLIGHT PASS") {
        line = "⭕ PREFLIGHT PASS"
      } else if (line == "PREFLIGHT BLOCKED") {
        line = "❌ PREFLIGHT BLOCKED"
      } else if (line == "VERIFIED") {
        line = "🔎 VERIFIED"
      } else if (line == "LANE INITIALIZED") {
        line = "🏗️ LANE INITIALIZED"
      } else if (line == "ALREADY INITIALIZED") {
        line = "♻️ ALREADY INITIALIZED"
      } else if (line == "IMPLEMENTATION STARTED") {
        line = "🚀 IMPLEMENTATION STARTED"
      } else if (line == "IMPLEMENTATION ALREADY STARTED") {
        line = "♻️ IMPLEMENTATION ALREADY STARTED"
      } else if (line == "IMPLEMENTATION RESUMED") {
        line = "▶️ IMPLEMENTATION RESUMED"
      } else if (line == "IMPLEMENTATION RELEASED") {
        line = "🏁 IMPLEMENTATION RELEASED"
      } else if (line == "IMPLEMENTATION ALREADY RELEASED") {
        line = "♻️ IMPLEMENTATION ALREADY RELEASED"
      } else if (line ~ /^RECOVERED operation=/) {
        sub(/^RECOVERED operation=/, "🛟 RECOVERED operation=", line)
      } else if (line == "AUTO-MERGE RESERVED") {
        line = "🔀 AUTO-MERGE RESERVED"
      } else if (line == "AUTO-MERGE ALREADY RESERVED") {
        line = "♻️ AUTO-MERGE ALREADY RESERVED"
      } else if (line == "INTEGRATION PUSHED") {
        line = "🧩 INTEGRATION PUSHED"
      } else if (line == "INTEGRATION ALREADY PUSHED") {
        line = "♻️ INTEGRATION ALREADY PUSHED"
      } else if (line == "E2E STARTED") {
        line = "🖐️ E2E STARTED"
      } else if (line == "E2E ALREADY STARTED") {
        line = "♻️ E2E ALREADY STARTED"
      } else if (line == "E2E RELEASED") {
        line = "🖐️ E2E RELEASED"
      } else if (line == "E2E ALREADY RELEASED") {
        line = "♻️ E2E ALREADY RELEASED"
      } else if (line == "AUDIT COMPLETE") {
        line = "🔎 AUDIT COMPLETE"
      } else if (line == "CONTEXT SYNCED") {
        line = "🔄 CONTEXT SYNCED"
      } else if (line == "DEV-CONTEXT AUDIT COMPLETE") {
        line = "🔎 DEV-CONTEXT AUDIT COMPLETE"
      } else if (line == "DEV-CONTEXT TRANSITIONED") {
        line = "🔀 DEV-CONTEXT TRANSITIONED"
      } else if (line == "DEV-CONTEXT ALREADY TRANSITIONED") {
        line = "♻️ DEV-CONTEXT ALREADY TRANSITIONED"
      } else if (line == "TRANSITION AUDIT (read-only)") {
        line = "🔎 TRANSITION AUDIT (read-only)"
      } else if (line == "TRANSITION AUDIT PREPARED") {
        line = "🔎 TRANSITION AUDIT PREPARED"
      } else if (line == "CONTEXT CHECK PASS") {
        line = "📚 CONTEXT CHECK PASS"
      } else if (line == "CONTEXT CHECK BLOCKED") {
        line = "⛔ CONTEXT CHECK BLOCKED"
      } else if (line == "SELFTEST PASS") {
        line = "🧪 SELFTEST PASS"
      } else if (line ~ /^SELFTEST BLOCKED:/) {
        sub(/^SELFTEST BLOCKED:/, "⛔ SELFTEST BLOCKED:", line)
      }

      if (line ~ /^[[:space:]]*state=FREE/) {
        line = decorate_prefix(line, "🟢 ")
      } else if (line ~ /^[[:space:]]*state=BUSY/) {
        line = decorate_prefix(line, "🔵 ")
      } else if (line ~ /^[[:space:]]*state=RELEASE-PENDING/) {
        line = decorate_prefix(line, "🟠 ")
      } else if (line ~ /^[[:space:]]*state=BLOCKED/) {
        line = decorate_prefix(line, "⛔ ")
      } else if (line ~ /^[[:space:]]*result=SUCCESS$/) {
        line = decorate_prefix(line, "⭕ ")
      } else if (line ~ /^[[:space:]]*result=BLOCKED$/) {
        line = decorate_prefix(line, "⛔ ")
      } else if (line ~ /^[[:space:]]*result=ERROR$/) {
        line = decorate_prefix(line, "❌ ")
      } else if (line ~ /^[[:space:]]*result=INCOMPLETE$/) {
        line = decorate_prefix(line, "🟠 ")
      } else if (line ~ /^[[:space:]]*recovery=READY$/) {
        line = decorate_prefix(line, "🟢 ")
      } else if (line ~ /^[[:space:]]*recovery=BLOCKED$/) {
        line = decorate_prefix(line, "⛔ ")
      } else if (line ~ /^[[:space:]]*recovery=INVALID$/) {
        line = decorate_prefix(line, "❌ ")
      } else if (line ~ /^[[:space:]]*forensic_exception=BLOCKED([[:space:]]|$)/) {
        line = decorate_prefix(line, "⛔ ")
      } else if (line ~ /^[[:space:]]*BLOCKED:/) {
        line = decorate_prefix(line, "⛔ ")
      } else if (line ~ /^[[:space:]]*ERROR:/) {
        line = decorate_prefix(line, "❌ ")
      }
      print line
    }
  '
}

nuinui_run_public() {
  nuinui_public_name=$1
  shift
  nuinui_public_output=
  nuinui_public_rc=0
  nuinui_public_output=$( "$@" 2>&1 ) || nuinui_public_rc=$?
  if [ "$nuinui_public_rc" = 0 ] && [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    case "$nuinui_public_name" in
      begin|start)
        nuinui_public_output=$(printf '%s\nforensic_exception=active\nforensic_worktree=%s' \
          "$nuinui_public_output" "$nuinui_forensic_worktree")
        ;;
      esac
  fi
  if [ -z "$nuinui_public_output" ]; then
    nuinui_public_output=$(printf 'ERROR: public command %s failed without a diagnostic' "$nuinui_public_name")
  fi
  printf '%s\n' "$nuinui_public_output" | nuinui_render_human_output "$nuinui_public_name"
  return "$nuinui_public_rc"
}

nuinui_run_tracked() {
  nuinui_tracked_name=$1
  nuinui_tracked_request_count=$2
  shift 2
  nuinui_tracked_display_file=$(mktemp "${TMPDIR:-/tmp}/nuinui-human-output.XXXXXX") || {
    printf 'ERROR: unable to capture tracked command output\n' |
      nuinui_render_human_output "$nuinui_tracked_name"
    return 1
  }
  nuinui_tracked_rc=0
  nuinui_command_result_run "$nuinui_tracked_name" "$nuinui_tracked_request_count" "$@" >"$nuinui_tracked_display_file" 2>&1 || {
    nuinui_tracked_rc=$?
  }
  nuinui_render_human_output "$nuinui_tracked_name" <"$nuinui_tracked_display_file"
  rm -f -- "$nuinui_tracked_display_file"
  return "$nuinui_tracked_rc"
}

nuinui_lane_dispatch() {
  NUINUI_COMMAND_RESULT_LANE=-
  case "$1" in
    e2e-start|e2e-start-local-main|e2e-release)
      if [ "$#" = 4 ]; then
        NUINUI_COMMAND_RESULT_LANE=$2
      else
        NUINUI_COMMAND_RESULT_LANE=$(lane_execution_cli_resolve_human_test_lane \
          "$NUINUI_RUNTIME_MANIFEST") || return 1
      fi
      ;;
    verify|lane-init|begin|start|resume|release|recover|integrate-clean)
      NUINUI_COMMAND_RESULT_LANE=$2
      ;;
  esac
  lane_execution_cli_command "$NUINUI_RUNTIME_MANIFEST" "$@"
}

nuinui_forensic_worktree=
nuinui_forensic_option_active=0

case "$1" in
  version)
    [ "$#" = 1 ] || { echo 'Usage: nuinui version'; exit 2; }
    echo "$V"
    exit 0
    ;;
  --help|-h|help|'')
    nuinui_usage
    [ -n "$1" ] && exit 0 || exit 2
    ;;
  preflight)
    if [ "$#" = 3 ] && [ "$2" = --forensic-worktree ]; then
      nuinui_forensic_worktree=$3
      nuinui_forensic_option_active=1
    elif [ "$#" != 1 ]; then
      echo 'Usage: nuinui preflight [--forensic-worktree <absolute-path>]'
      exit 2
    fi
    nuinui_require_runtime_manifest || exit 1
    if [ "$nuinui_forensic_option_active" = 1 ]; then
      nuinui_run_public preflight lane_execution_preflight "$NUINUI_RUNTIME_MANIFEST" \
        --forensic-worktree "$nuinui_forensic_worktree"
    else
      nuinui_run_public preflight lane_execution_preflight "$NUINUI_RUNTIME_MANIFEST"
    fi
    exit $?
    ;;
  verify)
    [ "$#" = 5 ] || { echo 'Usage: nuinui verify <implementation-lane> <SAY-123> <expected-base-sha> <branch>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    nuinui_validate_public_issue_branch_human verify "$3" "$5" || exit $?
    nuinui_run_public verify nuinui_lane_dispatch verify "$2" "$3" "$4" "$5"
    exit $?
    ;;
  lane-init)
    [ "$#" = 2 ] || { echo 'Usage: nuinui lane-init <implementation-lane>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    nuinui_run_tracked lane-init "$#" "$@" nuinui_lane_dispatch lane-init "$2"
    exit $?
    ;;
  begin)
    if [ "$#" = 8 ] && [ "$7" = --forensic-worktree ]; then
      nuinui_forensic_worktree=$8
      nuinui_forensic_option_active=1
    elif [ "$#" != 6 ]; then
      echo 'Usage: nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory> [--forensic-worktree <absolute-path>]'
      exit 2
    fi
    nuinui_require_runtime_manifest || exit 1
    nuinui_validate_public_issue_branch_human begin "$3" "$5" || exit $?
    if [ "$nuinui_forensic_option_active" = 1 ]; then
      nuinui_run_tracked begin "$#" "$@" nuinui_lane_dispatch begin \
        "$2" "$3" "$4" "$5" "$6" --forensic-worktree "$8"
    else
      nuinui_run_tracked begin "$#" "$@" nuinui_lane_dispatch begin \
        "$2" "$3" "$4" "$5" "$6"
    fi
    exit $?
    ;;
  start)
    if [ "$#" = 7 ] && [ "$6" = --forensic-worktree ]; then
      nuinui_forensic_worktree=$7
      nuinui_forensic_option_active=1
    elif [ "$#" != 5 ]; then
      echo 'Usage: nuinui start <implementation-lane> <SAY-123> <expected-base-sha> <branch> [--forensic-worktree <absolute-path>]'
      exit 2
    fi
    nuinui_require_runtime_manifest || exit 1
    nuinui_validate_public_issue_branch_human start "$3" "$5" || exit $?
    if [ "$nuinui_forensic_option_active" = 1 ]; then
      nuinui_run_tracked start "$#" "$@" nuinui_lane_dispatch start \
        "$2" "$3" "$4" "$5" --forensic-worktree "$7"
    else
      nuinui_run_tracked start "$#" "$@" nuinui_lane_dispatch start \
        "$2" "$3" "$4" "$5"
    fi
    exit $?
    ;;
  resume)
    [ "$#" = 7 ] || { echo 'Usage: nuinui resume <implementation-lane> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    nuinui_run_tracked resume "$#" "$@" nuinui_lane_dispatch resume "$2" "$3" "$4" "$5" "$6" "$7"
    exit $?
    ;;
  release)
    [ "$#" = 4 ] || { echo 'Usage: nuinui release <implementation-lane> <merged-checkpoint-sha> <expected-claim>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    nuinui_run_tracked release "$#" "$@" nuinui_lane_dispatch release "$2" "$3" "$4"
    exit $?
    ;;
  recover)
    [ "$#" = 3 ] || { echo 'Usage: nuinui recover <implementation-lane> <expected-claim>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    nuinui_run_tracked recover "$#" "$@" nuinui_lane_dispatch recover "$2" "$3"
    exit $?
    ;;
  pr-auto-merge)
    [ "$#" = 4 ] || { echo 'Usage: nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>'; exit 2; }
    nuinui_run_tracked pr-auto-merge "$#" "$@" pam "$2" "$3" "$4"
    exit $?
    ;;
  integrate-clean)
    [ "$#" = 8 ] || { echo 'Usage: nuinui integrate-clean <implementation-lane> <SAY-123> <expected-claim> <expected-topic-head> <expected-main> <verification-script> <expected-files-manifest|->'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    nuinui_run_tracked integrate-clean "$#" "$@" nuinui_lane_dispatch integrate-clean "$2" "$3" "$4" "$5" "$6" "$7" "$8"
    exit $?
    ;;
  e2e-start)
    [ "$#" = 3 ] || [ "$#" = 4 ] || { echo 'Usage: nuinui e2e-start [<human-test-lane>] <SAY-123> <tested-ref>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    if [ "$#" = 4 ]; then
      nuinui_run_tracked e2e-start "$#" "$@" nuinui_lane_dispatch \
        e2e-start "$2" "$3" "$4"
    else
      nuinui_run_tracked e2e-start "$#" "$@" nuinui_lane_dispatch \
        e2e-start "$2" "$3"
    fi
    exit $?
    ;;
  e2e-start-local-main)
    [ "$#" = 3 ] || [ "$#" = 4 ] || { echo 'Usage: nuinui e2e-start-local-main [<human-test-lane>] <SAY-123> <tested-ref>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    if [ "$#" = 4 ]; then
      nuinui_run_tracked e2e-start-local-main "$#" "$@" nuinui_lane_dispatch \
        e2e-start-local-main "$2" "$3" "$4"
    else
      nuinui_run_tracked e2e-start-local-main "$#" "$@" nuinui_lane_dispatch \
        e2e-start-local-main "$2" "$3"
    fi
    exit $?
    ;;
  e2e-release)
    [ "$#" = 3 ] || [ "$#" = 4 ] || { echo 'Usage: nuinui e2e-release [<human-test-lane>] <SAY-123> <tested-ref>'; exit 2; }
    nuinui_require_runtime_manifest || exit 1
    if [ "$#" = 4 ]; then
      nuinui_run_tracked e2e-release "$#" "$@" nuinui_lane_dispatch \
        e2e-release "$2" "$3" "$4"
    else
      nuinui_run_tracked e2e-release "$#" "$@" nuinui_lane_dispatch \
        e2e-release "$2" "$3"
    fi
    exit $?
    ;;
  context-audit)
    [ "$#" = 3 ] || { echo 'Usage: nuinui context-audit <expected-main> <expected-artifact-blob>'; exit 2; }
    nuinui_run_public context-audit context_audit_command "$2" "$3"
    exit $?
    ;;
  context-sync)
    [ "$#" = 3 ] || { echo 'Usage: nuinui context-sync <expected-main> <expected-artifact-blob>'; exit 2; }
    nuinui_run_tracked context-sync "$#" "$@" sy "$2" "$3"
    exit $?
    ;;
  context-dev-audit)
    [ "$#" = 3 ] || { echo 'Usage: nuinui context-dev-audit <expected-branch> <expected-head>'; exit 2; }
    nuinui_run_public context-dev-audit context_dev_audit_command "$2" "$3"
    exit $?
    ;;
  context-dev-transition)
    [ "$#" = 5 ] || { echo 'Usage: nuinui context-dev-transition <expected-old-branch> <expected-old-head> <expected-main> <new-branch>'; exit 2; }
    nuinui_run_tracked context-dev-transition "$#" "$@" context_dev_transition_command "$2" "$3" "$4" "$5"
    exit $?
    ;;
  doctor)
    if [ "$#" = 2 ]; then
      [ "$2" = --full ] || { echo 'Usage: nuinui doctor [--full]'; exit 2; }
      shift
    elif [ "$#" != 1 ]; then
      echo 'Usage: nuinui doctor [--full]'
      exit 2
    fi
    nuinui_run_public doctor doctor "$@"
    exit $?
    ;;
  transition-audit)
    [ "$#" = 1 ] || { echo 'Usage: nuinui transition-audit'; exit 2; }
    nuinui_run_public transition-audit ta
    exit $?
    ;;
  context-check)
    [ "$#" = 1 ] || { nuinui_usage; exit 2; }
    nuinui_run_public context-check cc
    exit $?
    ;;
  self-test)
    [ "$#" = 1 ] || { nuinui_usage; exit 2; }
    nuinui_run_public self-test nuinui_self_test
    exit $?
    ;;
  last-result)
    [ "$#" = 1 ] || { echo 'Usage: nuinui last-result'; exit 2; }
    nuinui_run_public last-result nuinui_command_result_last_result
    exit $?
    ;;
  *)
    nuinui_usage
    exit 2
    ;;
esac
