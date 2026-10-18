# Native GitHub D1 local admission. All functions are namespaced to avoid
# collisions with the shared generated lane-execution helpers.
checkout_check_block() {
  printf 'LOCAL CHECK BLOCKED reason=%s\n' "$1" >&2
  exit 1
}
checkout_check_exists() { [ -e "$1" ] || [ -L "$1" ]; }
checkout_check_sha() { printf '%s\n' "$1" | LC_ALL=C grep -Eq '^[0-9a-f]{40}$'; }
checkout_check_regular() { [ -f "$1" ] && [ ! -L "$1" ]; }
checkout_check_path() {
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  (CDPATH= cd -- "$1" && pwd -P)
}
checkout_check_clean() {
  checkout_check_status=$(git -C "$1" status --porcelain --untracked-files=all 2>/dev/null) || return 1
  [ -z "$checkout_check_status" ]
}
checkout_check_metadata() {
  checkout_check_dir=$1
  [ -d "$checkout_check_dir" ] && [ ! -L "$checkout_check_dir" ] ||
    checkout_check_block invalid-git-directory
  checkout_check_init=$checkout_check_dir/nuinui-implementation-v1
  checkout_check_regular "$checkout_check_init" &&
    nuinui_ownership_validate_initialization "$checkout_check_init" ||
    checkout_check_block missing-or-malformed-legacy-initialization

  checkout_check_slot=$checkout_check_dir/nuinui-implementation-slot
  if checkout_check_exists "$checkout_check_slot"; then
    [ -d "$checkout_check_slot" ] && [ ! -L "$checkout_check_slot" ] &&
      checkout_check_regular "$checkout_check_slot/state" &&
      nuinui_ownership_parse_slot "$checkout_check_slot/state" >/dev/null ||
      checkout_check_block malformed-legacy-slot
    checkout_check_block active-legacy-claim
  fi

  checkout_check_lock=$checkout_check_dir/nuinui-implementation-lock
  if checkout_check_exists "$checkout_check_lock"; then
    [ -d "$checkout_check_lock" ] && [ ! -L "$checkout_check_lock" ] &&
      checkout_check_regular "$checkout_check_lock/state" &&
      nuinui_ownership_parse_lock "$checkout_check_lock/state" >/dev/null ||
      checkout_check_block malformed-legacy-lock
    checkout_check_block active-legacy-lock
  fi
  for checkout_check_releasing in "$checkout_check_dir"/nuinui-implementation-slot.releasing.*; do
    checkout_check_exists "$checkout_check_releasing" || continue
    [ -d "$checkout_check_releasing" ] && [ ! -L "$checkout_check_releasing" ] &&
      checkout_check_regular "$checkout_check_releasing/state" &&
      checkout_check_regular "$checkout_check_releasing/checkpoint" &&
      nuinui_ownership_parse_releasing "$checkout_check_releasing" >/dev/null ||
      checkout_check_block malformed-release-tombstone
    checkout_check_block release-pending-tombstone
  done

  checkout_check_audit=$checkout_check_dir/nuinui-audit-reservation-v1
  if checkout_check_exists "$checkout_check_audit"; then
    checkout_check_regular "$checkout_check_audit" &&
      nuinui_ownership_validate_audit_reservation "$checkout_check_audit" ||
      checkout_check_block malformed-audit-reservation
    checkout_check_block active-audit-reservation
  fi

  # Native E2E metadata is not legacy SAY state. An active or interrupted
  # generation blocks, but completed release receipts need not block D1.
  for checkout_check_marker in "$checkout_check_dir"/nuinui-github-e2e-active-v1 \
    "$checkout_check_dir"/nuinui-github-e2e-starting-v1.* \
    "$checkout_check_dir"/nuinui-github-e2e-releasing-v1.*; do
    checkout_check_exists "$checkout_check_marker" || continue
    checkout_check_block active-or-interrupted-native-e2e
  done
}
checkout_check_main() {
  [ "$#" -ge 1 ] || checkout_check_block usage
  checkout_check_mode=$1
  shift
  case "$checkout_check_mode" in
    version) [ "$#" = 0 ] || checkout_check_block usage; echo 'nuinui-checkout-check 1.0.0'; return 0 ;;
    new|continue) ;;
    *) checkout_check_block usage ;;
  esac

  checkout_check_issue=
  checkout_check_main_sha=
  checkout_check_branch=
  checkout_check_checkpoint=
  checkout_check_human=
  while [ "$#" -gt 0 ]; do
    [ "$#" -ge 2 ] || {
      [ "$1" = --human-clear ] && { checkout_check_human=yes; shift; continue; }
      checkout_check_block usage
    }
    case "$1" in
      --issue) checkout_check_issue=$2 ;;
      --main) checkout_check_main_sha=$2 ;;
      --branch) checkout_check_branch=$2 ;;
      --checkpoint) checkout_check_checkpoint=$2 ;;
      --human-clear) checkout_check_block usage ;;
      *) checkout_check_block usage ;;
    esac
    shift 2
  done
  [ "$checkout_check_human" = yes ] || checkout_check_block human-occupancy-not-confirmed
  printf '%s\n' "$checkout_check_issue" |
    LC_ALL=C grep -Eq '^sayosomi/nuinuiCAD#[1-9][0-9]*$' ||
    checkout_check_block invalid-issue
  git check-ref-format --branch "$checkout_check_branch" >/dev/null 2>&1 ||
    checkout_check_block invalid-topic-branch
  [ "$checkout_check_branch" != main ] || checkout_check_block reserved-topic-branch
  case "$checkout_check_mode" in
    new)
      checkout_check_sha "$checkout_check_main_sha" ||
        checkout_check_block invalid-expected-main
      [ -z "$checkout_check_checkpoint" ] || checkout_check_block incompatible-arguments
      ;;
    continue)
      checkout_check_sha "$checkout_check_checkpoint" ||
        checkout_check_block invalid-checkpoint
      [ -z "$checkout_check_main_sha" ] || checkout_check_block incompatible-arguments
      ;;
  esac

  checkout_check_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) ||
    checkout_check_block invalid-executable-path
  checkout_check_manifest=$checkout_check_script_dir/../LANES.conf
  checkout_check_regular "$checkout_check_manifest" &&
    lane_manifest_validate "$checkout_check_manifest" ||
    checkout_check_block invalid-manifest
  checkout_check_repository=$(lane_manifest_repository_identity "$checkout_check_manifest") ||
    checkout_check_block invalid-manifest-repository
  [ "$checkout_check_repository" = sayosomi/nuinuiCAD ] ||
    checkout_check_block wrong-repository
  checkout_check_default=$(lane_manifest_default_branch "$checkout_check_manifest") ||
    checkout_check_block invalid-default-branch
  [ "$checkout_check_default" = main ] || checkout_check_block wrong-default-branch
  set -- $(lane_manifest_lanes_by_role "$checkout_check_manifest" implementation) ||
    checkout_check_block missing-implementation-lane
  [ "$#" = 1 ] || checkout_check_block ambiguous-implementation-lanes
  checkout_check_impl_lane=$1
  set -- $(lane_manifest_lanes_by_role "$checkout_check_manifest" human-test) ||
    checkout_check_block missing-human-lane
  [ "$#" = 1 ] || checkout_check_block ambiguous-human-lanes
  checkout_check_human_lane=$1

  checkout_check_impl_path=$(lane_manifest_lane_path "$checkout_check_manifest" "$checkout_check_impl_lane") ||
    checkout_check_block invalid-implementation-path
  checkout_check_impl_real=$(checkout_check_path "$checkout_check_impl_path") ||
    checkout_check_block invalid-implementation-checkout
  [ "$checkout_check_impl_real" = "$checkout_check_impl_path" ] ||
    checkout_check_block noncanonical-implementation-checkout
  checkout_check_human_path=$(lane_manifest_lane_path "$checkout_check_manifest" "$checkout_check_human_lane") ||
    checkout_check_block invalid-human-path
  checkout_check_human_real=$(checkout_check_path "$checkout_check_human_path") ||
    checkout_check_block invalid-human-checkout
  [ "$checkout_check_human_real" = "$checkout_check_human_path" ] ||
    checkout_check_block noncanonical-human-checkout
  for checkout_check_repo_path in "$checkout_check_impl_real" "$checkout_check_human_real"; do
    [ "$(git -C "$checkout_check_repo_path" rev-parse --show-toplevel 2>/dev/null)" = "$checkout_check_repo_path" ] ||
      checkout_check_block invalid-checkout-root
    lane_execution__repository_matches "$checkout_check_repo_path" "$checkout_check_repository" ||
      checkout_check_block wrong-origin
  done
  checkout_check_inventory=$(lane_execution__inventory_check     "$checkout_check_manifest" "$checkout_check_impl_real" 2>&1) ||
    checkout_check_block registered-worktree-set-mismatch
  checkout_check_impl_git=$(lane_execution__git_dir "$checkout_check_impl_real") ||
    checkout_check_block missing-implementation-git-dir
  checkout_check_human_git=$(lane_execution__git_dir "$checkout_check_human_real") ||
    checkout_check_block missing-human-git-dir
  checkout_check_impl_common=$(git -C "$checkout_check_impl_real" rev-parse --git-common-dir 2>/dev/null) ||
    checkout_check_block invalid-common-git-dir
  checkout_check_human_common=$(git -C "$checkout_check_human_real" rev-parse --git-common-dir 2>/dev/null) ||
    checkout_check_block invalid-common-git-dir
  case "$checkout_check_impl_common" in
    /*) ;;
    *) checkout_check_impl_common=$checkout_check_impl_real/$checkout_check_impl_common ;;
  esac
  case "$checkout_check_human_common" in
    /*) ;;
    *) checkout_check_human_common=$checkout_check_human_real/$checkout_check_human_common ;;
  esac
  checkout_check_impl_common=$(checkout_check_path "$checkout_check_impl_common") ||
    checkout_check_block invalid-common-git-dir
  checkout_check_human_common=$(checkout_check_path "$checkout_check_human_common") ||
    checkout_check_block invalid-common-git-dir
  [ "$checkout_check_impl_common" = "$checkout_check_human_common" ] ||
    checkout_check_block different-repository-git-directories
  checkout_check_metadata "$checkout_check_impl_git"
  # The Human-test worktree has its own per-worktree Git directory, but the
  # legacy implementation initialization lives only in the implementation
  # Git directory. Check native Human E2E markers there without inventing a
  # second initialization requirement.
  if [ "$checkout_check_human_git" != "$checkout_check_impl_git" ]; then
    [ -d "$checkout_check_human_git" ] && [ ! -L "$checkout_check_human_git" ] ||
      checkout_check_block invalid-human-git-directory
    for checkout_check_marker in "$checkout_check_human_git"/nuinui-github-e2e-active-v1 \
      "$checkout_check_human_git"/nuinui-github-e2e-starting-v1.* \
      "$checkout_check_human_git"/nuinui-github-e2e-releasing-v1.*; do
      checkout_check_exists "$checkout_check_marker" || continue
      checkout_check_block active-or-interrupted-native-e2e
    done
  fi

  checkout_check_clean "$checkout_check_impl_real" || checkout_check_block dirty-implementation
  checkout_check_clean "$checkout_check_human_real" || checkout_check_block dirty-human-checkout
  checkout_check_human_active=$(git -C "$checkout_check_human_real" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  [ -z "$checkout_check_human_active" ] || checkout_check_block human-checkout-not-detached
  checkout_check_branch_now=$(git -C "$checkout_check_impl_real" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  checkout_check_head=$(git -C "$checkout_check_impl_real" rev-parse HEAD 2>/dev/null) ||
    checkout_check_block missing-local-head
  checkout_check_sha "$checkout_check_head" || checkout_check_block invalid-local-head

  checkout_check_refs=$(git -C "$checkout_check_impl_real" ls-remote origin     "refs/heads/$checkout_check_default" "refs/heads/$checkout_check_branch" 2>/dev/null) ||
    checkout_check_block remote-unavailable
  checkout_check_remote_main=$(printf '%s\n' "$checkout_check_refs" |
    awk -v ref="refs/heads/$checkout_check_default" '$2 == ref {print $1}')
  checkout_check_remote_topic=$(printf '%s\n' "$checkout_check_refs" |
    awk -v ref="refs/heads/$checkout_check_branch" '$2 == ref {print $1}')
  checkout_check_sha "$checkout_check_remote_main" || checkout_check_block missing-remote-main

  if [ "$checkout_check_mode" = new ]; then
    [ "$checkout_check_branch_now" = "$checkout_check_default" ] ||
      checkout_check_block not-idle-main
    [ "$checkout_check_remote_main" = "$checkout_check_main_sha" ] ||
      checkout_check_block stale-remote-main
    [ -z "$checkout_check_remote_topic" ] ||
      checkout_check_block remote-topic-collision
    git -C "$checkout_check_impl_real" show-ref --verify --quiet "refs/heads/$checkout_check_branch" &&
      checkout_check_block local-topic-collision
    if [ "$checkout_check_head" != "$checkout_check_main_sha" ]; then
      if git -C "$checkout_check_impl_real" cat-file -e "$checkout_check_main_sha^{commit}" 2>/dev/null; then
        git -C "$checkout_check_impl_real" merge-base --is-ancestor           "$checkout_check_head" "$checkout_check_main_sha" 2>/dev/null ||
          checkout_check_block local-main-not-fast-forwardable
        checkout_check_ancestry=verified-fast-forward
      else
        checkout_check_ancestry=requires-agent-fetch
      fi
    else
      checkout_check_ancestry=exact
    fi
    printf 'LOCAL CHECK PASS mode=new issue=%s branch=%s main=%s local_head=%s ancestry=%s human_clear=yes\n'       "$checkout_check_issue" "$checkout_check_branch" "$checkout_check_main_sha"       "$checkout_check_head" "$checkout_check_ancestry"
  else
    [ "$checkout_check_remote_topic" = "$checkout_check_checkpoint" ] ||
      checkout_check_block missing-or-moved-remote-checkpoint
    if [ "$checkout_check_branch_now" = "$checkout_check_branch" ]; then
      [ "$checkout_check_head" = "$checkout_check_checkpoint" ] ||
        checkout_check_block local-checkpoint-mismatch
      checkout_check_resume=exact
    else
      [ "$checkout_check_branch_now" = "$checkout_check_default" ] ||
        checkout_check_block wrong-continuation-branch
      git -C "$checkout_check_impl_real" show-ref --verify --quiet         "refs/heads/$checkout_check_branch" &&
        checkout_check_block conflicting-local-topic-branch
      checkout_check_resume=tracking-branch-needed
    fi
    printf 'LOCAL CHECK PASS mode=continue issue=%s branch=%s checkpoint=%s state=%s human_clear=yes\n'       "$checkout_check_issue" "$checkout_check_branch" "$checkout_check_checkpoint" "$checkout_check_resume"
  fi
  printf '%s\n' 'LOCAL CHECK is not GitHub Issue authorization; agent must recheck volatile state immediately before mutation.'
}
checkout_check_main "$@"
