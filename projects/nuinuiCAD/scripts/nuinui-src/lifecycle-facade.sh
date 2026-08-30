# Lifecycle façade. Public lifecycle commands call the canonical low-level
# state and mutation owners assembled earlier in this standalone artifact.
#
# This module intentionally has no process-reset or runtime source delegation.
# Every command initializes scratch state before using it and reconciles
# mutation results from fresh durable state before exposing a terminal outcome.

lifecycle_repo() {
  lr "$1"
}

lifecycle_peer_lane() {
  case "$1" in
    main) printf '%s\n' sub ;;
    sub) printf '%s\n' main ;;
    *) return 2 ;;
  esac
}

lifecycle_git_dir() {
  gd "$1"
}

lifecycle_slot_state() {
  printf '%s/state\n' "$(sp "$1")"
}

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
    FREE)
      [ "$actual_state" = FREE ] && [ -z "$actual_issue" ]
      ;;
    SAY-*)
      [ "$actual_state" = BUSY ] && [ "$actual_issue" = "$expected_occupancy" ]
      ;;
    *) return 2 ;;
  esac
}

lifecycle_blocked_occupancy() {
  local peer_state peer_issue
  peer_state=$5
  peer_issue=$6
  [ -n "$peer_state" ] || peer_state=-
  [ -n "$peer_issue" ] || peer_issue=-
  printf '%s\n' "$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT"
  printf 'BLOCKED: begin %s\n' "$1"
  printf 'lane=%s\n' "$2"
  printf 'expected_peer=%s\n' "$3"
  printf 'peer_lane=%s\n' "$4"
  printf 'peer_state=%s\n' "$peer_state"
  printf 'peer_issue=%s\n' "$peer_issue"
}

lifecycle_prove_busy() {
  local lane expected_issue expected_branch expected_base expected_claim expected_checkpoint
  local repo git_dir slot issue branch base claim head current_branch branch_head
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
  git_dir=$(lifecycle_git_dir "$repo") || return 1
  [ ! -e "$git_dir/nuinui-implementation-lock" ] || return 1
  [ -z "$(rds "$repo")" ] || return 1
  slot=$(lifecycle_slot_state "$repo") || return 1
  [ -f "$slot" ] || return 1
  set -- $(nuinui_ownership_parse_slot "$slot") || return 1
  [ "$#" = 4 ] || return 1
  issue=$1
  branch=$2
  base=$3
  claim=$4
  [ "$issue" = "$expected_issue" ] || return 1
  [ "$branch" = "$expected_branch" ] || return 1
  [ "$base" = "$expected_base" ] || return 1
  if [ -n "$expected_claim" ] && [ "$claim" != "$expected_claim" ]; then
    return 1
  fi
  [ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] || return 1
  current_branch=$(bn "$repo")
  [ "$current_branch" = "$branch" ] || return 1
  head=$(hh "$repo" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$head" || return 1
  if [ -n "$expected_checkpoint" ] && [ "$head" != "$expected_checkpoint" ]; then
    return 1
  fi
  branch_head=$(git -C "$repo" rev-parse "refs/heads/$branch^{commit}" 2>/dev/null) || return 1
  [ "$branch_head" = "$head" ] || return 1
  an "$repo" "$base" "$head" || return 1
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
  for attempt in 1 2 3; do
    lifecycle_prove_busy "$@" && return 0
  done
  return 1
}

lifecycle_prove_begin_duplicate() {
  local lane issue branch base peer expected_peer
  lane=$1
  issue=$2
  branch=$3
  base=$4
  peer=$5
  expected_peer=$6

  lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' "$base" || return 1
  lifecycle_preflight || return 1
  lifecycle_expect_lane "$lane" "$issue" || return 1
  lifecycle_expect_lane "$peer" "$expected_peer" || return 1
  lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' "$base"
}

lifecycle_prove_idle() {
  local lane repo git_dir head origin branch clean
  lane=$1
  lifecycle_idle_branch=
  lifecycle_idle_head=
  lifecycle_idle_origin=
  lifecycle_idle_clean=

  repo=$(lifecycle_repo "$lane") || return 1
  git_dir=$(lifecycle_git_dir "$repo") || return 1
  [ ! -e "$git_dir/nuinui-implementation-slot" ] || return 1
  [ ! -e "$git_dir/nuinui-implementation-lock" ] || return 1
  [ -z "$(rds "$repo")" ] || return 1
  fp "$repo" || return 1
  head=$(hh "$repo" 2>/dev/null) || return 1
  origin=$(om "$repo" 2>/dev/null) || return 1
  branch=$(bn "$repo")
  clean=$(git -C "$repo" status --porcelain 2>/dev/null)
  [ -z "$clean" ] || return 1
  nuinui_ownership_valid_sha "$head" || return 1
  nuinui_ownership_valid_sha "$origin" || return 1
  case "$lane" in
    main) [ "$branch" = main ] || return 1 ;;
    sub) [ -z "$branch" ] || return 1 ;;
    *) return 2 ;;
  esac
  [ "$head" = "$origin" ] || return 1

  lifecycle_idle_branch=$branch
  [ -n "$lifecycle_idle_branch" ] || lifecycle_idle_branch=DETACHED
  lifecycle_idle_head=$head
  lifecycle_idle_origin=$origin
  lifecycle_idle_clean=yes
}

lifecycle_prove_idle_retry() {
  local attempt
  for attempt in 1 2 3; do
    lifecycle_prove_idle "$@" && return 0
  done
  return 1
}

lifecycle_emit_busy_envelope() {
  printf '%s\n' "$1"
  printf 'lane=%s\n' "$2"
  printf 'issue=%s\n' "$lifecycle_proven_issue"
  printf 'branch=%s\n' "$lifecycle_proven_branch"
  printf 'base=%s\n' "$lifecycle_proven_base"
  printf 'checkpoint=%s\n' "$lifecycle_proven_checkpoint"
  printf 'claim=%s\n' "$lifecycle_proven_claim"
  printf 'clean=%s\n' "$lifecycle_proven_clean"
  printf 'state=%s\n' "$lifecycle_proven_state"
}

lifecycle_begin() {
  local lane issue base branch expected_peer peer
  lane=$1
  issue=$2
  base=$3
  branch=$4
  expected_peer=$5

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
    echo 'ERROR: lane must be main or sub'
    return 2
  }
  lifecycle_begin_peer=$peer
  nuinui_ownership_valid_issue "$issue" || {
    echo 'ERROR: Issue must look like SAY-123'
    return 2
  }
  nuinui_ownership_valid_sha "$base" || {
    echo 'ERROR: expected base must be a full 40-character commit SHA'
    return 2
  }
  lifecycle_valid_peer "$expected_peer" || {
    echo 'ERROR: expected peer must be FREE or SAY-123'
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
      printf 'peer_lane=%s\n' "$peer"
      printf 'peer_state=%s\n' "$lifecycle_begin_peer_state"
      peer_issue=$lifecycle_begin_peer_issue
      [ -n "$peer_issue" ] || peer_issue=-
      printf 'peer_issue=%s\n' "$peer_issue"
      printf 'mutation=no-op\npreflight=PASS\n'
      return 0
    fi
    lifecycle_blocked_occupancy 'target lane is not FREE' "$lane" FREE "$peer" \
      "$(lifecycle_lane_state "$lane")" "$(lifecycle_lane_issue "$lane")"
    return 1
  fi
  lifecycle_expect_lane "$peer" "$expected_peer" || {
    lifecycle_blocked_occupancy 'peer occupancy does not match caller expectation' "$lane" \
      "$expected_peer" "$peer" "$(lifecycle_lane_state "$peer")" \
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

  if [ "$(printenv NUINUI_SELFTEST 2>/dev/null || true)" = 1 ]; then
    case "$(printenv NUINUI_SELFTEST_BEGIN_AFTER_START 2>/dev/null || true)" in
      dirty-peer)
        printf '%s\n' selftest > "$(lifecycle_repo "$peer")/nuinui-selftest-peer-dirty"
        ;;
      dirty-e2e)
        printf '%s\n' selftest > "$E/nuinui-selftest-e2e-dirty"
        ;;
    esac
  fi

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
        printf 'peer_lane=%s\n' "$peer"
        printf 'peer_state=%s\n' "$lifecycle_begin_peer_state"
        peer_issue=$lifecycle_begin_peer_issue
        [ -n "$peer_issue" ] || peer_issue=-
        printf 'peer_issue=%s\n' "$peer_issue"
        printf 'preflight=PASS\n'
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

  printf 'BLOCKED: begin start mutation completion could not be proven\n'
  printf 'mutation_state=UNKNOWN\n'
  printf 'lane=%s\nissue=%s\nbranch=%s\nbase=%s\n' "$lane" "$issue" "$branch" "$base"
  if [ -n "$lifecycle_begin_start_output" ]; then
    printf 'mutation_output:\n%s\n' "$lifecycle_begin_start_output"
  fi
  if [ -n "$lifecycle_begin_post_output" ]; then
    printf 'audit_evidence:\n%s\n' "$lifecycle_begin_post_output"
  fi
  return 1
}

lifecycle_start_command() {
  local lane issue base branch peer peer_state peer_issue
  lane=$1
  issue=$2
  base=$3
  branch=$4
  NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT=
  NUINUI_LIFECYCLE_PREFLIGHT_RC=0

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
  lifecycle_start_output=$(st "$lane" "$issue" "$base" "$branch" 2>&1) ||
    lifecycle_start_rc=$?
  lifecycle_preflight
  lifecycle_start_post_rc=$?
  lifecycle_start_post_output=$NUINUI_LIFECYCLE_PREFLIGHT_OUTPUT

  if lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" '' ''; then
    lifecycle_start_peer=$(lifecycle_peer_lane "$lane")
    if [ "$lifecycle_start_post_rc" = 0 ]; then
      lifecycle_start_peer_state=$(lifecycle_lane_state "$lifecycle_start_peer")
      lifecycle_start_peer_issue=$(lifecycle_lane_issue "$lifecycle_start_peer")
      lifecycle_emit_busy_envelope 'IMPLEMENTATION STARTED' "$lane"
      printf 'peer_lane=%s\n' "$lifecycle_start_peer"
      printf 'peer_state=%s\n' "$lifecycle_start_peer_state"
      [ -n "$lifecycle_start_peer_issue" ] || lifecycle_start_peer_issue=-
      printf 'peer_issue=%s\n' "$lifecycle_start_peer_issue"
      printf 'preflight=PASS\n'
      return 0
    fi
    lifecycle_emit_busy_envelope 'IMPLEMENTATION STARTED' "$lane"
    printf 'mutation_state=COMPLETED\n'
    if [ -n "$lifecycle_start_post_output" ]; then
      printf 'audit_evidence:\n%s\n' "$lifecycle_start_post_output"
    else
      printf 'audit_evidence=unavailable\n'
    fi
    return 0
  fi

  printf 'BLOCKED: start mutation completion could not be proven\n'
  printf 'lane=%s\nissue=%s\nbase=%s\nbranch=%s\n' "$lane" "$issue" "$base" "$branch"
  if [ -n "$lifecycle_start_output" ]; then
    printf 'mutation_output:\n%s\n' "$lifecycle_start_output"
  fi
  if [ -n "$lifecycle_start_post_output" ]; then
    printf 'audit_evidence:\n%s\n' "$lifecycle_start_post_output"
  fi
  return 1
}

lifecycle_resume_command() {
  local lane issue base checkpoint branch claim
  lane=$1
  issue=$2
  base=$3
  checkpoint=$4
  branch=$5
  claim=$6

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
  if [ -n "$lifecycle_resume_output" ]; then
    printf 'mutation_output:\n%s\n' "$lifecycle_resume_output"
  fi
  return 1
}

lifecycle_release_prove_drift_checkout() {
  local current_branch current_head authoritative_main
  current_branch=$(bn "$lifecycle_release_repo")
  current_head=$lifecycle_release_head

  [ -z "$(git -C "$lifecycle_release_repo" status --porcelain 2>/dev/null)" ] || return 1
  case "$lifecycle_release_lane" in
    main) [ "$current_branch" = main ] || return 1 ;;
    sub) [ -z "$current_branch" ] || return 1 ;;
    *) return 1 ;;
  esac
  nuinui_ownership_valid_sha "$current_head" || return 1
  fp "$lifecycle_release_repo" || return 1
  authoritative_main=$(om "$lifecycle_release_repo" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$authoritative_main" || return 1
  an "$lifecycle_release_repo" "$current_head" "$authoritative_main" || return 1
  an "$lifecycle_release_repo" "$lifecycle_release_topic_checkpoint" "$authoritative_main" || return 1
}

lifecycle_release_prove_duplicate() {
  local receipt receipt_lane receipt_issue receipt_branch receipt_base receipt_checkpoint receipt_claim
  local current_branch current_head authoritative_main

  lifecycle_release_duplicate_proven=
  case "$lifecycle_release_lane" in
    main|sub) ;;
    *) return 1 ;;
  esac
  nuinui_ownership_valid_sha "$lifecycle_release_saved_checkpoint" || return 1
  nuinui_ownership_valid_claim "$lifecycle_release_claim" || return 1
  [ -n "$lifecycle_release_git_dir" ] || return 1
  [ ! -e "$lifecycle_release_slot_dir" ] || return 1
  [ ! -e "$lifecycle_release_lock_dir" ] || return 1
  [ -z "$(rds "$lifecycle_release_repo")" ] || return 1

  receipt=$(rr "$lifecycle_release_repo") || return 1
  [ -f "$receipt" ] || return 1
  set -- $(nuinui_ownership_parse_release_receipt "$receipt") || return 1
  [ "$#" = 6 ] || return 1
  receipt_lane=$1
  receipt_issue=$2
  receipt_branch=$3
  receipt_base=$4
  receipt_checkpoint=$5
  receipt_claim=$6
  [ "$receipt_lane" = "$lifecycle_release_lane" ] || return 1
  [ "$receipt_checkpoint" = "$lifecycle_release_saved_checkpoint" ] || return 1
  [ "$receipt_claim" = "$lifecycle_release_claim" ] || return 1
  an "$lifecycle_release_repo" "$receipt_base" "$receipt_checkpoint" || return 1

  [ -z "$(git -C "$lifecycle_release_repo" status --porcelain 2>/dev/null)" ] || return 1
  current_branch=$(bn "$lifecycle_release_repo")
  case "$lifecycle_release_lane" in
    main) [ "$current_branch" = main ] || return 1 ;;
    sub) [ -z "$current_branch" ] || return 1 ;;
  esac
  current_head=$(hh "$lifecycle_release_repo" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$current_head" || return 1
  authoritative_main=$(am "$lifecycle_release_repo") || return 1
  nuinui_ownership_valid_sha "$authoritative_main" || return 1
  [ "$current_head" = "$authoritative_main" ] || return 1
  an "$lifecycle_release_repo" "$receipt_checkpoint" "$authoritative_main" || return 1

  lifecycle_release_duplicate_issue=$receipt_issue
  lifecycle_release_duplicate_branch=$receipt_branch
  lifecycle_release_duplicate_base=$receipt_base
  lifecycle_release_duplicate_origin_main=$authoritative_main
  lifecycle_release_duplicate_proven=yes
}

lifecycle_release_validate() {
  lifecycle_release_git_dir=$(lifecycle_git_dir "$lifecycle_release_repo" 2>/dev/null || true)
  if [ -n "$lifecycle_release_git_dir" ]; then
    lifecycle_release_slot_dir=$lifecycle_release_git_dir/nuinui-implementation-slot
    lifecycle_release_lock_dir=$lifecycle_release_git_dir/nuinui-implementation-lock
  else
    lifecycle_release_slot_dir=
    lifecycle_release_lock_dir=
  fi
  lifecycle_release_tombstones=
  lifecycle_release_duplicate_proven=
  [ -z "$lifecycle_release_git_dir" ] || lifecycle_release_tombstones=$(find "$lifecycle_release_git_dir" -maxdepth 1 -type d -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null)

  if [ -n "$lifecycle_release_tombstones" ]; then
    echo 'BLOCKED: mutation lock/state conflict'
    printf 'lane=%s\n' "$lifecycle_release_lane"
    printf 'issue=%s\n' '-'
    printf 'checkpoint=%s\nclaim=%s\n' "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
    printf 'releasing_state=%s\n' "$lifecycle_release_tombstones"
    return 1
  fi
  if [ -e "$lifecycle_release_lock_dir" ]; then
    if [ -f "$lifecycle_release_lock_dir/state" ] &&
      nuinui_ownership_parse_lock "$lifecycle_release_lock_dir/state" >/dev/null; then
      printf 'BLOCKED: mutation lock/state conflict\nlane=%s\noperation=%s\nlock_claim=%s\n' \
        "$lifecycle_release_lane" "$(nuinui_ownership_field "$lifecycle_release_lock_dir/state" operation)" \
        "$(nuinui_ownership_field "$lifecycle_release_lock_dir/state" claim)"
    else
      echo 'BLOCKED: malformed durable ownership state'
    fi
    printf 'checkpoint=%s\nclaim=%s\n' "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
    return 1
  fi
  if [ -n "$lifecycle_release_git_dir" ] && [ ! -e "$lifecycle_release_slot_dir" ] &&
    lifecycle_release_prove_duplicate; then
    return 0
  fi
  if [ -z "$lifecycle_release_git_dir" ] ||
    [ ! -d "$lifecycle_release_slot_dir" ] ||
    [ ! -f "$lifecycle_release_slot_dir/state" ]; then
    echo 'BLOCKED: invalid/missing active slot'
    printf 'lane=%s\ncheckpoint=%s\nclaim=%s\n' \
      "$lifecycle_release_lane" "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
    return 1
  fi
  if ! nuinui_ownership_parse_slot "$lifecycle_release_slot_dir/state" >/dev/null; then
    echo 'BLOCKED: malformed durable ownership state'
    printf 'lane=%s\nslot=%s\n' "$lifecycle_release_lane" "$lifecycle_release_slot_dir/state"
    return 1
  fi

  lifecycle_release_issue=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" issue 2>/dev/null || true)
  lifecycle_release_topic=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" branch 2>/dev/null || true)
  lifecycle_release_base=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" base 2>/dev/null || true)
  lifecycle_release_durable_claim=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" claim 2>/dev/null || true)
  if ! nuinui_ownership_valid_sha "$lifecycle_release_saved_checkpoint"; then
    echo 'BLOCKED: checkpoint mismatch'
    printf 'expected=%s\nactual=%s\n' '-' "$lifecycle_release_saved_checkpoint"
    printf 'lane=%s\nclaim=%s\n' "$lifecycle_release_lane" "$lifecycle_release_claim"
    return 1
  fi
  if ! nuinui_ownership_valid_claim "$lifecycle_release_claim"; then
    echo 'BLOCKED: claim mismatch'
    printf 'expected=%s\nactual=%s\n' "$lifecycle_release_durable_claim" "$lifecycle_release_claim"
    printf 'lane=%s\nissue=%s\nbranch=%s\n' "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic"
    return 1
  fi
  if [ "$lifecycle_release_durable_claim" != "$lifecycle_release_claim" ]; then
    echo 'BLOCKED: claim mismatch'
    printf 'expected=%s\nactual=%s\n' "$lifecycle_release_durable_claim" "$lifecycle_release_claim"
    printf 'lane=%s\nissue=%s\nbranch=%s\nbase=%s\n' \
      "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" "$lifecycle_release_base"
    return 1
  fi
  lifecycle_release_topic_checkpoint=$(git -C "$lifecycle_release_repo" rev-parse \
    "refs/heads/$lifecycle_release_topic^{commit}" 2>/dev/null || true)
  if ! nuinui_ownership_valid_sha "$lifecycle_release_topic_checkpoint" ||
    [ "$lifecycle_release_topic_checkpoint" != "$lifecycle_release_saved_checkpoint" ]; then
    echo 'BLOCKED: checkpoint mismatch'
    printf 'expected=%s\nactual=%s\n' "$lifecycle_release_topic_checkpoint" "$lifecycle_release_saved_checkpoint"
    printf 'lane=%s\nissue=%s\nbranch=%s\nclaim=%s\n' \
      "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" "$lifecycle_release_claim"
    return 1
  fi
  lifecycle_release_head=$(git -C "$lifecycle_release_repo" rev-parse HEAD 2>/dev/null || true)
  if [ "$lifecycle_release_head" = "$lifecycle_release_topic_checkpoint" ] &&
    [ "$(bn "$lifecycle_release_repo")" = "$lifecycle_release_topic" ]; then
    if [ -n "$(bo "$lifecycle_release_repo" "$lifecycle_release_topic")" ]; then
      echo 'BLOCKED: claim-checkout-mismatch'
      printf 'lane=%s\nissue=%s\nbranch=%s\nclaim=%s\n' \
        "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" "$lifecycle_release_claim"
      return 1
    fi
  else
    if ! lifecycle_release_prove_drift_checkout; then
      echo 'BLOCKED: claim-checkout-mismatch'
      printf 'lane=%s\nissue=%s\nbranch=%s\nclaim=%s\n' \
        "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" "$lifecycle_release_claim"
      return 1
    fi
  fi
  if [ -n "$(git -C "$lifecycle_release_repo" status --porcelain 2>/dev/null)" ]; then
    echo 'BLOCKED: mutation lock/state conflict'
    printf 'lane=%s\nissue=%s\nbranch=%s\ncheckpoint=%s\nclaim=%s\nclean=no\n' \
      "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" \
      "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
    return 1
  fi
  return 0
}

lifecycle_emit_release_duplicate_envelope() {
  printf 'IMPLEMENTATION ALREADY RELEASED\n'
  printf 'lane=%s\n' "$lifecycle_release_lane"
  printf 'issue=%s\n' "$lifecycle_release_duplicate_issue"
  printf 'base=%s\n' "$lifecycle_release_duplicate_base"
  printf 'saved_checkpoint=%s\n' "$lifecycle_release_saved_checkpoint"
  printf 'released_claim=%s\n' "$lifecycle_release_claim"
  printf 'released_branch=%s\n' "$lifecycle_release_duplicate_branch"
  printf 'origin_main=%s\n' "$lifecycle_release_duplicate_origin_main"
  printf 'clean=yes\nmutation=no-op\nstate=FREE\n'
}

lifecycle_emit_release_envelope() {
  printf 'IMPLEMENTATION RELEASED\n'
  printf 'lane=%s\n' "$lifecycle_release_lane"
  printf 'issue=%s\n' "$lifecycle_release_issue"
  printf 'saved_checkpoint=%s\n' "$lifecycle_release_saved_checkpoint"
  printf 'released_claim=%s\n' "$lifecycle_release_claim"
  printf 'released_branch=%s\n' "$lifecycle_release_topic"
  printf 'idle_branch=%s\n' "$lifecycle_idle_branch"
  printf 'idle_head=%s\n' "$lifecycle_idle_head"
  printf 'origin_main=%s\n' "$lifecycle_idle_origin"
  printf 'clean=%s\n' "$lifecycle_idle_clean"
  printf 'state=FREE\n'
}

lifecycle_release_command() {
  lifecycle_release_lane=$1
  lifecycle_release_saved_checkpoint=$2
  lifecycle_release_claim=$3
  lifecycle_release_repo=
  lifecycle_release_issue=
  lifecycle_release_topic=
  lifecycle_release_base=
  lifecycle_release_durable_claim=
  lifecycle_release_output=
  lifecycle_release_rc=0

  lifecycle_release_repo=$(lifecycle_repo "$lifecycle_release_lane") || {
    echo 'ERROR: lane must be main or sub'
    return 2
  }

  lifecycle_release_validate || return $?
  if [ "$lifecycle_release_duplicate_proven" = yes ]; then
    lifecycle_emit_release_duplicate_envelope
    return 0
  fi
  lifecycle_release_output=$(rl "$lifecycle_release_lane" "$lifecycle_release_saved_checkpoint" \
    "$lifecycle_release_claim" 2>&1) || lifecycle_release_rc=$?

  if lifecycle_prove_idle_retry "$lifecycle_release_lane"; then
    lifecycle_emit_release_envelope
    return 0
  fi

  printf 'BLOCKED: release mutation completion could not be proven\n'
  printf 'lane=%s\nissue=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\n' \
    "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_saved_checkpoint" \
    "$lifecycle_release_claim" "$lifecycle_release_topic"
  if [ -n "$lifecycle_release_output" ]; then
    printf 'mutation_output:\n%s\n' "$lifecycle_release_output"
  fi
  printf 'state=BLOCKED\n'
  return 1
}
