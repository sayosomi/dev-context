#!/bin/sh

# Generic manifest-driven lane preflight and registered-worktree inventory.
#
# This source consumes the data-only manifest API and adapts the existing v1
# ownership readers/classification rules without assigning meaning to lane
# names.

# BEGIN DEVELOPMENT-ONLY SOURCE LOADING
lane_execution_source_dir=${LANE_EXECUTION_SOURCE_DIR:-}
if [ -z "$lane_execution_source_dir" ] && [ "${LANE_EXECUTION_PREFLIGHT_EXECUTE:-0}" = 1 ]; then
  lane_execution_source_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
fi

if ! command -v lane_manifest_validate >/dev/null 2>&1 && [ -n "$lane_execution_source_dir" ]; then
  . "$lane_execution_source_dir/manifest.sh"
fi

if ! command -v nuinui_ownership_read_fields >/dev/null 2>&1 && [ -n "$lane_execution_source_dir" ]; then
  . "$lane_execution_source_dir/ownership.sh"
fi
# END DEVELOPMENT-ONLY SOURCE LOADING

# Reuse the established v1 field reader and generic scalar validators.  The
# generic parser below supplies the lane-independent slot/lock checks while
# keeping project Work-ID / branch policy in an explicit callback.

lane_execution_validate_issue_branch() {
  # Project adapters may replace this callback with their stricter Work-ID /
  # branch relationship rule.  The topology contract itself only requires a
  # non-empty safe issue token and a valid Git branch reference.
  lane_execution_issue=$1
  lane_execution_branch=$2
  case "$lane_execution_issue" in
    ''|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  git check-ref-format --branch "$lane_execution_branch" >/dev/null 2>&1
}

lane_execution_validate_work_id() {
  # Project adapters replace this callback with their Work-ID policy.  It is
  # intentionally separate from topology parsing: a manifest never contains
  # project expressions or executable validation rules.
  lane_execution_work_id=$1
  case "$lane_execution_work_id" in
    ''|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
}

lane_execution_human_test_preflight() {
  # Project adapters replace this hook.  The generic fallback proves only the
  # common checkout boundary and emits role-specific evidence.
  lane_execution_human_lane=$1
  lane_execution_human_repo=$2
  lane_execution_human_manifest=$3
  lane_execution_human_branch=$(git -C "$lane_execution_human_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  lane_execution_human_head=$(git -C "$lane_execution_human_repo" rev-parse HEAD 2>/dev/null || true)
  lane_execution_human_dirty=$(git -C "$lane_execution_human_repo" status --porcelain 2>/dev/null)
  printf '  branch=%s\n' "${lane_execution_human_branch:-DETACHED}"
  printf '  head=%s\n' "$lane_execution_human_head"
  printf '  clean=%s\n' "$([ -z "$lane_execution_human_dirty" ] && echo yes || echo no)"
  printf '  human_hook=generic\n'
  printf '  state=%s\n' "$([ -z "$lane_execution_human_dirty" ] && [ -z "$lane_execution_human_branch" ] && echo FREE || echo BLOCKED)"
  [ -n "$lane_execution_human_head" ] &&
    [ -z "$lane_execution_human_dirty" ] &&
    [ -z "$lane_execution_human_branch" ]
}

lane_execution__path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

lane_execution__git_dir() {
  git -C "$1" rev-parse --absolute-git-dir 2>/dev/null
}

lane_execution__canonical_path() {
  lane_execution_input_path=$1
  [ -d "$lane_execution_input_path" ] || return 1
  lane_execution_canonical=$(CDPATH= cd -- "$lane_execution_input_path" && pwd -P) || return 1
  [ -n "$lane_execution_canonical" ] || return 1
  case "$lane_execution_canonical" in
    /*) printf '%s\n' "$lane_execution_canonical" ;;
    *) return 1 ;;
  esac
}

lane_execution__repository_matches() {
  lane_execution_repo=$1
  lane_execution_expected_identity=$2
  lane_execution_origin=$(git -C "$lane_execution_repo" remote get-url origin 2>/dev/null) || return 1
  lane_execution_origin=${lane_execution_origin%/}
  case "$lane_execution_origin" in
    *"/$lane_execution_expected_identity"|*"/$lane_execution_expected_identity.git"|*":$lane_execution_expected_identity"|*":$lane_execution_expected_identity.git"|"$lane_execution_expected_identity"|"$lane_execution_expected_identity.git")
      return 0
      ;;
    *) return 1 ;;
  esac
}

lane_execution__origin_default() {
  lane_execution_default_repo=$1
  lane_execution_default_branch_name=$2
  git -C "$lane_execution_default_repo" ls-remote origin \
    "refs/heads/$lane_execution_default_branch_name" 2>/dev/null |
    awk 'NR == 1 {print $1}'
}

lane_execution__valid_sha() {
  nuinui_ownership_valid_sha "$1"
}

lane_execution__valid_claim() {
  nuinui_ownership_valid_claim "$1"
}

lane_execution__parse_issue_branch() {
  lane_execution_validate_issue_branch "$1" "$2"
}

lane_execution__parse_slot() {
  [ -f "$1" ] || return 1
  set -- $(nuinui_ownership_read_fields "$1" version,issue,branch,base,claim) || return 1
  [ "$#" = 5 ] || return 1
  [ "$1" = 1 ] || return 1
  lane_execution__parse_issue_branch "$2" "$3" || return 1
  lane_execution__valid_sha "$4" || return 1
  lane_execution__valid_claim "$5" || return 1
  printf '%s %s %s %s\n' "$2" "$3" "$4" "$5"
}

lane_execution__parse_lock() {
  [ -f "$1" ] || return 1
  set -- $(nuinui_ownership_read_fields "$1" version,operation,issue,branch,base,checkpoint,claim) || return 1
  [ "$#" = 7 ] || return 1
  [ "$1" = 1 ] || return 1
  case "$2" in
    init|start|resume|release) ;;
    *) return 1 ;;
  esac
  case "$3:$4" in
    -:-) ;;
    -:*|*:-) return 1 ;;
    *) lane_execution__parse_issue_branch "$3" "$4" || return 1 ;;
  esac
  [ "$5" = - ] || lane_execution__valid_sha "$5" || return 1
  [ "$6" = - ] || lane_execution__valid_sha "$6" || return 1
  lane_execution__valid_claim "$7" || return 1
  printf '%s %s %s %s %s %s\n' "$2" "$3" "$4" "$5" "$6" "$7"
}

lane_execution__parse_releasing() {
  lane_execution_releasing_dir=$1
  [ -d "$lane_execution_releasing_dir" ] || return 1
  set -- $(lane_execution__parse_slot "$lane_execution_releasing_dir/state") || return 1
  [ -f "$lane_execution_releasing_dir/checkpoint" ] || return 1
  lane_execution_releasing_checkpoint=$(cat "$lane_execution_releasing_dir/checkpoint") || return 1
  lane_execution__valid_sha "$lane_execution_releasing_checkpoint" || return 1
  [ "${lane_execution_releasing_dir##*/}" = "nuinui-implementation-slot.releasing.$4" ] || return 1
  printf '%s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$lane_execution_releasing_checkpoint"
}

lane_execution__release_dirs() {
  lane_execution_git_dir=$1
  find "$lane_execution_git_dir" -maxdepth 1 -type d \
    -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null | LC_ALL=C sort
}

lane_execution__idle_proof() {
  lane_execution_idle_lane=$1
  lane_execution_idle_repo=$2
  lane_execution_idle_policy=$3
  lane_execution_idle_default_branch=$4
  lane_execution_idle_origin=$5
  lane_execution_idle_dirty=$(git -C "$lane_execution_idle_repo" status --porcelain 2>/dev/null)
  [ -z "$lane_execution_idle_dirty" ] || return 1
  [ "$(git -C "$lane_execution_idle_repo" rev-parse HEAD 2>/dev/null)" = "$lane_execution_idle_origin" ] || return 1
  case "$lane_execution_idle_policy" in
    branch)
      [ "$(git -C "$lane_execution_idle_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" = "$lane_execution_idle_default_branch" ]
      ;;
    detached)
      [ -z "$(git -C "$lane_execution_idle_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" ]
      ;;
    *) return 1 ;;
  esac
}

lane_execution__classify_implementation() {
  lane_execution_lane=$1
  lane_execution_repo=$2
  lane_execution_idle_policy=$3
  lane_execution_default_branch=$4
  lane_execution_git_dir=$(lane_execution__git_dir "$lane_execution_repo" || true)
  lane_execution_slot=$lane_execution_git_dir/nuinui-implementation-slot
  lane_execution_lock=$lane_execution_git_dir/nuinui-implementation-lock
  lane_execution_initialization=$lane_execution_git_dir/nuinui-implementation-v1
  lane_execution_branch=$(git -C "$lane_execution_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  lane_execution_head=$(git -C "$lane_execution_repo" rev-parse HEAD 2>/dev/null || true)
  lane_execution_dirty=$(git -C "$lane_execution_repo" status --porcelain 2>/dev/null)
  lane_execution_releasing=$(lane_execution__release_dirs "$lane_execution_git_dir")
  lane_execution_releasing_count=$(printf '%s\n' "$lane_execution_releasing" | grep -c . || true)
  printf '  branch=%s\n' "${lane_execution_branch:-DETACHED}"
  printf '  head=%s\n' "$lane_execution_head"
  printf '  clean=%s\n' "$([ -z "$lane_execution_dirty" ] && echo yes || echo no)"

  if [ -e "$lane_execution_lock" ] || [ -L "$lane_execution_lock" ]; then
    set -- $(lane_execution__parse_lock "$lane_execution_lock/state" 2>/dev/null || true)
    if [ "$#" = 6 ]; then
      printf '  state=BLOCKED reason=mutation-in-progress operation=%s claim=%s\n' "$1" "$6"
    else
      echo '  state=BLOCKED reason=invalid-mutation-lock'
    fi
    return 1
  fi

  if [ -e "$lane_execution_slot" ] || [ -L "$lane_execution_slot" ]; then
    [ -d "$lane_execution_slot" ] || {
      echo '  state=BLOCKED reason=invalid-active-slot'
      return 1
    }
    [ "$lane_execution_releasing_count" = 0 ] || {
      echo '  state=BLOCKED reason=active-and-releasing-state-coexist'
      return 1
    }
    set -- $(lane_execution__parse_slot "$lane_execution_slot/state" 2>/dev/null || true)
    [ "$#" = 4 ] || {
      echo '  state=BLOCKED reason=invalid-active-slot'
      return 1
    }
    printf '  owner_issue=%s owner_branch=%s base=%s claim=%s\n' "$1" "$2" "$3" "$4"
    [ "$lane_execution_branch" = "$2" ] &&
      git -C "$lane_execution_repo" merge-base --is-ancestor "$3" "$lane_execution_head" 2>/dev/null || {
        echo '  state=BLOCKED reason=claim-checkout-mismatch'
        return 1
      }
    echo '  state=BUSY'
    return 0
  fi

  if [ "$lane_execution_releasing_count" != 0 ]; then
    [ "$lane_execution_releasing_count" = 1 ] || {
      echo '  state=BLOCKED reason=multiple-release-states'
      return 1
    }
    set -- $(lane_execution__parse_releasing "$lane_execution_releasing" 2>/dev/null || true)
    [ "$#" = 5 ] || {
      echo '  state=BLOCKED reason=invalid-release-state'
      return 1
    }
    printf '  state=RELEASE-PENDING claim=%s checkpoint=%s\n' "$4" "$5"
    return 0
  fi

  nuinui_ownership_validate_initialization "$lane_execution_initialization" || {
    echo '  state=BLOCKED reason=durable-ownership-initialization-required'
    return 1
  }
  lane_execution_origin=$(
    lane_execution__origin_default "$lane_execution_repo" "$lane_execution_default_branch"
  )
  lane_execution__valid_sha "$lane_execution_origin" &&
    lane_execution__idle_proof "$lane_execution_lane" "$lane_execution_repo" \
      "$lane_execution_idle_policy" "$lane_execution_default_branch" "$lane_execution_origin" || {
      printf '  state=BLOCKED reason=invalid-idle-state origin_main=%s\n' "$lane_execution_origin"
      return 1
    }
  printf '  state=FREE origin_main=%s\n' "$lane_execution_origin"
}

lane_execution__inventory_check() {
  lane_execution_manifest=$1
  lane_execution_anchor=$2
  lane_execution_forensic=${3-}
  lane_execution_expected_file=$(mktemp "${TMPDIR:-/tmp}/lane-expected.XXXXXX") || return 1
  lane_execution_actual_file=$(mktemp "${TMPDIR:-/tmp}/lane-actual.XXXXXX") || {
    rm -f "$lane_execution_expected_file"
    return 1
  }
  lane_execution_sorted_expected=$lane_execution_expected_file.sorted
  lane_execution_sorted_actual=$lane_execution_actual_file.sorted
  lane_execution_inventory_rc=0
  trap 'rm -f "$lane_execution_expected_file" "$lane_execution_actual_file" "$lane_execution_sorted_expected" "$lane_execution_sorted_actual"' HUP INT TERM

  while IFS= read -r lane_execution_inventory_lane || [ -n "$lane_execution_inventory_lane" ]; do
    lane_execution_inventory_path=$(lane_manifest_lane_path "$lane_execution_manifest" "$lane_execution_inventory_lane") || {
      lane_execution_inventory_rc=1
      continue
    }
    lane_execution_inventory_physical=$(lane_execution__canonical_path "$lane_execution_inventory_path" || true)
    [ -n "$lane_execution_inventory_physical" ] || {
      lane_execution_inventory_rc=1
      continue
    }
    printf '%s\n' "$lane_execution_inventory_physical" >> "$lane_execution_expected_file"
  done <<EOF
$(lane_manifest_all_lanes "$lane_execution_manifest")
EOF

  if awk 'seen[$0]++ {invalid=1} END {exit invalid}' "$lane_execution_expected_file"; then
    :
  else
    echo '  inventory_state=BLOCKED reason=duplicate-configured-physical-path'
    lane_execution_inventory_rc=1
  fi

  lane_execution_registered=$(git -C "$lane_execution_anchor" worktree list --porcelain 2>/dev/null |
    sed -n 's/^worktree //p') || lane_execution_registered=
  [ -n "$lane_execution_registered" ] || lane_execution_inventory_rc=1
  while IFS= read -r lane_execution_registered_path || [ -n "$lane_execution_registered_path" ]; do
    [ -n "$lane_execution_registered_path" ] || continue
    lane_execution_registered_physical=$(lane_execution__canonical_path "$lane_execution_registered_path" || true)
    if [ -z "$lane_execution_registered_physical" ]; then
      echo "  inventory_state=BLOCKED reason=invalid-registered-worktree path=$lane_execution_registered_path"
      lane_execution_inventory_rc=1
    else
      printf '%s\n' "$lane_execution_registered_physical" >> "$lane_execution_actual_file"
    fi
  done <<EOF
$lane_execution_registered
EOF

  if awk 'seen[$0]++ {invalid=1} END {exit invalid}' "$lane_execution_actual_file"; then
    :
  else
    echo '  inventory_state=BLOCKED reason=duplicate-registered-physical-path'
    lane_execution_inventory_rc=1
  fi

  if [ -n "$lane_execution_forensic" ]; then
    case "$lane_execution_forensic" in /*) ;; *) echo '  inventory_state=BLOCKED reason=forensic-path-not-absolute'; lane_execution_inventory_rc=1 ;; esac
    lane_execution_forensic_physical=$(lane_execution__canonical_path "$lane_execution_forensic" || true)
    if [ -z "$lane_execution_forensic_physical" ] || [ "$lane_execution_forensic_physical" != "$lane_execution_forensic" ]; then
      echo '  inventory_state=BLOCKED reason=forensic-path-not-canonical'
      lane_execution_inventory_rc=1
    elif grep -Fqx "$lane_execution_forensic_physical" "$lane_execution_expected_file"; then
      echo '  inventory_state=BLOCKED reason=forensic-path-is-declared-lane'
      lane_execution_inventory_rc=1
    else
      printf '%s\n' "$lane_execution_forensic_physical" >> "$lane_execution_expected_file"
      grep -Fqx "$lane_execution_forensic_physical" "$lane_execution_actual_file" || {
        echo '  inventory_state=BLOCKED reason=forensic-path-not-registered'
        lane_execution_inventory_rc=1
      }
    fi
  fi

  LC_ALL=C sort "$lane_execution_expected_file" > "$lane_execution_sorted_expected" || lane_execution_inventory_rc=1
  LC_ALL=C sort "$lane_execution_actual_file" > "$lane_execution_sorted_actual" || lane_execution_inventory_rc=1
  if ! cmp -s "$lane_execution_sorted_expected" "$lane_execution_sorted_actual"; then
    echo '  inventory_state=BLOCKED reason=registered-worktree-set-mismatch'
    lane_execution_inventory_rc=1
  fi
  echo '  registered_worktrees:'
  while IFS= read -r lane_execution_registered_path || [ -n "$lane_execution_registered_path" ]; do
    [ -n "$lane_execution_registered_path" ] || continue
    printf '    path=%s\n' "$lane_execution_registered_path"
  done <<EOF
$lane_execution_registered
EOF
  [ "$lane_execution_inventory_rc" = 0 ] && echo '  inventory_state=PASS'
  rm -f "$lane_execution_expected_file" "$lane_execution_actual_file" \
    "$lane_execution_sorted_expected" "$lane_execution_sorted_actual"
  trap - HUP INT TERM
  return "$lane_execution_inventory_rc"
}

lane_execution_preflight() {
  [ "$#" = 1 ] || [ "$#" = 3 ] || return 2
  lane_execution_manifest=$1
  lane_execution_forensic=
  if [ "$#" = 3 ]; then
    [ "$2" = --forensic-worktree ] || return 2
    lane_execution_forensic=$3
  fi
  printf '%s\n' '===== LANE PREFLIGHT RESULT ====='
  printf 'manifest=%s\n' "$lane_execution_manifest"
  if ! lane_manifest_validate "$lane_execution_manifest"; then
    echo 'state=BLOCKED reason=invalid-manifest'
    echo 'PREFLIGHT BLOCKED'
    return 1
  fi
  printf 'repository=%s\ndefault_branch=%s\n' \
    "$(lane_manifest_repository_identity "$lane_execution_manifest")" \
    "$(lane_manifest_default_branch "$lane_execution_manifest")"
  lane_execution_repository=$(lane_manifest_repository_identity "$lane_execution_manifest")
  lane_execution_default_branch=$(lane_manifest_default_branch "$lane_execution_manifest")
  lane_execution_result=0
  lane_execution_anchor=
  lane_execution_seen_paths=$(mktemp "${TMPDIR:-/tmp}/lane-seen.XXXXXX") || return 1
  trap 'rm -f "$lane_execution_seen_paths"' HUP INT TERM

  while IFS= read -r lane_execution_lane || [ -n "$lane_execution_lane" ]; do
    lane_execution_role=$(lane_manifest_lane_role "$lane_execution_manifest" "$lane_execution_lane" || true)
    lane_execution_declared_path=$(lane_manifest_lane_path "$lane_execution_manifest" "$lane_execution_lane" || true)
    lane_execution_idle=$(lane_manifest_lane_idle_policy "$lane_execution_manifest" "$lane_execution_lane" || true)
    lane_execution_physical=$(lane_execution__canonical_path "$lane_execution_declared_path" || true)
    printf 'lane name=%s role=%s path=%s\n' "$lane_execution_lane" "$lane_execution_role" "${lane_execution_physical:-$lane_execution_declared_path}"
    if [ -z "$lane_execution_physical" ]; then
      echo '  state=BLOCKED reason=invalid-checkout-path'
      lane_execution_result=1
      continue
    fi
    if grep -Fqx "$lane_execution_physical" "$lane_execution_seen_paths"; then
      echo '  state=BLOCKED reason=duplicate-configured-physical-path'
      lane_execution_result=1
    else
      printf '%s\n' "$lane_execution_physical" >> "$lane_execution_seen_paths"
    fi
    [ -n "$lane_execution_anchor" ] || lane_execution_anchor=$lane_execution_physical
    if ! git -C "$lane_execution_physical" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo '  state=BLOCKED reason=not-a-git-checkout'
      lane_execution_result=1
      continue
    fi
    if ! lane_execution__repository_matches "$lane_execution_physical" "$lane_execution_repository"; then
      echo '  state=BLOCKED reason=repository-mismatch'
      lane_execution_result=1
      continue
    fi
    case "$lane_execution_role" in
      implementation)
        lane_execution__classify_implementation "$lane_execution_lane" \
          "$lane_execution_physical" "$lane_execution_idle" "$lane_execution_default_branch" || lane_execution_result=1
        ;;
      human-test)
        lane_execution_human_test_preflight "$lane_execution_lane" \
          "$lane_execution_physical" "$lane_execution_manifest" || lane_execution_result=1
        ;;
      *)
        echo '  state=BLOCKED reason=invalid-role'
        lane_execution_result=1
        ;;
    esac
  done <<EOF
$(lane_manifest_all_lanes "$lane_execution_manifest")
EOF

  if [ -n "$lane_execution_anchor" ]; then
    lane_execution__inventory_check "$lane_execution_manifest" "$lane_execution_anchor" "$lane_execution_forensic" || lane_execution_result=1
  else
    echo '  inventory_state=BLOCKED reason=no-validated-checkout-anchor'
    lane_execution_result=1
  fi
  rm -f "$lane_execution_seen_paths"
  trap - HUP INT TERM
  if [ "$lane_execution_result" = 0 ]; then
    echo 'PREFLIGHT PASS'
    return 0
  fi
  echo 'PREFLIGHT BLOCKED'
  return 1
}

lane_execution_preflight_command() {
  [ "$#" = 1 ] || [ "$#" = 3 ] || {
    echo 'Usage: lane-execution-preflight <manifest> [--forensic-worktree <absolute-path>]' >&2
    return 2
  }
  lane_execution_preflight "$@"
}

if [ "${LANE_EXECUTION_PREFLIGHT_EXECUTE:-0}" = 1 ] || [ "${0##*/}" = preflight.sh ]; then
  lane_execution_preflight_command "$@"
fi
