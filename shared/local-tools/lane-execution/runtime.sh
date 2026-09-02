#!/bin/sh

# Generic runtime mechanics shared by manifest-driven lane operations and the
# existing project command sources.  Lane identity, checkout path, idle form,
# repository, and default branch are read from NUINUI_RUNTIME_MANIFEST.

lane_execution_runtime_ready() {
  [ -n "${NUINUI_RUNTIME_MANIFEST:-}" ] &&
    lane_manifest_validate "$NUINUI_RUNTIME_MANIFEST"
}

lr() {
  lane_execution_runtime_ready || return 1
  lane_manifest_lane_path "$NUINUI_RUNTIME_MANIFEST" "$1"
}

il() {
  lane_execution_runtime_ready || return 1
  [ "$(lane_manifest_lane_role "$NUINUI_RUNTIME_MANIFEST" "$1" 2>/dev/null)" = implementation ]
}

gr() { [ -d "$1" ] && git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

ao() {
  runtime_origin=$(git -C "$1" remote get-url origin 2>/dev/null) || return 1
  runtime_origin=${runtime_origin%/}
  runtime_expected=$2
  case "$runtime_origin" in
    *"/$runtime_expected"|*"/$runtime_expected.git"|*":$runtime_expected"|*":$runtime_expected.git"|"$runtime_expected"|"$runtime_expected.git") return 0 ;;
    *) return 1 ;;
  esac
}

cn() { [ -z "$(git -C "$1" status --porcelain 2>/dev/null)" ]; }
bn() { git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null || true; }
hh() { git -C "$1" rev-parse HEAD 2>/dev/null; }

lane_execution_runtime_default_branch() {
  if [ -n "${NUINUI_RUNTIME_MANIFEST:-}" ]; then
    lane_manifest_default_branch "$NUINUI_RUNTIME_MANIFEST"
  else
    printf '%s\n' main
  fi
}

om() { git -C "$1" rev-parse "origin/$(lane_execution_runtime_default_branch)" 2>/dev/null; }
fm() { git -C "$1" fetch origin "$(lane_execution_runtime_default_branch)" >/dev/null 2>&1; }
fp() { git -C "$1" fetch origin --prune >/dev/null 2>&1; }
an() { git -C "$1" merge-base --is-ancestor "$2" "$3"; }
sd() { git -C "$1" switch --detach "$2" >/dev/null; }
gd() { git -C "$1" rev-parse --absolute-git-dir 2>/dev/null; }
ip() { printf '%s/nuinui-implementation-v1\n' "$(gd "$1")"; }
sp() { printf '%s/nuinui-implementation-slot\n' "$(gd "$1")"; }
kp() { printf '%s/nuinui-implementation-lock\n' "$(gd "$1")"; }
rp() { printf '%s/nuinui-implementation-slot.releasing.%s\n' "$(gd "$1")" "$2"; }
rds() {
  runtime_releasing_git_dir=$(gd "$1") || return 1
  runtime_releasing=$(find "$runtime_releasing_git_dir" -maxdepth 1 -type d \
    -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null) || return 1
  [ -z "$runtime_releasing" ] || printf '%s\n' "$runtime_releasing" | LC_ALL=C sort
}
mp() { printf '%s/nuinui-slot\n' "$(gd "$1")"; }
ep() { printf '%s/nuinui-e2e-session\n' "$(gd "$1")"; }

wa() {
  runtime_write_target=$1.tmp.$$
  (umask 077; printf '%b' "$2" >"$runtime_write_target") && mv -- "$runtime_write_target" "$1"
}

gc() {
  command -v uuidgen >/dev/null 2>&1 && uuidgen | tr A-Z a-z ||
    printf '%s:%s:%s\n' $$ "$(date +%s)" "${RANDOM:-0}" | git hash-object --stdin
}

lo() {
  runtime_lock_dir=$(kp "$1")
  mkdir "$runtime_lock_dir" 2>/dev/null || return 1
  wa "$runtime_lock_dir/state" \
    "version=1\noperation=$2\nissue=$4\nbranch=$5\nbase=$6\ncheckpoint=$7\nclaim=$3\n"
}

ul() {
  runtime_unlock_repo=$1
  runtime_unlock_claim=$2
  set -- $(nuinui_ownership_parse_lock "$(kp "$runtime_unlock_repo")/state") || return 1
  [ "$6" = "$runtime_unlock_claim" ] || return 1
  rm "$(kp "$runtime_unlock_repo")/state" && rmdir "$(kp "$runtime_unlock_repo")"
}

am() {
  git -C "$1" ls-remote origin "refs/heads/$(lane_execution_runtime_default_branch)" 2>/dev/null |
    awk 'NR == 1 {print $1}'
}

ab() {
  git -C "$1" ls-remote --heads origin "refs/heads/$2" 2>/dev/null | awk 'NR == 1 {print $1}'
}

id() {
  runtime_idle_lane=$1
  runtime_idle_repo=$2
  runtime_idle_head=$3
  cn "$runtime_idle_repo" || return 1
  [ "$(hh "$runtime_idle_repo")" = "$runtime_idle_head" ] || return 1
  case "$(lane_manifest_lane_idle_policy "$NUINUI_RUNTIME_MANIFEST" "$runtime_idle_lane" 2>/dev/null)" in
    branch) [ "$(bn "$runtime_idle_repo")" = "$(lane_execution_runtime_default_branch)" ] ;;
    detached) [ -z "$(bn "$runtime_idle_repo")" ] ;;
    *) return 1 ;;
  esac
}

nr() {
  runtime_no_release_dirs=$(rds "$1") || return 1
  [ -z "$runtime_no_release_dirs" ]
}

bo() {
  runtime_branch_path=$(CDPATH= cd -- "$1" && pwd -P) || return 1
  git -C "$1" worktree list --porcelain 2>/dev/null |
    awk -v branch="refs/heads/$2" -v path="$runtime_branch_path" '
      /^worktree / {worktree=substr($0, 10)}
      /^branch / && substr($0, 8) == branch && worktree != path {print worktree; exit}
    '
}

rr() { printf '%s/nuinui-implementation-release-receipt\n' "$(gd "$1")"; }

lane_execution_prove_busy_retry() {
  local attempt
  for attempt in 1 2 3; do lane_execution__prove_busy "$@" && return 0; done
  return 1
}

# Compatibility name retained for project integration code. Existing project
# callers pass lane-first arguments; the generic owner receives the manifest.
lifecycle_prove_busy_retry() {
  [ "$#" = 6 ] || return 2
  lane_execution_prove_busy_retry "$NUINUI_RUNTIME_MANIFEST" "$1" "$2" \
    "$4" "$3" "$5" &&
    [ "$lane_execution_proof_checkpoint" = "$6" ]
}
