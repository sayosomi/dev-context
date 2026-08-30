CONTEXT_ARTIFACT=projects/nuinuiCAD/scripts/nuinui

context_valid_sha() {
  nuinui_ownership_valid_sha "$1"
}

context_origin_exact() {
  context_origin_actual=$(git -C "$C" remote get-url origin 2>/dev/null) || return 1
  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    [ -n "$CT" ] && [ "$context_origin_actual" = "$CT" ]
    return $?
  fi
  case "$context_origin_actual" in
    https://github.com/sayosomi/dev-context|https://github.com/sayosomi/dev-context.git|git@github.com:sayosomi/dev-context|git@github.com:sayosomi/dev-context.git|ssh://git@github.com/sayosomi/dev-context|ssh://git@github.com/sayosomi/dev-context.git)
      return 0
      ;;
  esac
  return 1
}

context_repo_ready() {
  [ -n "$C" ] && gr "$C" && context_origin_exact
}

context_artifact_blob() {
  context_artifact_repo=$1
  context_artifact_ref=$2
  context_artifact_sha=$(git -C "$context_artifact_repo" rev-parse "$context_artifact_ref:$CONTEXT_ARTIFACT" 2>/dev/null) || return 1
  context_valid_sha "$context_artifact_sha" || return 1
  [ "$(git -C "$context_artifact_repo" cat-file -t "$context_artifact_sha" 2>/dev/null)" = blob ] || return 1
  printf '%s\n' "$context_artifact_sha"
}

context_authoritative_main() {
  context_remote_line=$(git -C "$C" ls-remote --exit-code origin refs/heads/main 2>/dev/null) || {
    context_remote_rc=$?
    return "$context_remote_rc"
  }
  set -- $context_remote_line
  [ "$#" = 2 ] || return 1
  context_valid_sha "$1" || return 1
  [ "$2" = refs/heads/main ] || return 1
  context_remote_main=$1
  printf '%s\n' "$context_remote_main"
}

context_remote_branch() {
  context_remote_branch_name=$1
  context_remote_line=$(git -C "$C" ls-remote --exit-code --heads origin "refs/heads/$context_remote_branch_name" 2>/dev/null)
  context_remote_rc=$?
  if [ "$context_remote_rc" = 2 ] && [ -z "$context_remote_line" ]; then
    context_remote_branch_state=absent
    context_remote_branch_sha=
    return 0
  fi
  [ "$context_remote_rc" = 0 ] || return 1
  set -- $context_remote_line
  [ "$#" = 2 ] || return 1
  context_valid_sha "$1" || return 1
  [ "$2" = "refs/heads/$context_remote_branch_name" ] || return 1
  context_remote_branch_state=present
  context_remote_branch_sha=$1
}

context_git_common_abs() {
  context_common_repo=$1
  context_common_dir=$(git -C "$context_common_repo" rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$context_common_dir" in
    /*) CDPATH= cd -- "$context_common_dir" 2>/dev/null && pwd -P;;
    *) CDPATH= cd -- "$context_common_repo/$context_common_dir" 2>/dev/null && pwd -P;;
  esac
}

context_worktree_registry() {
  context_worktree_listing=$(git -C "$C" worktree list --porcelain 2>/dev/null) || return 1
  context_worktree_target=$(git -C "$CD" rev-parse --show-toplevel 2>/dev/null) || return 1
  context_worktree_target_count=$(printf '%s\n' "$context_worktree_listing" | awk -v target="$context_worktree_target" '
    BEGIN { valid=1 }
    function finish_record() {
      if (in_record && (!have_head || (!have_branch && !is_detached && !is_bare) || is_prunable)) valid=0
    }
    /^worktree / {
      finish_record()
      in_record=1
      path=substr($0,10)
      have_head=0
      have_branch=0
      is_detached=0
      is_bare=0
      is_prunable=0
      if (path == "") valid=0
      if (seen[path]++) valid=0
      if (path == target) target_count++
      next
    }
    /^HEAD / {
      if (!in_record || have_head || $2 !~ /^[0-9a-fA-F]{40}$/) valid=0
      have_head=1
      next
    }
    /^branch / {
      if (!in_record || have_branch || is_detached || is_bare || $2 !~ /^refs\/heads\/.+/) valid=0
      have_branch=1
      next
    }
    /^detached$/ {
      if (!in_record || have_branch || is_detached || is_bare) valid=0
      is_detached=1
      next
    }
    /^bare$/ {
      if (!in_record || have_branch || is_detached || is_bare) valid=0
      is_bare=1
      next
    }
    /^locked( |$)/ { if (!in_record) valid=0; next }
    /^prunable( |$)/ { if (!in_record) valid=0; is_prunable=1; next }
    /^$/ { next }
    { valid=0 }
    END {
      finish_record()
      if (!valid || target_count != 1) exit 1
      print target_count
    }
  ') || return 1
  [ "$context_worktree_target_count" = 1 ]
}

context_dev_ready() {
  [ -n "$CD" ] && [ -d "$CD" ] && gr "$CD" || return 1
  context_worktree_registry || return 1
  context_common_standard=$(context_git_common_abs "$C") || return 1
  context_common_dev=$(context_git_common_abs "$CD") || return 1
  [ "$context_common_standard" = "$context_common_dev" ]
}

context_valid_branch() {
  git -C "$C" check-ref-format --branch "$1" >/dev/null 2>&1
}

context_local_branch_exists() {
  git -C "$C" show-ref --verify --quiet "refs/heads/$1"
}

context_audit_prove() {
  context_expected_main=$1
  context_expected_artifact=$2
  context_valid_sha "$context_expected_main" || {
    context_audit_error="ERROR: invalid expected main SHA: $context_expected_main"
    return 2
  }
  context_valid_sha "$context_expected_artifact" || {
    context_audit_error="ERROR: invalid expected artifact blob SHA: $context_expected_artifact"
    return 2
  }
  context_repo_ready || {
    context_audit_error="BLOCKED: standard clone repository/origin mismatch expected_origin=$CT path=$C"
    return 1
  }
  context_audit_branch=$(bn "$C")
  [ "$context_audit_branch" = main ] || {
    context_audit_error="BLOCKED: standard clone branch mismatch expected=main actual=${context_audit_branch:-detached}"
    return 1
  }
  cn "$C" || {
    context_audit_error="BLOCKED: standard clone is dirty path=$C"
    return 1
  }
  context_audit_head=$(hh "$C") || {
    context_audit_error='ERROR: unable to read standard clone HEAD'
    return 1
  }
  context_valid_sha "$context_audit_head" || {
    context_audit_error="ERROR: standard clone HEAD is not a valid SHA: $context_audit_head"
    return 1
  }
  context_audit_artifact=$(context_artifact_blob "$C" HEAD) || {
    context_audit_error="ERROR: unable to read local artifact blob at $CONTEXT_ARTIFACT"
    return 1
  }
  context_audit_remote=$(context_authoritative_main) || {
    context_audit_error="ERROR: authoritative remote main query failed origin=$CT"
    return 1
  }
  [ "$context_audit_remote" = "$context_expected_main" ] || {
    context_audit_error="BLOCKED: authoritative main mismatch expected=$context_expected_main actual=$context_audit_remote"
    return 1
  }
}

context_audit_command() {
  context_audit_prove "$1" "$2" || {
    printf '%s\n' "$context_audit_error"
    return 1
  }
  printf 'AUDIT COMPLETE\nhead=%s\norigin_main=%s\nartifact_blob=%s\nclean=yes\n' "$context_audit_head" "$context_audit_remote" "$context_audit_artifact"
}

context_sync_command() {
  context_sync_expected_main=$1
  context_sync_expected_artifact=$2
  context_audit_prove "$context_sync_expected_main" "$context_sync_expected_artifact" || {
    printf '%s\n' "$context_audit_error"
    return 1
  }
  context_sync_old_head=$context_audit_head
  fm "$C" || {
    echo "ERROR: fetch of origin/main failed expected=$context_sync_expected_main"
    return 1
  }
  [ "$(om "$C")" = "$context_sync_expected_main" ] || {
    echo "BLOCKED: fetched origin/main mismatch expected=$context_sync_expected_main actual=$(om "$C")"
    return 1
  }
  [ "$(bn "$C")" = main ] && cn "$C" && [ "$(hh "$C")" = "$context_sync_old_head" ] || {
    echo 'BLOCKED: standard clone changed during guarded fetch'
    return 1
  }
  context_authoritative_main >/dev/null || {
    echo 'ERROR: authoritative remote main query failed after fetch'
    return 1
  }
  [ "$context_remote_main" = "$context_sync_expected_main" ] || {
    echo "BLOCKED: authoritative main raced during sync expected=$context_sync_expected_main actual=$context_remote_main"
    return 1
  }
  an "$C" "$context_sync_old_head" "$context_sync_expected_main" || {
    echo "BLOCKED: local main history diverges expected_ancestor=$context_sync_old_head target=$context_sync_expected_main"
    return 1
  }
  context_sync_target_artifact=$(context_artifact_blob "$C" "$context_sync_expected_main") || {
    echo "ERROR: unable to read target artifact blob at $CONTEXT_ARTIFACT for expected-main=$context_sync_expected_main"
    return 1
  }
  [ "$context_sync_target_artifact" = "$context_sync_expected_artifact" ] || {
    echo "BLOCKED: target artifact blob mismatch expected=$context_sync_expected_artifact actual=$context_sync_target_artifact"
    return 1
  }
  git -C "$C" merge --ff-only origin/main >/dev/null 2>&1 || {
    echo "ERROR: fast-forward sync failed expected=$context_sync_expected_main"
    return 1
  }
  [ "$(hh "$C")" = "$context_sync_expected_main" ] || {
    echo "ERROR: post-sync HEAD mismatch expected=$context_sync_expected_main actual=$(hh "$C")"
    return 1
  }
  cn "$C" || {
    echo 'ERROR: standard clone is dirty after sync'
    return 1
  }
  context_sync_post_artifact=$(context_artifact_blob "$C" HEAD) || {
    echo 'ERROR: unable to read post-sync artifact blob'
    return 1
  }
  [ "$context_sync_post_artifact" = "$context_sync_expected_artifact" ] || {
    echo "ERROR: post-sync artifact blob mismatch expected=$context_sync_expected_artifact actual=$context_sync_post_artifact"
    return 1
  }
  printf 'CONTEXT SYNCED\nhead=%s\nartifact_blob=%s\nclean=yes\n' "$context_sync_expected_main" "$context_sync_post_artifact"
}

context_dev_audit_prove() {
  context_dev_expected_branch=$1
  context_dev_expected_head=$2
  context_valid_branch "$context_dev_expected_branch" || {
    context_dev_audit_error="ERROR: invalid expected dev branch: $context_dev_expected_branch"
    return 2
  }
  context_valid_sha "$context_dev_expected_head" || {
    context_dev_audit_error="ERROR: invalid expected dev HEAD SHA: $context_dev_expected_head"
    return 2
  }
  context_repo_ready || {
    context_dev_audit_error="BLOCKED: standard clone repository/origin mismatch expected_origin=$CT path=$C"
    return 1
  }
  context_dev_ready || {
    context_dev_audit_error="BLOCKED: canonical dev worktree registration is missing, duplicate, malformed, or belongs to another repository path=$CD"
    return 1
  }
  context_dev_audit_branch=$(bn "$CD")
  [ "$context_dev_audit_branch" = "$context_dev_expected_branch" ] || {
    context_dev_audit_error="BLOCKED: dev branch mismatch expected=$context_dev_expected_branch actual=${context_dev_audit_branch:-detached}"
    return 1
  }
  cn "$CD" || {
    context_dev_audit_error="BLOCKED: canonical dev worktree is dirty path=$CD"
    return 1
  }
  context_dev_audit_head=$(hh "$CD") || {
    context_dev_audit_error='ERROR: unable to read canonical dev worktree HEAD'
    return 1
  }
  [ "$context_dev_audit_head" = "$context_dev_expected_head" ] || {
    context_dev_audit_error="BLOCKED: dev HEAD mismatch expected=$context_dev_expected_head actual=$context_dev_audit_head"
    return 1
  }
}

context_dev_audit_command() {
  context_dev_audit_prove "$1" "$2" || {
    printf '%s\n' "$context_dev_audit_error"
    return 1
  }
  printf 'DEV-CONTEXT AUDIT COMPLETE\nworktree=%s\nbranch=%s\nhead=%s\nclean=yes\n' "$CD" "$context_dev_audit_branch" "$context_dev_audit_head"
}

context_dev_transition_command() {
  context_transition_old_branch=$1
  context_transition_old_head=$2
  context_transition_expected_main=$3
  context_transition_new_branch=$4
  context_valid_branch "$context_transition_old_branch" || { echo "ERROR: invalid expected old branch: $context_transition_old_branch"; return 2; }
  context_valid_branch "$context_transition_new_branch" || { echo "ERROR: invalid new branch: $context_transition_new_branch"; return 2; }
  context_valid_sha "$context_transition_old_head" || { echo "ERROR: invalid expected old HEAD SHA: $context_transition_old_head"; return 2; }
  context_valid_sha "$context_transition_expected_main" || { echo "ERROR: invalid expected main SHA: $context_transition_expected_main"; return 2; }
  context_repo_ready || { echo "BLOCKED: standard clone repository/origin mismatch expected_origin=$CT path=$C"; return 1; }
  context_dev_ready || { echo "BLOCKED: canonical dev worktree registration is missing, duplicate, malformed, or belongs to another repository path=$CD"; return 1; }
  [ "$(bn "$CD")" = "$context_transition_old_branch" ] || { echo "BLOCKED: old dev branch mismatch expected=$context_transition_old_branch actual=$(bn "$CD")"; return 1; }
  cn "$CD" || { echo "BLOCKED: canonical dev worktree is dirty path=$CD"; return 1; }
  [ "$(hh "$CD")" = "$context_transition_old_head" ] || { echo "BLOCKED: old dev HEAD mismatch expected=$context_transition_old_head actual=$(hh "$CD")"; return 1; }
  context_authoritative_main >/dev/null || { echo 'ERROR: authoritative remote main query failed'; return 1; }
  [ "$context_remote_main" = "$context_transition_expected_main" ] || { echo "BLOCKED: authoritative main mismatch expected=$context_transition_expected_main actual=$context_remote_main"; return 1; }
  an "$C" "$context_transition_old_head" "$context_transition_expected_main" || { echo "BLOCKED: old HEAD is not contained in expected main old=$context_transition_old_head expected_main=$context_transition_expected_main"; return 1; }
  context_local_branch_exists "$context_transition_new_branch" && { echo "BLOCKED: local new branch already exists: $context_transition_new_branch"; return 1; }
  context_remote_branch "$context_transition_new_branch" || { echo "ERROR: unable to query remote new branch: $context_transition_new_branch"; return 1; }
  [ "$context_remote_branch_state" = absent ] || { echo "BLOCKED: remote new branch already exists: $context_transition_new_branch"; return 1; }
  fm "$C" || { echo "ERROR: fetch of origin/main failed expected=$context_transition_expected_main"; return 1; }
  [ "$(om "$C")" = "$context_transition_expected_main" ] || { echo "BLOCKED: fetched origin/main mismatch expected=$context_transition_expected_main actual=$(om "$C")"; return 1; }
  [ "$(bn "$CD")" = "$context_transition_old_branch" ] && cn "$CD" && [ "$(hh "$CD")" = "$context_transition_old_head" ] || { echo 'BLOCKED: old dev checkout changed during guarded fetch'; return 1; }
  context_local_branch_exists "$context_transition_new_branch" && { echo "BLOCKED: local new branch appeared during guarded fetch: $context_transition_new_branch"; return 1; }
  context_authoritative_main >/dev/null || { echo 'ERROR: authoritative remote main query failed after fetch'; return 1; }
  [ "$context_remote_main" = "$context_transition_expected_main" ] || { echo "BLOCKED: authoritative main raced before transition expected=$context_transition_expected_main actual=$context_remote_main"; return 1; }
  context_remote_branch "$context_transition_new_branch" || { echo "ERROR: unable to query remote new branch after fetch: $context_transition_new_branch"; return 1; }
  [ "$context_remote_branch_state" = absent ] || { echo "BLOCKED: remote new branch appeared before transition: $context_transition_new_branch"; return 1; }
  an "$C" "$context_transition_old_head" "$context_transition_expected_main" || { echo "BLOCKED: old HEAD is not contained in expected main after fetch old=$context_transition_old_head expected_main=$context_transition_expected_main"; return 1; }
  git -C "$CD" switch --detach "$context_transition_expected_main" >/dev/null 2>&1 || { echo "ERROR: ordinary detach to expected main failed: $context_transition_expected_main"; return 1; }
  git -C "$CD" switch -c "$context_transition_new_branch" "$context_transition_expected_main" >/dev/null 2>&1 || { echo "ERROR: ordinary create/switch of new branch failed: $context_transition_new_branch"; return 1; }
  context_worktree_registry || { echo 'ERROR: canonical dev worktree registration changed after transition'; return 1; }
  [ "$(bn "$CD")" = "$context_transition_new_branch" ] || { echo "ERROR: post-transition branch mismatch expected=$context_transition_new_branch actual=$(bn "$CD")"; return 1; }
  [ "$(hh "$CD")" = "$context_transition_expected_main" ] || { echo "ERROR: post-transition HEAD mismatch expected=$context_transition_expected_main actual=$(hh "$CD")"; return 1; }
  cn "$CD" || { echo 'ERROR: canonical dev worktree is dirty after transition'; return 1; }
  context_local_branch_exists "$context_transition_old_branch" || { echo "ERROR: old branch was not retained: $context_transition_old_branch"; return 1; }
  printf 'DEV-CONTEXT TRANSITIONED\nworktree=%s\nbranch=%s\nbase=%s\nhead=%s\nclean=yes\n' "$CD" "$context_transition_new_branch" "$context_transition_expected_main" "$context_transition_expected_main"
}

sy() { context_sync_command "$@"; }
dc() { [ -d "$C" ] || { echo 'dev-context=not-installed'; return; }; gr "$C" || return 1; echo "dev-context=$C branch=$(bn "$C") head=$(hh "$C") clean=$([ cn "$C" ]&&echo yes||echo no)"; cn "$C"; }
