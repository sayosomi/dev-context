# Public implementation lifecycle façade for the fixed two-lane core.
# Release-specific façade logic lives in release-facade.sh.

lifecycle_repo() { lr "$1"; }
lifecycle_peer_lane() { fixed_2plus1_profile_peer_lane "$1"; }
lifecycle_git_dir() { gd "$1"; }
lifecycle_slot_state() { printf '%s/state\n' "$(sp "$1")"; }
lifecycle_valid_peer() {
  [ "$1" = FREE ] || nuinui_ownership_valid_issue "$1"
}

lifecycle_preflight() {
  NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT=
  NUINUI_LIFECYCLE_PREFLIGHT_RC=0
  NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT=$(pf 2>&1) ||
    NUINUI_LIFECYCLE_PREFLIGHT_RC=$?
  [ "$NUINUI_LIFECYCLE_PREFLIGHT_RC" = 0 ]
}

lifecycle_lane_state() {
  printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT" | awk -v lane="$1" '
    $0 ~ ("^" lane " path=") {seen_lane=1; next}
    seen_lane && $0 ~ /^  state=/ {sub(/^  state=/,""); sub(/ .*/,""); print; exit}
    seen_lane && $0 !~ /^ / {exit}
  '
}

lifecycle_lane_issue() {
  printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT" | awk -v lane="$1" '
    $0 ~ ("^" lane " path=") {seen_lane=1; next}
    seen_lane && $0 ~ /^  owner_issue=/ {sub(/^  owner_issue=/,""); sub(/ .*/,""); print; exit}
    seen_lane && $0 !~ /^ / {exit}
  '
}

lifecycle_expect_lane() {
  local expected_lane expected_occupancy actual_state actual_issue
  expected_lane=$1
  expected_occupancy=$2
  actual_state=$(lifecycle_lane_state "$expected_lane")
  actual_issue=$(lifecycle_lane_issue "$expected_lane")
  case "$expected_occupancy" in
    FREE) [ "$actual_state" = FREE ] && [ -z "$actual_issue" ] ;;
    *) nuinui_ownership_valid_issue "$expected_occupancy" &&
      [ "$actual_state" = BUSY ] && [ "$actual_issue" = "$expected_occupancy" ] ;;
  esac
}

lifecycle_blocked_occupancy() {
  local peer_state peer_issue
  peer_state=$5
  peer_issue=$6
  [ -n "$peer_state" ] || peer_state=-
  [ -n "$peer_issue" ] || peer_issue=-
  printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT"
  printf 'BLOCKED: begin %s\nlane=%s\nexpected_peer=%s\npeer_lane=%s\n' \
    "$1" "$2" "$3" "$4"
  printf 'peer_state=%s\npeer_issue=%s\n' "$peer_state" "$peer_issue"
}

lifecycle_prove_busy() {
  local lane expected_issue expected_branch expected_base expected_claim expected_checkpoint
  local repo slot issue branch base claim head current_branch branch_head
  lane=$1
  expected_issue=$2
  expected_branch=$3
  expected_base=$4
  expected_claim=$5
  expected_checkpoint=$6
  lifecycle_proven_issue=
  lifecycle_proven_branch=
  lifecycle_proven_base=
  lifecycle_proven_claim=
  lifecycle_proven_checkpoint=
  lifecycle_proven_clean=
  lifecycle_proven_state=
  repo=$(lifecycle_repo "$lane") || return 1
  [ ! -e "$(gd "$repo")/nuinui-implementation-lock" ] || return 1
  [ -z "$(rds "$repo")" ] || return 1
  slot=$(lifecycle_slot_state "$repo")
  [ -f "$slot" ] || return 1
  set -- $(nuinui_ownership_parse_slot "$slot") || return 1
  [ "$#" = 4 ] || return 1
  issue=$1; branch=$2; base=$3; claim=$4
  [ "$issue" = "$expected_issue" ] && [ "$branch" = "$expected_branch" ] &&
    [ "$base" = "$expected_base" ] || return 1
  [ -z "$expected_claim" ] || [ "$claim" = "$expected_claim" ] || return 1
  [ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] || return 1
  current_branch=$(bn "$repo")
  [ "$current_branch" = "$branch" ] || return 1
  head=$(hh "$repo" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$head" || return 1
  [ -z "$expected_checkpoint" ] || [ "$head" = "$expected_checkpoint" ] || return 1
  branch_head=$(git -C "$repo" rev-parse "refs/heads/$branch^{commit}" 2>/dev/null) || return 1
  [ "$branch_head" = "$head" ] && an "$repo" "$base" "$head" || return 1
  nuinui_ownership_valid_claim "$claim" || return 1
  lifecycle_proven_issue=$issue
  lifecycle_proven_branch=$branch
  lifecycle_proven_base=$base
  lifecycle_proven_claim=$claim
  lifecycle_proven_checkpoint=$head
  lifecycle_proven_clean=yes
  lifecycle_proven_state=BUSY
}

lifecycle_prove_busy_retry() {
  local attempt
  for attempt in 1 2 3; do lifecycle_prove_busy "$@" && return 0; done
  return 1
}

lifecycle_prove_begin_duplicate() {
  local lane issue branch base peer expected_peer
  lane=$1; issue=$2; branch=$3; base=$4; peer=$5; expected_peer=$6
  lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' "$base" || return 1
  lifecycle_preflight || return 1
  lifecycle_expect_lane "$lane" "$issue" || return 1
  lifecycle_expect_lane "$peer" "$expected_peer" || return 1
  lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' "$base"
}

lifecycle_prove_idle() {
  local lane repo head origin branch clean
  lane=$1
  lifecycle_idle_branch=
  lifecycle_idle_head=
  lifecycle_idle_origin=
  lifecycle_idle_clean=
  repo=$(lifecycle_repo "$lane") || return 1
  [ ! -e "$(sp "$repo")" ] && [ ! -e "$(kp "$repo")" ] || return 1
  [ -z "$(rds "$repo")" ] || return 1
  fp "$repo" || return 1
  head=$(hh "$repo" 2>/dev/null) || return 1
  origin=$(om "$repo" 2>/dev/null) || return 1
  branch=$(bn "$repo")
  clean=$(git -C "$repo" status --porcelain 2>/dev/null)
  [ -z "$clean" ] && nuinui_ownership_valid_sha "$head" &&
    nuinui_ownership_valid_sha "$origin" || return 1
  id "$lane" "$repo" "$origin" || return 1
  lifecycle_idle_branch=${branch:-DETACHED}
  lifecycle_idle_head=$head
  lifecycle_idle_origin=$origin
  lifecycle_idle_clean=yes
}

lifecycle_prove_idle_retry() {
  local attempt
  for attempt in 1 2 3; do lifecycle_prove_idle "$@" && return 0; done
  return 1
}

lifecycle_emit_busy_envelope() {
  printf '%s\nlane=%s\nissue=%s\nbranch=%s\nbase=%s\ncheckpoint=%s\nclaim=%s\nclean=%s\nstate=%s\n' \
    "$1" "$2" "$lifecycle_proven_issue" "$lifecycle_proven_branch" \
    "$lifecycle_proven_base" "$lifecycle_proven_checkpoint" \
    "$lifecycle_proven_claim" "$lifecycle_proven_clean" "$lifecycle_proven_state"
}

lifecycle_begin() {
  local lane issue base branch expected_peer peer peer_issue
  lane=$1; issue=$2; base=$3; branch=$4; expected_peer=$5
  lifecycle_begin_lane=$lane
  lifecycle_begin_issue=$issue
  lifecycle_begin_base=$base
  lifecycle_begin_branch=$branch
  lifecycle_begin_expected_peer=$expected_peer
  lifecycle_begin_peer=
  lifecycle_begin_claim=
  lifecycle_begin_checkpoint=
  lifecycle_begin_peer_state=
  lifecycle_begin_peer_issue=
  lifecycle_begin_start_output=
  lifecycle_begin_post_output=
  lifecycle_begin_post_rc=0
  peer=$(lifecycle_peer_lane "$lane") || {
    echo 'ERROR: lane must be an implementation lane'
    return 2
  }
  lifecycle_begin_peer=$peer
  nuinui_ownership_valid_issue "$issue" || {
    echo 'ERROR: Work-ID is invalid'
    return 2
  }
  nuinui_ownership_valid_sha "$base" || {
    echo 'ERROR: expected base must be a full 40-character commit SHA'
    return 2
  }
  lifecycle_valid_peer "$expected_peer" || {
    echo 'ERROR: expected peer must be FREE or a valid Work-ID'
    return 2
  }
  lifecycle_preflight || {
    printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT"
    echo 'BLOCKED: begin fixed-lane preflight failed'
    return 1
  }
  if ! lifecycle_expect_lane "$lane" FREE; then
    if [ "$(lifecycle_lane_state "$lane")" = BUSY ] &&
      lifecycle_prove_begin_duplicate "$lane" "$issue" "$branch" "$base" "$peer" "$expected_peer"; then
      lifecycle_begin_peer_state=$(lifecycle_lane_state "$peer")
      lifecycle_begin_peer_issue=$(lifecycle_lane_issue "$peer")
      lifecycle_emit_busy_envelope 'IMPLEMENTATION ALREADY STARTED' "$lane"
      printf 'peer_lane=%s\npeer_state=%s\n' "$peer" "$lifecycle_begin_peer_state"
      peer_issue=$lifecycle_begin_peer_issue; [ -n "$peer_issue" ] || peer_issue=-
      printf 'peer_issue=%s\nmutation=no-op\npreflight=PASS\n' "$peer_issue"
      return 0
    fi
    lifecycle_blocked_occupancy 'target lane is not FREE' "$lane" FREE "$peer" \
      "$(lifecycle_lane_state "$lane")" "$(lifecycle_lane_issue "$lane")"
    return 1
  fi
  lifecycle_expect_lane "$peer" "$expected_peer" || {
    lifecycle_blocked_occupancy 'peer occupancy does not match caller expectation' \
      "$lane" "$expected_peer" "$peer" "$(lifecycle_lane_state "$peer")" \
      "$(lifecycle_lane_issue "$peer")"
    return 1
  }
  lifecycle_preflight || {
    printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT"
    echo 'BLOCKED: begin pre-mutation revalidation failed'
    return 1
  }
  lifecycle_expect_lane "$lane" FREE || {
    lifecycle_blocked_occupancy 'target changed before mutation' "$lane" FREE "$peer" \
      "$(lifecycle_lane_state "$lane")" "$(lifecycle_lane_issue "$lane")"
    return 1
  }
  lifecycle_expect_lane "$peer" "$expected_peer" || {
    lifecycle_blocked_occupancy 'peer changed before mutation' "$lane" "$expected_peer" \
      "$peer" "$(lifecycle_lane_state "$peer")" "$(lifecycle_lane_issue "$peer")"
    return 1
  }
  lifecycle_begin_start_output=$(st "$lane" "$issue" "$base" "$branch" 2>&1)
  lifecycle_begin_start_rc=$?
  fixed_2plus1_profile_after_begin_start "$lane" "$peer" || true
  lifecycle_preflight
  lifecycle_begin_post_rc=$?
  lifecycle_begin_post_output=$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT
  if lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' ''; then
    lifecycle_begin_claim=$lifecycle_proven_claim
    lifecycle_begin_checkpoint=$lifecycle_proven_checkpoint
    if [ "$lifecycle_begin_post_rc" = 0 ]; then
      lifecycle_begin_peer_state=$(lifecycle_lane_state "$peer")
      lifecycle_begin_peer_issue=$(lifecycle_lane_issue "$peer")
      if lifecycle_expect_lane "$peer" "$expected_peer"; then
        lifecycle_emit_busy_envelope 'IMPLEMENTATION STARTED' "$lane"
        printf 'peer_lane=%s\npeer_state=%s\n' "$peer" "$lifecycle_begin_peer_state"
        peer_issue=$lifecycle_begin_peer_issue; [ -n "$peer_issue" ] || peer_issue=-
        printf 'peer_issue=%s\npreflight=PASS\n' "$peer_issue"
        return 0
      fi
    fi
    lifecycle_emit_busy_envelope 'IMPLEMENTATION STARTED' "$lane"
    printf 'mutation_state=COMPLETED\n'
    if [ -n "$lifecycle_begin_post_output" ]; then
      printf 'audit_evidence:\n%s\n' "$lifecycle_begin_post_output"
    else
      printf 'audit_evidence=unavailable\n'
    fi
    return 0
  fi
  printf 'BLOCKED: begin start mutation completion could not be proven\nmutation_state=UNKNOWN\n'
  printf 'lane=%s\nissue=%s\nbranch=%s\nbase=%s\n' "$lane" "$issue" "$branch" "$base"
  [ -z "$lifecycle_begin_start_output" ] || printf 'mutation_output:\n%s\n' "$lifecycle_begin_start_output"
  [ -z "$lifecycle_begin_post_output" ] || printf 'audit_evidence:\n%s\n' "$lifecycle_begin_post_output"
  return 1
}

lifecycle_start_command() {
  local lane issue base branch peer
  lane=$1; issue=$2; base=$3; branch=$4
  lifecycle_preflight || {
    printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT"
    echo 'BLOCKED: start fixed-lane preflight failed'
    return 1
  }
  lifecycle_expect_lane "$lane" FREE || {
    printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT"
    echo 'BLOCKED: start target lane is not FREE'
    return 1
  }
  lifecycle_start_output=
  lifecycle_start_rc=0
  lifecycle_start_output=$(st "$lane" "$issue" "$base" "$branch" 2>&1) || lifecycle_start_rc=$?
  lifecycle_preflight
  lifecycle_start_post_rc=$?
  lifecycle_start_post_output=$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT
  if lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' ''; then
    peer=$(lifecycle_peer_lane "$lane")
    lifecycle_emit_busy_envelope 'IMPLEMENTATION STARTED' "$lane"
    printf 'peer_lane=%s\npeer_state=%s\n' "$peer" "$(lifecycle_lane_state "$peer")"
    lifecycle_start_peer_issue=$(lifecycle_lane_issue "$peer")
    [ -n "$lifecycle_start_peer_issue" ] || lifecycle_start_peer_issue=-
    printf 'peer_issue=%s\n' "$lifecycle_start_peer_issue"
    if [ "$lifecycle_start_post_rc" = 0 ]; then
      printf 'preflight=PASS\n'
    else
      printf 'mutation_state=COMPLETED\n'
      [ -z "$lifecycle_start_post_output" ] || printf 'audit_evidence:\n%s\n' "$lifecycle_start_post_output"
    fi
    return 0
  fi
  printf 'BLOCKED: start mutation completion could not be proven\nlane=%s\nissue=%s\nbase=%s\nbranch=%s\n' \
    "$lane" "$issue" "$base" "$branch"
  [ -z "$lifecycle_start_output" ] || printf 'mutation_output:\n%s\n' "$lifecycle_start_output"
  [ -z "$lifecycle_start_post_output" ] || printf 'audit_evidence:\n%s\n' "$lifecycle_start_post_output"
  return 1
}

lifecycle_resume_command() {
  local lane issue base checkpoint branch claim
  lane=$1; issue=$2; base=$3; checkpoint=$4; branch=$5; claim=$6
  lifecycle_resume_output=
  lifecycle_resume_rc=0
  lifecycle_resume_output=$(rs "$lane" "$issue" "$base" "$checkpoint" "$branch" "$claim" 2>&1) ||
    lifecycle_resume_rc=$?
  if lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" "$claim" "$checkpoint"; then
    lifecycle_emit_busy_envelope 'IMPLEMENTATION RESUMED' "$lane"
    return 0
  fi
  printf 'BLOCKED: resume mutation completion could not be proven\n'
  printf 'lane=%s\nissue=%s\nbase=%s\ncheckpoint=%s\nbranch=%s\nclaim=%s\n' \
    "$lane" "$issue" "$base" "$checkpoint" "$branch" "$claim"
  [ -z "$lifecycle_resume_output" ] || printf 'mutation_output:\n%s\n' "$lifecycle_resume_output"
  return 1
}
