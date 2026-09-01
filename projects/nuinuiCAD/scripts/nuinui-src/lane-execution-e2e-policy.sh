#!/bin/sh

# nuinuiCAD adapter for the topology-neutral Human-test lifecycle.
# Human-test/session/local-main behavior is project policy; lane topology is
# resolved by the generic manifest runtime.

lane_execution_human_test_marker_path() {
  printf '%s/nuinui-slot\n' "$(lane_execution__git_dir "$1")"
}

lane_execution_human_test_session_path() {
  printf '%s/nuinui-e2e-session\n' "$(lane_execution__git_dir "$1")"
}

lane_execution_human_test_receipt_path() {
  printf '%s/nuinui-e2e-release-receipt\n' "$(lane_execution__git_dir "$1")"
}

lane_execution_nuinui_e2e__path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

lane_execution_nuinui_e2e__regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

lane_execution_nuinui_e2e__read_session() {
  lane_execution_nuinui_e2e_session_path=$1
  lane_execution_nuinui_e2e__regular_file \
    "$lane_execution_nuinui_e2e_session_path" || return 1
  if nuinui_ownership_validate_exact_file "$lane_execution_nuinui_e2e_session_path" \
    issue,ref,source_fixture,root,handoff,cdp_port,launch_pid; then
    lane_execution_nuinui_e2e_source_fixture=$(nuinui_ownership_field \
      "$lane_execution_nuinui_e2e_session_path" source_fixture) || return 1
    case "$lane_execution_nuinui_e2e_source_fixture" in /*) ;; *) return 1 ;; esac
  elif ! nuinui_ownership_validate_exact_file \
    "$lane_execution_nuinui_e2e_session_path" issue,ref,root,handoff,cdp_port,launch_pid; then
    return 1
  fi
  lane_execution_nuinui_e2e_session_issue=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" issue) || return 1
  lane_execution_nuinui_e2e_session_ref=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" ref) || return 1
  lane_execution_nuinui_e2e_session_root=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" root) || return 1
  lane_execution_nuinui_e2e_session_handoff=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" handoff) || return 1
  lane_execution_nuinui_e2e_session_cdp=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" cdp_port) || return 1
  lane_execution_nuinui_e2e_session_pid=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" launch_pid) || return 1
  lane_execution_validate_work_id "$lane_execution_nuinui_e2e_session_issue" &&
    nuinui_ownership_valid_sha "$lane_execution_nuinui_e2e_session_ref" || return 1
  [ -n "$lane_execution_nuinui_e2e_session_root" ] &&
    [ -n "$lane_execution_nuinui_e2e_session_handoff" ] || return 1
  printf '%s\n' "$lane_execution_nuinui_e2e_session_cdp" |
    grep -Eq '^[0-9]+$' || return 1
  printf '%s\n' "$lane_execution_nuinui_e2e_session_pid" |
    grep -Eq '^[0-9]+$' || return 1
}

lane_execution_human_test_start_guard() {
  lane_execution_nuinui_e2e_guard_lane=$1
  lane_execution_nuinui_e2e_guard_repo=$2
  lane_execution_nuinui_e2e_guard_issue=$3
  lane_execution_nuinui_e2e_guard_ref=$4
  lane_execution_nuinui_e2e_guard_mode=$5
  lane_execution_nuinui_e2e_guard_session=$(lane_execution_human_test_session_path \
    "$lane_execution_nuinui_e2e_guard_repo") || return 1
  case "$lane_execution_nuinui_e2e_guard_mode" in
    active)
      lane_execution_nuinui_e2e__path_exists \
        "$lane_execution_nuinui_e2e_guard_session" && {
        echo 'BLOCKED: E2E start requires a valid clean detached checkout with no session'
        return 1
      }
      return 0
      ;;
    duplicate)
      if lane_execution_nuinui_e2e__path_exists \
        "$lane_execution_nuinui_e2e_guard_session"; then
        lane_execution_nuinui_e2e__read_session \
          "$lane_execution_nuinui_e2e_guard_session" || {
          echo 'BLOCKED: duplicate E2E start session is malformed or conflicts with marker'
          return 1
        }
        [ "$lane_execution_nuinui_e2e_session_issue" = \
          "$lane_execution_nuinui_e2e_guard_issue" ] &&
          [ "$lane_execution_nuinui_e2e_session_ref" = \
            "$lane_execution_nuinui_e2e_guard_ref" ] || {
          echo 'BLOCKED: duplicate E2E start session conflicts with marker'
          return 1
        }
      fi
      return 0
      ;;
    *) return 1 ;;
  esac
}

lane_execution_human_test_release_guard() {
  lane_execution_nuinui_e2e_guard_repo=$2
  lane_execution_nuinui_e2e_guard_mode=$5
  lane_execution_nuinui_e2e_guard_stage=$6
  lane_execution_nuinui_e2e_guard_session=$(lane_execution_human_test_session_path \
    "$lane_execution_nuinui_e2e_guard_repo") || return 1
  if lane_execution_nuinui_e2e__path_exists \
    "$lane_execution_nuinui_e2e_guard_session"; then
    if [ "$lane_execution_nuinui_e2e_guard_stage" = after-fetch ]; then
      echo 'BLOCKED: E2E session metadata appeared after fetch'
    else
      echo 'BLOCKED: E2E session metadata must be cleaned up before release'
    fi
    return 1
  fi
  case "$lane_execution_nuinui_e2e_guard_mode" in active|duplicate) return 0 ;; *) return 1 ;; esac
}

lane_execution_human_test_local_main_source_lane() {
  lane_execution_nuinui_source_manifest=$1
  lane_execution_nuinui_source_lane=
  lane_execution_nuinui_source_count=0
  while IFS= read -r lane_execution_nuinui_candidate ||
    [ -n "$lane_execution_nuinui_candidate" ]; do
    [ -n "$lane_execution_nuinui_candidate" ] || continue
    [ "$(lane_manifest_lane_idle_policy "$lane_execution_nuinui_source_manifest" \
      "$lane_execution_nuinui_candidate")" = branch ] || continue
    lane_execution_nuinui_source_lane=$lane_execution_nuinui_candidate
    lane_execution_nuinui_source_count=$((lane_execution_nuinui_source_count + 1))
  done <<EOF
$(lane_manifest_lanes_by_role "$lane_execution_nuinui_source_manifest" implementation)
EOF
  [ "$lane_execution_nuinui_source_count" = 1 ] || {
    echo 'BLOCKED: nuinuiCAD local-main source implementation lane is missing or ambiguous' >&2
    return 1
  }
  printf '%s\n' "$lane_execution_nuinui_source_lane"
}

lane_execution_human_test_local_main_policy() {
  lane_execution_nuinui_local_manifest=$1
  lane_execution_nuinui_local_human_lane=$2
  lane_execution_nuinui_local_issue=$3
  lane_execution_nuinui_local_ref=$4
  lane_execution_validate_work_id "$lane_execution_nuinui_local_issue" || {
    echo 'BLOCKED: invalid local-main Human-test Work-ID'
    return 1
  }
  nuinui_ownership_valid_sha "$lane_execution_nuinui_local_ref" || {
    echo 'BLOCKED: local-main tested-ref must be a full commit SHA'
    return 1
  }
  lane_execution_nuinui_local_ref=$(printf '%s' \
    "$lane_execution_nuinui_local_ref" | tr '[:upper:]' '[:lower:]')
  lane_execution_nuinui_local_source_lane=$(lane_execution_human_test_local_main_source_lane \
    "$lane_execution_nuinui_local_manifest") || return 1
  lane_manifest_validate_lane_name "$lane_execution_nuinui_local_manifest" \
    "$lane_execution_nuinui_local_source_lane" >/dev/null 2>&1 || return 1
  [ "$(lane_manifest_lane_role "$lane_execution_nuinui_local_manifest" \
    "$lane_execution_nuinui_local_source_lane")" = implementation ] || return 1
  lane_execution_nuinui_local_source=$(lane_manifest_lane_path \
    "$lane_execution_nuinui_local_manifest" \
    "$lane_execution_nuinui_local_source_lane") || return 1
  lane_execution_nuinui_local_source=$(lane_execution__canonical_path \
    "$lane_execution_nuinui_local_source") || return 1
  lane_execution_nuinui_local_human=$(lane_manifest_lane_path \
    "$lane_execution_nuinui_local_manifest" "$lane_execution_nuinui_local_human_lane") || return 1
  lane_execution_nuinui_local_human=$(lane_execution__canonical_path \
    "$lane_execution_nuinui_local_human") || return 1
  [ "$lane_execution_nuinui_local_source" != \
    "$lane_execution_nuinui_local_human" ] || {
    echo 'BLOCKED: local-main source lane cannot equal selected Human-test lane'
    return 1
  }
  lane_execution_nuinui_local_default=$(lane_manifest_default_branch \
    "$lane_execution_nuinui_local_manifest") || return 1
  lane_execution_nuinui_local_repository=$(lane_manifest_repository_identity \
    "$lane_execution_nuinui_local_manifest") || return 1
  lane_execution__repository_matches "$lane_execution_nuinui_local_source" \
    "$lane_execution_nuinui_local_repository" || {
    echo 'BLOCKED: local-main source checkout repository identity is invalid'
    return 1
  }
  git -C "$lane_execution_nuinui_local_source" fetch origin \
    "$lane_execution_nuinui_local_default" >/dev/null 2>&1 || {
    echo 'BLOCKED: local-main source fetch failed'
    return 1
  }
  [ -z "$(git -C "$lane_execution_nuinui_local_source" \
    status --porcelain 2>/dev/null)" ] || {
    echo 'BLOCKED: local-main source checkout is not clean'
    return 1
  }
  [ "$(git -C "$lane_execution_nuinui_local_source" \
    symbolic-ref --quiet --short HEAD 2>/dev/null || true)" = \
    codex/interim-sequential ] || {
    echo 'BLOCKED: local-main source checkout is not on codex/interim-sequential'
    return 1
  }
  [ "$(git -C "$lane_execution_nuinui_local_source" rev-parse HEAD 2>/dev/null)" = \
    "$lane_execution_nuinui_local_ref" ] || {
    echo 'BLOCKED: local-main source checkout does not match tested-ref'
    return 1
  }
  lane_execution_nuinui_local_origin=$(lane_execution__origin_default \
    "$lane_execution_nuinui_local_source" "$lane_execution_nuinui_local_default")
  nuinui_ownership_valid_sha "$lane_execution_nuinui_local_origin" || {
    echo 'BLOCKED: local-main source authoritative default branch is invalid'
    return 1
  }
  git -C "$lane_execution_nuinui_local_source" merge-base --is-ancestor \
    "$lane_execution_nuinui_local_origin" "$lane_execution_nuinui_local_ref" || {
    echo 'BLOCKED: local-main tested-ref is not descended from authoritative default branch'
    return 1
  }
  printf 'local_main_source_lane=%s\nlocal_main_source_path=%s\n' \
    "$lane_execution_nuinui_local_source_lane" "$lane_execution_nuinui_local_source"
}
