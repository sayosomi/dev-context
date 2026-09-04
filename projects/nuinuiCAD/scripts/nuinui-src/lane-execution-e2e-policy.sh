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

lane_execution_nuinui_e2e__absolute_path() {
  case "$1" in
    /*) ;;
    *) return 1 ;;
  esac
  case "$1" in
    */|*/./*|*/../*|*//*) return 1 ;;
  esac
}

lane_execution_nuinui_e2e__valid_source_fixture() {
  lane_execution_nuinui_e2e_fixture=$1
  lane_execution_nuinui_e2e__absolute_path \
    "$lane_execution_nuinui_e2e_fixture" || return 1
  if [ -e "$lane_execution_nuinui_e2e_fixture" ] ||
    [ -L "$lane_execution_nuinui_e2e_fixture" ]; then
    [ -f "$lane_execution_nuinui_e2e_fixture" ] &&
      [ ! -L "$lane_execution_nuinui_e2e_fixture" ] || return 1
    [ "$(realpath "$lane_execution_nuinui_e2e_fixture" 2>/dev/null)" = \
      "$lane_execution_nuinui_e2e_fixture" ] || return 1
  fi
}

lane_execution_nuinui_e2e__valid_session_root() {
  lane_execution_nuinui_e2e_temp_parent=${NUINUI_E2E_TEMP_PARENT-/private/tmp}
  case "$lane_execution_nuinui_e2e_temp_parent" in
    /) lane_execution_nuinui_e2e_temp_parent_prefix=/ ;;
    *) lane_execution_nuinui_e2e_temp_parent_prefix=${lane_execution_nuinui_e2e_temp_parent%/} ;;
  esac
  lane_execution_nuinui_e2e_root=$1
  lane_execution_nuinui_e2e_relative=${lane_execution_nuinui_e2e_root#"$lane_execution_nuinui_e2e_temp_parent_prefix"/}
  [ "$lane_execution_nuinui_e2e_relative" != \
    "$lane_execution_nuinui_e2e_root" ] || return 1
  case "$lane_execution_nuinui_e2e_relative" in
    nuinui-vscode-e2e.*) ;;
    *) return 1 ;;
  esac
  case "$lane_execution_nuinui_e2e_relative" in
    */*) return 1 ;;
  esac
  [ ! -L "$lane_execution_nuinui_e2e_root" ] || return 1
  lane_execution_nuinui_e2e_parent_real=$(realpath \
    "$lane_execution_nuinui_e2e_temp_parent" 2>/dev/null) || return 1
  if [ -e "$lane_execution_nuinui_e2e_root" ]; then
    [ -d "$lane_execution_nuinui_e2e_root" ] &&
      [ ! -L "$lane_execution_nuinui_e2e_root" ] || return 1
    lane_execution_nuinui_e2e_root_real=$(realpath \
      "$lane_execution_nuinui_e2e_root" 2>/dev/null) || return 1
    [ "$(dirname "$lane_execution_nuinui_e2e_root_real")" = \
      "$lane_execution_nuinui_e2e_parent_real" ] || return 1
  fi
}

lane_execution_nuinui_e2e__expected_session_handoff() {
  lane_execution_nuinui_e2e_temp_parent=${NUINUI_E2E_TEMP_PARENT-/private/tmp}
  lane_execution_nuinui_e2e_temp_parent=${lane_execution_nuinui_e2e_temp_parent%/}
  printf '%s/nuinui-%s-human-e2e.env\n' \
    "$lane_execution_nuinui_e2e_temp_parent" "$1"
}

lane_execution_nuinui_e2e__valid_port() {
  printf '%s\n' "$1" | grep -Eq '^[1-9][0-9]{0,4}$' || return 1
  if [ "$1" -le 65535 ] 2>/dev/null; then
    return 0
  fi
  return 1
}

lane_execution_nuinui_e2e__read_session() {
  lane_execution_nuinui_e2e_session_path=$1
  lane_execution_nuinui_e2e_session_kind=
  lane_execution_nuinui_e2e_session_lane=
  lane_execution_nuinui_e2e_session_issue=
  lane_execution_nuinui_e2e_session_ref=
  lane_execution_nuinui_e2e_session_source_fixture=
  lane_execution_nuinui_e2e_session_root=
  lane_execution_nuinui_e2e_session_handoff=
  lane_execution_nuinui_e2e_session_cdp=
  lane_execution_nuinui_e2e_session_pid=
  lane_execution_nuinui_e2e_session_locale=
  lane_execution_nuinui_e2e_session_prepare_owner=
  lane_execution_nuinui_e2e_session_prepare_pid=
  lane_execution_nuinui_e2e__regular_file \
    "$lane_execution_nuinui_e2e_session_path" || return 1

  if nuinui_ownership_validate_exact_file "$lane_execution_nuinui_e2e_session_path" \
    lane,issue,ref,source_fixture,root,handoff,cdp_port,launch_pid,locale; then
    lane_execution_nuinui_e2e_session_kind=current
  elif nuinui_ownership_validate_exact_file "$lane_execution_nuinui_e2e_session_path" \
    lane,issue,ref,source_fixture,root,handoff,cdp_port,launch_pid; then
    lane_execution_nuinui_e2e_session_kind=pre-locale
  elif nuinui_ownership_validate_exact_file "$lane_execution_nuinui_e2e_session_path" \
    kind,lane,issue,ref,root,prepare_owner,prepare_pid; then
    lane_execution_nuinui_e2e_session_kind=preparing
  elif nuinui_ownership_validate_exact_file \
    "$lane_execution_nuinui_e2e_session_path" issue,ref,root,handoff,cdp_port,launch_pid; then
    lane_execution_nuinui_e2e_session_kind=legacy
  else
    return 1
  fi

  if [ "$lane_execution_nuinui_e2e_session_kind" = current ] ||
    [ "$lane_execution_nuinui_e2e_session_kind" = pre-locale ] ||
    [ "$lane_execution_nuinui_e2e_session_kind" = preparing ]; then
    lane_execution_nuinui_e2e_session_lane=$(nuinui_ownership_field \
      "$lane_execution_nuinui_e2e_session_path" lane) || return 1
    nuinui_ownership_valid_lane_name \
      "$lane_execution_nuinui_e2e_session_lane" || return 1
  fi

  lane_execution_nuinui_e2e_session_issue=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" issue) || return 1
  lane_execution_nuinui_e2e_session_ref=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" ref) || return 1
  lane_execution_nuinui_e2e_session_root=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" root) || return 1
  lane_execution_validate_work_id "$lane_execution_nuinui_e2e_session_issue" &&
    nuinui_ownership_valid_sha "$lane_execution_nuinui_e2e_session_ref" || return 1
  case "$lane_execution_nuinui_e2e_session_kind" in
    current|pre-locale|preparing)
      lane_execution_nuinui_e2e__valid_session_root \
        "$lane_execution_nuinui_e2e_session_root" || return 1
      ;;
    *)
      lane_execution_nuinui_e2e__absolute_path \
        "$lane_execution_nuinui_e2e_session_root" || return 1
      ;;
  esac

  if [ "$lane_execution_nuinui_e2e_session_kind" = preparing ]; then
    lane_execution_nuinui_e2e_session_prepare_owner=$(nuinui_ownership_field \
      "$lane_execution_nuinui_e2e_session_path" prepare_owner) || return 1
    [ "$lane_execution_nuinui_e2e_session_prepare_owner" = \
      nuinui-e2e-prepare ] || return 1
    lane_execution_nuinui_e2e_session_prepare_pid=$(nuinui_ownership_field \
      "$lane_execution_nuinui_e2e_session_path" prepare_pid) || return 1
    printf '%s\n' "$lane_execution_nuinui_e2e_session_prepare_pid" |
      grep -Eq '^[1-9][0-9]*$' || return 1
    return 0
  fi

  lane_execution_nuinui_e2e_session_handoff=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" handoff) || return 1
  lane_execution_nuinui_e2e__absolute_path \
    "$lane_execution_nuinui_e2e_session_handoff" || return 1
  if [ "$lane_execution_nuinui_e2e_session_kind" = current ] ||
    [ "$lane_execution_nuinui_e2e_session_kind" = pre-locale ]; then
    [ "$lane_execution_nuinui_e2e_session_handoff" = \
      "$(lane_execution_nuinui_e2e__expected_session_handoff \
        "$lane_execution_nuinui_e2e_session_issue")" ] || return 1
  fi
  lane_execution_nuinui_e2e_session_cdp=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" cdp_port) || return 1
  lane_execution_nuinui_e2e__valid_port \
    "$lane_execution_nuinui_e2e_session_cdp" || return 1
  lane_execution_nuinui_e2e_session_pid=$(nuinui_ownership_field \
    "$lane_execution_nuinui_e2e_session_path" launch_pid) || return 1
  printf '%s\n' "$lane_execution_nuinui_e2e_session_pid" |
    grep -Eq '^[1-9][0-9]*$' || return 1

  if [ "$lane_execution_nuinui_e2e_session_kind" = current ] ||
    [ "$lane_execution_nuinui_e2e_session_kind" = pre-locale ]; then
    lane_execution_nuinui_e2e_session_source_fixture=$(nuinui_ownership_field \
      "$lane_execution_nuinui_e2e_session_path" source_fixture) || return 1
    lane_execution_nuinui_e2e__valid_source_fixture \
      "$lane_execution_nuinui_e2e_session_source_fixture" || return 1
  fi
  if [ "$lane_execution_nuinui_e2e_session_kind" = current ]; then
    lane_execution_nuinui_e2e_session_locale=$(nuinui_ownership_field \
      "$lane_execution_nuinui_e2e_session_path" locale) || return 1
    case "$lane_execution_nuinui_e2e_session_locale" in
      default|ja) ;;
      *) return 1 ;;
    esac
  fi
}

lane_execution_nuinui_human_test__blocked() {
  printf '  state=BLOCKED reason=%s\n' "$1"
  return 1
}

lane_execution_nuinui_human_test_classify() {
  [ "$#" = 3 ] || return 2
  lane_execution_nuinui_human_lane=$1
  lane_execution_nuinui_human_repo=$2
  lane_execution_nuinui_human_manifest=$3
  lane_execution_nuinui_human_git_dir=$(lane_execution__git_dir \
    "$lane_execution_nuinui_human_repo" 2>/dev/null || true)
  [ -n "$lane_execution_nuinui_human_git_dir" ] || {
    printf '  branch=DETACHED\n  head=\n  clean=no\n  marker=unknown\n  session=unknown\n'
    lane_execution_nuinui_human_test__blocked invalid-checkout
    return 1
  }
  lane_execution_nuinui_human_marker=$(lane_execution_human_test_marker_path \
    "$lane_execution_nuinui_human_repo") || return 1
  lane_execution_nuinui_human_session=$(lane_execution_human_test_session_path \
    "$lane_execution_nuinui_human_repo") || return 1
  lane_execution_nuinui_human_marker_present=0
  lane_execution_nuinui_human_session_present=0
  lane_execution_nuinui_human_marker_exists=0
  lane_execution_nuinui_human_session_exists=0
  lane_execution_nuinui_human_marker_record=
  lane_execution_nuinui_human_session_kind=
  lane_execution_nuinui_human_checkout_readable=1

  lane_execution_nuinui_human_branch=$(git -C \
    "$lane_execution_nuinui_human_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  lane_execution_nuinui_human_head=$(git -C \
    "$lane_execution_nuinui_human_repo" rev-parse HEAD 2>/dev/null || true)
  if lane_execution_nuinui_human_dirty=$(git -C \
    "$lane_execution_nuinui_human_repo" status --porcelain 2>/dev/null); then
    :
  else
    lane_execution_nuinui_human_dirty=
    lane_execution_nuinui_human_checkout_readable=0
  fi
  lane_execution_nuinui_e2e__path_exists \
    "$lane_execution_nuinui_human_marker" && {
    lane_execution_nuinui_human_marker_present=1
    lane_execution_nuinui_human_marker_exists=1
  }
  lane_execution_nuinui_e2e__path_exists \
    "$lane_execution_nuinui_human_session" && {
    lane_execution_nuinui_human_session_present=1
    lane_execution_nuinui_human_session_exists=1
  }
  printf '  branch=%s\n' "${lane_execution_nuinui_human_branch:-DETACHED}"
  printf '  head=%s\n' "$lane_execution_nuinui_human_head"
  printf '  clean=%s\n' "$([ "$lane_execution_nuinui_human_checkout_readable" = 1 ] &&
    [ -z "$lane_execution_nuinui_human_dirty" ] && echo yes || echo no)"
  printf '  marker=%s\n' "$([ "$lane_execution_nuinui_human_marker_present" = 1 ] &&
    echo present || echo none)"
  printf '  session=%s\n' "$([ "$lane_execution_nuinui_human_session_present" = 1 ] &&
    echo present || echo none)"

  if [ "$lane_execution_nuinui_human_marker_present" = 1 ]; then
    lane_execution_nuinui_e2e__regular_file \
      "$lane_execution_nuinui_human_marker" ||
      { lane_execution_nuinui_human_test__blocked invalid-marker-type; return 1; }
    lane_execution_nuinui_human_marker_issue=$(nuinui_ownership_field \
      "$lane_execution_nuinui_human_marker" issue 2>/dev/null || true)
    lane_execution_nuinui_human_marker_ref=$(nuinui_ownership_field \
      "$lane_execution_nuinui_human_marker" ref 2>/dev/null || true)
    nuinui_ownership_validate_exact_file \
      "$lane_execution_nuinui_human_marker" issue,ref ||
      { lane_execution_nuinui_human_test__blocked invalid-marker; return 1; }
    lane_execution_validate_work_id \
      "$lane_execution_nuinui_human_marker_issue" &&
      nuinui_ownership_valid_sha \
        "$lane_execution_nuinui_human_marker_ref" ||
      { lane_execution_nuinui_human_test__blocked invalid-marker-identity; return 1; }
  fi

  if [ "$lane_execution_nuinui_human_marker_present" = 0 ]; then
    [ "$lane_execution_nuinui_human_session_present" = 0 ] ||
      { lane_execution_nuinui_human_test__blocked orphan-session; return 1; }
    [ "$lane_execution_nuinui_human_checkout_readable" = 1 ] ||
      { lane_execution_nuinui_human_test__blocked checkout-unreadable; return 1; }
    [ -z "$lane_execution_nuinui_human_dirty" ] ||
      { lane_execution_nuinui_human_test__blocked dirty-checkout; return 1; }
    [ -z "$lane_execution_nuinui_human_branch" ] ||
      { lane_execution_nuinui_human_test__blocked named-checkout; return 1; }
    nuinui_ownership_valid_sha "$lane_execution_nuinui_human_head" ||
      { lane_execution_nuinui_human_test__blocked invalid-head; return 1; }
    git -C "$lane_execution_nuinui_human_repo" cat-file -e \
      "$lane_execution_nuinui_human_head^{commit}" 2>/dev/null ||
      { lane_execution_nuinui_human_test__blocked invalid-head; return 1; }
    echo '  state=FREE'
    return 0
  fi

  [ "$lane_execution_nuinui_human_checkout_readable" = 1 ] ||
    { lane_execution_nuinui_human_test__blocked checkout-unreadable; return 1; }
  [ -z "$lane_execution_nuinui_human_dirty" ] ||
    { lane_execution_nuinui_human_test__blocked dirty-checkout; return 1; }
  [ -z "$lane_execution_nuinui_human_branch" ] ||
    { lane_execution_nuinui_human_test__blocked named-checkout; return 1; }
  nuinui_ownership_valid_sha "$lane_execution_nuinui_human_head" ||
    { lane_execution_nuinui_human_test__blocked invalid-head; return 1; }
  git -C "$lane_execution_nuinui_human_repo" cat-file -e \
    "$lane_execution_nuinui_human_head^{commit}" 2>/dev/null ||
    { lane_execution_nuinui_human_test__blocked invalid-head; return 1; }
  [ "$lane_execution_nuinui_human_head" = \
    "$lane_execution_nuinui_human_marker_ref" ] ||
    { lane_execution_nuinui_human_test__blocked checkout-head-mismatch; return 1; }

  if [ "$lane_execution_nuinui_human_session_present" = 1 ]; then
    lane_execution_nuinui_e2e__regular_file \
      "$lane_execution_nuinui_human_session" ||
      { lane_execution_nuinui_human_test__blocked invalid-session-type; return 1; }
    lane_execution_nuinui_e2e__read_session \
      "$lane_execution_nuinui_human_session" ||
      { lane_execution_nuinui_human_test__blocked invalid-session; return 1; }
    lane_execution_nuinui_human_session_kind=$lane_execution_nuinui_e2e_session_kind
    printf '  session_kind=%s\n' "$lane_execution_nuinui_human_session_kind"
    if [ "$lane_execution_nuinui_human_session_kind" = legacy ]; then
      lane_execution_nuinui_human_test__blocked unsupported-session-kind
      return 1
    fi
    [ "$lane_execution_nuinui_e2e_session_issue" = \
      "$lane_execution_nuinui_human_marker_issue" ] ||
      { lane_execution_nuinui_human_test__blocked marker-session-issue-mismatch; return 1; }
    [ "$lane_execution_nuinui_e2e_session_ref" = \
      "$lane_execution_nuinui_human_marker_ref" ] ||
      { lane_execution_nuinui_human_test__blocked marker-session-ref-mismatch; return 1; }
    if [ -n "$lane_execution_nuinui_e2e_session_lane" ]; then
      [ "$lane_execution_nuinui_e2e_session_lane" = \
        "$lane_execution_nuinui_human_lane" ] ||
        { lane_execution_nuinui_human_test__blocked session-lane-mismatch; return 1; }
    fi
  fi

  printf '  owner_issue=%s\n  owner_ref=%s\n  state=BUSY\n' \
    "$lane_execution_nuinui_human_marker_issue" \
    "$lane_execution_nuinui_human_marker_ref"
  return 0
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
        case "$lane_execution_nuinui_e2e_session_kind" in
          current|pre-locale|preparing)
            [ "$lane_execution_nuinui_e2e_session_lane" = \
              "$lane_execution_nuinui_e2e_guard_lane" ] || {
              echo 'BLOCKED: duplicate E2E start session lane mismatch'
              return 1
            }
            ;;
        esac
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
