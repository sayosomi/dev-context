# Canonical Luna startup handoff façade.
#
# The standalone nuinui-handoff-check remains the proof authority. This
# façade only owns the named public surface and the one-shot exact recovery
# orchestration around the existing tracked resume command.

nuinui_handoff_parse_args() {
  nuinui_handoff_lane=
  nuinui_handoff_issue=
  nuinui_handoff_claim=
  nuinui_handoff_checkpoint=
  nuinui_handoff_main=
  nuinui_handoff_topic=
  nuinui_handoff_lane_seen=0
  nuinui_handoff_issue_seen=0
  nuinui_handoff_claim_seen=0
  nuinui_handoff_checkpoint_seen=0
  nuinui_handoff_main_seen=0
  nuinui_handoff_topic_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --lane)
        [ "$nuinui_handoff_lane_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --lane\n'
          return 2
        }
        nuinui_handoff_lane_seen=1
        nuinui_handoff_option_name=--lane
        ;;
      --issue)
        [ "$nuinui_handoff_issue_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --issue\n'
          return 2
        }
        nuinui_handoff_issue_seen=1
        nuinui_handoff_option_name=--issue
        ;;
      --claim)
        [ "$nuinui_handoff_claim_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --claim\n'
          return 2
        }
        nuinui_handoff_claim_seen=1
        nuinui_handoff_option_name=--claim
        ;;
      --checkpoint)
        [ "$nuinui_handoff_checkpoint_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --checkpoint\n'
          return 2
        }
        nuinui_handoff_checkpoint_seen=1
        nuinui_handoff_option_name=--checkpoint
        ;;
      --main)
        [ "$nuinui_handoff_main_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --main\n'
          return 2
        }
        nuinui_handoff_main_seen=1
        nuinui_handoff_option_name=--main
        ;;
      --topic)
        [ "$nuinui_handoff_topic_seen" = 0 ] || {
          printf 'ERROR: duplicate named option --topic\n'
          return 2
        }
        nuinui_handoff_topic_seen=1
        nuinui_handoff_option_name=--topic
        ;;
      --*|-*)
        printf 'ERROR: unknown option %s\n' "$1"
        printf 'expected named options: --lane --issue --claim --checkpoint --main --topic\n'
        return 2
        ;;
      *)
        printf 'ERROR: unexpected positional argument %s\n' "$1"
        printf 'use named options: --lane --issue --claim --checkpoint --main --topic\n'
        return 2
        ;;
    esac

    [ "$#" -ge 2 ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_handoff_option_name"
      return 2
    }
    shift
    [ -n "$1" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' \
        "$nuinui_handoff_option_name"
      return 2
    }
    case "$1" in
      --*)
        printf 'ERROR: named option %s is missing its value before %s\n' \
          "$nuinui_handoff_option_name" "$1"
        return 2
        ;;
    esac
    case "$nuinui_handoff_option_name" in
      --lane) nuinui_handoff_lane=$1 ;;
      --issue) nuinui_handoff_issue=$1 ;;
      --claim) nuinui_handoff_claim=$1 ;;
      --checkpoint) nuinui_handoff_checkpoint=$1 ;;
      --main) nuinui_handoff_main=$1 ;;
      --topic) nuinui_handoff_topic=$1 ;;
    esac
    shift
  done

  [ "$nuinui_handoff_lane_seen" = 1 ] || {
    printf 'ERROR: missing required named option --lane\n'
    return 2
  }
  [ "$nuinui_handoff_issue_seen" = 1 ] || {
    printf 'ERROR: missing required named option --issue\n'
    return 2
  }
  [ "$nuinui_handoff_claim_seen" = 1 ] || {
    printf 'ERROR: missing required named option --claim\n'
    return 2
  }
  [ "$nuinui_handoff_checkpoint_seen" = 1 ] || {
    printf 'ERROR: missing required named option --checkpoint\n'
    return 2
  }
  [ "$nuinui_handoff_main_seen" = 1 ] || {
    printf 'ERROR: missing required named option --main\n'
    return 2
  }
  [ "$nuinui_handoff_topic_seen" = 1 ] || {
    printf 'ERROR: missing required named option --topic\n'
    return 2
  }
}

nuinui_handoff_validate_args() {
  il "$nuinui_handoff_lane" || {
    printf 'ERROR: lane must be a declared implementation lane\n'
    return 2
  }
  nuinui_ownership_valid_issue "$nuinui_handoff_issue" || {
    printf 'ERROR: Issue must look like SAY-123\n'
    return 2
  }
  nuinui_ownership_valid_claim "$nuinui_handoff_claim" || {
    printf 'ERROR: claim is invalid\n'
    return 2
  }
  nuinui_ownership_valid_sha "$nuinui_handoff_checkpoint" || {
    printf 'ERROR: checkpoint must be a full 40-character commit SHA\n'
    return 2
  }
  nuinui_ownership_valid_sha "$nuinui_handoff_main" || {
    printf 'ERROR: main must be a full 40-character commit SHA\n'
    return 2
  }
  case "$nuinui_handoff_topic" in
    absent|exact) ;;
    *)
      printf 'ERROR: topic must be absent or exact\n'
      return 2
      ;;
  esac
}

nuinui_handoff_run_check() {
  nuinui_handoff_check_helper=${NUINUI_HANDOFF_CHECK_HELPER:-$D/nuinui-handoff-check}
  if [ -n "${NUINUI_HANDOFF_CHECK_HELPER:-}" ] &&
    [ "${NUINUI_SELFTEST:-0}" != 1 ]; then
    printf 'ERROR: test-only handoff-check override is unavailable outside self-test mode\n'
    return 1
  fi
  [ -f "$nuinui_handoff_check_helper" ] &&
    [ ! -L "$nuinui_handoff_check_helper" ] || {
    printf 'BLOCKED: standalone handoff-check authority is unavailable\n'
    return 1
  }

  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    NUINUI_HANDOFF_SELFTEST=1 \
      NUINUI_HANDOFF_MANIFEST="$NUINUI_RUNTIME_MANIFEST" \
      "$nuinui_handoff_check_helper" \
      "$nuinui_handoff_lane" "$nuinui_handoff_issue" \
      "$nuinui_handoff_claim" "$nuinui_handoff_checkpoint" \
      "$nuinui_handoff_main" "$nuinui_handoff_topic"
  else
    "$nuinui_handoff_check_helper" \
      "$nuinui_handoff_lane" "$nuinui_handoff_issue" \
      "$nuinui_handoff_claim" "$nuinui_handoff_checkpoint" \
      "$nuinui_handoff_main" "$nuinui_handoff_topic"
  fi
}

nuinui_handoff_read_durable_slot() {
  nuinui_handoff_recovery_repo=$(lr "$nuinui_handoff_lane") || {
    printf 'BLOCKED: assigned lane is not a Git worktree\n'
    return 1
  }
  gr "$nuinui_handoff_recovery_repo" || {
    printf 'BLOCKED: assigned lane is not a Git worktree\n'
    return 1
  }
  if [ "${NUINUI_SELFTEST:-0}" != 1 ]; then
    ao "$nuinui_handoff_recovery_repo" \
      "$(lane_manifest_repository_identity "$NUINUI_RUNTIME_MANIFEST")" || {
      printf 'BLOCKED: assigned lane repository identity does not match LANES.conf\n'
      return 1
    }
  fi
  nuinui_handoff_recovery_gitdir=$(gd "$nuinui_handoff_recovery_repo") || return 1
  nuinui_handoff_recovery_slot=$nuinui_handoff_recovery_gitdir/nuinui-implementation-slot
  nuinui_handoff_recovery_lock=$nuinui_handoff_recovery_gitdir/nuinui-implementation-lock
  [ ! -e "$nuinui_handoff_recovery_lock" ] &&
    [ ! -L "$nuinui_handoff_recovery_lock" ] || {
    printf 'BLOCKED: implementation lane mutation lock exists\n'
    return 1
  }
  nuinui_handoff_recovery_releasing=$(rds "$nuinui_handoff_recovery_repo") || {
    printf 'BLOCKED: unable to discover release-pending state\n'
    return 1
  }
  [ -z "$nuinui_handoff_recovery_releasing" ] || {
    printf 'BLOCKED: implementation lane has release-pending state\n'
    return 1
  }
  [ -d "$nuinui_handoff_recovery_slot" ] &&
    [ ! -L "$nuinui_handoff_recovery_slot" ] &&
    [ -f "$nuinui_handoff_recovery_slot/state" ] &&
    [ ! -L "$nuinui_handoff_recovery_slot/state" ] || {
    printf 'BLOCKED: active durable lane claim is missing\n'
    return 1
  }
  nuinui_handoff_recovery_snapshot=$(cat \
    "$nuinui_handoff_recovery_slot/state") || return 1
  nuinui_handoff_recovery_fields=$(nuinui_ownership_parse_slot \
    "$nuinui_handoff_recovery_slot/state") || {
    printf 'BLOCKED: active durable lane claim is invalid\n'
    return 1
  }
  set -- $nuinui_handoff_recovery_fields
  [ "$#" = 4 ] || {
    printf 'BLOCKED: active durable lane claim is invalid\n'
    return 1
  }
  nuinui_handoff_recovery_slot_issue=$1
  nuinui_handoff_recovery_slot_branch=$2
  nuinui_handoff_recovery_slot_base=$3
  nuinui_handoff_recovery_slot_claim=$4
  [ "$nuinui_handoff_recovery_slot_issue" = "$nuinui_handoff_issue" ] || {
    printf 'BLOCKED: handoff recovery durable Issue mismatch\n'
    return 1
  }
  [ "$nuinui_handoff_recovery_slot_claim" = "$nuinui_handoff_claim" ] || {
    printf 'BLOCKED: handoff recovery durable claim mismatch\n'
    return 1
  }
  [ "$(cat "$nuinui_handoff_recovery_slot/state")" = \
    "$nuinui_handoff_recovery_snapshot" ] || {
    printf 'BLOCKED: durable lane claim changed during handoff recovery setup\n'
    return 1
  }
  nuinui_handoff_recovery_issue=$nuinui_handoff_recovery_slot_issue
  nuinui_handoff_recovery_branch=$nuinui_handoff_recovery_slot_branch
  nuinui_handoff_recovery_base=$nuinui_handoff_recovery_slot_base
  nuinui_handoff_recovery_claim=$nuinui_handoff_recovery_slot_claim
}

nuinui_handoff_recovery_remote_main() {
  nuinui_handoff_recovery_default_branch=$(lane_execution_runtime_default_branch) || return 1
  nuinui_handoff_recovery_default_raw=$(git -C \
    "$nuinui_handoff_recovery_repo" ls-remote --exit-code origin \
    "refs/heads/$nuinui_handoff_recovery_default_branch" 2>/dev/null) || return 1
  [ "$(printf '%s\n' "$nuinui_handoff_recovery_default_raw" |
    awk 'NF {count++} END {print count+0}')" = 1 ] || return 1
  [ "$(printf '%s\n' "$nuinui_handoff_recovery_default_raw" |
    awk 'NR == 1 {print $2}')" = \
    "refs/heads/$nuinui_handoff_recovery_default_branch" ] || return 1
  nuinui_handoff_recovery_default_sha=$(printf '%s\n' \
    "$nuinui_handoff_recovery_default_raw" | awk 'NR == 1 {print $1}')
  nuinui_ownership_valid_sha "$nuinui_handoff_recovery_default_sha" || return 1
  [ "$nuinui_handoff_recovery_default_sha" = "$nuinui_handoff_main" ]
}

nuinui_handoff_recovery_preconditions() {
  cn "$nuinui_handoff_recovery_repo" || {
    printf 'BLOCKED: assigned lane became dirty before handoff recovery\n'
    return 1
  }
  an "$nuinui_handoff_recovery_repo" "$nuinui_handoff_recovery_base" \
    "$nuinui_handoff_checkpoint" || {
    printf 'BLOCKED: checkpoint is not descended from claimed Base\n'
    return 1
  }
  [ "$(lane_execution_remote_topic \
    "$nuinui_handoff_recovery_repo" "$nuinui_handoff_recovery_branch" \
    "$nuinui_handoff_checkpoint" 2>/dev/null)" = pushed ] || {
    printf 'BLOCKED: handoff recovery remote topic is not exact\n'
    return 1
  }
  nuinui_handoff_recovery_remote_main || {
    printf 'BLOCKED: handoff recovery authoritative remote main is not exact\n'
    return 1
  }
}

nuinui_handoff_resume() {
  nuinui_handoff_resume_output=
  nuinui_handoff_resume_rc=0
  nuinui_handoff_resume_output=$(nuinui_run_tracked resume 7 \
    resume "$nuinui_handoff_lane" "$nuinui_handoff_issue" \
    "$nuinui_handoff_recovery_base" "$nuinui_handoff_checkpoint" \
    "$nuinui_handoff_recovery_branch" "$nuinui_handoff_claim" \
    nuinui_lane_dispatch resume "$nuinui_handoff_lane" \
    "$nuinui_handoff_issue" "$nuinui_handoff_recovery_base" \
    "$nuinui_handoff_checkpoint" "$nuinui_handoff_recovery_branch" \
    "$nuinui_handoff_claim" 2>&1) || nuinui_handoff_resume_rc=$?
  printf '%s\n' "$nuinui_handoff_resume_output"
  [ "$nuinui_handoff_resume_rc" = 0 ] || return "$nuinui_handoff_resume_rc"
  printf '%s\n' "$nuinui_handoff_resume_output" |
    grep -Eq '^(IMPLEMENTATION RESUMED|▶️ IMPLEMENTATION RESUMED)$' || {
    printf 'BLOCKED: handoff recovery did not return canonical IMPLEMENTATION RESUMED evidence\n'
    return 1
  }
  printf '%s\n' "$nuinui_handoff_resume_output" |
    grep -Fqx "  base=$nuinui_handoff_recovery_base" || {
    printf 'BLOCKED: handoff recovery Base evidence did not match durable state\n'
    return 1
  }
  printf '%s\n' "$nuinui_handoff_resume_output" |
    grep -Fqx "  claim=$nuinui_handoff_claim" || {
    printf 'BLOCKED: handoff recovery claim evidence did not match caller state\n'
    return 1
  }
}

nuinui_handoff() {
  nuinui_handoff_parse_args "$@" || {
    nuinui_handoff_parse_rc=$?
    return "$nuinui_handoff_parse_rc"
  }
  nuinui_handoff_validate_args || {
    nuinui_handoff_validate_rc=$?
    return "$nuinui_handoff_validate_rc"
  }

  nuinui_handoff_first_output=
  nuinui_handoff_first_rc=0
  nuinui_handoff_first_output=$(nuinui_handoff_run_check 2>&1) ||
    nuinui_handoff_first_rc=$?
  if [ "$nuinui_handoff_first_rc" = 0 ]; then
    printf '%s\n' "$nuinui_handoff_first_output"
    return 0
  fi

  nuinui_handoff_first_line=$(printf '%s\n' \
    "$nuinui_handoff_first_output" | sed -n '1p')
  if [ "$nuinui_handoff_topic" != exact ] ||
    [ "$nuinui_handoff_first_line" != \
      'BLOCKED: handoff claimed branch mismatch' ]; then
    printf '%s\n' "$nuinui_handoff_first_output"
    return "$nuinui_handoff_first_rc"
  fi

  nuinui_handoff_read_durable_slot || {
    nuinui_handoff_recovery_setup_rc=$?
    printf '%s\n' "$nuinui_handoff_first_output"
    return "$nuinui_handoff_recovery_setup_rc"
  }
  nuinui_handoff_recovery_preconditions || {
    nuinui_handoff_recovery_precondition_rc=$?
    printf '%s\n' "$nuinui_handoff_first_output"
    return "$nuinui_handoff_recovery_precondition_rc"
  }
  printf '%s\n' "$nuinui_handoff_first_output"
  nuinui_handoff_resume || return $?

  nuinui_handoff_second_output=
  nuinui_handoff_second_rc=0
  nuinui_handoff_second_output=$(nuinui_handoff_run_check 2>&1) ||
    nuinui_handoff_second_rc=$?
  printf '%s\n' "$nuinui_handoff_second_output"
  [ "$nuinui_handoff_second_rc" = 0 ] ||
    return "$nuinui_handoff_second_rc"
  printf '%s\n' "$nuinui_handoff_second_output" |
    grep -q '^HANDOFF VERIFIED$' || {
    printf 'BLOCKED: second handoff proof did not return HANDOFF VERIFIED\n'
    return 1
  }
}
