#!/bin/sh

# Staged topology-neutral command router.
#
# The development CLI keeps the manifest explicit.  The standalone public
# wrapper resolves its versioned project manifest before calling this router.
# This router owns lane role validation and E2E lane selection; operation-
# specific adapters receive the validated lane and manifest and keep their
# existing durable semantics.

lane_execution_cli_source_dir=${LANE_EXECUTION_SOURCE_DIR:-}
if [ -z "$lane_execution_cli_source_dir" ] &&
  [ "${LANE_EXECUTION_CLI_EXECUTE:-0}" = 1 ]; then
  lane_execution_cli_source_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
fi
if ! command -v lane_manifest_validate >/dev/null 2>&1 &&
  [ -n "$lane_execution_cli_source_dir" ]; then
  . "$lane_execution_cli_source_dir/manifest.sh"
fi
if ! command -v lane_execution_begin >/dev/null 2>&1 &&
  [ -n "$lane_execution_cli_source_dir" ]; then
  . "$lane_execution_cli_source_dir/lifecycle.sh"
fi
if ! command -v lane_execution_human_test_start >/dev/null 2>&1 &&
  [ -n "$lane_execution_cli_source_dir" ]; then
  . "$lane_execution_cli_source_dir/human-test.sh"
fi

lane_execution_cli_validate_lane() {
  [ "$#" = 3 ] || return 2
  lane_execution_cli_manifest=$1
  lane_execution_cli_lane=$2
  lane_execution_cli_role=$3
  lane_manifest_validate "$lane_execution_cli_manifest" || return 1
  lane_manifest_validate_lane_name "$lane_execution_cli_manifest" \
    "$lane_execution_cli_lane" >/dev/null 2>&1 || return 1
  [ "$(lane_manifest_lane_role "$lane_execution_cli_manifest" \
    "$lane_execution_cli_lane")" = "$lane_execution_cli_role" ]
}

lane_execution_cli_validate_implementation_lane() {
  lane_execution_cli_validate_lane "$1" "$2" implementation || {
    echo 'BLOCKED: selected lane is not a declared implementation lane'
    return 1
  }
}

lane_execution_cli_validate_human_test_lane() {
  lane_execution_cli_validate_lane "$1" "$2" human-test || {
    echo 'BLOCKED: selected lane is not a declared Human-test lane'
    return 1
  }
}

lane_execution_cli_resolve_human_test_lane() {
  [ "$#" = 1 ] || return 2
  lane_execution_cli_resolve_manifest=$1
  lane_execution_cli_human_lanes=$(lane_manifest_lanes_by_role \
    "$lane_execution_cli_resolve_manifest" human-test) || return 1
  lane_execution_cli_human_count=$(printf '%s\n' \
    "$lane_execution_cli_human_lanes" | grep -c . || true)
  case "$lane_execution_cli_human_count" in
    0)
      echo 'BLOCKED: no Human-test lane configured' >&2
      return 1
      ;;
    1)
      printf '%s\n' "$lane_execution_cli_human_lanes"
      ;;
    *)
      echo 'BLOCKED: explicit Human-test lane required (multiple Human-test lanes configured)' >&2
      printf 'human_test_lanes=%s\n' \
        "$(printf '%s\n' "$lane_execution_cli_human_lanes" | tr '\n' ',')" >&2
      return 1
      ;;
  esac
}

lane_execution_cli_e2e_start() {
  [ "$#" = 3 ] || [ "$#" = 4 ] || return 2
  lane_execution_cli_e2e_manifest=$1
  if [ "$#" = 4 ]; then
    lane_execution_cli_e2e_lane=$2
    lane_execution_cli_e2e_issue=$3
    lane_execution_cli_e2e_ref=$4
    lane_execution_cli_validate_human_test_lane \
      "$lane_execution_cli_e2e_manifest" "$lane_execution_cli_e2e_lane" || return 1
  else
    lane_execution_cli_e2e_lane=$(lane_execution_cli_resolve_human_test_lane \
      "$lane_execution_cli_e2e_manifest") || return 1
    lane_execution_cli_e2e_issue=$2
    lane_execution_cli_e2e_ref=$3
  fi
  lane_execution_human_test_start "$lane_execution_cli_e2e_manifest" \
    "$lane_execution_cli_e2e_lane" "$lane_execution_cli_e2e_issue" \
    "$lane_execution_cli_e2e_ref" 'E2E STARTED' 'E2E ALREADY STARTED'
}

lane_execution_cli_e2e_start_local_main() {
  [ "$#" = 3 ] || [ "$#" = 4 ] || return 2
  lane_execution_cli_e2e_manifest=$1
  if [ "$#" = 4 ]; then
    lane_execution_cli_e2e_lane=$2
    lane_execution_cli_e2e_issue=$3
    lane_execution_cli_e2e_ref=$4
    lane_execution_cli_validate_human_test_lane \
      "$lane_execution_cli_e2e_manifest" "$lane_execution_cli_e2e_lane" || return 1
  else
    lane_execution_cli_e2e_lane=$(lane_execution_cli_resolve_human_test_lane \
      "$lane_execution_cli_e2e_manifest") || return 1
    lane_execution_cli_e2e_issue=$2
    lane_execution_cli_e2e_ref=$3
  fi
  lane_execution_human_test_local_main_policy \
    "$lane_execution_cli_e2e_manifest" "$lane_execution_cli_e2e_lane" \
    "$lane_execution_cli_e2e_issue" "$lane_execution_cli_e2e_ref" || return 1
  lane_execution_human_test_start "$lane_execution_cli_e2e_manifest" \
    "$lane_execution_cli_e2e_lane" "$lane_execution_cli_e2e_issue" \
    "$lane_execution_cli_e2e_ref" 'E2E STARTED' 'E2E ALREADY STARTED'
}

lane_execution_cli_e2e_release() {
  [ "$#" = 3 ] || [ "$#" = 4 ] || return 2
  lane_execution_cli_e2e_manifest=$1
  if [ "$#" = 4 ]; then
    lane_execution_cli_e2e_lane=$2
    lane_execution_cli_e2e_issue=$3
    lane_execution_cli_e2e_ref=$4
    lane_execution_cli_validate_human_test_lane \
      "$lane_execution_cli_e2e_manifest" "$lane_execution_cli_e2e_lane" || return 1
  else
    lane_execution_cli_e2e_lane=$(lane_execution_cli_resolve_human_test_lane \
      "$lane_execution_cli_e2e_manifest") || return 1
    lane_execution_cli_e2e_issue=$2
    lane_execution_cli_e2e_ref=$3
  fi
  lane_execution_human_test_release "$lane_execution_cli_e2e_manifest" \
    "$lane_execution_cli_e2e_lane" "$lane_execution_cli_e2e_issue" \
    "$lane_execution_cli_e2e_ref" 'E2E RELEASED' 'E2E ALREADY RELEASED'
}

if ! command -v lane_execution_cli_implementation_operation >/dev/null 2>&1; then
  lane_execution_cli_implementation_operation() {
    echo "BLOCKED: implementation operation adapter is not assembled: operation=$1 lane=$3"
    return 1
  }
fi

lane_execution_cli_usage() {
  cat <<'EOF'
Usage: lane-execution-cli <manifest> <command> ...
  verify <implementation-lane> <SAY-123> <expected-base-sha> <branch>
  lane-init <implementation-lane>
  begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <inventory> [--forensic-worktree <absolute-path>]
  start <implementation-lane> <SAY-123> <expected-base-sha> <branch> [--forensic-worktree <absolute-path>]
  resume|release|recover|integrate-clean <implementation-lane> ...
  e2e-start|e2e-start-local-main|e2e-release [<human-test-lane>] <SAY-123> <tested-ref>
EOF
}

lane_execution_cli_route_implementation() {
  [ "$#" -ge 3 ] || return 2
  lane_execution_cli_operation=$1
  lane_execution_cli_manifest=$2
  lane_execution_cli_lane=$3
  shift 3
  lane_execution_cli_validate_implementation_lane \
    "$lane_execution_cli_manifest" "$lane_execution_cli_lane" || return 1
  lane_execution_cli_implementation_operation \
    "$lane_execution_cli_operation" "$lane_execution_cli_manifest" \
    "$lane_execution_cli_lane" "$@"
}

lane_execution_cli_command() {
  [ "$#" -ge 2 ] || {
    lane_execution_cli_usage >&2
    return 2
  }
  lane_execution_cli_command_manifest=$1
  lane_execution_cli_command_name=$2
  shift 2
  lane_manifest_validate "$lane_execution_cli_command_manifest" || {
    echo 'BLOCKED: lane manifest is invalid'
    return 1
  }
  NUINUI_RUNTIME_MANIFEST=$lane_execution_cli_command_manifest
  export NUINUI_RUNTIME_MANIFEST
  case "$lane_execution_cli_command_name" in
    e2e-start)
      lane_execution_cli_e2e_start "$lane_execution_cli_command_manifest" "$@"
      ;;
    e2e-start-local-main)
      lane_execution_cli_e2e_start_local_main "$lane_execution_cli_command_manifest" "$@"
      ;;
    e2e-release)
      lane_execution_cli_e2e_release "$lane_execution_cli_command_manifest" "$@"
      ;;
    begin)
      [ "$#" = 5 ] || [ "$#" = 7 ] || return 2
      lane_execution_begin "$lane_execution_cli_command_manifest" "$@"
      ;;
    start)
      [ "$#" = 4 ] || [ "$#" = 6 ] || return 2
      lane_execution_start "$lane_execution_cli_command_manifest" "$@"
      ;;
    verify|lane-init|resume|release|recover|integrate-clean)
      lane_execution_cli_route_implementation \
        "$lane_execution_cli_command_name" "$lane_execution_cli_command_manifest" "$@"
      ;;
    *)
      lane_execution_cli_usage >&2
      return 2
      ;;
  esac
}

if [ "${LANE_EXECUTION_CLI_EXECUTE:-0}" = 1 ] ||
  [ "${0##*/}" = cli.sh ]; then
  lane_execution_cli_command "$@"
fi
