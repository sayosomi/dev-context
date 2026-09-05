# Public command membership, usage, validation, routing, and dispatch.
# K is consumed by both usage and the existing context-check implementation.
V=1.8.4
K='preflight verify lane-init begin begin-command start resume release recover pr-auto-merge integrate-clean e2e-start e2e-start-command e2e-start-local-main e2e-release context-audit context-sync context-dev-audit context-dev-transition context-dev-next doctor transition-audit context-check self-test last-result'

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

nuinui_shell_quote() {
  nuinui_shell_quote_value=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  printf "'%s'" "$nuinui_shell_quote_value"
}

nuinui_begin_command_parse_args() {
  nuinui_begin_command_lane=
  nuinui_begin_command_issue=
  nuinui_begin_command_base=
  nuinui_begin_command_branch=
  nuinui_begin_command_forensic=
  nuinui_begin_command_lane_seen=0
  nuinui_begin_command_issue_seen=0
  nuinui_begin_command_base_seen=0
  nuinui_begin_command_branch_seen=0
  nuinui_begin_command_forensic_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --lane)
        [ "$nuinui_begin_command_lane_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --lane\n'
          return 2
        }
        nuinui_begin_command_lane_seen=1
        nuinui_begin_command_option_name=--lane
        ;;
      --issue)
        [ "$nuinui_begin_command_issue_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --issue\n'
          return 2
        }
        nuinui_begin_command_issue_seen=1
        nuinui_begin_command_option_name=--issue
        ;;
      --base)
        [ "$nuinui_begin_command_base_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --base\n'
          return 2
        }
        nuinui_begin_command_base_seen=1
        nuinui_begin_command_option_name=--base
        ;;
      --branch)
        [ "$nuinui_begin_command_branch_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --branch\n'
          return 2
        }
        nuinui_begin_command_branch_seen=1
        nuinui_begin_command_option_name=--branch
        ;;
      --forensic-worktree)
        [ "$nuinui_begin_command_forensic_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --forensic-worktree\n'
          return 2
        }
        nuinui_begin_command_forensic_seen=1
        nuinui_begin_command_option_name=--forensic-worktree
        ;;
      --*|-*)
        printf 'ERROR: unknown option %s\n' "$1"
        printf 'expected named options: --lane --issue --base --branch [--forensic-worktree]\n'
        return 2
        ;;
      *)
        printf 'ERROR: unexpected positional argument %s\n' "$1"
        printf 'use named options: --lane --issue --base --branch [--forensic-worktree]\n'
        return 2
        ;;
    esac

    [ "$#" -ge 2 ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_begin_command_option_name"
      return 2
    }
    shift
    [ -n "$1" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_begin_command_option_name"
      return 2
    }
    case "$1" in
      --*)
        printf 'ERROR: named option %s is missing its value before %s\n' \
          "$nuinui_begin_command_option_name" "$1"
        return 2
        ;;
    esac
    case "$nuinui_begin_command_option_name" in
      --lane) nuinui_begin_command_lane=$1 ;;
      --issue) nuinui_begin_command_issue=$1 ;;
      --base) nuinui_begin_command_base=$1 ;;
      --branch) nuinui_begin_command_branch=$1 ;;
      --forensic-worktree) nuinui_begin_command_forensic=$1 ;;
    esac
    shift
  done

  [ "$nuinui_begin_command_lane_seen" = 1 ] || {
    printf 'ERROR: missing required named option --lane\n'
    return 2
  }
  [ "$nuinui_begin_command_issue_seen" = 1 ] || {
    printf 'ERROR: missing required named option --issue\n'
    return 2
  }
  [ "$nuinui_begin_command_base_seen" = 1 ] || {
    printf 'ERROR: missing required named option --base\n'
    return 2
  }
  [ "$nuinui_begin_command_branch_seen" = 1 ] || {
    printf 'ERROR: missing required named option --branch\n'
    return 2
  }
}

nuinui_begin_command() {
  nuinui_begin_command_parse_args "$@" || {
    nuinui_begin_command_parse_rc=$?
    return "$nuinui_begin_command_parse_rc"
  }

  nuinui_require_runtime_manifest || return 1
  nuinui_begin_command_lane_output=$(lane_execution_cli_validate_implementation_lane \
    "$NUINUI_RUNTIME_MANIFEST" "$nuinui_begin_command_lane" 2>&1) || {
    [ -z "$nuinui_begin_command_lane_output" ] ||
      printf '%s\n' "$nuinui_begin_command_lane_output"
    printf 'BLOCKED: begin-command selected lane is not a declared implementation lane\n'
    return 1
  }

  nuinui_begin_command_issue_output=$(nuinui_validate_public_issue_branch \
    "$nuinui_begin_command_issue" "$nuinui_begin_command_branch" 2>&1) || {
    [ -z "$nuinui_begin_command_issue_output" ] ||
      printf '%s\n' "$nuinui_begin_command_issue_output"
    printf 'ERROR: begin-command Issue/branch validation failed\n'
    return 2
  }
  nuinui_ownership_valid_sha "$nuinui_begin_command_base" || {
    printf 'ERROR: invalid --base; expected a full 40-character commit SHA\n'
    printf 'found=%s\n' "$nuinui_begin_command_base"
    return 2
  }

  nuinui_forensic_worktree=
  nuinui_forensic_option_active=0
  if [ "$nuinui_begin_command_forensic_seen" = 1 ]; then
    nuinui_forensic_worktree=$nuinui_begin_command_forensic
    nuinui_forensic_option_active=1
  fi

  nuinui_begin_command_preflight_output=
  nuinui_begin_command_preflight_rc=0
  if [ "$nuinui_forensic_option_active" = 1 ]; then
    nuinui_begin_command_preflight_output=$(lane_execution_preflight \
      "$NUINUI_RUNTIME_MANIFEST" --forensic-worktree "$nuinui_forensic_worktree" 2>&1) ||
      nuinui_begin_command_preflight_rc=$?
  else
    nuinui_begin_command_preflight_output=$(lane_execution_preflight \
      "$NUINUI_RUNTIME_MANIFEST" 2>&1) ||
      nuinui_begin_command_preflight_rc=$?
  fi
  [ "$nuinui_begin_command_preflight_rc" = 0 ] || {
    printf '%s\n' "$nuinui_begin_command_preflight_output"
    printf 'BLOCKED: begin-command read-only preflight failed\n'
    return 1
  }

  nuinui_begin_command_inventory=
  nuinui_begin_command_inventory_rc=0
  nuinui_begin_command_inventory=$(lane_execution_inventory_from_audit \
    "$NUINUI_RUNTIME_MANIFEST" "$nuinui_begin_command_preflight_output" 2>&1) ||
    nuinui_begin_command_inventory_rc=$?
  [ "$nuinui_begin_command_inventory_rc" = 0 ] &&
    [ -n "$nuinui_begin_command_inventory" ] || {
    printf '%s\n' "$nuinui_begin_command_preflight_output"
    [ -z "$nuinui_begin_command_inventory" ] ||
      printf 'inventory_evidence:\n%s\n' "$nuinui_begin_command_inventory"
    printf 'BLOCKED: begin-command canonical implementation inventory is unavailable\n'
    return 1
  }
  nuinui_begin_command_target_state=$(lane_execution__inventory_value \
    "$nuinui_begin_command_inventory" "$nuinui_begin_command_lane" 2>/dev/null || true)
  [ "$nuinui_begin_command_target_state" = FREE ] || {
    printf 'BLOCKED: begin-command target lane is not FREE in the current inventory\n'
    printf 'implementation_inventory=%s\n' "$nuinui_begin_command_inventory"
    return 1
  }

  nuinui_begin_command_verify_output=
  nuinui_begin_command_verify_rc=0
  nuinui_begin_command_verify_output=$(nuinui_lane_dispatch verify \
    "$nuinui_begin_command_lane" "$nuinui_begin_command_issue" \
    "$nuinui_begin_command_base" "$nuinui_begin_command_branch" 2>&1) ||
    nuinui_begin_command_verify_rc=$?
  [ "$nuinui_begin_command_verify_rc" = 0 ] || {
    printf 'BLOCKED: begin-command read-only verify failed; Base, branch, ownership, or current start precondition is stale or conflicting\n'
    [ -z "$nuinui_begin_command_verify_output" ] ||
      printf 'verify_evidence:\n%s\n' "$nuinui_begin_command_verify_output"
    return 1
  }

  printf '%s\n' 'BEGIN COMMAND READY'
  if [ "$nuinui_begin_command_forensic_seen" = 1 ]; then
    printf '%s %s %s %s %s %s %s %s %s\n' \
      "$(nuinui_shell_quote "$P")" \
      "$(nuinui_shell_quote begin)" \
      "$(nuinui_shell_quote "$nuinui_begin_command_lane")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_issue")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_base")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_branch")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_inventory")" \
      "$(nuinui_shell_quote --forensic-worktree)" \
      "$(nuinui_shell_quote "$nuinui_begin_command_forensic")"
  else
    printf '%s %s %s %s %s %s %s\n' \
      "$(nuinui_shell_quote "$P")" \
      "$(nuinui_shell_quote begin)" \
      "$(nuinui_shell_quote "$nuinui_begin_command_lane")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_issue")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_base")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_branch")" \
      "$(nuinui_shell_quote "$nuinui_begin_command_inventory")"
  fi
}

nuinui_context_dev_next_parse_args() {
  nuinui_context_dev_next_old_branch=
  nuinui_context_dev_next_old_head=
  nuinui_context_dev_next_main=
  nuinui_context_dev_next_new_branch=
  nuinui_context_dev_next_old_branch_seen=0
  nuinui_context_dev_next_old_head_seen=0
  nuinui_context_dev_next_main_seen=0
  nuinui_context_dev_next_new_branch_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --old-branch)
        [ "$nuinui_context_dev_next_old_branch_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --old-branch\n'
          return 2
        }
        nuinui_context_dev_next_old_branch_seen=1
        nuinui_context_dev_next_option_name=--old-branch
        ;;
      --old-head)
        [ "$nuinui_context_dev_next_old_head_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --old-head\n'
          return 2
        }
        nuinui_context_dev_next_old_head_seen=1
        nuinui_context_dev_next_option_name=--old-head
        ;;
      --main)
        [ "$nuinui_context_dev_next_main_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --main\n'
          return 2
        }
        nuinui_context_dev_next_main_seen=1
        nuinui_context_dev_next_option_name=--main
        ;;
      --new-branch)
        [ "$nuinui_context_dev_next_new_branch_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --new-branch\n'
          return 2
        }
        nuinui_context_dev_next_new_branch_seen=1
        nuinui_context_dev_next_option_name=--new-branch
        ;;
      --*|-*)
        printf 'ERROR: unknown option %s\n' "$1"
        printf 'expected named options: --old-branch --old-head --main --new-branch\n'
        return 2
        ;;
      *)
        printf 'ERROR: unexpected positional argument %s\n' "$1"
        printf 'use named options: --old-branch --old-head --main --new-branch\n'
        return 2
        ;;
    esac

    [ "$#" -ge 2 ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_context_dev_next_option_name"
      return 2
    }
    shift
    [ -n "$1" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_context_dev_next_option_name"
      return 2
    }
    case "$1" in
      --*)
        printf 'ERROR: named option %s is missing its value before %s\n' \
          "$nuinui_context_dev_next_option_name" "$1"
        return 2
        ;;
    esac
    case "$nuinui_context_dev_next_option_name" in
      --old-branch) nuinui_context_dev_next_old_branch=$1 ;;
      --old-head) nuinui_context_dev_next_old_head=$1 ;;
      --main) nuinui_context_dev_next_main=$1 ;;
      --new-branch) nuinui_context_dev_next_new_branch=$1 ;;
    esac
    shift
  done

  [ "$nuinui_context_dev_next_old_branch_seen" = 1 ] || {
    printf 'ERROR: missing required named option --old-branch\n'
    return 2
  }
  [ "$nuinui_context_dev_next_old_head_seen" = 1 ] || {
    printf 'ERROR: missing required named option --old-head\n'
    return 2
  }
  [ "$nuinui_context_dev_next_main_seen" = 1 ] || {
    printf 'ERROR: missing required named option --main\n'
    return 2
  }
  [ "$nuinui_context_dev_next_new_branch_seen" = 1 ] || {
    printf 'ERROR: missing required named option --new-branch\n'
    return 2
  }
}

nuinui_usage() {
  echo "nuinui $V"
  echo "Commands: $K"
  echo 'Usage: nuinui begin-command --lane <implementation-lane> --issue <SAY-123> --base <expected-base-sha> --branch <branch> [--forensic-worktree <absolute-path>]'
  echo 'Usage: nuinui e2e-start-command --issue <SAY-123> --tested-ref <full-sha> --executor <human|luna> --fixture <absolute-fixture-path> [--lane <human-test-lane>] [--locale <default|ja>] [--port <port>]'
  echo 'Usage: nuinui context-dev-next --old-branch <expected-old-branch> --old-head <expected-old-head> --main <expected-main> --new-branch <new-branch>'
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
  begin-command)
    shift
    nuinui_run_public begin-command nuinui_begin_command "$@"
    exit $?
    ;;
  e2e-start-command)
    shift
    nuinui_run_public e2e-start-command nuinui_e2e_start_command "$@"
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
  context-dev-next)
    nuinui_context_dev_next_request_count=$#
    shift
    nuinui_context_dev_next_parse_args "$@" || exit $?
    nuinui_run_tracked context-dev-transition "$nuinui_context_dev_next_request_count" \
      context-dev-transition "$@" context_dev_next_command \
      "$nuinui_context_dev_next_old_branch" "$nuinui_context_dev_next_old_head" \
      "$nuinui_context_dev_next_main" "$nuinui_context_dev_next_new_branch"
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
