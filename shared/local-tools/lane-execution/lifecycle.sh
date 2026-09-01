#!/bin/sh

# Generic manifest-driven implementation lifecycle façade.
#
# This is the generic N-lane admission/mutation path used by the standalone
# runtime. The manifest supplies topology; this source supplies lifecycle
# mechanics.

lane_execution_source_dir=${LANE_EXECUTION_SOURCE_DIR:-}
if [ -z "$lane_execution_source_dir" ] && {
  [ "${LANE_EXECUTION_LIFECYCLE_EXECUTE:-0}" = 1 ] || [ "${0##*/}" = lifecycle.sh ];
}; then
  lane_execution_source_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
fi
if ! command -v lane_execution_preflight >/dev/null 2>&1 && [ -n "$lane_execution_source_dir" ]; then
  . "$lane_execution_source_dir/preflight.sh"
fi
if ! command -v lane_execution_inventory_normalize >/dev/null 2>&1 && [ -n "$lane_execution_source_dir" ]; then
  . "$lane_execution_source_dir/inventory.sh"
fi

if ! command -v lane_execution_before_mutation_revalidate >/dev/null 2>&1; then
  lane_execution_before_mutation_revalidate() { return 0; }
fi
if ! command -v lane_execution_after_mutation >/dev/null 2>&1; then
  lane_execution_after_mutation() { return 0; }
fi

lane_execution__atomic_write() {
  lane_execution_write_target=$1.tmp.$$
  (umask 077; printf '%b' "$2" >"$lane_execution_write_target") &&
    mv -- "$lane_execution_write_target" "$1"
}

lane_execution__claim() {
  command -v uuidgen >/dev/null 2>&1 && uuidgen | tr A-Z a-z ||
    printf '%s:%s:%s\n' $$ "$(date +%s)" "${RANDOM:-0}" | git hash-object --stdin
}

lane_execution__metadata_path() {
  printf '%s/%s\n' "$(lane_execution__git_dir "$1")" "$2"
}

lane_execution__forensic_args() {
  lane_execution_forensic=
  if [ "$#" = 2 ]; then
    [ "$1" = --forensic-worktree ] || return 2
    lane_execution_forensic=$2
  elif [ "$#" != 0 ]; then
    return 2
  fi
}

lane_execution__target_validate() {
  lane_execution_target_manifest=$1
  lane_execution_target_lane=$2
  lane_manifest_validate "$lane_execution_target_manifest" || return 1
  lane_manifest_validate_lane_name "$lane_execution_target_manifest" \
    "$lane_execution_target_lane" >/dev/null 2>&1 || return 1
  [ "$(lane_manifest_lane_role "$lane_execution_target_manifest" \
    "$lane_execution_target_lane")" = implementation ] || return 1
  lane_execution_target_path=$(lane_manifest_lane_path "$lane_execution_target_manifest" \
    "$lane_execution_target_lane") || return 1
  lane_execution_target_path=$(lane_execution__canonical_path "$lane_execution_target_path") || return 1
  lane_execution_target_idle=$(lane_manifest_lane_idle_policy "$lane_execution_target_manifest" \
    "$lane_execution_target_lane") || return 1
  lane_execution_target_default=$(lane_manifest_default_branch "$lane_execution_target_manifest") || return 1
  lane_execution_target_repository=$(lane_manifest_repository_identity "$lane_execution_target_manifest") || return 1
  lane_execution__repository_matches "$lane_execution_target_path" \
    "$lane_execution_target_repository" || return 1
}

lane_execution__audit() {
  lane_execution_audit_manifest=$1
  lane_execution_audit_forensic=${2-}
  lane_execution_audit_output=
  lane_execution_audit_rc=0
  if [ -n "$lane_execution_audit_forensic" ]; then
    lane_execution_audit_output=$(lane_execution_preflight "$lane_execution_audit_manifest" \
      --forensic-worktree "$lane_execution_audit_forensic" 2>&1) ||
      lane_execution_audit_rc=$?
  else
    lane_execution_audit_output=$(lane_execution_preflight "$lane_execution_audit_manifest" 2>&1) ||
      lane_execution_audit_rc=$?
  fi
  lane_execution_audit_inventory=
  if [ -n "$lane_execution_audit_output" ]; then
    lane_execution_audit_inventory=$(lane_execution_inventory_from_audit \
      "$lane_execution_audit_manifest" "$lane_execution_audit_output" 2>/dev/null || true)
  fi
}

lane_execution__print_audit_blocked() {
  [ -z "$lane_execution_audit_output" ] || printf '%s\n' "$lane_execution_audit_output"
  printf 'BLOCKED: %s\n' "$1"
  [ -z "$lane_execution_audit_inventory" ] ||
    printf 'actual_inventory=%s\n' "$lane_execution_audit_inventory"
  return 1
}

lane_execution__idle_for_start() {
  lane_execution_idle_repo=$1
  lane_execution_idle_lane=$2
  lane_execution_idle_policy=$3
  lane_execution_idle_default=$4
  lane_execution_idle_origin=$5
  lane_execution__idle_proof "$lane_execution_idle_lane" "$lane_execution_idle_repo" \
    "$lane_execution_idle_policy" "$lane_execution_idle_default" "$lane_execution_idle_origin"
}

lane_execution__unlock() {
  lane_execution_unlock_repo=$1
  lane_execution_unlock_claim=$2
  lane_execution_unlock_state=$(lane_execution__metadata_path "$lane_execution_unlock_repo" \
    nuinui-implementation-lock)/state
  set -- $(lane_execution__parse_lock "$lane_execution_unlock_state") || return 1
  [ "$6" = "$lane_execution_unlock_claim" ] || return 1
  rm "$lane_execution_unlock_state" &&
    rmdir "${lane_execution_unlock_state%/state}"
}

lane_execution__lock() {
  lane_execution_lock_repo=$1
  lane_execution_lock_claim=$2
  lane_execution_lock_issue=$3
  lane_execution_lock_branch=$4
  lane_execution_lock_base=$5
  lane_execution_lock_dir=$(lane_execution__metadata_path "$lane_execution_lock_repo" \
    nuinui-implementation-lock)
  mkdir "$lane_execution_lock_dir" 2>/dev/null || return 1
  lane_execution__atomic_write "$lane_execution_lock_dir/state" \
    "version=1\noperation=start\nissue=$lane_execution_lock_issue\nbranch=$lane_execution_lock_branch\nbase=$lane_execution_lock_base\ncheckpoint=-\nclaim=$lane_execution_lock_claim\n"
}

lane_execution__remote_branch() {
  lane_execution_remote_branch_listing=$(git -C "$1" ls-remote --heads origin \
    "refs/heads/$2" 2>/dev/null) || return 1
  printf '%s\n' "$lane_execution_remote_branch_listing" | awk 'NR == 1 {print $1}'
}

lane_execution__branch_on_other_worktree() {
  lane_execution_branch_repo=$1
  lane_execution_branch_name=$2
  lane_execution_branch_path=$(CDPATH= cd -- "$lane_execution_branch_repo" && pwd -P) || return 1
  git -C "$lane_execution_branch_repo" worktree list --porcelain 2>/dev/null |
    awk -v branch="refs/heads/$lane_execution_branch_name" \
      -v path="$lane_execution_branch_path" '
      /^worktree / { worktree=substr($0, 10) }
      /^branch / && substr($0, 8) == branch && worktree != path { print worktree; exit }
    '
}

lane_execution__start_mutation() {
  [ "$#" = 5 ] || return 2
  lane_execution_mutation_manifest=$1
  lane_execution_mutation_lane=$2
  lane_execution_mutation_issue=$3
  lane_execution_mutation_base=$4
  lane_execution_mutation_branch=$5
  lane_execution__target_validate "$lane_execution_mutation_manifest" \
    "$lane_execution_mutation_lane" || return 1
  lane_execution_mutation_repo=$lane_execution_target_path
  lane_execution_mutation_git_dir=$(lane_execution__git_dir "$lane_execution_mutation_repo") || return 1
  lane_execution_mutation_slot=$lane_execution_mutation_git_dir/nuinui-implementation-slot
  lane_execution_mutation_lock=$lane_execution_mutation_git_dir/nuinui-implementation-lock
  lane_execution_mutation_initialization=$lane_execution_mutation_git_dir/nuinui-implementation-v1
  lane_execution_validate_work_id "$lane_execution_mutation_issue" || return 2
  lane_execution_validate_issue_branch "$lane_execution_mutation_issue" \
    "$lane_execution_mutation_branch" || return 2
  nuinui_ownership_valid_sha "$lane_execution_mutation_base" || return 2
  git -C "$lane_execution_mutation_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  lane_execution__repository_matches "$lane_execution_mutation_repo" \
    "$lane_execution_target_repository" || return 1
  nuinui_ownership_validate_initialization "$lane_execution_mutation_initialization" || return 1
  [ ! -e "$lane_execution_mutation_slot" ] && [ ! -e "$lane_execution_mutation_lock" ] || return 1
  [ -z "$(lane_execution__release_dirs "$lane_execution_mutation_git_dir")" ] || return 1
  lane_execution_mutation_origin=$(lane_execution__origin_default "$lane_execution_mutation_repo" \
    "$lane_execution_target_default")
  nuinui_ownership_valid_sha "$lane_execution_mutation_origin" || return 1
  lane_execution__idle_for_start "$lane_execution_mutation_repo" \
    "$lane_execution_mutation_lane" "$lane_execution_target_idle" \
    "$lane_execution_target_default" "$lane_execution_mutation_origin" || return 1
  [ "$(git -C "$lane_execution_mutation_repo" rev-parse HEAD)" = \
    "$lane_execution_mutation_base" ] || return 1
  git -C "$lane_execution_mutation_repo" show-ref --verify --quiet \
    "refs/heads/$lane_execution_mutation_branch" && return 1
  lane_execution_mutation_remote_branch=$(lane_execution__remote_branch \
    "$lane_execution_mutation_repo" "$lane_execution_mutation_branch") || return 1
  [ -z "$lane_execution_mutation_remote_branch" ] || return 1
  [ -z "$(lane_execution__branch_on_other_worktree "$lane_execution_mutation_repo" \
    "$lane_execution_mutation_branch")" ] || return 1

  lane_execution_mutation_claim=$(lane_execution__claim)
  lane_execution__lock "$lane_execution_mutation_repo" "$lane_execution_mutation_claim" \
    "$lane_execution_mutation_issue" "$lane_execution_mutation_branch" \
    "$lane_execution_mutation_base" || return 1
  mkdir "$lane_execution_mutation_slot" || return 1
  lane_execution__atomic_write "$lane_execution_mutation_slot/state" \
    "version=1\nissue=$lane_execution_mutation_issue\nbranch=$lane_execution_mutation_branch\nbase=$lane_execution_mutation_base\nclaim=$lane_execution_mutation_claim\n" || return 1
  [ "${NUINUI_SELFTEST_CRASH_AT:-}" = start-after-slot ] && return 97
  git -C "$lane_execution_mutation_repo" switch -c "$lane_execution_mutation_branch" \
    "$lane_execution_mutation_base" >/dev/null 2>&1 || {
    if lane_execution__idle_for_start "$lane_execution_mutation_repo" \
      "$lane_execution_mutation_lane" "$lane_execution_target_idle" \
      "$lane_execution_target_default" "$lane_execution_mutation_origin" &&
      ! git -C "$lane_execution_mutation_repo" show-ref --verify --quiet \
        "refs/heads/$lane_execution_mutation_branch"; then
      rm -rf "$lane_execution_mutation_slot"
      lane_execution__unlock "$lane_execution_mutation_repo" \
        "$lane_execution_mutation_claim" >/dev/null 2>&1 || true
    fi
    return 1
  }
  lane_execution__unlock "$lane_execution_mutation_repo" "$lane_execution_mutation_claim" || return 1
  lane_execution_mutation_checkpoint=$lane_execution_mutation_base
  printf 'claim=%s\ncheckpoint=%s\n' "$lane_execution_mutation_claim" \
    "$lane_execution_mutation_checkpoint"
}

lane_execution__prove_busy() {
  [ "$#" = 6 ] || return 2
  lane_execution_proof_manifest=$1
  lane_execution_proof_lane=$2
  lane_execution_proof_issue=$3
  lane_execution_proof_base=$4
  lane_execution_proof_branch=$5
  lane_execution_proof_claim=${6-}
  lane_execution__target_validate "$lane_execution_proof_manifest" \
    "$lane_execution_proof_lane" || return 1
  lane_execution_proof_repo=$lane_execution_target_path
  lane_execution_proof_git_dir=$(lane_execution__git_dir "$lane_execution_proof_repo") || return 1
  [ ! -e "$lane_execution_proof_git_dir/nuinui-implementation-lock" ] || return 1
  [ -z "$(lane_execution__release_dirs "$lane_execution_proof_git_dir")" ] || return 1
  lane_execution_proof_slot=$lane_execution_proof_git_dir/nuinui-implementation-slot/state
  set -- $(lane_execution__parse_slot "$lane_execution_proof_slot") || return 1
  [ "$#" = 4 ] || return 1
  [ "$1" = "$lane_execution_proof_issue" ] &&
    [ "$2" = "$lane_execution_proof_branch" ] &&
    [ "$3" = "$lane_execution_proof_base" ] || return 1
  [ -z "$lane_execution_proof_claim" ] || [ "$4" = "$lane_execution_proof_claim" ] || return 1
  [ -z "$(git -C "$lane_execution_proof_repo" status --porcelain 2>/dev/null)" ] || return 1
  [ "$(git -C "$lane_execution_proof_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" = \
    "$lane_execution_proof_branch" ] || return 1
  lane_execution_proof_head=$(git -C "$lane_execution_proof_repo" rev-parse HEAD 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$lane_execution_proof_head" || return 1
  git -C "$lane_execution_proof_repo" merge-base --is-ancestor \
    "$lane_execution_proof_base" "$lane_execution_proof_head" 2>/dev/null || return 1
  [ "$(git -C "$lane_execution_proof_repo" rev-parse \
    "refs/heads/$lane_execution_proof_branch^{commit}" 2>/dev/null)" = \
    "$lane_execution_proof_head" ] || return 1
  lane_execution_proof_claim_value=$4
  lane_execution_proof_checkpoint=$lane_execution_proof_head
  lane_execution_proof_issue_value=$1
  lane_execution_proof_branch_value=$2
  lane_execution_proof_base_value=$3
}

lane_execution__emit_proven() {
  printf '%s\nlane=%s\nissue=%s\nbranch=%s\nbase=%s\ncheckpoint=%s\nclaim=%s\nclean=yes\nstate=BUSY\n' \
    "$1" "$2" "$lane_execution_proof_issue_value" \
    "$lane_execution_proof_branch_value" "$lane_execution_proof_base_value" \
    "$lane_execution_proof_checkpoint" "$lane_execution_proof_claim_value"
}

lane_execution__emit_post_result() {
  lane_execution_post_status=$1
  lane_execution_post_inventory=$2
  if [ "$lane_execution_audit_rc" = 0 ] && [ -n "$lane_execution_post_inventory" ]; then
    printf 'implementation_inventory=%s\npreflight=PASS\npost_audit=PASS\n' "$lane_execution_post_inventory"
    return 0
  fi
  printf 'mutation_state=COMPLETED\npost_audit=BLOCKED\n'
  [ -z "$lane_execution_post_inventory" ] ||
    printf 'implementation_inventory=%s\n' "$lane_execution_post_inventory"
  [ -z "$lane_execution_audit_output" ] ||
    printf 'audit_evidence:\n%s\n' "$lane_execution_audit_output"
  [ "$lane_execution_post_status" = completed ]
}

lane_execution_start() {
  [ "$#" = 5 ] || [ "$#" = 7 ] || return 2
  lane_execution_start_manifest=$1
  lane_execution_start_lane=$2
  lane_execution_start_issue=$3
  lane_execution_start_base=$4
  lane_execution_start_branch=$5
  shift 5
  lane_execution__forensic_args "$@" || return 2
  lane_execution__target_validate "$lane_execution_start_manifest" \
    "$lane_execution_start_lane" || {
    echo 'BLOCKED: target is not a declared implementation lane'
    return 1
  }
  lane_execution__audit "$lane_execution_start_manifest" "$lane_execution_forensic"
  [ "$lane_execution_audit_rc" = 0 ] ||
    lane_execution__print_audit_blocked 'generic preflight failed'
  lane_execution_start_actual=$lane_execution_audit_inventory
  [ -n "$lane_execution_start_actual" ] ||
    lane_execution__print_audit_blocked 'implementation inventory unavailable'
  [ "$(lane_execution__inventory_value "$lane_execution_start_actual" \
    "$lane_execution_start_lane")" = FREE ] ||
    lane_execution__print_audit_blocked 'start target is not FREE'
  lane_execution_start_mutation_output=
  lane_execution_start_mutation_rc=0
  lane_execution_start_mutation_output=$(lane_execution__start_mutation \
    "$lane_execution_start_manifest" "$lane_execution_start_lane" \
    "$lane_execution_start_issue" "$lane_execution_start_base" \
    "$lane_execution_start_branch" 2>&1) ||
    lane_execution_start_mutation_rc=$?
  lane_execution_after_mutation "$lane_execution_start_manifest" \
    "$lane_execution_start_lane" || true
  lane_execution__audit "$lane_execution_start_manifest" "$lane_execution_forensic"
  if lane_execution__prove_busy "$lane_execution_start_manifest" \
    "$lane_execution_start_lane" "$lane_execution_start_issue" \
    "$lane_execution_start_base" "$lane_execution_start_branch" ''; then
    lane_execution__emit_proven 'IMPLEMENTATION STARTED' "$lane_execution_start_lane"
    lane_execution__emit_post_result completed "$lane_execution_audit_inventory"
    return 0
  fi
  printf 'BLOCKED: start mutation completion could not be proven\nmutation_state=UNKNOWN\nlane=%s\nissue=%s\nbranch=%s\nbase=%s\n' \
    "$lane_execution_start_lane" "$lane_execution_start_issue" \
    "$lane_execution_start_branch" "$lane_execution_start_base"
  [ -z "$lane_execution_start_mutation_output" ] ||
    printf 'mutation_output:\n%s\n' "$lane_execution_start_mutation_output"
  [ -z "$lane_execution_audit_output" ] ||
    printf 'audit_evidence:\n%s\n' "$lane_execution_audit_output"
  return 1
}

lane_execution__duplicate() {
  lane_execution_duplicate_manifest=$1
  lane_execution_duplicate_lane=$2
  lane_execution_duplicate_issue=$3
  lane_execution_duplicate_base=$4
  lane_execution_duplicate_branch=$5
  lane_execution_duplicate_expected=$6
  lane_execution_duplicate_actual=$7
  lane_execution__prove_busy "$lane_execution_duplicate_manifest" \
    "$lane_execution_duplicate_lane" "$lane_execution_duplicate_issue" \
    "$lane_execution_duplicate_base" "$lane_execution_duplicate_branch" '' || return 1
  lane_execution_duplicate_claim=$lane_execution_proof_claim_value
  lane_execution_inventory_compare "$lane_execution_duplicate_manifest" \
    "$lane_execution_duplicate_expected" "$lane_execution_duplicate_actual" \
    "$lane_execution_duplicate_lane" || return 1
  lane_execution__audit "$lane_execution_duplicate_manifest" \
    "$lane_execution_forensic"
  [ "$lane_execution_audit_rc" = 0 ] || return 1
  lane_execution_duplicate_actual_second=$lane_execution_audit_inventory
  [ -n "$lane_execution_duplicate_actual_second" ] || return 1
  lane_execution_inventory_compare "$lane_execution_duplicate_manifest" \
    "$lane_execution_duplicate_expected" "$lane_execution_duplicate_actual_second" \
    "$lane_execution_duplicate_lane" || return 1
  lane_execution__prove_busy "$lane_execution_duplicate_manifest" \
    "$lane_execution_duplicate_lane" "$lane_execution_duplicate_issue" \
    "$lane_execution_duplicate_base" "$lane_execution_duplicate_branch" \
    "$lane_execution_duplicate_claim" || return 1
  [ "$lane_execution_duplicate_claim" = "$lane_execution_proof_claim_value" ] || return 1
  lane_execution__emit_proven 'IMPLEMENTATION ALREADY STARTED' \
    "$lane_execution_duplicate_lane"
  printf 'implementation_inventory=%s\nmutation=no-op\npreflight=PASS\npost_audit=PASS\n' \
    "$lane_execution_duplicate_actual_second"
}

lane_execution_begin() {
  [ "$#" = 6 ] || [ "$#" = 8 ] || return 2
  lane_execution_begin_manifest=$1
  lane_execution_begin_lane=$2
  lane_execution_begin_issue=$3
  lane_execution_begin_base=$4
  lane_execution_begin_branch=$5
  lane_execution_begin_expected=$6
  shift 6
  lane_execution__forensic_args "$@" || return 2
  lane_execution__target_validate "$lane_execution_begin_manifest" \
    "$lane_execution_begin_lane" || {
    echo 'BLOCKED: target is not a declared implementation lane'
    return 1
  }
  lane_execution_validate_work_id "$lane_execution_begin_issue" || {
    echo 'ERROR: Work-ID is invalid'
    return 2
  }
  nuinui_ownership_valid_sha "$lane_execution_begin_base" || {
    echo 'ERROR: expected base must be a full 40-character commit SHA'
    return 2
  }
  lane_execution_validate_issue_branch "$lane_execution_begin_issue" \
    "$lane_execution_begin_branch" || {
    echo 'ERROR: branch is invalid for Work-ID'
    return 2
  }
  lane_execution_begin_expected=$(lane_execution_inventory_normalize \
    "$lane_execution_begin_manifest" "$lane_execution_begin_expected") || {
    echo 'ERROR: implementation inventory is invalid'
    return 2
  }
  [ "$(lane_execution__inventory_value "$lane_execution_begin_expected" \
    "$lane_execution_begin_lane")" = FREE ] || {
    echo 'ERROR: target inventory entry must be FREE for a new begin'
    return 2
  }
  lane_execution__audit "$lane_execution_begin_manifest" "$lane_execution_forensic"
  [ "$lane_execution_audit_rc" = 0 ] ||
    lane_execution__print_audit_blocked 'begin generic preflight failed'
  lane_execution_begin_actual=$lane_execution_audit_inventory
  [ -n "$lane_execution_begin_actual" ] ||
    lane_execution__print_audit_blocked 'begin implementation inventory unavailable'

  lane_execution_begin_target_actual=$(lane_execution__inventory_value \
    "$lane_execution_begin_actual" "$lane_execution_begin_lane" 2>/dev/null || true)
  if [ "$lane_execution_begin_target_actual" != FREE ]; then
    if [ "$lane_execution_begin_target_actual" != "" ] &&
      lane_execution__duplicate "$lane_execution_begin_manifest" \
        "$lane_execution_begin_lane" "$lane_execution_begin_issue" \
        "$lane_execution_begin_base" "$lane_execution_begin_branch" \
        "$lane_execution_begin_expected" "$lane_execution_begin_actual"; then
      return 0
    fi
    printf '%s\nBLOCKED: target occupancy does not prove requested duplicate or FREE state\n' \
      "$lane_execution_audit_output"
    lane_execution_inventory_compare "$lane_execution_begin_manifest" \
      "$lane_execution_begin_expected" "$lane_execution_begin_actual" \
      "$lane_execution_begin_lane" || true
    return 1
  fi

  lane_execution_inventory_compare "$lane_execution_begin_manifest" \
    "$lane_execution_begin_expected" "$lane_execution_begin_actual" || {
    printf '%s\nBLOCKED: implementation inventory does not match caller expectation\n' \
      "$lane_execution_audit_output"
    return 1
  }
  lane_execution_before_mutation_revalidate "$lane_execution_begin_manifest" \
    "$lane_execution_begin_lane" || return 1
  lane_execution__audit "$lane_execution_begin_manifest" "$lane_execution_forensic"
  [ "$lane_execution_audit_rc" = 0 ] ||
    lane_execution__print_audit_blocked 'begin mutation-boundary preflight failed'
  lane_execution_begin_actual_second=$lane_execution_audit_inventory
  [ -n "$lane_execution_begin_actual_second" ] ||
    lane_execution__print_audit_blocked 'begin mutation-boundary inventory unavailable'
  lane_execution_inventory_compare "$lane_execution_begin_manifest" \
    "$lane_execution_begin_expected" "$lane_execution_begin_actual_second" || {
    printf '%s\nBLOCKED: implementation inventory changed before mutation\n' \
      "$lane_execution_audit_output"
    return 1
  }
  [ "$(lane_execution__inventory_value "$lane_execution_begin_actual_second" \
    "$lane_execution_begin_lane")" = FREE ] || {
    echo 'BLOCKED: target changed before mutation'
    return 1
  }

  lane_execution_begin_mutation_output=
  lane_execution_begin_mutation_rc=0
  lane_execution_begin_mutation_output=$(lane_execution__start_mutation \
    "$lane_execution_begin_manifest" "$lane_execution_begin_lane" \
    "$lane_execution_begin_issue" "$lane_execution_begin_base" \
    "$lane_execution_begin_branch" 2>&1) ||
    lane_execution_begin_mutation_rc=$?
  lane_execution_after_mutation "$lane_execution_begin_manifest" \
    "$lane_execution_begin_lane" || true
  lane_execution__audit "$lane_execution_begin_manifest" "$lane_execution_forensic"
  if lane_execution__prove_busy "$lane_execution_begin_manifest" \
    "$lane_execution_begin_lane" "$lane_execution_begin_issue" \
    "$lane_execution_begin_base" "$lane_execution_begin_branch" ''; then
    lane_execution__emit_proven 'IMPLEMENTATION STARTED' "$lane_execution_begin_lane"
    lane_execution__emit_post_result completed "$lane_execution_audit_inventory"
    return 0
  fi
  printf 'BLOCKED: begin mutation completion could not be proven\nmutation_state=UNKNOWN\nlane=%s\nissue=%s\nbranch=%s\nbase=%s\n' \
    "$lane_execution_begin_lane" "$lane_execution_begin_issue" \
    "$lane_execution_begin_branch" "$lane_execution_begin_base"
  [ -z "$lane_execution_begin_mutation_output" ] ||
    printf 'mutation_output:\n%s\n' "$lane_execution_begin_mutation_output"
  [ -z "$lane_execution_audit_output" ] ||
    printf 'audit_evidence:\n%s\n' "$lane_execution_audit_output"
  return 1
}

lane_execution_lifecycle_command() {
  [ "$#" -ge 1 ] || return 2
  lane_execution_lifecycle_operation=$1
  shift
  case "$lane_execution_lifecycle_operation" in
    begin) lane_execution_begin "$@" ;;
    start) lane_execution_start "$@" ;;
    *) echo 'Usage: lane-execution-lifecycle {begin|start} ...' >&2; return 2 ;;
  esac
}

if [ "${LANE_EXECUTION_LIFECYCLE_EXECUTE:-0}" = 1 ] || [ "${0##*/}" = lifecycle.sh ]; then
  lane_execution_lifecycle_command "$@"
fi
