#!/bin/sh

# Read-only Manual E2E startup handoff generation.
#
# This fragment validates caller intent and projects current Human-test
# occupancy.  It does not select an executor, tested ref, lane (when the
# topology is ambiguous), or any E2E outcome.  e2e-start and
# nuinui-e2e-prepare remain the mutation-time authorities for the emitted
# continuation.

nuinui_e2e_start_command_parse_args() {
  nuinui_e2e_start_command_lane=
  nuinui_e2e_start_command_issue=
  nuinui_e2e_start_command_ref=
  nuinui_e2e_start_command_executor=
  nuinui_e2e_start_command_fixture=
  nuinui_e2e_start_command_locale=default
  nuinui_e2e_start_command_port=
  nuinui_e2e_start_command_lane_seen=0
  nuinui_e2e_start_command_issue_seen=0
  nuinui_e2e_start_command_ref_seen=0
  nuinui_e2e_start_command_executor_seen=0
  nuinui_e2e_start_command_fixture_seen=0
  nuinui_e2e_start_command_locale_seen=0
  nuinui_e2e_start_command_port_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --lane)
        [ "$nuinui_e2e_start_command_lane_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --lane\n'
          return 2
        }
        nuinui_e2e_start_command_lane_seen=1
        nuinui_e2e_start_command_option_name=--lane
        ;;
      --issue)
        [ "$nuinui_e2e_start_command_issue_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --issue\n'
          return 2
        }
        nuinui_e2e_start_command_issue_seen=1
        nuinui_e2e_start_command_option_name=--issue
        ;;
      --tested-ref)
        [ "$nuinui_e2e_start_command_ref_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --tested-ref\n'
          return 2
        }
        nuinui_e2e_start_command_ref_seen=1
        nuinui_e2e_start_command_option_name=--tested-ref
        ;;
      --executor)
        [ "$nuinui_e2e_start_command_executor_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --executor\n'
          return 2
        }
        nuinui_e2e_start_command_executor_seen=1
        nuinui_e2e_start_command_option_name=--executor
        ;;
      --fixture)
        [ "$nuinui_e2e_start_command_fixture_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --fixture\n'
          return 2
        }
        nuinui_e2e_start_command_fixture_seen=1
        nuinui_e2e_start_command_option_name=--fixture
        ;;
      --locale)
        [ "$nuinui_e2e_start_command_locale_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --locale\n'
          return 2
        }
        nuinui_e2e_start_command_locale_seen=1
        nuinui_e2e_start_command_option_name=--locale
        ;;
      --port)
        [ "$nuinui_e2e_start_command_port_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --port\n'
          return 2
        }
        nuinui_e2e_start_command_port_seen=1
        nuinui_e2e_start_command_option_name=--port
        ;;
      --*|-*)
        printf 'ERROR: unknown option %s\n' "$1"
        printf 'expected named options: --issue --tested-ref --executor --fixture [--lane] [--locale] [--port]\n'
        return 2
        ;;
      *)
        printf 'ERROR: unexpected positional argument %s\n' "$1"
        printf 'use named options: --issue --tested-ref --executor --fixture [--lane] [--locale] [--port]\n'
        return 2
        ;;
    esac

    [ "$#" -ge 2 ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_e2e_start_command_option_name"
      return 2
    }
    shift
    [ -n "$1" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_e2e_start_command_option_name"
      return 2
    }
    case "$1" in
      --*)
        printf 'ERROR: named option %s is missing its value before %s\n' \
          "$nuinui_e2e_start_command_option_name" "$1"
        return 2
        ;;
    esac
    case "$nuinui_e2e_start_command_option_name" in
      --lane) nuinui_e2e_start_command_lane=$1 ;;
      --issue) nuinui_e2e_start_command_issue=$1 ;;
      --tested-ref) nuinui_e2e_start_command_ref=$1 ;;
      --executor) nuinui_e2e_start_command_executor=$1 ;;
      --fixture) nuinui_e2e_start_command_fixture=$1 ;;
      --locale) nuinui_e2e_start_command_locale=$1 ;;
      --port) nuinui_e2e_start_command_port=$1 ;;
    esac
    shift
  done

  [ "$nuinui_e2e_start_command_issue_seen" = 1 ] || {
    printf 'ERROR: missing required named option --issue\n'
    return 2
  }
  [ "$nuinui_e2e_start_command_ref_seen" = 1 ] || {
    printf 'ERROR: missing required named option --tested-ref\n'
    return 2
  }
  [ "$nuinui_e2e_start_command_executor_seen" = 1 ] || {
    printf 'ERROR: missing required named option --executor\n'
    return 2
  }
  [ "$nuinui_e2e_start_command_fixture_seen" = 1 ] || {
    printf 'ERROR: missing required named option --fixture\n'
    return 2
  }
}

nuinui_e2e_start_command_invalid_fixture() {
  printf 'ERROR: invalid --fixture; expected a canonical absolute regular file outside the selected Human-test checkout\n'
  return 2
}

nuinui_e2e_start_command_validate_fixture() {
  nuinui_e2e_start_command_fixture_path=$1
  nuinui_e2e_start_command_human_path=$2
  lane_execution_nuinui_e2e__absolute_path \
    "$nuinui_e2e_start_command_fixture_path" || {
    nuinui_e2e_start_command_invalid_fixture
    return 2
  }
  if printf '%s' "$nuinui_e2e_start_command_fixture_path" |
    LC_ALL=C grep -q '[[:cntrl:]]'; then
    nuinui_e2e_start_command_invalid_fixture
    return 2
  fi
  [ -f "$nuinui_e2e_start_command_fixture_path" ] &&
    [ ! -L "$nuinui_e2e_start_command_fixture_path" ] || {
    nuinui_e2e_start_command_invalid_fixture
    return 2
  }
  [ "$(realpath "$nuinui_e2e_start_command_fixture_path" 2>/dev/null)" = \
    "$nuinui_e2e_start_command_fixture_path" ] || {
    nuinui_e2e_start_command_invalid_fixture
    return 2
  }
  case "$nuinui_e2e_start_command_fixture_path" in
    "$nuinui_e2e_start_command_human_path"|\
    "$nuinui_e2e_start_command_human_path"/*)
      nuinui_e2e_start_command_invalid_fixture
      return 2
      ;;
  esac
}

nuinui_e2e_start_command_validate_helper() {
  nuinui_e2e_start_command_helper_path=$1
  case "$nuinui_e2e_start_command_helper_path" in
    /*) ;;
    *)
      printf 'BLOCKED: E2E preparation helper path is not absolute\n'
      return 1
      ;;
  esac
  [ -f "$nuinui_e2e_start_command_helper_path" ] &&
    [ ! -L "$nuinui_e2e_start_command_helper_path" ] &&
    [ -x "$nuinui_e2e_start_command_helper_path" ] || {
      printf 'BLOCKED: E2E preparation helper is missing or not executable\n'
      return 1
    }
  [ "$(realpath "$nuinui_e2e_start_command_helper_path" 2>/dev/null)" = \
    "$nuinui_e2e_start_command_helper_path" ] || {
    printf 'BLOCKED: E2E preparation helper path is not canonical\n'
    return 1
  }
}

nuinui_e2e_start_command() {
  nuinui_e2e_start_command_parse_args "$@" || {
    nuinui_e2e_start_command_parse_rc=$?
    return "$nuinui_e2e_start_command_parse_rc"
  }

  nuinui_require_runtime_manifest || return 1

  lane_execution_validate_work_id \
    "$nuinui_e2e_start_command_issue" || {
    printf 'ERROR: invalid --issue; expected SAY-<digits>\n'
    return 2
  }
  nuinui_ownership_valid_sha \
    "$nuinui_e2e_start_command_ref" || {
    printf 'ERROR: invalid --tested-ref; expected a full 40-character commit SHA\n'
    return 2
  }
  nuinui_e2e_start_command_ref=$(printf '%s' \
    "$nuinui_e2e_start_command_ref" | tr '[:upper:]' '[:lower:]')

  case "$nuinui_e2e_start_command_executor" in
    human|luna) ;;
    *)
      printf 'ERROR: invalid --executor; expected human or luna\n'
      return 2
      ;;
  esac
  case "$nuinui_e2e_start_command_locale" in
    default|ja) ;;
    *)
      printf 'ERROR: invalid --locale; expected default or ja\n'
      return 2
      ;;
  esac
  if [ -n "$nuinui_e2e_start_command_port" ] &&
    ! lane_execution_nuinui_e2e__valid_port \
      "$nuinui_e2e_start_command_port"; then
    printf 'ERROR: invalid --port; expected a TCP port from 1 through 65535\n'
    return 2
  fi

  if [ "$nuinui_e2e_start_command_lane_seen" = 1 ]; then
    nuinui_e2e_start_command_lane_output=$(lane_execution_cli_validate_human_test_lane \
      "$NUINUI_RUNTIME_MANIFEST" "$nuinui_e2e_start_command_lane" 2>&1) || {
      [ -z "$nuinui_e2e_start_command_lane_output" ] ||
        printf '%s\n' "$nuinui_e2e_start_command_lane_output"
      return 1
    }
  else
    nuinui_e2e_start_command_lane_output=$(lane_execution_cli_resolve_human_test_lane \
      "$NUINUI_RUNTIME_MANIFEST" 2>&1) || {
      [ -z "$nuinui_e2e_start_command_lane_output" ] ||
        printf '%s\n' "$nuinui_e2e_start_command_lane_output"
      return 1
    }
    nuinui_e2e_start_command_lane=$nuinui_e2e_start_command_lane_output
  fi

  nuinui_e2e_start_command_human_path=$(lane_manifest_lane_path \
    "$NUINUI_RUNTIME_MANIFEST" "$nuinui_e2e_start_command_lane") || {
    printf 'BLOCKED: selected Human-test lane path is unavailable\n'
    return 1
  }
  nuinui_e2e_start_command_human_path=$(lane_execution__canonical_path \
    "$nuinui_e2e_start_command_human_path") || {
    printf 'BLOCKED: selected Human-test lane checkout is unavailable\n'
    return 1
  }
  nuinui_e2e_start_command_validate_fixture \
    "$nuinui_e2e_start_command_fixture" \
    "$nuinui_e2e_start_command_human_path" || return $?
  nuinui_e2e_start_command_validate_helper "$EH" || return 1

  nuinui_e2e_start_command_preflight_output=
  nuinui_e2e_start_command_preflight_rc=0
  nuinui_e2e_start_command_preflight_output=$(lane_execution_preflight \
    "$NUINUI_RUNTIME_MANIFEST" 2>&1) ||
    nuinui_e2e_start_command_preflight_rc=$?
  [ "$nuinui_e2e_start_command_preflight_rc" = 0 ] || {
    printf '%s\n' "$nuinui_e2e_start_command_preflight_output"
    printf 'BLOCKED: e2e-start-command read-only preflight failed\n'
    return 1
  }

  # Reclassify the selected lane after the full manifest preflight.  This is
  # the fresh selected-lane evidence used for the narrow FREE/BUSY decision;
  # the classifier remains the only occupancy interpretation authority.
  nuinui_e2e_start_command_human_output=
  nuinui_e2e_start_command_human_rc=0
  nuinui_e2e_start_command_human_output=$(lane_execution_nuinui_human_test_classify \
    "$nuinui_e2e_start_command_lane" \
    "$nuinui_e2e_start_command_human_path" \
    "$NUINUI_RUNTIME_MANIFEST" 2>&1) ||
    nuinui_e2e_start_command_human_rc=$?
  [ "$nuinui_e2e_start_command_human_rc" = 0 ] || {
    printf '%s\n' "$nuinui_e2e_start_command_human_output"
    printf 'BLOCKED: selected Human-test lane classification failed\n'
    return 1
  }
  nuinui_e2e_start_command_lane_state=$(printf '%s\n' \
    "$nuinui_e2e_start_command_human_output" |
    sed -n 's/^  state=//p' | tail -n 1)
  case "$nuinui_e2e_start_command_lane_state" in
    FREE) ;;
    BUSY)
      nuinui_e2e_start_command_owner_issue=$(printf '%s\n' \
        "$nuinui_e2e_start_command_human_output" |
        sed -n 's/^  owner_issue=//p' | tail -n 1)
      nuinui_e2e_start_command_owner_ref=$(printf '%s\n' \
        "$nuinui_e2e_start_command_human_output" |
        sed -n 's/^  owner_ref=//p' | tail -n 1)
      if [ "$nuinui_e2e_start_command_owner_issue" != \
        "$nuinui_e2e_start_command_issue" ] ||
        [ "$nuinui_e2e_start_command_owner_ref" != \
          "$nuinui_e2e_start_command_ref" ]; then
        printf '%s\n' "$nuinui_e2e_start_command_human_output"
        printf 'BLOCKED: selected Human-test lane is BUSY for another Issue/ref\n'
        return 1
      fi
      ;;
    *)
      printf '%s\n' "$nuinui_e2e_start_command_human_output"
      printf 'BLOCKED: selected Human-test lane did not produce a valid FREE/BUSY classification\n'
      return 1
      ;;
  esac

  nuinui_e2e_start_command_cli_path=$P
  case "$nuinui_e2e_start_command_cli_path" in
    /*) ;;
    *)
      nuinui_e2e_start_command_cli_path=$D/$(basename -- \
        "$nuinui_e2e_start_command_cli_path")
      ;;
  esac

  printf '%s\n' 'E2E START COMMAND READY'
  printf '%s %s %s %s %s %s %s %s %s %s %s %s' \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_cli_path")" \
    "$(nuinui_shell_quote e2e-start)" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_lane")" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_issue")" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_ref")" \
    '&&' \
    "$(nuinui_shell_quote "$EH")" \
    "$(nuinui_shell_quote prepare)" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_lane")" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_issue")" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_ref")" \
    "$(nuinui_shell_quote "$nuinui_e2e_start_command_fixture")"
  if [ -n "$nuinui_e2e_start_command_port" ]; then
    printf ' %s' "$(nuinui_shell_quote "$nuinui_e2e_start_command_port")"
  fi
  if [ "$nuinui_e2e_start_command_locale" = ja ]; then
    printf ' %s %s' "$(nuinui_shell_quote --locale)" \
      "$(nuinui_shell_quote ja)"
  fi
  printf '\nexecutor=%s\nlane=%s\nissue=%s\ntested_ref=%s\nfixture=%s\nlocale=%s\nport=%s\nlane_state=%s\n' \
    "$nuinui_e2e_start_command_executor" \
    "$nuinui_e2e_start_command_lane" \
    "$nuinui_e2e_start_command_issue" \
    "$nuinui_e2e_start_command_ref" \
    "$nuinui_e2e_start_command_fixture" \
    "$nuinui_e2e_start_command_locale" \
    "${nuinui_e2e_start_command_port:-default}" \
    "$nuinui_e2e_start_command_lane_state"
}
