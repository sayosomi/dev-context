#!/bin/sh

# Read-only canonical implementation-release handoff generation.
#
# The emitted continuation is the existing positional release command.  The
# release mutation path remains the authority for the final race-safe release.

nuinui_release_command_parse_args() {
  nuinui_release_command_lane=
  nuinui_release_command_issue=
  nuinui_release_command_claim=
  nuinui_release_command_lane_seen=0
  nuinui_release_command_issue_seen=0
  nuinui_release_command_claim_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --lane)
        [ "$nuinui_release_command_lane_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --lane\n'
          return 2
        }
        nuinui_release_command_lane_seen=1
        nuinui_release_command_option_name=--lane
        ;;
      --issue)
        [ "$nuinui_release_command_issue_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --issue\n'
          return 2
        }
        nuinui_release_command_issue_seen=1
        nuinui_release_command_option_name=--issue
        ;;
      --claim)
        [ "$nuinui_release_command_claim_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --claim\n'
          return 2
        }
        nuinui_release_command_claim_seen=1
        nuinui_release_command_option_name=--claim
        ;;
      --*|-*)
        printf 'ERROR: unknown option %s\n' "$1"
        printf 'expected named options: --lane --issue --claim\n'
        return 2
        ;;
      *)
        printf 'ERROR: unexpected positional argument %s\n' "$1"
        printf 'use named options: --lane --issue --claim\n'
        return 2
        ;;
    esac

    [ "$#" -ge 2 ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_release_command_option_name"
      return 2
    }
    shift
    [ -n "$1" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_release_command_option_name"
      return 2
    }
    case "$1" in
      --*)
        printf 'ERROR: named option %s is missing its value before %s\n' \
          "$nuinui_release_command_option_name" "$1"
        return 2
        ;;
    esac
    case "$nuinui_release_command_option_name" in
      --lane) nuinui_release_command_lane=$1 ;;
      --issue) nuinui_release_command_issue=$1 ;;
      --claim) nuinui_release_command_claim=$1 ;;
    esac
    shift
  done

  [ "$nuinui_release_command_lane_seen" = 1 ] || {
    printf 'ERROR: missing required named option --lane\n'
    return 2
  }
  [ "$nuinui_release_command_issue_seen" = 1 ] || {
    printf 'ERROR: missing required named option --issue\n'
    return 2
  }
  [ "$nuinui_release_command_claim_seen" = 1 ] || {
    printf 'ERROR: missing required named option --claim\n'
    return 2
  }
}

nuinui_release_command() {
  nuinui_release_command_parse_args "$@" || {
    nuinui_release_command_parse_rc=$?
    return "$nuinui_release_command_parse_rc"
  }
  nuinui_require_runtime_manifest || return 1
  lane_execution_cli_validate_implementation_lane \
    "$NUINUI_RUNTIME_MANIFEST" "$nuinui_release_command_lane" || return 1
  lane_execution_validate_work_id "$nuinui_release_command_issue" || {
    printf 'ERROR: invalid --issue; expected SAY-<digits>\n'
    return 2
  }
  nuinui_ownership_valid_claim "$nuinui_release_command_claim" || {
    printf 'ERROR: invalid --claim; expected a durable claim token\n'
    return 2
  }

  lane_execution_release_candidate_proof \
    "$NUINUI_RUNTIME_MANIFEST" "$nuinui_release_command_lane" \
    "$nuinui_release_command_issue" "$nuinui_release_command_claim" || {
    printf 'BLOCKED: release-command proof failed\n'
    return 1
  }

  nuinui_release_command_cli_path=$P
  case "$nuinui_release_command_cli_path" in
    /*) ;;
    *)
      nuinui_release_command_cli_path=$D/$(basename -- \
        "$nuinui_release_command_cli_path")
      ;;
  esac
  printf '%s\n' 'RELEASE COMMAND READY'
  printf '%s %s %s %s %s\n' \
    "$(nuinui_shell_quote "$nuinui_release_command_cli_path")" \
    "$(nuinui_shell_quote release)" \
    "$(nuinui_shell_quote "$nuinui_release_command_lane")" \
    "$(nuinui_shell_quote "$lane_execution_release_candidate_checkpoint")" \
    "$(nuinui_shell_quote "$nuinui_release_command_claim")"
  printf 'kind=%s\nlane=%s\nissue=%s\nbase=%s\nbranch=%s\ncheckpoint=%s\nclaim=%s\n' \
    "$lane_execution_release_candidate_kind" \
    "$nuinui_release_command_lane" \
    "$lane_execution_release_candidate_issue" \
    "$lane_execution_release_candidate_base" \
    "$lane_execution_release_candidate_branch" \
    "$lane_execution_release_candidate_checkpoint" \
    "$nuinui_release_command_claim"
}
