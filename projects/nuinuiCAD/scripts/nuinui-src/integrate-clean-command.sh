#!/bin/sh

# Read-only canonical integrate-clean handoff generation.
#
# The emitted continuation is the existing positional integrate-clean
# command. Semantic eligibility and the mutation-time safety state machine
# remain owned by ChatGPT and integration-clean.sh respectively.

nuinui_integrate_clean_command_parse_args() {
  nuinui_integrate_clean_command_lane=
  nuinui_integrate_clean_command_issue=
  nuinui_integrate_clean_command_claim=
  nuinui_integrate_clean_command_topic_head=
  nuinui_integrate_clean_command_main=
  nuinui_integrate_clean_command_verification_script=
  nuinui_integrate_clean_command_manifest=-
  nuinui_integrate_clean_command_lane_seen=0
  nuinui_integrate_clean_command_issue_seen=0
  nuinui_integrate_clean_command_claim_seen=0
  nuinui_integrate_clean_command_topic_head_seen=0
  nuinui_integrate_clean_command_main_seen=0
  nuinui_integrate_clean_command_verification_script_seen=0
  nuinui_integrate_clean_command_manifest_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --lane)
        [ "$nuinui_integrate_clean_command_lane_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --lane\n'
          return 2
        }
        nuinui_integrate_clean_command_lane_seen=1
        nuinui_integrate_clean_command_option_name=--lane
        ;;
      --issue)
        [ "$nuinui_integrate_clean_command_issue_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --issue\n'
          return 2
        }
        nuinui_integrate_clean_command_issue_seen=1
        nuinui_integrate_clean_command_option_name=--issue
        ;;
      --claim)
        [ "$nuinui_integrate_clean_command_claim_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --claim\n'
          return 2
        }
        nuinui_integrate_clean_command_claim_seen=1
        nuinui_integrate_clean_command_option_name=--claim
        ;;
      --topic-head)
        [ "$nuinui_integrate_clean_command_topic_head_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --topic-head\n'
          return 2
        }
        nuinui_integrate_clean_command_topic_head_seen=1
        nuinui_integrate_clean_command_option_name=--topic-head
        ;;
      --main)
        [ "$nuinui_integrate_clean_command_main_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --main\n'
          return 2
        }
        nuinui_integrate_clean_command_main_seen=1
        nuinui_integrate_clean_command_option_name=--main
        ;;
      --verification-script)
        [ "$nuinui_integrate_clean_command_verification_script_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --verification-script\n'
          return 2
        }
        nuinui_integrate_clean_command_verification_script_seen=1
        nuinui_integrate_clean_command_option_name=--verification-script
        ;;
      --manifest)
        [ "$nuinui_integrate_clean_command_manifest_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --manifest\n'
          return 2
        }
        nuinui_integrate_clean_command_manifest_seen=1
        nuinui_integrate_clean_command_option_name=--manifest
        ;;
      --*|-*)
        printf 'ERROR: unknown option %s\n' "$1"
        printf 'expected named options: --lane --issue --claim --topic-head --main --verification-script [--manifest]\n'
        return 2
        ;;
      *)
        printf 'ERROR: unexpected positional argument %s\n' "$1"
        printf 'use named options: --lane --issue --claim --topic-head --main --verification-script [--manifest]\n'
        return 2
        ;;
    esac

    [ "$#" -ge 2 ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_integrate_clean_command_option_name"
      return 2
    }
    shift
    [ -n "$1" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_integrate_clean_command_option_name"
      return 2
    }
    case "$1" in
      --*|-*)
        printf 'ERROR: named option %s is missing its value before %s\n' \
          "$nuinui_integrate_clean_command_option_name" "$1"
        return 2
        ;;
    esac
    case "$nuinui_integrate_clean_command_option_name" in
      --lane) nuinui_integrate_clean_command_lane=$1 ;;
      --issue) nuinui_integrate_clean_command_issue=$1 ;;
      --claim) nuinui_integrate_clean_command_claim=$1 ;;
      --topic-head) nuinui_integrate_clean_command_topic_head=$1 ;;
      --main) nuinui_integrate_clean_command_main=$1 ;;
      --verification-script) nuinui_integrate_clean_command_verification_script=$1 ;;
      --manifest) nuinui_integrate_clean_command_manifest=$1 ;;
    esac
    shift
  done

  [ "$nuinui_integrate_clean_command_lane_seen" = 1 ] || {
    printf 'ERROR: missing required named option --lane\n'
    return 2
  }
  [ "$nuinui_integrate_clean_command_issue_seen" = 1 ] || {
    printf 'ERROR: missing required named option --issue\n'
    return 2
  }
  [ "$nuinui_integrate_clean_command_claim_seen" = 1 ] || {
    printf 'ERROR: missing required named option --claim\n'
    return 2
  }
  [ "$nuinui_integrate_clean_command_topic_head_seen" = 1 ] || {
    printf 'ERROR: missing required named option --topic-head\n'
    return 2
  }
  [ "$nuinui_integrate_clean_command_main_seen" = 1 ] || {
    printf 'ERROR: missing required named option --main\n'
    return 2
  }
  [ "$nuinui_integrate_clean_command_verification_script_seen" = 1 ] || {
    printf 'ERROR: missing required named option --verification-script\n'
    return 2
  }
}

nuinui_integrate_clean_command_validate_verification_script() {
  case "$1" in
    /*) ;;
    *)
      printf 'ERROR: verification script must be an absolute path\n'
      return 2
      ;;
  esac
  [ -f "$1" ] && [ -x "$1" ] && [ ! -L "$1" ] || {
    printf 'ERROR: verification script must be an executable regular file\n'
    return 2
  }
}

nuinui_integrate_clean_command_validate_manifest() {
  case "$1" in
    /*) ;;
    *)
      printf 'ERROR: manifest must be an absolute path\n'
      return 2
      ;;
  esac
  [ -f "$1" ] && [ -r "$1" ] && [ ! -L "$1" ] || {
    printf 'ERROR: manifest must be a readable regular file\n'
    return 2
  }
}

nuinui_integrate_clean_command() {
  nuinui_integrate_clean_command_parse_args "$@" || {
    nuinui_integrate_clean_command_parse_rc=$?
    return "$nuinui_integrate_clean_command_parse_rc"
  }

  nuinui_require_runtime_manifest || return 1
  nuinui_integrate_clean_command_lane_output=$(lane_execution_cli_validate_implementation_lane \
    "$NUINUI_RUNTIME_MANIFEST" "$nuinui_integrate_clean_command_lane" 2>&1) || {
    [ -z "$nuinui_integrate_clean_command_lane_output" ] ||
      printf '%s\n' "$nuinui_integrate_clean_command_lane_output"
    printf 'BLOCKED: integrate-clean-command lane is not a declared implementation lane\n'
    return 1
  }
  nuinui_ownership_valid_issue "$nuinui_integrate_clean_command_issue" || {
    printf 'ERROR: invalid --issue; expected SAY-<digits>\n'
    return 2
  }
  nuinui_ownership_valid_claim "$nuinui_integrate_clean_command_claim" || {
    printf 'ERROR: invalid --claim; expected a durable claim token\n'
    return 2
  }
  nuinui_ownership_valid_sha "$nuinui_integrate_clean_command_topic_head" || {
    printf 'ERROR: invalid --topic-head; expected a full 40-character commit SHA\n'
    return 2
  }
  nuinui_ownership_valid_sha "$nuinui_integrate_clean_command_main" || {
    printf 'ERROR: invalid --main; expected a full 40-character commit SHA\n'
    return 2
  }
  nuinui_integrate_clean_command_validate_verification_script \
    "$nuinui_integrate_clean_command_verification_script" || return $?
  if [ "$nuinui_integrate_clean_command_manifest_seen" = 1 ]; then
    nuinui_integrate_clean_command_validate_manifest \
      "$nuinui_integrate_clean_command_manifest" || return $?
  fi

  nuinui_integrate_clean_command_cli_path=$P
  case "$nuinui_integrate_clean_command_cli_path" in
    /*) ;;
    *)
      nuinui_integrate_clean_command_cli_path=$D/$(basename -- \
        "$nuinui_integrate_clean_command_cli_path")
      ;;
  esac
  printf '%s\n' 'INTEGRATE CLEAN COMMAND READY'
  printf '%s %s %s %s %s %s %s %s %s\n' \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_cli_path")" \
    "$(nuinui_shell_quote integrate-clean)" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_lane")" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_issue")" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_claim")" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_topic_head")" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_main")" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_verification_script")" \
    "$(nuinui_shell_quote "$nuinui_integrate_clean_command_manifest")"
  printf 'lane=%s\nissue=%s\nclaim=%s\ntopic_head=%s\nmain=%s\nverification_script=%s\nmanifest=%s\n' \
    "$nuinui_integrate_clean_command_lane" \
    "$nuinui_integrate_clean_command_issue" \
    "$nuinui_integrate_clean_command_claim" \
    "$nuinui_integrate_clean_command_topic_head" \
    "$nuinui_integrate_clean_command_main" \
    "$nuinui_integrate_clean_command_verification_script" \
    "$nuinui_integrate_clean_command_manifest"
}
