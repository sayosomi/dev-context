# Canonical implementation-agent startup handoff façade.
#
# This façade resolves the requested Issue from the existing manifest-driven
# durable implementation slots, derives the current checkpoint and remote
# topic mode, and delegates the safety proof to nuinui-handoff-check.

nuinui_handoff_parse_args() {
  [ "$#" = 2 ] || {
    printf 'ERROR: handoff expects exactly an Issue and expected authoritative main SHA\n'
    printf 'Usage: nuinui handoff <SAY-N> <expected-main-sha>\n'
    return 2
  }
  nuinui_handoff_issue=$1
  nuinui_handoff_main=$2
  nuinui_ownership_valid_issue "$nuinui_handoff_issue" || {
    printf 'ERROR: Issue must look like SAY-123\n'
    return 2
  }
  nuinui_ownership_valid_sha "$nuinui_handoff_main" || {
    printf 'ERROR: expected authoritative main must be a full 40-character commit SHA\n'
    return 2
  }
}

nuinui_handoff_read_slot() {
  nuinui_handoff_slot_repo=$1
  nuinui_handoff_slot_lane=$2
  nuinui_handoff_slot_gitdir=$(gd "$nuinui_handoff_slot_repo") || {
    printf 'BLOCKED: implementation lane Git directory is unavailable\n'
    return 1
  }
  nuinui_handoff_slot_dir=$nuinui_handoff_slot_gitdir/nuinui-implementation-slot
  [ -e "$nuinui_handoff_slot_dir" ] || return 2
  [ -d "$nuinui_handoff_slot_dir" ] &&
    [ ! -L "$nuinui_handoff_slot_dir" ] &&
    [ -f "$nuinui_handoff_slot_dir/state" ] &&
    [ ! -L "$nuinui_handoff_slot_dir/state" ] || {
    printf 'BLOCKED: durable implementation slot is malformed for lane %s\n' \
      "$nuinui_handoff_slot_lane"
    return 1
  }
  nuinui_handoff_slot_snapshot=$(cat "$nuinui_handoff_slot_dir/state") || {
    printf 'BLOCKED: durable implementation slot cannot be read for lane %s\n' \
      "$nuinui_handoff_slot_lane"
    return 1
  }
  nuinui_handoff_slot_fields=$(nuinui_ownership_parse_slot \
    "$nuinui_handoff_slot_dir/state") || {
    printf 'BLOCKED: durable implementation slot is invalid for lane %s\n' \
      "$nuinui_handoff_slot_lane"
    return 1
  }
  set -- $nuinui_handoff_slot_fields
  [ "$#" = 4 ] || {
    printf 'BLOCKED: durable implementation slot is invalid for lane %s\n' \
      "$nuinui_handoff_slot_lane"
    return 1
  }
  nuinui_handoff_slot_issue=$1
  nuinui_handoff_slot_branch=$2
  nuinui_handoff_slot_base=$3
  nuinui_handoff_slot_claim=$4
}

nuinui_handoff_resolve_identity() {
  nuinui_handoff_match_count=0
  nuinui_handoff_match_lane=
  nuinui_handoff_match_repo=

  while IFS= read -r nuinui_handoff_candidate_lane ||
    [ -n "$nuinui_handoff_candidate_lane" ]; do
    [ -n "$nuinui_handoff_candidate_lane" ] || continue
    nuinui_handoff_candidate_repo=$(lr "$nuinui_handoff_candidate_lane") || {
      printf 'BLOCKED: implementation lane path is unavailable for %s\n' \
        "$nuinui_handoff_candidate_lane"
      return 1
    }
    gr "$nuinui_handoff_candidate_repo" || {
      printf 'BLOCKED: implementation lane is not a Git worktree: %s\n' \
        "$nuinui_handoff_candidate_lane"
      return 1
    }
    nuinui_handoff_read_slot "$nuinui_handoff_candidate_repo" \
      "$nuinui_handoff_candidate_lane"
    case "$?" in
      2) continue ;;
      0) ;;
      *) return 1 ;;
    esac
    if [ "$nuinui_handoff_slot_issue" = "$nuinui_handoff_issue" ]; then
      nuinui_handoff_match_count=$((nuinui_handoff_match_count + 1))
      nuinui_handoff_match_lane=$nuinui_handoff_candidate_lane
      nuinui_handoff_match_repo=$nuinui_handoff_candidate_repo
      nuinui_handoff_match_issue=$nuinui_handoff_slot_issue
      nuinui_handoff_match_branch=$nuinui_handoff_slot_branch
      nuinui_handoff_match_base=$nuinui_handoff_slot_base
      nuinui_handoff_match_claim=$nuinui_handoff_slot_claim
      nuinui_handoff_match_slot_snapshot=$nuinui_handoff_slot_snapshot
    fi
  done <<EOF
$(lane_manifest_lanes_by_role "$NUINUI_RUNTIME_MANIFEST" implementation)
EOF

  [ "$nuinui_handoff_match_count" = 1 ] || {
    if [ "$nuinui_handoff_match_count" = 0 ]; then
      printf 'BLOCKED: no active valid implementation generation matches Issue %s\n' \
        "$nuinui_handoff_issue"
    else
      printf 'BLOCKED: multiple active implementation generations match Issue %s\n' \
        "$nuinui_handoff_issue"
    fi
    return 1
  }

  nuinui_handoff_lane=$nuinui_handoff_match_lane
  nuinui_handoff_repo=$nuinui_handoff_match_repo
  nuinui_handoff_issue=$nuinui_handoff_match_issue
  nuinui_handoff_branch=$nuinui_handoff_match_branch
  nuinui_handoff_base=$nuinui_handoff_match_base
  nuinui_handoff_claim=$nuinui_handoff_match_claim
  nuinui_handoff_checkpoint=$(hh "$nuinui_handoff_repo") || {
    printf 'BLOCKED: current implementation checkpoint is unavailable\n'
    return 1
  }
  nuinui_ownership_valid_sha "$nuinui_handoff_checkpoint" || {
    printf 'BLOCKED: current implementation checkpoint is invalid\n'
    return 1
  }
}

nuinui_handoff_derive_topic_mode() {
  nuinui_handoff_topic_raw=$(git -C "$nuinui_handoff_repo" \
    ls-remote --exit-code --heads origin \
    "refs/heads/$nuinui_handoff_branch" 2>/dev/null)
  nuinui_handoff_topic_rc=$?
  case "$nuinui_handoff_topic_rc" in
    0)
      [ "$(printf '%s\n' "$nuinui_handoff_topic_raw" |
        awk 'NF {count++} END {print count+0}')" = 1 ] || {
        printf 'BLOCKED: authoritative remote topic lookup is ambiguous\n'
        return 1
      }
      nuinui_handoff_topic_ref=$(printf '%s\n' "$nuinui_handoff_topic_raw" |
        awk 'NR == 1 {print $2}')
      [ "$nuinui_handoff_topic_ref" = \
        "refs/heads/$nuinui_handoff_branch" ] || {
        printf 'BLOCKED: authoritative remote topic ref is ambiguous\n'
        return 1
      }
      nuinui_handoff_topic_head=$(printf '%s\n' "$nuinui_handoff_topic_raw" |
        awk 'NR == 1 {print $1}')
      nuinui_ownership_valid_sha "$nuinui_handoff_topic_head" || {
        printf 'BLOCKED: authoritative remote topic HEAD is invalid\n'
        return 1
      }
      [ "$nuinui_handoff_topic_head" = "$nuinui_handoff_checkpoint" ] || {
        printf 'BLOCKED: authoritative remote topic does not equal current HEAD\n'
        return 1
      }
      nuinui_handoff_topic=exact
      ;;
    2)
      [ -z "$nuinui_handoff_topic_raw" ] || {
        printf 'BLOCKED: authoritative remote topic lookup failed ambiguously\n'
        return 1
      }
      [ "$nuinui_handoff_checkpoint" = "$nuinui_handoff_base" ] || {
        printf 'BLOCKED: absent remote topic requires current HEAD to equal durable Base\n'
        return 1
      }
      nuinui_handoff_topic=absent
      ;;
    *)
      printf 'BLOCKED: authoritative remote topic is unavailable\n'
      return 1
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

  nuinui_handoff_slot_gitdir=$(gd "$nuinui_handoff_repo") || {
    printf 'BLOCKED: implementation lane Git directory disappeared before handoff proof\n'
    return 1
  }
  nuinui_handoff_slot_path=$nuinui_handoff_slot_gitdir/nuinui-implementation-slot/state
  [ -f "$nuinui_handoff_slot_path" ] &&
    [ ! -L "$nuinui_handoff_slot_path" ] || {
    printf 'BLOCKED: durable implementation slot disappeared before handoff proof\n'
    return 1
  }
  [ "$(cat "$nuinui_handoff_slot_path")" = \
    "$nuinui_handoff_match_slot_snapshot" ] || {
    printf 'BLOCKED: durable implementation slot changed during handoff resolution\n'
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

nuinui_handoff() {
  nuinui_handoff_parse_args "$@" || return $?
  nuinui_handoff_resolve_identity || return $?
  nuinui_handoff_derive_topic_mode || return $?
  nuinui_handoff_run_check
}
