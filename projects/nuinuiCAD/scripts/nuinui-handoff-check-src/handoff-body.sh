VERSION="1.1.0"

handoff_context() {
  handoff_manifest=$(lane_standalone_context_manifest "$0" \
    "${NUINUI_HANDOFF_SELFTEST:-0}" "${NUINUI_HANDOFF_MANIFEST:-}") || return 1
  export NUINUI_RUNTIME_MANIFEST=$handoff_manifest
  lane_manifest_validate "$handoff_manifest" || {
    echo "BLOCKED: authoritative project lane manifest is invalid"
    return 1
  }
}

usage() {
  echo "Usage: $0 <implementation-lane> <SAY-123> <expected-claim> <expected-checkpoint-sha> <expected-default-sha> <absent|exact>"
}

blocked_mismatch() {
  label=$1
  expected=$2
  actual=$3
  echo "BLOCKED: handoff $label mismatch"
  echo "CALLER_EXPECTED: $expected"
  echo "ACTUAL:          ${actual:-missing}"
  return 1
}

handoff_git_repo() {
  gr "$1" || {
    echo "BLOCKED: assigned lane is not a Git worktree"
    echo "PATH: $1"
    return 1
  }
  if [ "${NUINUI_HANDOFF_SELFTEST:-0}" != 1 ]; then
    ao "$1" "$(lane_manifest_repository_identity "$NUINUI_RUNTIME_MANIFEST")" || {
      echo "BLOCKED: assigned lane repository identity does not match LANES.conf"
      echo "PATH: $1"
      return 1
    }
  fi
}

handoff_remote_topic() {
  handoff_remote_repo=$1
  handoff_remote_branch=$2
  handoff_remote_raw=$(git -C "$handoff_remote_repo" ls-remote --exit-code --heads \
    origin "refs/heads/$handoff_remote_branch" 2>/dev/null)
  handoff_remote_rc=$?
  case "$handoff_remote_rc" in
    0)
      [ "$(printf '%s\n' "$handoff_remote_raw" | awk 'NF {count++} END {print count+0}')" = 1 ] || return 1
      [ "$(printf '%s\n' "$handoff_remote_raw" | awk 'NR == 1 {print $2}')" = \
        "refs/heads/$handoff_remote_branch" ] || return 1
      handoff_remote_sha=$(printf '%s\n' "$handoff_remote_raw" | awk 'NR == 1 {print $1}')
      nuinui_ownership_valid_sha "$handoff_remote_sha" || return 1
      HANDOFF_REMOTE_STATE=present
      HANDOFF_REMOTE_SHA=$handoff_remote_sha
      ;;
    2)
      [ -z "$handoff_remote_raw" ] || return 1
      HANDOFF_REMOTE_STATE=absent
      HANDOFF_REMOTE_SHA=
      ;;
    *) return 1 ;;
  esac
}

handoff_remote_default() {
  handoff_default_branch=$(lane_execution_runtime_default_branch) || return 1
  handoff_default_raw=$(git -C "$1" ls-remote --exit-code origin \
    "refs/heads/$handoff_default_branch" 2>/dev/null) || return 1
  [ "$(printf '%s\n' "$handoff_default_raw" | awk 'NF {count++} END {print count+0}')" = 1 ] || return 1
  [ "$(printf '%s\n' "$handoff_default_raw" | awk 'NR == 1 {print $2}')" = \
    "refs/heads/$handoff_default_branch" ] || return 1
  handoff_default_sha=$(printf '%s\n' "$handoff_default_raw" | awk 'NR == 1 {print $1}')
  nuinui_ownership_valid_sha "$handoff_default_sha" || return 1
  HANDOFF_DEFAULT_SHA=$handoff_default_sha
}

handoff_check() {
  lane=$1
  issue=$2
  expected_claim=$3
  expected_checkpoint=$4
  expected_default=$5
  remote_mode=$6

  nuinui_ownership_valid_issue "$issue" || { echo "ERROR: Issue must look like SAY-123"; return 2; }
  nuinui_ownership_valid_claim "$expected_claim" || { echo "ERROR: expected claim is invalid"; return 2; }
  nuinui_ownership_valid_sha "$expected_checkpoint" || {
    echo "ERROR: expected checkpoint must be a full 40-character commit SHA"; return 2
  }
  nuinui_ownership_valid_sha "$expected_default" || {
    echo "ERROR: expected default must be a full 40-character commit SHA"; return 2
  }
  case "$remote_mode" in absent|exact) ;; *) echo "ERROR: remote mode must be absent or exact"; return 2 ;; esac
  il "$lane" || { echo "ERROR: lane must be a declared implementation lane"; return 2; }
  repo=$(lr "$lane") || return 1
  handoff_git_repo "$repo" || return 1
  gitdir=$(gd "$repo") || return 1
  slot=$gitdir/nuinui-implementation-slot
  lock=$gitdir/nuinui-implementation-lock

  [ ! -e "$lock" ] && [ ! -L "$lock" ] || { echo "BLOCKED: implementation lane mutation lock exists"; return 1; }
  releasing=$(rds "$repo") || { echo "BLOCKED: unable to discover release-pending state"; return 1; }
  [ -z "$releasing" ] || { echo "BLOCKED: implementation lane has release-pending state"; return 1; }
  [ -d "$slot" ] && [ ! -L "$slot" ] || { echo "BLOCKED: active durable lane claim is missing"; return 1; }
  [ -f "$slot/state" ] && [ ! -L "$slot/state" ] || { echo "BLOCKED: active durable lane claim is missing"; return 1; }
  set -- $(nuinui_ownership_parse_slot "$slot/state") || {
    echo "BLOCKED: active durable lane claim is invalid"; return 1
  }
  slot_snapshot=$(cat "$slot/state") || return 1
  slot_issue=$1
  slot_branch=$2
  slot_base=$3
  slot_claim=$4
  [ "$slot_issue" = "$issue" ] || blocked_mismatch Issue "$issue" "$slot_issue" || return 1
  [ "$slot_claim" = "$expected_claim" ] || blocked_mismatch claim "$expected_claim" "$slot_claim" || return 1

  dirty=$(git -C "$repo" status --porcelain 2>/dev/null) || { echo "BLOCKED: unable to read working tree state"; return 1; }
  [ -z "$dirty" ] || { echo "BLOCKED: assigned lane is dirty"; return 1; }
  current_branch=$(bn "$repo")
  current_head=$(hh "$repo") || return 1
  [ "$current_branch" = "$slot_branch" ] || blocked_mismatch "claimed branch" "$slot_branch" "${current_branch:-DETACHED}" || return 1
  [ "$current_head" = "$expected_checkpoint" ] || blocked_mismatch checkpoint "$expected_checkpoint" "$current_head" || return 1
  an "$repo" "$slot_base" "$current_head" || { echo "BLOCKED: checkpoint is not descended from claimed Base"; return 1; }

  handoff_remote_topic "$repo" "$slot_branch" || { echo "BLOCKED: authoritative remote topic state is unavailable"; return 1; }
  remote_topic_state=$HANDOFF_REMOTE_STATE
  remote_topic_sha=$HANDOFF_REMOTE_SHA
  case "$remote_mode" in
    absent) [ "$remote_topic_state" = absent ] || { echo "BLOCKED: handoff expected fresh unpushed topic branch"; return 1; } ;;
    exact)
      [ "$remote_topic_state" = present ] || { echo "BLOCKED: authoritative remote topic is absent"; return 1; }
      [ "$remote_topic_sha" = "$expected_checkpoint" ] || blocked_mismatch "remote topic checkpoint" "$expected_checkpoint" "$remote_topic_sha" || return 1
      ;;
  esac
  handoff_remote_default "$repo" || { echo "BLOCKED: authoritative remote default is unavailable"; return 1; }
  [ "$HANDOFF_DEFAULT_SHA" = "$expected_default" ] || blocked_mismatch "remote default" "$expected_default" "$HANDOFF_DEFAULT_SHA" || return 1

  handoff_remote_topic "$repo" "$slot_branch" || { echo "BLOCKED: authoritative remote topic became unavailable during verification"; return 1; }
  [ "$HANDOFF_REMOTE_STATE" = "$remote_topic_state" ] || { echo "BLOCKED: remote topic presence changed during handoff verification"; return 1; }
  [ "$HANDOFF_REMOTE_SHA" = "$remote_topic_sha" ] || { echo "BLOCKED: remote topic changed during handoff verification"; return 1; }
  handoff_remote_default "$repo" || { echo "BLOCKED: authoritative remote default became unavailable during verification"; return 1; }
  [ "$HANDOFF_DEFAULT_SHA" = "$expected_default" ] || { echo "BLOCKED: remote default changed during handoff verification"; return 1; }

  [ ! -e "$lock" ] && [ ! -L "$lock" ] || { echo "BLOCKED: implementation lane mutation lock appeared during handoff verification"; return 1; }
  [ -z "$(rds "$repo")" ] || { echo "BLOCKED: release-pending state appeared during handoff verification"; return 1; }
  nuinui_ownership_parse_slot "$slot/state" >/dev/null || { echo "BLOCKED: durable lane claim became invalid during handoff verification"; return 1; }
  [ "$(cat "$slot/state")" = "$slot_snapshot" ] || { echo "BLOCKED: durable lane claim changed during handoff verification"; return 1; }
  [ "$(bn "$repo")" = "$current_branch" ] || { echo "BLOCKED: local branch changed during handoff verification"; return 1; }
  [ "$(hh "$repo")" = "$current_head" ] || { echo "BLOCKED: local HEAD changed during handoff verification"; return 1; }
  [ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] || { echo "BLOCKED: working tree changed during handoff verification"; return 1; }

  echo "HANDOFF VERIFIED"
  echo "  lane=$lane"
  echo "  issue=$slot_issue"
  echo "  claim=$slot_claim"
  echo "  branch=$slot_branch"
  echo "  base=$slot_base"
  echo "  checkpoint=$current_head"
  echo "  remote_topic_mode=$remote_mode"
  echo "  default_branch=$(lane_execution_runtime_default_branch)"
  echo "  origin_default=$HANDOFF_DEFAULT_SHA"
  echo "  clean=yes"
  echo "  identity=$slot_issue/$slot_claim/$current_head/$HANDOFF_DEFAULT_SHA"
}

case "${1:-}" in
  version) echo "$VERSION" ;;
  *)
    [ "$#" -eq 6 ] || { usage; exit 2; }
    handoff_context || exit 1
    handoff_check "$1" "$2" "$3" "$4" "$5" "$6"
    ;;
esac
