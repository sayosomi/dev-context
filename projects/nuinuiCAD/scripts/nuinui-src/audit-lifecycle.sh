# Fixed-revision evaluator audit reservation lifecycle.
# Admission remains owned by lane-execution preflight and its implementation
# mutation lock; this source stores only the audit-specific durable identity.

nuinui_audit_blocked_before_mutation() {
  printf 'BLOCKED: %s\n' "$1"
  return 1
}

nuinui_audit_blocked_with_reservation() {
  printf 'BLOCKED: %s\n' "$1"
  printf 'mutation_state=UNKNOWN\nrecovery=preserve-audit-reservation\n'
  [ -z "${NUINUI_AUDIT_RESOLVED_ISSUE:-}" ] ||
    printf 'issue=%s\n' "$NUINUI_AUDIT_RESOLVED_ISSUE"
  [ -z "${NUINUI_AUDIT_RESOLVED_LANE:-}" ] ||
    printf 'lane=%s\n' "$NUINUI_AUDIT_RESOLVED_LANE"
  [ -z "${NUINUI_AUDIT_RESOLVED_GENERATION:-}" ] ||
    printf 'generation=%s\n' "$NUINUI_AUDIT_RESOLVED_GENERATION"
  [ -z "${nuinui_audit_reservation_file:-}" ] ||
    printf 'reservation=%s\n' "$nuinui_audit_reservation_file"
  printf 'next=keep the checkout and reservation unchanged; inspect nuinui last-result and the exact recorded state before any separately reviewed recovery\n'
  return 1
}

nuinui_audit_target() {
  nuinui_audit_target_manifest=$1
  nuinui_audit_target_lane=$2
  lane_execution__target_validate "$nuinui_audit_target_manifest" \
    "$nuinui_audit_target_lane" || return 1
  nuinui_audit_repo=$lane_execution_target_path
  nuinui_audit_git_dir=$(lane_execution__git_dir "$nuinui_audit_repo") || return 1
  nuinui_audit_checkout=$(lane_execution__canonical_path "$nuinui_audit_repo") || return 1
  nuinui_audit_repository=$lane_execution_target_repository
  nuinui_audit_default=$lane_execution_target_default
  nuinui_audit_idle=$lane_execution_target_idle
  nuinui_audit_reservation_file=$(ap "$nuinui_audit_repo")
  nuinui_audit_receipt_file=$(arp "$nuinui_audit_repo")
}

nuinui_audit_load_reservation() {
  nuinui_audit_load_file=$1
  [ -f "$nuinui_audit_load_file" ] && [ ! -L "$nuinui_audit_load_file" ] &&
    nuinui_ownership_validate_audit_reservation "$nuinui_audit_load_file" || return 1
  nuinui_audit_issue=$(nuinui_ownership_field "$nuinui_audit_load_file" issue) || return 1
  nuinui_audit_lane=$(nuinui_ownership_field "$nuinui_audit_load_file" lane) || return 1
  nuinui_audit_revision=$(nuinui_ownership_field "$nuinui_audit_load_file" revision) || return 1
  nuinui_audit_generation=$(nuinui_ownership_field "$nuinui_audit_load_file" generation) || return 1
  nuinui_audit_stored_checkout=$(nuinui_ownership_field "$nuinui_audit_load_file" checkout) || return 1
  nuinui_audit_stored_git_dir=$(nuinui_ownership_field "$nuinui_audit_load_file" git_dir) || return 1
  nuinui_audit_stored_repository=$(nuinui_ownership_field "$nuinui_audit_load_file" repository) || return 1
  nuinui_audit_stored_default=$(nuinui_ownership_field "$nuinui_audit_load_file" default_branch) || return 1
  nuinui_audit_stored_idle=$(nuinui_ownership_field "$nuinui_audit_load_file" idle_policy) || return 1
  nuinui_audit_original_branch=$(nuinui_ownership_field "$nuinui_audit_load_file" original_branch) || return 1
  nuinui_audit_pre_ff_head=$(nuinui_ownership_field "$nuinui_audit_load_file" pre_ff_head) || return 1
  nuinui_audit_post_ff_base=$(nuinui_ownership_field "$nuinui_audit_load_file" post_ff_base) || return 1
  nuinui_audit_state=$(nuinui_ownership_field "$nuinui_audit_load_file" state) || return 1
}

nuinui_audit_load_receipt() {
  nuinui_audit_receipt_load_file=$1
  [ -f "$nuinui_audit_receipt_load_file" ] && [ ! -L "$nuinui_audit_receipt_load_file" ] &&
    nuinui_ownership_validate_audit_receipt "$nuinui_audit_receipt_load_file" || return 1
  nuinui_audit_receipt_issue=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" issue) || return 1
  nuinui_audit_receipt_lane=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" lane) || return 1
  nuinui_audit_receipt_revision=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" revision) || return 1
  nuinui_audit_receipt_generation=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" generation) || return 1
  nuinui_audit_receipt_checkout=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" checkout) || return 1
  nuinui_audit_receipt_git_dir=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" git_dir) || return 1
  nuinui_audit_receipt_repository=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" repository) || return 1
  nuinui_audit_receipt_default=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" default_branch) || return 1
  nuinui_audit_receipt_idle=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" idle_policy) || return 1
  nuinui_audit_receipt_branch=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" original_branch) || return 1
  nuinui_audit_receipt_pre_ff_head=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" pre_ff_head) || return 1
  nuinui_audit_receipt_base=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" post_ff_base) || return 1
  nuinui_audit_receipt_time=$(nuinui_ownership_field "$nuinui_audit_receipt_load_file" released_at) || return 1
}

nuinui_audit_identity_matches_target() {
  [ "$nuinui_audit_lane" = "$nuinui_audit_target_lane" ] &&
    [ "$nuinui_audit_stored_checkout" = "$nuinui_audit_checkout" ] &&
    [ "$nuinui_audit_stored_git_dir" = "$nuinui_audit_git_dir" ] &&
    [ "$nuinui_audit_stored_repository" = "$nuinui_audit_repository" ] &&
    [ "$nuinui_audit_stored_default" = "$nuinui_audit_default" ] &&
    [ "$nuinui_audit_stored_idle" = "$nuinui_audit_idle" ]
}

nuinui_audit_receipt_matches_target() {
  [ "$nuinui_audit_receipt_lane" = "$nuinui_audit_target_lane" ] &&
    [ "$nuinui_audit_receipt_checkout" = "$nuinui_audit_checkout" ] &&
    [ "$nuinui_audit_receipt_git_dir" = "$nuinui_audit_git_dir" ] &&
    [ "$nuinui_audit_receipt_repository" = "$nuinui_audit_repository" ] &&
    [ "$nuinui_audit_receipt_default" = "$nuinui_audit_default" ] &&
    [ "$nuinui_audit_receipt_idle" = "$nuinui_audit_idle" ]
}

nuinui_audit_store_reservation() {
  nuinui_audit_store_state=$1
  nuinui_audit_store_content=$(printf 'version=1\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\ngit_dir=%s\nrepository=%s\ndefault_branch=%s\nidle_policy=%s\noriginal_branch=%s\npre_ff_head=%s\npost_ff_base=%s\nstate=%s\n' \
    "$nuinui_audit_requested_issue" "$nuinui_audit_target_lane" "$nuinui_audit_requested_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_checkout" "$nuinui_audit_git_dir" \
    "$nuinui_audit_repository" "$nuinui_audit_default" "$nuinui_audit_idle" \
    "$nuinui_audit_original_branch" "$nuinui_audit_pre_ff_head" \
    "$nuinui_audit_post_ff_base" "$nuinui_audit_store_state")
  lane_execution__atomic_write "$nuinui_audit_reservation_file" "$nuinui_audit_store_content"
}

nuinui_audit_reservation_fields_valid_for_request() {
  nuinui_audit_load_reservation "$nuinui_audit_reservation_file" || return 1
  nuinui_audit_identity_matches_target || return 1
  [ "$nuinui_audit_issue" = "$nuinui_audit_requested_issue" ] &&
    [ "$nuinui_audit_revision" = "$nuinui_audit_requested_revision" ]
}

nuinui_audit_branch_at_base() {
  if [ "$nuinui_audit_idle" = branch ]; then
    [ "$(git -C "$nuinui_audit_repo" rev-parse \
      "refs/heads/$nuinui_audit_default^{commit}" 2>/dev/null || true)" = \
      "$nuinui_audit_post_ff_base" ]
  else
    [ "$nuinui_audit_original_branch" = - ]
  fi
}

nuinui_audit_clean_active_checkout() {
  [ "$nuinui_audit_state" = ACTIVE ] &&
    [ "$(git -C "$nuinui_audit_repo" rev-parse --absolute-git-dir 2>/dev/null || true)" = \
      "$nuinui_audit_stored_git_dir" ] &&
    [ "$(git -C "$nuinui_audit_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" = '' ] &&
    [ "$(git -C "$nuinui_audit_repo" rev-parse HEAD 2>/dev/null || true)" = \
      "$nuinui_audit_revision" ] &&
    [ -z "$(git -C "$nuinui_audit_repo" status --porcelain 2>/dev/null)" ] &&
    nuinui_audit_branch_at_base &&
    [ ! -e "$(sp "$nuinui_audit_repo")" ] &&
    [ ! -L "$(sp "$nuinui_audit_repo")" ] &&
    [ -z "$(rds "$nuinui_audit_repo" 2>/dev/null || true)" ]
}

nuinui_audit_lane_state_line() {
  nuinui_audit_state_output=$1
  nuinui_audit_state_lane=$2
  printf '%s\n' "$nuinui_audit_state_output" | awk -v lane="$nuinui_audit_state_lane" '
    /^lane name=/ {
      current=substr($0, 11)
      sub(/ role=.*/, "", current)
      active=(current == lane)
      next
    }
    active && /^  state=/ { print; count++ }
    END { if (count != 1) exit 1 }
  '
}

nuinui_audit_read_preflight() {
  nuinui_audit_pf_manifest=$1
  nuinui_audit_pf_operation=${2-}
  nuinui_audit_pf_generation=${3-}
  nuinui_audit_preflight_output=
  nuinui_audit_preflight_rc=0
  if [ -n "$nuinui_audit_pf_operation" ]; then
    nuinui_audit_preflight_output=$(lane_execution__preflight_with_audit_lock \
      "$nuinui_audit_pf_manifest" "$nuinui_audit_pf_operation" \
      "$nuinui_audit_pf_generation" 2>&1) || nuinui_audit_preflight_rc=$?
  else
    nuinui_audit_preflight_output=$(lane_execution_implementation_preflight \
      "$nuinui_audit_pf_manifest" 2>&1) || nuinui_audit_preflight_rc=$?
  fi
}

nuinui_audit_projection_free_evidence() {
  nuinui_audit_projection_lane_line=$(nuinui_audit_lane_state_line \
    "$1" "$nuinui_audit_target_lane") || return 1
  case "$nuinui_audit_projection_lane_line" in
    '  state=FREE origin_main='*' freshness=FRESH'|'  state=FREE origin_main='*' freshness=STALE') ;;
    *) return 1 ;;
  esac
  printf '%s\n' "$nuinui_audit_projection_lane_line" | sed 's/^  state=FREE //'
}

nuinui_audit_output_has_inventory() {
  printf '%s\n' "$1" | grep -Fqx '  inventory_state=PASS'
}

nuinui_audit_initial_free_proof() {
  nuinui_audit_read_preflight "$1"
  [ "$nuinui_audit_preflight_rc" = 0 ] &&
    printf '%s\n' "$nuinui_audit_preflight_output" | grep -Fqx 'IMPLEMENTATION PREFLIGHT PASS' &&
    nuinui_audit_output_has_inventory "$nuinui_audit_preflight_output" || return 1
  nuinui_audit_projection_free_evidence "$nuinui_audit_preflight_output" >/dev/null
}

nuinui_audit_reservation_nonfree_proof() {
  nuinui_audit_read_preflight "$1"
  [ "$nuinui_audit_preflight_rc" != 0 ] &&
    nuinui_audit_output_has_inventory "$nuinui_audit_preflight_output" || return 1
  nuinui_audit_reservation_line=$(nuinui_audit_lane_state_line \
    "$nuinui_audit_preflight_output" "$nuinui_audit_target_lane") || return 1
  case "$nuinui_audit_reservation_line" in
    '  state=BLOCKED reason=audit-reservation') ;;
    *) return 1 ;;
  esac
  printf '%s\n' "$nuinui_audit_reservation_line"
}

nuinui_audit_validate_remote_revision() {
  nuinui_audit_remote_ref=$1
  nuinui_audit_live_main=$(am "$nuinui_audit_repo") || return 1
  nuinui_audit_fetched_main=$(om "$nuinui_audit_repo") || return 1
  [ "$nuinui_audit_live_main" = "$nuinui_audit_remote_ref" ] &&
    [ "$nuinui_audit_fetched_main" = "$nuinui_audit_remote_ref" ] &&
    git -C "$nuinui_audit_repo" cat-file -e \
      "$nuinui_audit_remote_ref^{commit}" >/dev/null 2>&1
}

nuinui_audit_prepare_result_identity() {
  NUINUI_AUDIT_RESOLVED_ISSUE=$nuinui_audit_requested_issue
  NUINUI_AUDIT_RESOLVED_LANE=$nuinui_audit_target_lane
  NUINUI_AUDIT_RESOLVED_GENERATION=$nuinui_audit_generation
}

nuinui_audit_begin() {
  [ "$#" = 4 ] || return 2
  nuinui_audit_manifest=$1
  nuinui_audit_requested_issue=$2
  nuinui_audit_target_lane=$3
  nuinui_audit_requested_revision=$(printf '%s' "$4" | tr 'A-F' 'a-f')
  NUINUI_AUDIT_RESOLVED_ISSUE=$nuinui_audit_requested_issue
  NUINUI_AUDIT_RESOLVED_LANE=$nuinui_audit_target_lane
  NUINUI_AUDIT_RESOLVED_GENERATION=
  lane_execution_validate_work_id "$nuinui_audit_requested_issue" || { nuinui_audit_blocked_before_mutation 'Issue must be a valid SAY identifier'; return 1; }
  nuinui_ownership_valid_sha "$nuinui_audit_requested_revision" || { nuinui_audit_blocked_before_mutation 'revision must be a full 40-character commit SHA'; return 1; }
  nuinui_audit_target "$nuinui_audit_manifest" "$nuinui_audit_target_lane" || { nuinui_audit_blocked_before_mutation 'target is not a declared implementation lane'; return 1; }

  if [ -e "$nuinui_audit_reservation_file" ] || [ -L "$nuinui_audit_reservation_file" ]; then
    nuinui_audit_reservation_fields_valid_for_request || { nuinui_audit_blocked_before_mutation 'an existing audit reservation is invalid or belongs to another Issue, lane, revision, or checkout'; return 1; }
    nuinui_audit_prepare_result_identity
    [ "$nuinui_audit_state" = ACTIVE ] && nuinui_audit_clean_active_checkout || { nuinui_audit_blocked_with_reservation 'existing reservation is not a proven active fixed-revision checkout'; return 1; }
    nuinui_audit_lock=$(kp "$nuinui_audit_repo")
    [ ! -e "$nuinui_audit_lock" ] && [ ! -L "$nuinui_audit_lock" ] || { nuinui_audit_blocked_with_reservation 'an unresolved mutation lock remains beside the active audit reservation'; return 1; }
    nuinui_audit_reservation_nonfree_proof "$nuinui_audit_manifest" >/dev/null || { nuinui_audit_blocked_with_reservation 'active audit reservation read-back did not match the canonical admission classifier'; return 1; }
    printf 'AUDIT RESERVATION READY\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npost_ff_base=%s\nbranch=DETACHED\nhead=%s\nclean=yes\nadmission=BLOCKED reason=audit-reservation\nmutation=no-op\n' \
      "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
      "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
      "$nuinui_audit_post_ff_base" "$nuinui_audit_revision"
    return 0
  fi

  nuinui_audit_lock=$(kp "$nuinui_audit_repo")
  [ ! -e "$nuinui_audit_lock" ] && [ ! -L "$nuinui_audit_lock" ] || { nuinui_audit_blocked_before_mutation 'an implementation or audit mutation lock is present'; return 1; }
  [ ! -e "$(sp "$nuinui_audit_repo")" ] && [ ! -L "$(sp "$nuinui_audit_repo")" ] || { nuinui_audit_blocked_before_mutation 'an implementation owner is present'; return 1; }
  [ -z "$(rds "$nuinui_audit_repo" 2>/dev/null || true)" ] || { nuinui_audit_blocked_before_mutation 'an implementation release is pending'; return 1; }
  if [ -e "$nuinui_audit_receipt_file" ] || [ -L "$nuinui_audit_receipt_file" ]; then
    nuinui_audit_load_receipt "$nuinui_audit_receipt_file" &&
      nuinui_audit_receipt_matches_target || { nuinui_audit_blocked_before_mutation 'an existing audit release receipt is malformed or belongs to another checkout'; return 1; }
    if [ "$nuinui_audit_receipt_issue" = "$nuinui_audit_requested_issue" ] &&
      [ "$nuinui_audit_receipt_revision" = "$nuinui_audit_requested_revision" ]; then
      NUINUI_AUDIT_RESOLVED_LANE=$nuinui_audit_target_lane
      NUINUI_AUDIT_RESOLVED_GENERATION=$nuinui_audit_receipt_generation
      nuinui_audit_receipt_expected_branch=$nuinui_audit_receipt_branch
      [ "$nuinui_audit_receipt_expected_branch" != - ] ||
        nuinui_audit_receipt_expected_branch=
      [ "$(hh "$nuinui_audit_repo" 2>/dev/null || true)" = \
        "$nuinui_audit_receipt_base" ] &&
        [ "$(bn "$nuinui_audit_repo")" = "$nuinui_audit_receipt_expected_branch" ] &&
        [ -z "$(git -C "$nuinui_audit_repo" status --porcelain 2>/dev/null)" ] &&
        lane_execution__occupancy_idle_proof "$nuinui_audit_target_lane" \
          "$nuinui_audit_repo" "$nuinui_audit_receipt_idle" \
          "$nuinui_audit_receipt_default" "$nuinui_audit_receipt_base" &&
        nuinui_audit_initial_free_proof "$nuinui_audit_manifest" || {
        nuinui_audit_blocked_before_mutation 'exact begin duplicate could not prove the recorded clean FREE release state'
        return 1
      }
      nuinui_audit_projection_line=$(nuinui_audit_projection_free_evidence \
        "$nuinui_audit_preflight_output") || {
        nuinui_audit_blocked_before_mutation 'exact begin duplicate did not read back FREE or FREE/STALE'
        return 1
      }
      printf 'AUDIT ALREADY RELEASED\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npost_ff_base=%s\n%s\nclean=yes\nmutation=no-op\n' \
        "$nuinui_audit_receipt_issue" "$nuinui_audit_receipt_lane" \
        "$nuinui_audit_receipt_revision" "$nuinui_audit_receipt_generation" \
        "$nuinui_audit_receipt_checkout" "$nuinui_audit_receipt_base" \
        "$nuinui_audit_projection_line"
      return 0
    fi
  fi

  fp "$nuinui_audit_repo" || { nuinui_audit_blocked_before_mutation 'unable to fetch authoritative remote main'; return 1; }
  nuinui_audit_validate_remote_revision "$nuinui_audit_requested_revision" || { nuinui_audit_blocked_before_mutation 'requested revision does not equal authoritative remote main'; return 1; }
  nuinui_audit_initial_free_proof "$nuinui_audit_manifest" || { nuinui_audit_blocked_before_mutation 'target lane is not truly FREE in canonical preflight'; return 1; }

  nuinui_audit_pre_ff_head=$(hh "$nuinui_audit_repo") || { nuinui_audit_blocked_before_mutation 'unable to read the idle checkout HEAD'; return 1; }
  nuinui_audit_original_branch=$(bn "$nuinui_audit_repo")
  nuinui_audit_dirty=$(git -C "$nuinui_audit_repo" status --porcelain 2>/dev/null)
  [ -z "$nuinui_audit_dirty" ] || { nuinui_audit_blocked_before_mutation 'target checkout contains tracked or untracked changes'; return 1; }
  case "$nuinui_audit_idle" in
    branch)
      [ "$nuinui_audit_original_branch" = "$nuinui_audit_default" ] || { nuinui_audit_blocked_before_mutation 'target is not in its declared idle branch form'; return 1; }
      ;;
    detached)
      [ -z "$nuinui_audit_original_branch" ] || { nuinui_audit_blocked_before_mutation 'target is not in its declared detached idle form'; return 1; }
      nuinui_audit_original_branch=-
      ;;
  esac
  git -C "$nuinui_audit_repo" merge-base --is-ancestor \
    "$nuinui_audit_pre_ff_head" "$nuinui_audit_requested_revision" 2>/dev/null || { nuinui_audit_blocked_before_mutation 'idle checkout is not an ancestor of the exact audit revision'; return 1; }
  nuinui_audit_post_ff_base=$nuinui_audit_requested_revision
  nuinui_audit_generation=$(lane_execution__claim) || { nuinui_audit_blocked_before_mutation 'unable to allocate audit generation identity'; return 1; }
  nuinui_ownership_valid_claim "$nuinui_audit_generation" || { nuinui_audit_blocked_before_mutation 'allocated audit generation identity is invalid'; return 1; }
  nuinui_audit_prepare_result_identity

  lane_execution__lock "$nuinui_audit_repo" "$nuinui_audit_generation" \
    - - "$nuinui_audit_requested_revision" audit-begin || { nuinui_audit_blocked_before_mutation 'could not acquire the existing per-lane atomic mutation lock'; return 1; }
  nuinui_audit_lock_held=1
  nuinui_audit_read_preflight "$nuinui_audit_manifest" audit-begin "$nuinui_audit_generation"
  [ "$nuinui_audit_preflight_rc" = 0 ] &&
    nuinui_audit_output_has_inventory "$nuinui_audit_preflight_output" &&
    nuinui_audit_projection_free_evidence "$nuinui_audit_preflight_output" >/dev/null || {
    lane_execution__unlock "$nuinui_audit_repo" "$nuinui_audit_generation" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not safely release the audit lock after a failed mutation-boundary proof'; return 1; }
    nuinui_audit_lock_held=0
    nuinui_audit_blocked_before_mutation 'target changed before audit reservation acquisition'
    return 1
  }
  fp "$nuinui_audit_repo" &&
    nuinui_audit_validate_remote_revision "$nuinui_audit_requested_revision" || {
    lane_execution__unlock "$nuinui_audit_repo" "$nuinui_audit_generation" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not safely release the audit lock after remote freshness changed'; return 1; }
    nuinui_audit_lock_held=0
    nuinui_audit_blocked_before_mutation 'authoritative remote main changed before checkout mutation'
    return 1
  }

  nuinui_audit_store_reservation PREPARING || { nuinui_audit_blocked_with_reservation 'unable to durably create the audit reservation'; return 1; }
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] &&
    [ "${NUINUI_SELFTEST_CRASH_AT:-}" = audit-after-reservation ]; then
    printf 'BLOCKED: injected interruption after durable audit reservation\nmutation_state=UNKNOWN\nrecovery=preserve-audit-reservation\nissue=%s\nlane=%s\ngeneration=%s\n' \
      "$nuinui_audit_requested_issue" "$nuinui_audit_target_lane" "$nuinui_audit_generation"
    return 97
  fi
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] &&
    [ "${NUINUI_SELFTEST_PAUSE_AT:-}" = audit-after-reservation ]; then
    [ -n "${NUINUI_SELFTEST_PAUSE_READY:-}" ] &&
      [ -n "${NUINUI_SELFTEST_PAUSE_RESUME:-}" ] || { nuinui_audit_blocked_with_reservation 'test pause markers were not configured'; return 1; }
    : > "$NUINUI_SELFTEST_PAUSE_READY" || { nuinui_audit_blocked_with_reservation 'unable to publish test pause marker'; return 1; }
    while [ ! -e "$NUINUI_SELFTEST_PAUSE_RESUME" ]; do sleep 0.02; done
  fi
  fp "$nuinui_audit_repo" &&
    nuinui_audit_validate_remote_revision "$nuinui_audit_requested_revision" || { nuinui_audit_blocked_with_reservation 'authoritative remote main changed after reservation and before checkout mutation'; return 1; }

  if [ "$nuinui_audit_pre_ff_head" != "$nuinui_audit_requested_revision" ]; then
    case "$nuinui_audit_idle" in
      branch)
        git -C "$nuinui_audit_repo" merge --ff-only \
          "$nuinui_audit_requested_revision" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'proven fast-forward to the fixed audit revision failed'; return 1; }
        ;;
      detached)
        git -C "$nuinui_audit_repo" switch --detach \
          "$nuinui_audit_requested_revision" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'proven detached fast-forward to the fixed audit revision failed'; return 1; }
        ;;
    esac
  fi
  [ "$(hh "$nuinui_audit_repo" 2>/dev/null || true)" = "$nuinui_audit_post_ff_base" ] || { nuinui_audit_blocked_with_reservation 'post-fast-forward base does not equal the fixed audit revision'; return 1; }
  nuinui_audit_store_reservation ACTIVE || { nuinui_audit_blocked_with_reservation 'unable to durably advance audit reservation to ACTIVE'; return 1; }
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] &&
    [ "${NUINUI_SELFTEST_CRASH_AT:-}" = audit-after-active ]; then
    printf 'BLOCKED: injected interruption after activation and before detachment\nmutation_state=UNKNOWN\nrecovery=preserve-audit-reservation\nissue=%s\nlane=%s\ngeneration=%s\n' \
      "$nuinui_audit_requested_issue" "$nuinui_audit_target_lane" "$nuinui_audit_generation"
    return 97
  fi
  git -C "$nuinui_audit_repo" switch --detach \
    "$nuinui_audit_requested_revision" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not detach the declared lane at the exact audit revision'; return 1; }
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] &&
    [ "${NUINUI_SELFTEST_CRASH_AT:-}" = audit-after-detach ]; then
    printf 'BLOCKED: injected interruption after fixed-revision detachment\nmutation_state=UNKNOWN\nrecovery=preserve-audit-reservation\nissue=%s\nlane=%s\ngeneration=%s\n' \
      "$nuinui_audit_requested_issue" "$nuinui_audit_target_lane" "$nuinui_audit_generation"
    return 97
  fi
  nuinui_audit_load_reservation "$nuinui_audit_reservation_file" &&
    nuinui_audit_identity_matches_target &&
    [ "$nuinui_audit_state" = ACTIVE ] &&
    [ "$nuinui_audit_issue" = "$nuinui_audit_requested_issue" ] &&
    [ "$nuinui_audit_revision" = "$nuinui_audit_requested_revision" ] &&
    nuinui_audit_clean_active_checkout || { nuinui_audit_blocked_with_reservation 'fixed-revision checkout or durable reservation read-back failed'; return 1; }
  nuinui_audit_reservation_nonfree_proof "$nuinui_audit_manifest" >/dev/null || { nuinui_audit_blocked_with_reservation 'audit reservation is not visible as non-FREE to canonical admission'; return 1; }
  lane_execution__unlock "$nuinui_audit_repo" "$nuinui_audit_generation" || { nuinui_audit_blocked_with_reservation 'could not release the audit-begin mutation lock after verified detachment'; return 1; }
  nuinui_audit_lock_held=0
  nuinui_audit_reservation_nonfree_proof "$nuinui_audit_manifest" >/dev/null || { nuinui_audit_blocked_with_reservation 'post-unlock audit reservation read-back was not authoritative'; return 1; }
  printf 'AUDIT RESERVATION READY\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npre_ff_head=%s\npost_ff_base=%s\nbranch=DETACHED\nhead=%s\nclean=yes\nadmission=BLOCKED reason=audit-reservation\nmutation_state=COMPLETED\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_pre_ff_head" "$nuinui_audit_post_ff_base" "$nuinui_audit_revision"
}

nuinui_audit_release() {
  [ "$#" = 3 ] || return 2
  nuinui_audit_manifest=$1
  nuinui_audit_requested_issue=$2
  nuinui_audit_requested_revision=$(printf '%s' "$3" | tr 'A-F' 'a-f')
  NUINUI_AUDIT_RESOLVED_ISSUE=$nuinui_audit_requested_issue
  NUINUI_AUDIT_RESOLVED_LANE=-
  NUINUI_AUDIT_RESOLVED_GENERATION=
  lane_execution_validate_work_id "$nuinui_audit_requested_issue" || { nuinui_audit_blocked_before_mutation 'Issue must be a valid SAY identifier'; return 1; }
  nuinui_ownership_valid_sha "$nuinui_audit_requested_revision" || { nuinui_audit_blocked_before_mutation 'revision must be a full 40-character commit SHA'; return 1; }

  lane_manifest_validate "$nuinui_audit_manifest" || { nuinui_audit_blocked_before_mutation 'lane manifest is invalid'; return 1; }
  nuinui_audit_matches=
  while IFS= read -r nuinui_audit_candidate_lane || [ -n "$nuinui_audit_candidate_lane" ]; do
    [ -n "$nuinui_audit_candidate_lane" ] || continue
    nuinui_audit_candidate_path=$(lane_manifest_lane_path \
      "$nuinui_audit_manifest" "$nuinui_audit_candidate_lane") || continue
    nuinui_audit_candidate_path=$(lane_execution__canonical_path \
      "$nuinui_audit_candidate_path" 2>/dev/null || true)
    [ -n "$nuinui_audit_candidate_path" ] || continue
    [ "$nuinui_audit_candidate_path" = "$(lane_execution__canonical_path \
      "$(lane_manifest_lane_path "$nuinui_audit_manifest" "$nuinui_audit_candidate_lane" 2>/dev/null || true)" 2>/dev/null || true)" ] || continue
    [ "$(lane_manifest_lane_role "$nuinui_audit_manifest" \
      "$nuinui_audit_candidate_lane" 2>/dev/null || true)" = implementation ] || continue
    nuinui_audit_candidate_git_dir=$(lane_execution__git_dir \
      "$nuinui_audit_candidate_path" 2>/dev/null || true)
    [ -n "$nuinui_audit_candidate_git_dir" ] || continue
    if [ -f "$(ap "$nuinui_audit_candidate_path")" ] ||
      [ -L "$(ap "$nuinui_audit_candidate_path")" ]; then
      [ -z "$nuinui_audit_matches" ] || { nuinui_audit_blocked_before_mutation 'multiple active audit reservations make release ambiguous'; return 1; }
      nuinui_audit_matches=$nuinui_audit_candidate_lane
    fi
  done <<EOF
$(lane_manifest_lanes_by_role "$nuinui_audit_manifest" implementation)
EOF

  if [ -z "$nuinui_audit_matches" ]; then
    nuinui_audit_receipt_lane=
    while IFS= read -r nuinui_audit_candidate_lane || [ -n "$nuinui_audit_candidate_lane" ]; do
      [ -n "$nuinui_audit_candidate_lane" ] || continue
      nuinui_audit_candidate_path=$(lane_manifest_lane_path \
        "$nuinui_audit_manifest" "$nuinui_audit_candidate_lane") || continue
      nuinui_audit_candidate_git_dir=$(lane_execution__git_dir \
        "$nuinui_audit_candidate_path" 2>/dev/null || true)
      [ -n "$nuinui_audit_candidate_git_dir" ] || continue
      nuinui_audit_candidate_receipt=$(arp "$nuinui_audit_candidate_path")
      if [ -f "$nuinui_audit_candidate_receipt" ] || [ -L "$nuinui_audit_candidate_receipt" ]; then
        [ -z "$nuinui_audit_receipt_lane" ] || { nuinui_audit_blocked_before_mutation 'multiple audit release receipts make duplicate release ambiguous'; return 1; }
        nuinui_audit_receipt_lane=$nuinui_audit_candidate_lane
        nuinui_audit_receipt_candidate_path=$nuinui_audit_candidate_path
      fi
    done <<EOF
$(lane_manifest_lanes_by_role "$nuinui_audit_manifest" implementation)
EOF
    [ -n "$nuinui_audit_receipt_lane" ] || { nuinui_audit_blocked_before_mutation 'no matching active audit reservation or release receipt exists'; return 1; }
    nuinui_audit_target "$nuinui_audit_manifest" "$nuinui_audit_receipt_lane" || { nuinui_audit_blocked_before_mutation 'release receipt target is not a declared implementation lane'; return 1; }
    [ ! -e "$nuinui_audit_reservation_file" ] && [ ! -L "$nuinui_audit_reservation_file" ] &&
      [ ! -e "$(kp "$nuinui_audit_repo")" ] && [ ! -L "$(kp "$nuinui_audit_repo")" ] || { nuinui_audit_blocked_before_mutation 'audit or mutation ownership changed during duplicate release read-back'; return 1; }
    nuinui_audit_load_receipt "$nuinui_audit_receipt_file" &&
      nuinui_audit_receipt_matches_target &&
      [ "$nuinui_audit_receipt_issue" = "$nuinui_audit_requested_issue" ] &&
      [ "$nuinui_audit_receipt_revision" = "$nuinui_audit_requested_revision" ] || { nuinui_audit_blocked_before_mutation 'release receipt does not exactly match the requested Issue and revision'; return 1; }
    NUINUI_AUDIT_RESOLVED_LANE=$nuinui_audit_target_lane
    NUINUI_AUDIT_RESOLVED_GENERATION=$nuinui_audit_receipt_generation
    nuinui_audit_receipt_base=$nuinui_audit_receipt_base
    nuinui_audit_current_branch=$(bn "$nuinui_audit_repo")
    nuinui_audit_expected_branch=$nuinui_audit_receipt_branch
    [ "$nuinui_audit_expected_branch" != - ] || nuinui_audit_expected_branch=
    [ "$(hh "$nuinui_audit_repo" 2>/dev/null || true)" = "$nuinui_audit_receipt_base" ] &&
      [ "$nuinui_audit_current_branch" = "$nuinui_audit_expected_branch" ] &&
      [ -z "$(git -C "$nuinui_audit_repo" status --porcelain 2>/dev/null)" ] || { nuinui_audit_blocked_before_mutation 'recorded released checkout is no longer in its canonical clean idle state'; return 1; }
    nuinui_audit_initial_free_proof "$nuinui_audit_manifest" || { nuinui_audit_blocked_before_mutation 'duplicate release read-back did not prove canonical FREE state'; return 1; }
    nuinui_audit_projection_free_evidence "$nuinui_audit_preflight_output" > /dev/null || { nuinui_audit_blocked_before_mutation 'duplicate release did not read back FREE or FREE/STALE'; return 1; }
    nuinui_audit_projection_line=$(nuinui_audit_projection_free_evidence \
      "$nuinui_audit_preflight_output") || return 1
    printf 'AUDIT ALREADY RELEASED\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npost_ff_base=%s\n%s\nclean=yes\nmutation=no-op\n' \
      "$nuinui_audit_receipt_issue" "$nuinui_audit_receipt_lane" \
      "$nuinui_audit_receipt_revision" "$nuinui_audit_receipt_generation" \
      "$nuinui_audit_receipt_checkout" "$nuinui_audit_receipt_base" \
      "$nuinui_audit_projection_line"
    return 0
  fi

  nuinui_audit_target "$nuinui_audit_manifest" "$nuinui_audit_matches" || { nuinui_audit_blocked_before_mutation 'active reservation target is not a declared implementation lane'; return 1; }
  if [ -e "$nuinui_audit_receipt_file" ] || [ -L "$nuinui_audit_receipt_file" ]; then
    nuinui_audit_load_receipt "$nuinui_audit_receipt_file" &&
      nuinui_audit_receipt_matches_target || { nuinui_audit_blocked_before_mutation 'existing audit receipt is malformed or belongs to another checkout'; return 1; }
  fi
  nuinui_audit_reservation_fields_valid_for_request || { nuinui_audit_blocked_before_mutation 'active audit reservation does not exactly match the requested Issue, lane, and revision'; return 1; }
  nuinui_audit_prepare_result_identity
  [ "$nuinui_audit_state" = ACTIVE ] && nuinui_audit_clean_active_checkout || { nuinui_audit_blocked_with_reservation 'release requires the exact clean detached ACTIVE audit checkout'; return 1; }
  nuinui_audit_lock=$(kp "$nuinui_audit_repo")
  [ ! -e "$nuinui_audit_lock" ] && [ ! -L "$nuinui_audit_lock" ] || { nuinui_audit_blocked_with_reservation 'an unresolved mutation lock prevents audit release'; return 1; }
  nuinui_audit_reservation_nonfree_proof "$nuinui_audit_manifest" >/dev/null || { nuinui_audit_blocked_with_reservation 'active reservation is not proven by canonical admission preflight'; return 1; }
  nuinui_audit_generation=$nuinui_audit_generation
  nuinui_audit_release_generation=$nuinui_audit_generation
  lane_execution__lock "$nuinui_audit_repo" "$nuinui_audit_release_generation" \
    - - "$nuinui_audit_requested_revision" audit-release || { nuinui_audit_blocked_with_reservation 'could not acquire the existing per-lane release mutation lock'; return 1; }
  nuinui_audit_load_reservation "$nuinui_audit_reservation_file" &&
    nuinui_audit_identity_matches_target &&
    [ "$nuinui_audit_state" = ACTIVE ] &&
    [ "$nuinui_audit_issue" = "$nuinui_audit_requested_issue" ] &&
    [ "$nuinui_audit_revision" = "$nuinui_audit_requested_revision" ] &&
    nuinui_audit_clean_active_checkout || { nuinui_audit_blocked_with_reservation 'release mutation-boundary reservation read-back failed'; return 1; }
  nuinui_audit_store_state=RELEASING
  nuinui_audit_store_content=$(printf 'version=1\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\ngit_dir=%s\nrepository=%s\ndefault_branch=%s\nidle_policy=%s\noriginal_branch=%s\npre_ff_head=%s\npost_ff_base=%s\nstate=RELEASING\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_stored_git_dir" "$nuinui_audit_stored_repository" \
    "$nuinui_audit_stored_default" "$nuinui_audit_stored_idle" \
    "$nuinui_audit_original_branch" "$nuinui_audit_pre_ff_head" \
    "$nuinui_audit_post_ff_base")
  lane_execution__atomic_write "$nuinui_audit_reservation_file" \
    "$nuinui_audit_store_content" || { nuinui_audit_blocked_with_reservation 'unable to durably mark the audit reservation as RELEASING'; return 1; }
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] &&
    [ "${NUINUI_SELFTEST_CRASH_AT:-}" = audit-release-after-marker ]; then
    printf 'BLOCKED: injected interruption after release marker\nmutation_state=UNKNOWN\nrecovery=preserve-audit-reservation\nissue=%s\nlane=%s\ngeneration=%s\n' \
      "$nuinui_audit_requested_issue" "$nuinui_audit_target_lane" "$nuinui_audit_generation"
    return 97
  fi
  if [ "$nuinui_audit_idle" = branch ]; then
    [ "$(git -C "$nuinui_audit_repo" rev-parse \
      "refs/heads/$nuinui_audit_default^{commit}" 2>/dev/null || true)" = \
      "$nuinui_audit_post_ff_base" ] || { nuinui_audit_blocked_with_reservation 'recorded canonical idle branch no longer points at the post-fast-forward base'; return 1; }
    git -C "$nuinui_audit_repo" switch "$nuinui_audit_default" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not restore the recorded canonical idle branch'; return 1; }
  else
    git -C "$nuinui_audit_repo" switch --detach \
      "$nuinui_audit_post_ff_base" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not restore the recorded canonical detached idle form'; return 1; }
  fi
  lane_execution__occupancy_idle_proof "$nuinui_audit_target_lane" \
    "$nuinui_audit_repo" "$nuinui_audit_idle" "$nuinui_audit_default" \
    "$nuinui_audit_post_ff_base" || { nuinui_audit_blocked_with_reservation 'restored checkout does not match the recorded clean idle base'; return 1; }
  nuinui_audit_read_preflight "$nuinui_audit_manifest" audit-release \
    "$nuinui_audit_generation"
  [ "$nuinui_audit_preflight_rc" = 0 ] &&
    nuinui_audit_output_has_inventory "$nuinui_audit_preflight_output" || { nuinui_audit_blocked_with_reservation 'release projection did not prove canonical FREE state'; return 1; }
  nuinui_audit_projection_line=$(nuinui_audit_projection_free_evidence \
    "$nuinui_audit_preflight_output") || { nuinui_audit_blocked_with_reservation 'release projection did not prove FREE or FREE/STALE'; return 1; }

  nuinui_audit_released_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ') || { nuinui_audit_blocked_with_reservation 'unable to allocate release receipt timestamp'; return 1; }
  nuinui_audit_receipt_content=$(printf 'version=1\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\ngit_dir=%s\nrepository=%s\ndefault_branch=%s\nidle_policy=%s\noriginal_branch=%s\npre_ff_head=%s\npost_ff_base=%s\nreleased_at=%s\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_stored_git_dir" "$nuinui_audit_stored_repository" \
    "$nuinui_audit_stored_default" "$nuinui_audit_stored_idle" \
    "$nuinui_audit_original_branch" "$nuinui_audit_pre_ff_head" \
    "$nuinui_audit_post_ff_base" "$nuinui_audit_released_at")
  lane_execution__atomic_write "$nuinui_audit_receipt_file" \
    "$nuinui_audit_receipt_content" || { nuinui_audit_blocked_with_reservation 'unable to persist the exact audit release receipt'; return 1; }
  nuinui_ownership_validate_audit_receipt "$nuinui_audit_receipt_file" || { nuinui_audit_blocked_with_reservation 'persisted audit release receipt failed strict read-back'; return 1; }
  nuinui_audit_receipt_read_generation=$(nuinui_ownership_field \
    "$nuinui_audit_receipt_file" generation) || { nuinui_audit_blocked_with_reservation 'release receipt generation read-back failed'; return 1; }
  [ "$nuinui_audit_receipt_read_generation" = "$nuinui_audit_generation" ] || { nuinui_audit_blocked_with_reservation 'release receipt generation does not match the reservation'; return 1; }
  nuinui_audit_load_reservation "$nuinui_audit_reservation_file" &&
    [ "$nuinui_audit_generation" = "$nuinui_audit_release_generation" ] &&
    [ "$nuinui_audit_state" = RELEASING ] || { nuinui_audit_blocked_with_reservation 'reservation changed before its protected release point'; return 1; }
  lane_execution__unlock "$nuinui_audit_repo" "$nuinui_audit_release_generation" || { nuinui_audit_blocked_with_reservation 'could not release the audit-release mutation lock'; return 1; }
  rm -f -- "$nuinui_audit_reservation_file" || { nuinui_audit_blocked_with_reservation 'could not remove the exact released reservation after unlocking'; return 1; }
  [ ! -e "$nuinui_audit_reservation_file" ] &&
    [ ! -L "$nuinui_audit_reservation_file" ] || { nuinui_audit_blocked_with_reservation 'released reservation path still exists after removal'; return 1; }
  nuinui_audit_released_branch=$nuinui_audit_original_branch
  [ "$nuinui_audit_released_branch" != - ] || nuinui_audit_released_branch=DETACHED
  printf 'AUDIT RELEASED\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npost_ff_base=%s\nbranch=%s\nhead=%s\nclean=yes\n%s\nstate=FREE\nmutation_state=COMPLETED\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_post_ff_base" \
    "$nuinui_audit_released_branch" "$nuinui_audit_post_ff_base" \
    "$nuinui_audit_projection_line"
}
