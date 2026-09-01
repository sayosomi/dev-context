# Release-specific façade for the fixed 2+1 implementation lifecycle.

lifecycle_release_prove_drift_checkout() {
  local mode current_branch current_head branch_head authoritative_main authoritative_main2
  local target_head target_head2 remote_state remote_state2 initial_branch initial_head
  mode=$1
  current_branch=$(bn "$lifecycle_release_repo")
  current_head=$lifecycle_release_head
  initial_branch=$current_branch
  initial_head=$current_head
  [ -z "$(git -C "$lifecycle_release_repo" status --porcelain 2>/dev/null)" ] || return 1
  nuinui_ownership_valid_sha "$current_head" || return 1
  case "$mode" in
    named)
      [ -n "$current_branch" ] && [ "$current_branch" != "$lifecycle_release_topic" ] || return 1
      [ "$current_head" = "$lifecycle_release_saved_checkpoint" ] || return 1
      branch_head=$(git -C "$lifecycle_release_repo" rev-parse "refs/heads/$current_branch^{commit}" 2>/dev/null || true)
      [ "$branch_head" = "$current_head" ] || return 1
      ;;
    rename)
      [ -n "$current_branch" ] &&
        [ "$current_branch" != "$(fixed_2plus1_profile_default_branch)" ] &&
        [ "$current_branch" != "$lifecycle_release_topic" ] || return 1
      [ "$current_head" = "$lifecycle_release_saved_checkpoint" ] || return 1
      branch_head=$(git -C "$lifecycle_release_repo" rev-parse "refs/heads/$current_branch^{commit}" 2>/dev/null || true)
      [ "$branch_head" = "$current_head" ] || return 1
      ;;
    canonical) id "$lifecycle_release_lane" "$lifecycle_release_repo" "$current_head" || return 1 ;;
    *) return 1 ;;
  esac
  [ "$lifecycle_release_base" = "$current_head" ] ||
    an "$lifecycle_release_repo" "$lifecycle_release_base" "$current_head" || return 1
  fp "$lifecycle_release_repo" || return 1
  authoritative_main=$(om "$lifecycle_release_repo") || return 1
  nuinui_ownership_valid_sha "$authoritative_main" || return 1
  an "$lifecycle_release_repo" "$current_head" "$authoritative_main" || return 1
  an "$lifecycle_release_repo" "$lifecycle_release_saved_checkpoint" "$authoritative_main" || return 1
  target_head=$(git -C "$lifecycle_release_repo" rev-parse --verify --quiet \
    "refs/heads/$lifecycle_release_topic^{commit}" 2>/dev/null || true)
  if [ "$lifecycle_release_topic_ref_missing" = yes ]; then
    [ -z "$target_head" ] || return 1
  else
    [ "$target_head" = "$lifecycle_release_saved_checkpoint" ] || return 1
  fi
  [ -z "$(bo "$lifecycle_release_repo" "$lifecycle_release_topic")" ] || return 1
  remote_state=$(rt "$lifecycle_release_repo" "$lifecycle_release_topic" \
    "$lifecycle_release_saved_checkpoint") || return 1
  fp "$lifecycle_release_repo" || return 1
  authoritative_main2=$(om "$lifecycle_release_repo") || return 1
  [ "$authoritative_main2" = "$authoritative_main" ] || return 1
  remote_state2=$(rt "$lifecycle_release_repo" "$lifecycle_release_topic" \
    "$lifecycle_release_saved_checkpoint") || return 1
  [ "$remote_state2" = "$remote_state" ] || return 1
  current_branch=$(bn "$lifecycle_release_repo")
  current_head=$(hh "$lifecycle_release_repo" 2>/dev/null || true)
  [ "$current_branch" = "$initial_branch" ] && [ "$current_head" = "$initial_head" ] || return 1
  [ -z "$(git -C "$lifecycle_release_repo" status --porcelain 2>/dev/null)" ] || return 1
  nuinui_ownership_valid_sha "$current_head" || return 1
  an "$lifecycle_release_repo" "$current_head" "$authoritative_main2" || return 1
  an "$lifecycle_release_repo" "$lifecycle_release_saved_checkpoint" "$authoritative_main2" || return 1
  case "$mode" in
    named|rename)
      [ "$current_head" = "$lifecycle_release_saved_checkpoint" ] || return 1
      branch_head=$(git -C "$lifecycle_release_repo" rev-parse "refs/heads/$current_branch^{commit}" 2>/dev/null || true)
      [ "$branch_head" = "$current_head" ] || return 1
      ;;
    canonical) id "$lifecycle_release_lane" "$lifecycle_release_repo" "$current_head" || return 1 ;;
  esac
  target_head2=$(git -C "$lifecycle_release_repo" rev-parse --verify --quiet \
    "refs/heads/$lifecycle_release_topic^{commit}" 2>/dev/null || true)
  if [ "$lifecycle_release_topic_ref_missing" = yes ]; then
    [ -z "$target_head2" ] || return 1
  else
    [ "$target_head2" = "$lifecycle_release_saved_checkpoint" ] || return 1
  fi
  [ -z "$(bo "$lifecycle_release_repo" "$lifecycle_release_topic")" ]
}

lifecycle_release_emit_branch_mismatch() {
  printf 'BLOCKED: release claimed branch mismatch\nlane=%s\nissue=%s\nclaimed_branch=%s\nactual_branch=%s\nhead=%s\n' \
    "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" \
    "${lifecycle_release_actual_branch:-DETACHED}" "$lifecycle_release_head"
  printf 'checkpoint=%s\nclaim=%s\nreason=%s\n' \
    "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim" "$lifecycle_release_branch_reason"
}

lifecycle_release_discover_tombstones() {
  local discovered
  lifecycle_release_tombstones=
  lifecycle_release_tombstone_discovery_ok=
  [ -n "$lifecycle_release_git_dir" ] || return 1
  discovered=$(find "$lifecycle_release_git_dir" -maxdepth 1 -type d \
    -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null) || return 1
  [ -z "$discovered" ] || lifecycle_release_tombstones=$(printf '%s\n' "$discovered" | LC_ALL=C sort)
  lifecycle_release_tombstone_discovery_ok=yes
}

lifecycle_release_prove_duplicate() {
  local receipt receipt_lane receipt_issue receipt_branch receipt_base receipt_checkpoint receipt_claim
  local current_head authoritative_main
  lifecycle_release_duplicate_proven=
  il "$lifecycle_release_lane" || return 1
  nuinui_ownership_valid_sha "$lifecycle_release_saved_checkpoint" || return 1
  nuinui_ownership_valid_claim "$lifecycle_release_claim" || return 1
  [ -n "$lifecycle_release_git_dir" ] && [ ! -e "$lifecycle_release_slot_dir" ] &&
    [ ! -e "$lifecycle_release_lock_dir" ] || return 1
  [ "$lifecycle_release_tombstone_discovery_ok" = yes ] &&
    [ -z "$lifecycle_release_tombstones" ] || return 1
  nuinui_ownership_validate_initialization "$(ip "$lifecycle_release_repo")" || return 1
  receipt=$(rr "$lifecycle_release_repo") || return 1
  [ -f "$receipt" ] || return 1
  set -- $(nuinui_ownership_parse_release_receipt "$receipt") || return 1
  [ "$#" = 6 ] || return 1
  receipt_lane=$1; receipt_issue=$2; receipt_branch=$3; receipt_base=$4
  receipt_checkpoint=$5; receipt_claim=$6
  [ "$receipt_lane" = "$lifecycle_release_lane" ] &&
    [ "$receipt_checkpoint" = "$lifecycle_release_saved_checkpoint" ] &&
    [ "$receipt_claim" = "$lifecycle_release_claim" ] || return 1
  an "$lifecycle_release_repo" "$receipt_base" "$receipt_checkpoint" || return 1
  cn "$lifecycle_release_repo" || return 1
  current_head=$(hh "$lifecycle_release_repo" 2>/dev/null) || return 1
  id "$lifecycle_release_lane" "$lifecycle_release_repo" "$current_head" || return 1
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
  local lane_a lane_b default_branch
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
  lifecycle_release_tombstone_discovery_ok=
  if [ -n "$lifecycle_release_git_dir" ]; then
    lifecycle_release_discover_tombstones || {
      echo 'BLOCKED: release-pending state discovery failed'
      printf 'lane=%s\ncheckpoint=%s\nclaim=%s\n' "$lifecycle_release_lane" \
        "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
      return 1
    }
  fi
  if [ -n "$lifecycle_release_tombstones" ]; then
    echo 'BLOCKED: mutation lock/state conflict'
    printf 'lane=%s\nissue=-\ncheckpoint=%s\nclaim=%s\nreleasing_state=%s\n' \
      "$lifecycle_release_lane" "$lifecycle_release_saved_checkpoint" \
      "$lifecycle_release_claim" "$lifecycle_release_tombstones"
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
    lifecycle_release_prove_duplicate; then return 0; fi
  if [ -z "$lifecycle_release_git_dir" ] || [ ! -d "$lifecycle_release_slot_dir" ] ||
    [ ! -f "$lifecycle_release_slot_dir/state" ]; then
    echo 'BLOCKED: invalid/missing active slot'
    printf 'lane=%s\ncheckpoint=%s\nclaim=%s\n' "$lifecycle_release_lane" \
      "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
    return 1
  fi
  nuinui_ownership_parse_slot "$lifecycle_release_slot_dir/state" >/dev/null || {
    echo 'BLOCKED: malformed durable ownership state'
    printf 'lane=%s\nslot=%s\n' "$lifecycle_release_lane" "$lifecycle_release_slot_dir/state"
    return 1
  }
  lifecycle_release_issue=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" issue 2>/dev/null || true)
  lifecycle_release_topic=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" branch 2>/dev/null || true)
  lifecycle_release_base=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" base 2>/dev/null || true)
  lifecycle_release_durable_claim=$(nuinui_ownership_field "$lifecycle_release_slot_dir/state" claim 2>/dev/null || true)
  nuinui_ownership_valid_sha "$lifecycle_release_saved_checkpoint" || {
    echo 'BLOCKED: checkpoint mismatch'
    printf 'expected=-\nactual=%s\nlane=%s\nclaim=%s\n' "$lifecycle_release_saved_checkpoint" \
      "$lifecycle_release_lane" "$lifecycle_release_claim"
    return 1
  }
  nuinui_ownership_valid_claim "$lifecycle_release_claim" &&
    [ "$lifecycle_release_durable_claim" = "$lifecycle_release_claim" ] || {
    echo 'BLOCKED: claim mismatch'
    printf 'expected=%s\nactual=%s\nlane=%s\nissue=%s\nbranch=%s\nbase=%s\n' \
      "$lifecycle_release_durable_claim" "$lifecycle_release_claim" "$lifecycle_release_lane" \
      "$lifecycle_release_issue" "$lifecycle_release_topic" "$lifecycle_release_base"
    return 1
  }
  lifecycle_release_topic_ref_missing=no
  lifecycle_release_topic_checkpoint=$(git -C "$lifecycle_release_repo" rev-parse --verify --quiet \
    "refs/heads/$lifecycle_release_topic^{commit}" 2>/dev/null || true)
  if [ -z "$lifecycle_release_topic_checkpoint" ]; then
    lifecycle_release_topic_ref_missing=yes
  elif ! nuinui_ownership_valid_sha "$lifecycle_release_topic_checkpoint" ||
    [ "$lifecycle_release_topic_checkpoint" != "$lifecycle_release_saved_checkpoint" ]; then
    echo 'BLOCKED: checkpoint mismatch'
    printf 'expected=%s\nactual=%s\nlane=%s\nissue=%s\nbranch=%s\nclaim=%s\n' \
      "$lifecycle_release_topic_checkpoint" "$lifecycle_release_saved_checkpoint" \
      "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" "$lifecycle_release_claim"
    return 1
  fi
  lifecycle_release_head=$(git -C "$lifecycle_release_repo" rev-parse HEAD 2>/dev/null || true)
  lifecycle_release_actual_branch=$(bn "$lifecycle_release_repo")
  [ -n "$lifecycle_release_actual_branch" ] || lifecycle_release_actual_branch=DETACHED
  lifecycle_release_branch_reason=
  lane_a=$(fixed_2plus1_profile_implementation_lane_a_name) || return 1
  lane_b=$(fixed_2plus1_profile_implementation_lane_b_name) || return 1
  default_branch=$(fixed_2plus1_profile_default_branch) || return 1
  if [ "$lifecycle_release_topic_ref_missing" = yes ]; then
    if [ -n "$(bo "$lifecycle_release_repo" "$lifecycle_release_topic")" ]; then
      lifecycle_release_branch_reason=claimed-branch-checked-out-elsewhere
    else
      lifecycle_release_branch_reason=missing-claimed-local-ref
      if [ "$lifecycle_release_actual_branch" != DETACHED ] &&
        lifecycle_release_prove_drift_checkout rename; then return 0; fi
    fi
    lifecycle_release_emit_branch_mismatch
    return 1
  fi
  if [ "$lifecycle_release_actual_branch" = "$lifecycle_release_topic" ]; then
    if [ -n "$(bo "$lifecycle_release_repo" "$lifecycle_release_topic")" ]; then
      lifecycle_release_branch_reason=claimed-branch-checked-out-elsewhere
      lifecycle_release_emit_branch_mismatch
      return 1
    fi
  else
    if [ -n "$(bo "$lifecycle_release_repo" "$lifecycle_release_topic")" ]; then
      lifecycle_release_branch_reason=claimed-branch-checked-out-elsewhere
      lifecycle_release_emit_branch_mismatch
      return 1
    fi
    if { [ "$lifecycle_release_lane" = "$lane_a" ] &&
      [ "$lifecycle_release_actual_branch" = "$default_branch" ]; } ||
      { [ "$lifecycle_release_lane" = "$lane_b" ] &&
        [ "$lifecycle_release_actual_branch" = DETACHED ]; }; then
      lifecycle_release_prove_drift_checkout canonical || {
        lifecycle_release_branch_reason=checkout-branch-drift
        lifecycle_release_emit_branch_mismatch
        return 1
      }
    else
      lifecycle_release_prove_drift_checkout named || {
        lifecycle_release_branch_reason=checkout-branch-drift
        lifecycle_release_emit_branch_mismatch
        return 1
      }
    fi
  fi
  if [ -n "$(git -C "$lifecycle_release_repo" status --porcelain 2>/dev/null)" ]; then
    echo 'BLOCKED: mutation lock/state conflict'
    printf 'lane=%s\nissue=%s\nbranch=%s\ncheckpoint=%s\nclaim=%s\nclean=no\n' \
      "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_topic" \
      "$lifecycle_release_saved_checkpoint" "$lifecycle_release_claim"
    return 1
  fi
}

lifecycle_emit_release_duplicate_envelope() {
  printf 'IMPLEMENTATION ALREADY RELEASED\nlane=%s\nissue=%s\nbase=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\norigin_main=%s\nclean=yes\nmutation=no-op\nstate=FREE\n' \
    "$lifecycle_release_lane" "$lifecycle_release_duplicate_issue" \
    "$lifecycle_release_duplicate_base" "$lifecycle_release_saved_checkpoint" \
    "$lifecycle_release_claim" "$lifecycle_release_duplicate_branch" \
    "$lifecycle_release_duplicate_origin_main"
}

lifecycle_emit_release_envelope() {
  printf 'IMPLEMENTATION RELEASED\nlane=%s\nissue=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\nidle_branch=%s\nidle_head=%s\norigin_main=%s\nclean=%s\nstate=FREE\n' \
    "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_saved_checkpoint" \
    "$lifecycle_release_claim" "$lifecycle_release_topic" "$lifecycle_idle_branch" \
    "$lifecycle_idle_head" "$lifecycle_idle_origin" "$lifecycle_idle_clean"
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
    echo 'ERROR: lane must be an implementation lane'
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
  printf 'BLOCKED: release mutation completion could not be proven\nlane=%s\nissue=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\n' \
    "$lifecycle_release_lane" "$lifecycle_release_issue" "$lifecycle_release_saved_checkpoint" \
    "$lifecycle_release_claim" "$lifecycle_release_topic"
  [ -z "$lifecycle_release_output" ] || printf 'mutation_output:\n%s\n' "$lifecycle_release_output"
  printf 'state=BLOCKED\n'
  return 1
}
